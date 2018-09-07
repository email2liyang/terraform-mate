output "s3_bucket_arn" {
  value = "${aws_s3_bucket.corp_artifact_repo.arn}"
}
