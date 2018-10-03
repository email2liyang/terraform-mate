output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "vpc_default_security_group_id" {
  value = "${module.vpc.default_security_group_id}"
}

output "ssh_security_group_id" {
  value = "${module.ssh_security_group.this_security_group_id}"
}

output "vpc_worker_public_ip" {
  value = "${aws_instance.vpc_work_node.public_ip}"
}
