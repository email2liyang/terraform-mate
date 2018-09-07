variable "region" {
  default = "us-west-2"
}

variable "bucket_name" {
  description = "The name of the S3 bucket. Must be globally unique."
  default = "corp-artifact-repo"
}
