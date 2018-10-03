output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "vpc_default_security_group_id" {
  value = "${module.vpc.default_security_group_id}"
}

output "ssh_security_group_id" {
  value = "${module.ssh_security_group.this_security_group_id}"
}
