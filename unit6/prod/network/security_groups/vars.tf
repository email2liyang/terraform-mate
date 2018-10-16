variable "region" {
  default = "ap-southeast-2"
}

variable "profile" {
  description = "aws profile to use"
  default     = "psn"
}

variable "terraform_state_bucket" {
  default = "terraform-mate"
}
