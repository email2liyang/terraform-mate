terraform {
  backend "s3" {
    bucket         = "temp-pi-terraform-state"
    key            = "live/global/s3"
    dynamodb_table = "terraform_state_locker"
    region         = "us-west-2"
  }
}

provider "aws" {
  version = ">= 1.24.0"
  region  = "${var.region}"
}

resource "aws_s3_bucket" "corp_artifact_repo" {
  bucket = "${var.bucket_name}"

  versioning {
    enabled = false
  }

  lifecycle {
    prevent_destroy = true
  }
}
