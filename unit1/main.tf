provider "aws" {
  region  = "ap-southeast-2"
  profile = "psn"
}

resource "aws_instance" "work-node" {
  ami           = "ami-00e17d1165b9dd3ec"
  instance_type = "t2.micro"
}
