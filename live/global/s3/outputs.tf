output "s3_bucket_arn" {
  value = "${aws_s3_bucket.corp_artifact_repo.arn}"
}
//the name of the bucket
output "bucket_name" {
  value = "${aws_s3_bucket.corp_artifact_repo.id}"
}
//the arn of the user that was created
output "user_arn_rw" {
  value = "${aws_iam_user.s3_repo_user_rw.arn}"
}
//the name of the service account user that was created
output "user_name_rw" {
  value = "${aws_iam_user.s3_repo_user_rw.name}"
}
//the access key
output "iam_access_key_id_rw" {
  value = "${aws_iam_access_key.s3_repo_user_keys_rw.id}"
}
//the access key secret
output "iam_access_key_secret_rw" {
  value = "${aws_iam_access_key.s3_repo_user_keys_rw.secret}"
}
//the arn of the user that was created
output "user_arn_ro" {
  value = "${aws_iam_user.s3_repo_user_ro.arn}"
}
//the name of the service account user that was created
output "user_name_ro" {
  value = "${aws_iam_user.s3_repo_user_ro.name}"
}
//the access key
output "iam_access_key_id_ro" {
  value = "${aws_iam_access_key.s3_repo_user_keys_ro.id}"
}
//the access key secret
output "iam_access_key_secret_ro" {
  value = "${aws_iam_access_key.s3_repo_user_keys_ro.secret}"
}
