# terraform.backend: configuration cannot contain interpolations
terraform {
  backend "s3" {
    bucket = "terraform-mate"
    key    = "unit5/prod/compute/ec2.tfstate"
    region = "ap-southeast-2"

    # The table must have a primary key named LockID
    dynamodb_table = "terraform_state_locker"
    profile        = "psn"
  }
}

provider "aws" {
  region  = "${var.region}"
  profile = "${var.profile}"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket  = "${var.terraform_state_bucket}"
    key     = "unit5/prod/network/vpc.tfstate"
    region  = "${var.region}"
    profile = "${var.profile}"
  }
}

data "terraform_remote_state" "security_groups" {
  backend = "s3"

  config {
    bucket  = "${var.terraform_state_bucket}"
    key     = "unit5/prod/network/security_groups.tfstate"
    region  = "${var.region}"
    profile = "${var.profile}"
  }
}

resource "aws_instance" "vpc_worker_node" {
  ami                    = "ami-00e17d1165b9dd3ec"
  instance_type          = "t2.micro"
  key_name               = "${var.key_name}"
  subnet_id              = "${element(data.terraform_remote_state.vpc.vpc_public_subnets,0 )}"
  vpc_security_group_ids = ["${data.terraform_remote_state.vpc.vpc_default_security_group_id}", "${data.terraform_remote_state.security_groups.ssh_security_group_id}"]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "vpc_standard_worker_node" {
  source                 = "../../../modules/compute/ec2/vpc_standard_worker_node"
  instance_count         = 2
  subnet_id              = "${element(data.terraform_remote_state.vpc.vpc_public_subnets,0 )}"
  vpc_security_group_ids = ["${data.terraform_remote_state.vpc.vpc_default_security_group_id}", "${data.terraform_remote_state.security_groups.ssh_security_group_id}"]
  user_data = "${var.user_data}"
}
