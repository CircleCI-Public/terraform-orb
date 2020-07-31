provider "aws" {
  region = "us-west-1"
}

terraform {
  backend "s3" {
    bucket = "terracube"
    key    = "terraform.tfstate"
    region = "us-west-1"
  }
}

resource "aws_security_group" "instance" {
  name = "terracube-example"
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "tag1" {}
variable "tag2" {}

resource "aws_instance" "example" {
  ami                    = "ami-059b818564104e5c6"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]
  user_data              = <<-EOF
              #!/bin/bash
              echo "<h1>Hello from CircleCI!</h1>" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
  tags = {
    Name = "terraform-example"
    Tag1 = var.tag1
    Tag2 = var.tag2
  }
}

output "instance_ips" {
  value = ["${aws_instance.example.*.public_ip}"]
}