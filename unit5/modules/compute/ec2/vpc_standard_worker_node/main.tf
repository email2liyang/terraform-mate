#standard vpc worker nodes

resource "aws_instance" "vpc_standard_worker_node" {
  count = "${var.instance_count}"

  ami                    = "ami-00e17d1165b9dd3ec"
  instance_type          = "${var.instance_type}"
  user_data              = "${var.user_data}"
  subnet_id              = "${var.subnet_id}"
  key_name               = "${var.key_name}"
  vpc_security_group_ids = ["${var.vpc_security_group_ids}"]

  tags = "${var.tags}"
}
