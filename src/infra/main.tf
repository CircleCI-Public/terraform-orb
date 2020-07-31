provider "aws" {
  region = "us-west-1"

  # Allow any 2.x version of the AWS provider
  version = "~> 2.0"
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
  ami                    = "ami-059b818564104e5c6"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]
  user_data              = <<-EOF
              #!/bin/bash
              echo "<h1>Hello from CircleCI!</h1>" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
}

output "instance_ips" {
  value = ["${aws_instance.example.*.public_ip}"]
}