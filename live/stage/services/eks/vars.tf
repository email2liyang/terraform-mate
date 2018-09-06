variable "aws_region" {
  description = "The AWS region to use"
  default     = "us-west-2"
}

variable "cluster-name" {
  default = "stage-online"
  type    = "string"
}
