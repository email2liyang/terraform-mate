variable "key_name" {
  description = "key name to connect to ec2"
  default     = "id-psn-ap-southeast-2"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "instance_count" {
  default = 0
}

variable "tags" {
  type = "map"

  default = {
    Terraform = "true"
  }
}

variable "subnet_id" {}

variable "vpc_security_group_ids" {
  type = "list"
  default = []
}
