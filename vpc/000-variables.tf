## VARIABLES

variable "region" {
  default = "eu-west-1"
}

variable "cidr" {
  default = "192.168.0.0/22"
}

variable "vpc_name" {
  default = "Dev"
}

variable "env" {
  default = "dev"
}

variable "azs" {
  default = 0
}

variable "instance_type" {
  default = "t2.small"
}

variable "keypair_name" {
  default = ""
}

## DATA

data "aws_availability_zones" "available" {}

data "external" "cidrs" {
  program = ["./vpc_subnets_terraform.sh", "--cidr ${var.cidr}", "--azs ${local.azs_count}"]
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

## LOCALS

locals {
  "azs_count"  = "${var.azs != 0 ? var.azs : length(data.aws_availability_zones.available.names)}"
  "app_cidrs"  = "${split("|", data.external.cidrs.result["app"])}"
  "pub_cidrs"  = "${split("|", data.external.cidrs.result["pub"])}"
  "stor_cidrs" = "${split("|", data.external.cidrs.result["stor"])}"
}

locals {
  ansible_vars_file_path = "/var/tmp/cf_vars.yml"
}
