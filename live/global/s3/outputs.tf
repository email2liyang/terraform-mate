output "s3_bucket_arn" {
  value = "${aws_s3_bucket.corp_artifact_repo.arn}"
}

//the arn of the user that was created
output "user_arn_rw" {
  value = "${aws_iam_user.s3_repo_user_rw.arn}"
}

//the name of the service account user that was created
output "user_name_rw" {
  value = "${aws_iam_user.s3_repo_user_rw.name}"
}

//the name of the bucket
output "bucket_name" {
  value = "${aws_s3_bucket.corp_artifact_repo.id}"
}

//the access key
output "iam_access_key_id_rw" {
  value = "${aws_iam_access_key.s3_repo_user_keys_rw.id}"
}

//the access key secret
output "iam_access_key_secret_rw" {
  value = "${aws_iam_access_key.s3_repo_user_keys_rw.secret}"
}
