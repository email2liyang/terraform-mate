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
    prevent_destroy = false
  }
}

# we need a service account user
resource "aws_iam_user" "s3_repo_user_rw" {
  name = "srv_${var.bucket_name}_rw"
}

# generate keys for service account user
resource "aws_iam_access_key" "s3_repo_user_keys_rw" {
  user = "${aws_iam_user.s3_repo_user_rw.name}"
}

# grant user access to the bucket
resource "aws_s3_bucket_policy" "bucket_policy_rw" {
  bucket = "${aws_s3_bucket.corp_artifact_repo.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_iam_user.s3_repo_user_rw.arn}"
      },
      "Action": [ "s3:*" ],
      "Resource": [
        "${aws_s3_bucket.corp_artifact_repo.arn}",
        "${aws_s3_bucket.corp_artifact_repo.arn}/*"
      ]
    }
  ]
}
EOF
}
