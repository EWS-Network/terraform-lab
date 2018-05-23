variable "region" {
  default = "eu-west-1"
}

variable "app_name" {
  default = "hello_world"
}

variable "vpc_name" {
  default = "Dev"
}

variable "env" {
  default = "dev"
}

variable "instance_type" {
  default = "t2.small"
}

variable "keypair_name" {
  default = ""
}

locals {
  ansible_vars_file_path = "/var/tmp/cf_vars.yml"
}

data "aws_vpc" "root" {
  tags {
    Name = "${var.vpc_name}"
  }
}

data "aws_subnet_ids" "app" {
  vpc_id = "${data.aws_vpc.root.id}"

  tags {
    Usage = "Public"
  }
}

data "aws_ami" "centos" {
  most_recent = true

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["CentOS Linux 7 x86_64 HVM EBS*ENA*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"] # MarketPlace
}
