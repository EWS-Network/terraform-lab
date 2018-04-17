
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


provider "aws" {
	 region = "${var.region}"
}

data "aws_availability_zones" "available" {}


data "external" "cidrs" {
    program = [ "/vol0/home/john/ews/cloudformation-templates/network/vpc/vpc_subnets_terraform.sh", "--cidr ${var.cidr}", "--azs ${local.azs_count}" ]
}


locals {
    "azs_count"		= "${length(data.aws_availability_zones.available.names)}"
    "app_cidrs"		= "${split("|", data.external.cidrs.result["app"])}"
    "pub_cidrs"		= "${split("|", data.external.cidrs.result["pub"])}"
    "stor_cidrs"	= "${split("|", data.external.cidrs.result["stor"])}"
}


output "cidrs_app" {
    value = "${local.app_cidrs}"
}


output "cidrs_pub" {
    value = "${local.pub_cidrs}"

}


output "cidrs_stor" {
    value = "${local.stor_cidrs}"

}

output "azs" {
    value = "${data.aws_availability_zones.available.names}"
}


################
#
# VPC
#
################

resource "aws_vpc" "vpc_root" {
    cidr_block	= "${var.cidr}"
    tags {
	Name = "${var.vpc_name}"
    }
}


################
#
# Subnets
#
################

# APP

resource "aws_subnet" "app_subnets" {

    count		= "${local.azs_count}"

    vpc_id		= "${aws_vpc.vpc_root.id}"
    availability_zone	= "${element(data.aws_availability_zones.available.names, count.index)}"
    cidr_block		= "${element(local.app_cidrs, count.index)}"

    tags = {
	Usage		= "Storage"
	Terraform	= "True"
	VPCName		= "${var.vpc_name}"
    }
}

# Public

resource "aws_subnet" "pub_subnets" {

    count		= "${local.azs_count}"

    vpc_id		= "${aws_vpc.vpc_root.id}"
    availability_zone	= "${element(data.aws_availability_zones.available.names, count.index)}"
    cidr_block		= "${element(local.pub_cidrs, count.index)}"
    map_public_ip_on_launch	= true

    tags = {
	Usage		= "Storage"
	Terraform	= "True"
	VPCName		= "${var.vpc_name}"
    }
}


# Private

resource "aws_subnet" "stor_subnets" {

    count		= "${local.azs_count}"

    vpc_id		= "${aws_vpc.vpc_root.id}"
    availability_zone	= "${element(data.aws_availability_zones.available.names, count.index)}"
    cidr_block		= "${element(local.stor_cidrs, count.index)}"

    tags = {
	Usage		= "Storage"
	Terraform	= "True"
	VPCName		= "${var.vpc_name}"
    }
}


################
#
# Internet Gateway
#
################


resource "aws_internet_gateway" "vpc_gw" {
    vpc_id		= "${aws_vpc.vpc_root.id}"
}


resource "aws_route_table" "pub_rtb" {
    vpc_id = "${aws_vpc.vpc_root.id}"
    route {
	cidr_block	= "0.0.0.0/0"
	gateway_id	= "${aws_internet_gateway.vpc_gw.id}"
    }
}


################
#
# NAT
#
################


resource "aws_eip" "eip_nat_a" {

    count		= "${var.env == "production" ? local.azs_count : 1 }"
    vpc = true
}


resource "aws_nat_gateway" "nat_gw" {

    count		= "${var.env == "production" ? local.azs_count : 1 }"

    allocation_id	= "${aws_eip.eip_nat_a.id}"
    subnet_id		= "${aws_subnet.pub_az_a.id}"

    tags {
	Name = "NAT GW"
    }
}


################
#
# NAT
#
################


// resource "aws_route_table" "app_rtb" {
//     vpc_id = "${aws_vpc.vpc_root.id}"
//     route {
// 	cidr_block = "0.0.0.0/0"
// 	gateway_id = "${aws_nat_gateway.nat_gw_a.id}"
//     }
// }


// resource "aws_route_table" "stor_rtb" {
//     vpc_id = "${aws_vpc.vpc_root.id}"
// }


// resource "aws_main_route_table_association" "rtb-assoc-pub" {
//   vpc_id         = "${aws_vpc.vpc_root.id}"
//   route_table_id = "${aws_route_table.pub_rtb.id}"
// }


// resource "aws_route_table_association" "rtb-assoc-app" {
//   // vpc_id         = "${aws_vpc.vpc_root.id}"
//   route_table_id = "${aws_route_table.app_rtb.id}"
// }


// resource "aws_route_table_association" "rtb-assoc-stor" {
//     // vpc_id         = "${aws_vpc.vpc_root.id}"
//     route_table_id = "${aws_route_table.stor_rtb.id}"
// }


// resource "aws_vpc_endpoint" "s3" {
//     vpc_id       = "${aws_vpc.vpc_root.id}"
//     service_name = "${format("com.amazonaws.%s.s3", var.region)}"

//     route_table_ids = [
// 	"${aws_route_table.app_rtb.id}"
//     ]
// }

