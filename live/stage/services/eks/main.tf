terraform {
  backend "s3" {
    bucket         = "temp-pi-terraform-state"
    key            = "live/stage/services/eks"
    dynamodb_table = "terraform_state_locker"
    region         = "us-west-2"
  }
}

# This data source is included for ease of sample architecture deployment
# and can be swapped out as necessary.
data "aws_availability_zones" "available" {}

provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_vpc" "stage-ip-aws-vpc" {
  cidr_block = "10.31.0.0/16"

  tags = "${
    map(
     "Name", "stage-ip-aws-vpc",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",

    )
  }"
}

resource "aws_subnet" "stage-ip-aws-subnet-a" {
  availability_zone = "us-west-2a"
  cidr_block        = "10.31.1.0/24"
  vpc_id            = "${aws_vpc.stage-ip-aws-vpc.id}"

  tags = "${
    map(
     "Name", "stage-ip-aws-subnet-a",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_subnet" "stage-ip-aws-subnet-b" {
  availability_zone = "us-west-2b"
  cidr_block        = "10.31.2.0/24"
  vpc_id            = "${aws_vpc.stage-ip-aws-vpc.id}"

  tags = "${
    map(
     "Name", "stage-ip-aws-subnet-b",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_internet_gateway" "stage-ip-aws-gw" {
  vpc_id = "${aws_vpc.stage-ip-aws-vpc.id}"

  tags {
    Name = "stage-ip-aws-gw"
  }
}

resource "aws_route_table" "stage-ip-aws-route-table" {
  vpc_id = "${aws_vpc.stage-ip-aws-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.stage-ip-aws-gw.id}"
  }

  tags {
    Name = "stage-ip-aws-route-table"
  }
}

resource "aws_route_table_association" "stage-ip-aws-route-table-ass-a" {
  subnet_id      = "${aws_subnet.stage-ip-aws-subnet-a.id}"
  route_table_id = "${aws_route_table.stage-ip-aws-route-table.id}"
}

resource "aws_route_table_association" "stage-ip-aws-route-table-ass-b" {
  subnet_id      = "${aws_subnet.stage-ip-aws-subnet-b.id}"
  route_table_id = "${aws_route_table.stage-ip-aws-route-table.id}"
}

resource "aws_iam_role" "eks-stage-online-iam-role" {
  name = "eks-stage-online-iam-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks-stage-online-iam-role-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.eks-stage-online-iam-role.name}"
}

resource "aws_iam_role_policy_attachment" "eks-stage-online-iam-role-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.eks-stage-online-iam-role.name}"
}

resource "aws_security_group" "eks-stage-online-sg" {
  name        = "eks-stage-online-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = "${aws_vpc.stage-ip-aws-vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "eks-stage-online-sg"
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
  security_group_id = "${aws_security_group.eks-stage-online-sg.id}"
  to_port           = 443
  type              = "ingress"
}

resource "aws_eks_cluster" "stage-online-cluster" {
  name     = "${var.cluster-name}"
  role_arn = "${aws_iam_role.eks-stage-online-iam-role.arn}"

  vpc_config {
    security_group_ids = ["${aws_security_group.eks-stage-online-sg.id}"]
    subnet_ids         = ["${aws_subnet.stage-ip-aws-subnet-a.id}", "${aws_subnet.stage-ip-aws-subnet-b.id}"]
  }

  depends_on = [
    "aws_iam_role_policy_attachment.eks-stage-online-iam-role-AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.eks-stage-online-iam-role-AmazonEKSServicePolicy",
  ]
}

# worker nodes
## IAM
resource "aws_iam_role" "stage-online-node" {
  name = "stage-online-node"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "stage-online-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.stage-online-node.name}"
}

resource "aws_iam_role_policy_attachment" "stage-online-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.stage-online-node.name}"
}

resource "aws_iam_role_policy_attachment" "stage-online-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.stage-online-node.name}"
}

resource "aws_iam_instance_profile" "stage-online-node" {
  name = "stage-online"
  role = "${aws_iam_role.stage-online-node.name}"
}

## security group
resource "aws_security_group" "stage-online-node" {
  name        = "stage-online-node"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${aws_vpc.stage-ip-aws-vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "stage-online-node",
     "kubernetes.io/cluster/${var.cluster-name}", "owned",
    )
  }"
}

resource "aws_security_group_rule" "stage-online-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.stage-online-node.id}"
  source_security_group_id = "${aws_security_group.stage-online-node.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "stage-online-node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.stage-online-node.id}"
  source_security_group_id = "${aws_security_group.eks-stage-online-sg.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "stage-online-cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.eks-stage-online-sg.id}"
  source_security_group_id = "${aws_security_group.stage-online-node.id}"
  to_port                  = 443
  type                     = "ingress"
}

## eks worker through auto scaling group
data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon
}

# This data source is included for ease of sample architecture deployment
# and can be swapped out as necessary.
data "aws_region" "current" {}

# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# We utilize a Terraform local here to simplify Base64 encoding this
# information into the AutoScaling Launch Configuration.
# More information: https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-06-05/amazon-eks-nodegroup.yaml
locals {
  stage-online-node-userdata = <<USERDATA
#!/bin/bash -xe

CA_CERTIFICATE_DIRECTORY=/etc/kubernetes/pki
CA_CERTIFICATE_FILE_PATH=$CA_CERTIFICATE_DIRECTORY/ca.crt
mkdir -p $CA_CERTIFICATE_DIRECTORY
echo "${aws_eks_cluster.stage-online-cluster.certificate_authority.0.data}" | base64 -d >  $CA_CERTIFICATE_FILE_PATH
INTERNAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
sed -i s,MASTER_ENDPOINT,${aws_eks_cluster.stage-online-cluster.endpoint},g /var/lib/kubelet/kubeconfig
sed -i s,CLUSTER_NAME,${var.cluster-name},g /var/lib/kubelet/kubeconfig
sed -i s,REGION,${data.aws_region.current.name},g /etc/systemd/system/kubelet.service
sed -i s,MAX_PODS,20,g /etc/systemd/system/kubelet.service
sed -i s,MASTER_ENDPOINT,${aws_eks_cluster.stage-online-cluster.endpoint},g /etc/systemd/system/kubelet.service
sed -i s,INTERNAL_IP,$INTERNAL_IP,g /etc/systemd/system/kubelet.service
DNS_CLUSTER_IP=10.100.0.10
if [[ $INTERNAL_IP == 10.* ]] ; then DNS_CLUSTER_IP=172.20.0.10; fi
sed -i s,DNS_CLUSTER_IP,$DNS_CLUSTER_IP,g /etc/systemd/system/kubelet.service
sed -i s,CERTIFICATE_AUTHORITY_FILE,$CA_CERTIFICATE_FILE_PATH,g /var/lib/kubelet/kubeconfig
sed -i s,CLIENT_CA_FILE,$CA_CERTIFICATE_FILE_PATH,g  /etc/systemd/system/kubelet.service
systemctl daemon-reload
systemctl restart kubelet
USERDATA
}

resource "aws_launch_configuration" "stage-online" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.stage-online-node.name}"
  image_id                    = "${data.aws_ami.eks-worker.id}"
  instance_type               = "m4.large"
  name_prefix                 = "stage-online-node"
  security_groups             = ["${aws_security_group.stage-online-node.id}"]
  user_data_base64            = "${base64encode(local.stage-online-node-userdata)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "stage-online" {
  desired_capacity     = 2
  launch_configuration = "${aws_launch_configuration.stage-online.id}"
  max_size             = 2
  min_size             = 1
  name                 = "stage-online"
  vpc_zone_identifier  = ["${aws_subnet.stage-ip-aws-subnet-a.id}", "${aws_subnet.stage-ip-aws-subnet-b.id}"]

  tag {
    key                 = "Name"
    value               = "stage-online"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }
}
