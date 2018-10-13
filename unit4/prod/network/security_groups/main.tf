# terraform.backend: configuration cannot contain interpolations
terraform {
  backend "s3" {
    bucket = "terraform-mate"
    key    = "unit4/prod/network/security_groups.tfstate"
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
    key     = "unit4/prod/network/vpc.tfstate"
    region  = "${var.region}"
    profile = "${var.profile}"
  }
}

module "ssh_security_group" {
  source = "terraform-aws-modules/security-group/aws//modules/ssh"

  name                = "ssh_security_group"
  vpc_id              = "${data.terraform_remote_state.vpc.vpc_id}"
  ingress_cidr_blocks = ["0.0.0.0/0"]
}
