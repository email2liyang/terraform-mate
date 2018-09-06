terraform {
  backend "s3" {
    bucket         = "temp-pi-terraform-state"
    key            = "live/stage/services/eks-module"
    dynamodb_table = "terraform_state_locker"
    region         = "us-west-2"
  }
}

provider "aws" {
  version = ">= 1.24.0"
  region  = "${var.region}"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.14.0"

  name = "test-vpc"
  cidr = "10.31.0.0/16"

  azs            = ["us-west-2a", "us-west-2b"]
  public_subnets = ["10.31.1.0/24", "10.31.2.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_security_group" "stage-online-master" {
  name        = "eks-stage-online-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = "${module.vpc.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "stage-online-master"
  }
}

# OPTIONAL: Allow inbound traffic from your local workstation external IP
#           to the Kubernetes. You will need to replace A.B.C.D below with
#           your real IP. Services like icanhazip.com can help you find this.
resource "aws_security_group_rule" "eks-stage-online-ingress-workstation-https" {
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.stage-online-master.id}"
  to_port           = 443
  type              = "ingress"
}

resource "aws_security_group" "stage-online-worker" {
  name        = "stage-online-worker"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${module.vpc.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "stage-online-worker",
     "kubernetes.io/cluster/${var.cluster_name}", "owned",
    )
  }"
}

resource "aws_security_group_rule" "stage-online-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.stage-online-worker.id}"
  source_security_group_id = "${aws_security_group.stage-online-worker.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "stage-online-node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.stage-online-worker.id}"
  source_security_group_id = "${aws_security_group.stage-online-master.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "stage-online-cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.stage-online-master.id}"
  source_security_group_id = "${aws_security_group.stage-online-worker.id}"
  to_port                  = 443
  type                     = "ingress"
}

locals {
  # the commented out worker group list below shows an example of how to define  # multiple worker groups of differing configurations  # worker_groups = "${list(  #                   map("asg_desired_capacity", "2",  #                       "asg_max_size", "10",  #                       "asg_min_size", "2",  #                       "instance_type", "m4.xlarge",  #                       "name", "worker_group_a",  #                       "subnets", "${join(",", module.vpc.private_subnets)}",  #                   ),  #                   map("asg_desired_capacity", "1",  #                       "asg_max_size", "5",  #                       "asg_min_size", "1",  #                       "instance_type", "m4.2xlarge",  #                       "name", "worker_group_b",  #                       "subnets", "${join(",", module.vpc.private_subnets)}",  #                   ),  # )}"

  worker_groups = "${list(
    map("instance_type","m4.large",
      "additional_userdata","echo 'm4.large'",
      "subnets", "${join(",", module.vpc.public_subnets)}",
    ),
    map("instance_type","t2.small",
      "additional_userdata","echo 't2.small'",
      "subnets", "${join(",", module.vpc.public_subnets)}",
      "asg_desired_capacity","3",
      "asg_max_size","5",
      "asg_min_size","1",
    )
  )}"

  tags = "${map("Environment", "test",
                "GithubRepo", "terraform-aws-eks",
                "GithubOrg", "terraform-aws-modules",
                "Workspace", "${terraform.workspace}",
  )}"
}

module "eks" {
  source                         = "terraform-aws-modules/eks/aws"
  version                        = "1.6.0"
  cluster_name                   = "${var.cluster_name}"
  subnets                        = ["${module.vpc.public_subnets}"]
  tags                           = "${local.tags}"
  vpc_id                         = "${module.vpc.vpc_id}"
  worker_groups                  = "${local.worker_groups}"
  worker_group_count             = "2"
  worker_security_group_id       = "${aws_security_group.stage-online-worker.id}"
  cluster_security_group_id      = "${aws_security_group.stage-online-master.id}"
  create_elb_service_linked_role = true
}
