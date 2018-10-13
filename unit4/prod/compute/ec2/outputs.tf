output "vpc_worker_public_ip" {
  value = "${aws_instance.vpc_work_node.public_ip}"
}
