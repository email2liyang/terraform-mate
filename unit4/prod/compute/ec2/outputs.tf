output "vpc_worker_public_ip" {
  value = "${aws_instance.vpc_worker_node.public_ip}"
}

output "vpc_standard_worker_public_ips" {
  value = "${module.vpc_standard_worker_node.vpc_standard_worker_node_public_ips}"
}
