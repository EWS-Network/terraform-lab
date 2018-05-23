
resource "aws_security_group" "web_sg" {
  name        = "${format("%s-sg", var.app_name)}"
  description = "${format("Main SG for %s", var.app_name)}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "allow_all"
  }
}

