provider "aws" {
  region  = "${var.region}"
  profile = "${var.profile}"
}

resource "aws_s3_bucket" "corp_maven_repo" {
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

# we need a service account user
resource "aws_iam_user" "s3_repo_user_ro" {
  name = "srv_${var.bucket_name}_ro"
}

# generate keys for service account user
resource "aws_iam_access_key" "s3_repo_user_keys_ro" {
  user = "${aws_iam_user.s3_repo_user_ro.name}"
}

# grant user access to the bucket
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = "${aws_s3_bucket.corp_maven_repo.id}"

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
        "${aws_s3_bucket.corp_maven_repo.arn}",
        "${aws_s3_bucket.corp_maven_repo.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_iam_user.s3_repo_user_ro.arn}"
      },
      "Action": [
        "s3:GetAccelerateConfiguration",
        "s3:GetAnalyticsConfiguration",
        "s3:GetBucketAcl",
        "s3:GetBucketCORS",
        "s3:GetBucketLocation",
        "s3:GetBucketLogging",
        "s3:GetBucketPolicy",
        "s3:GetBucketRequestPayment",
        "s3:GetBucketTagging",
        "s3:GetBucketVersioning",
        "s3:GetBucketWebsite",
        "s3:GetEncryptionConfiguration",
        "s3:GetInventoryConfiguration",
        "s3:GetIpConfiguration",
        "s3:GetLifecycleConfiguration",
        "s3:GetMetricsConfiguration",
        "s3:GetObject",
        "s3:GetObjectAcl",
        "s3:GetObjectTagging",
        "s3:GetObjectTorrent",
        "s3:GetObjectVersion",
        "s3:GetObjectVersionAcl",
        "s3:GetObjectVersionTagging",
        "s3:GetObjectVersionTorrent",
        "s3:GetReplicationConfiguration",
        "s3:ListBucketVersions",
        "s3:ListMultipartUploadParts"
       ],
      "Resource": [
        "${aws_s3_bucket.corp_maven_repo.arn}",
        "${aws_s3_bucket.corp_maven_repo.arn}/*"
      ]
    }
  ]
}
EOF
}
