locals {
  vpc_standard_worker_node_public_ips = "${compact(concat(aws_instance.vpc_standard_worker_node.*.public_ip, list("")))}"
}

output "vpc_standard_worker_node_public_ips" {
  value = "${local.vpc_standard_worker_node_public_ips}"
}
