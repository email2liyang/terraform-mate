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

module "vpc-stage-ip-aws" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.14.0"

  name = "stage-ip-aws"
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

resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_management"
  vpc_id      = "${module.vpc-stage-ip-aws.vpc_id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.30.0.0/16","10.31.0.0/16"]
  }
}

locals {
  worker_groups = "${list(
    map("instance_type","m5.large",
      "additional_userdata","echo 'm5.large'",
      "subnets", "${join(",", module.vpc-stage-ip-aws.public_subnets)}",
      "asg_desired_capacity","4",
      "asg_max_size","6",
      "asg_min_size","1",
    ),
    map("instance_type","t2.small",
      "additional_userdata","echo 't2.small'",
      "subnets", "${join(",", module.vpc-stage-ip-aws.public_subnets)}",
      "asg_desired_capacity","3",
      "asg_max_size","5",
      "asg_min_size","1",
    )
  )}"

  tags = "${map("Environment", "stage",
                "GithubRepo", "terraform-aws-eks",
                "GithubOrg", "terraform-aws-modules",
                "Workspace", "${terraform.workspace}",
  )}"
}

module "eks-stage-online" {
  source                               = "terraform-aws-modules/eks/aws"
  version                              = "1.6.0"
  cluster_name                         = "${var.cluster_name}"
  subnets                              = ["${module.vpc-stage-ip-aws.public_subnets}"]
  tags                                 = "${local.tags}"
  vpc_id                               = "${module.vpc-stage-ip-aws.vpc_id}"
  worker_groups                        = "${local.worker_groups}"
  worker_group_count                   = "2"
  worker_additional_security_group_ids = ["${aws_security_group.all_worker_mgmt.id}"]

  # create_elb_service_linked_role = true
}

resource "aws_autoscaling_policy" "stage-online-asg" {
  name                   = "stage-online-asg"
  scaling_adjustment     = 2
  adjustment_type        = "ExactCapacity"
  cooldown               = 10
  autoscaling_group_name = "${module.eks-stage-online.workers_asg_names[1]}"
}
