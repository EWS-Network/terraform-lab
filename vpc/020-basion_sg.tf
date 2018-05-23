resource "aws_security_group" "bastion_sg" {
  name        = "${format("bastion-%s-sg", aws_vpc.vpc_root.id)}"
  description = "${format("Bastion SG for %s", aws_vpc.vpc_root.id)}"

  vpc_id = "${aws_vpc.vpc_root.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${format("Bastion SG for %s", aws_vpc.vpc_root.id)}"
  }
}
