

# VPC

resource "aws_vpc" "vpc_root" {
  cidr_block = "${var.cidr}"

  tags {
    Name = "${var.vpc_name}"
    Terraform = "Yes"
  }
}
