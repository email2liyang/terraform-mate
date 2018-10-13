# terraform.backend: configuration cannot contain interpolations
terraform {
  backend "s3" {
    bucket         = "terraform-mate"
    key            = "unit4/prod/network/vpc.tfstate"
    region         = "ap-southeast-2"
    # The table must have a primary key named LockID
    dynamodb_table = "terraform_state_locker"
    profile        = "psn"
  }
}

provider "aws" {
  region  = "${var.region}"
  profile = "${var.profile}"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "dev-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  enable_nat_gateway     = false
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}