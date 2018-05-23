
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

## DATA

data "aws_availability_zones" "available" {}

data "external" "cidrs" {
  program = ["./vpc_subnets_terraform.sh", "--cidr ${var.cidr}", "--azs ${local.azs_count}"]
}

## LOCALS

locals {
  "azs_count"  = "${var.azs != 0 ? var.azs : length(data.aws_availability_zones.available.names)}"
  "app_cidrs"  = "${split("|", data.external.cidrs.result["app"])}"
  "pub_cidrs"  = "${split("|", data.external.cidrs.result["pub"])}"
  "stor_cidrs" = "${split("|", data.external.cidrs.result["stor"])}"
}
