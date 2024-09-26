provider "aws" {
  region = "us-west-1"
}

terraform {
  backend "s3" {
    bucket = "terracube-1"
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

resource "aws_instance" "example" {
  ami                    = "ami-0d53d72369335a9d6"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]
  tags = {
    Instance_Name    = "Ave_Mundus"
    Instance_Purpose = var.purpose
    Instance_Role    = var.role
  }
  user_data = <<-EOF
              #!/bin/bash
              apt update
              apt install busybox
              echo "<h1>Hello from CircleCI!</h1>" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
}

output "instance_ips" {
  value = aws_instance.example.*.public_ip
}