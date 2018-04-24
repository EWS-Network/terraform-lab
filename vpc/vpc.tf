terraform {

    backend "s3" {

	bucket	= "ews-terraform-state"
//	key	= "${var.region}/${var.cidr}/${var.vpc_name}.tfstate"
	key	= "ews-terraform-states/vpc/vpc.tfstate"
	region	= "eu-west-1"
	}
}

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

resource "aws_subnet"	"app_vpc_subnets" {

    count		= "${local.azs_count}"

    vpc_id		= "${aws_vpc.vpc_root.id}"
    availability_zone	= "${element(data.aws_availability_zones.available.names, count.index)}"
    cidr_block		= "${element(local.app_cidrs, count.index)}"

    tags = {
	Name		= "${format("Application-%s", replace(element(data.aws_availability_zones.available.names, count.index), var.region, ""))}"
	Usage		= "Application"
	Terraform	= "True"
	VPCName		= "${var.vpc_name}"
    }
}

# Public

resource "aws_subnet"	"pub_vpc_subnets" {

    count		= "${local.azs_count}"

    vpc_id		= "${aws_vpc.vpc_root.id}"
    availability_zone	= "${element(data.aws_availability_zones.available.names, count.index)}"
    cidr_block		= "${element(local.pub_cidrs, count.index)}"
    map_public_ip_on_launch	= true

    tags = {
	Name		= "${format("Public-%s", replace(element(data.aws_availability_zones.available.names, count.index), var.region, ""))}"
	Usage		= "Public"
	Terraform	= "True"
	VPCName		= "${var.vpc_name}"
    }
}


# Private - Storage

resource "aws_subnet"	"stor_vpc_subnets" {

    count		= "${local.azs_count}"

    vpc_id		= "${aws_vpc.vpc_root.id}"
    availability_zone	= "${element(data.aws_availability_zones.available.names, count.index)}"
    cidr_block		= "${element(local.stor_cidrs, count.index)}"

    tags = {
	Name		= "${format("Storage-%s", replace(element(data.aws_availability_zones.available.names, count.index), var.region, ""))}"
	Usage		= "Storage"
	Terraform	= "True"
	VPCName		= "${var.vpc_name}"
    }
}


################
#
# Public Layer routing
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

    tags {
	Name	= "PublicSubnetsRtb"
	Env	= "${var.env}"
	VPCName = "${var.vpc_name}"
    }
}


resource "aws_route_table_association" "pub_subnets_assoc" {

    count		= "${local.azs_count}"

    subnet_id		= "${element(aws_subnet.pub_vpc_subnets.*.id, count.index)}"
    route_table_id	= "${aws_route_table.pub_rtb.id}"
    depends_on		= ["aws_subnet.pub_vpc_subnets"]

}


###############
################
#
# Private Layers routing
#
################



################
#
# NAT
#
################


resource "aws_eip"	"eip_nat_gw" {

    count		= "${var.env == "production" ? local.azs_count : 1 }"
    vpc = true
}


resource "aws_nat_gateway" "app_nat_gw" {

    count		= "${var.env == "production" ? local.azs_count : 1 }"

    allocation_id	= "${var.env == "production" ? element(aws_eip.eip_nat_gw.*.id, count.index)		: element(aws_eip.eip_nat_gw.*.id, 0)}"
    subnet_id		= "${var.env == "production" ? element(aws_subnet.pub_vpc_subnets.*.id, count.index)	: element(aws_subnet.pub_vpc_subnets.*.id, 0) }"

    tags {
	Name = "NAT GW"
    }

    depends_on		= ["aws_eip.eip_nat_gw"]

}

################
#
# Routing table(s)
#
################

resource "aws_route_table" "app_rtb" {

    count		= "${var.env == "production" ? local.azs_count : 1 }"

    route {
 	cidr_block	= "0.0.0.0/0"
	gateway_id	= "${var.env == "production" ? element(aws_nat_gateway.app_nat_gw.*.id, count.index) : element(aws_nat_gateway.app_nat_gw.*.id, 0)}"
    }

    vpc_id = "${aws_vpc.vpc_root.id}"
    tags {
	Name	= "${format("ApplicationRtb-%s", replace(element(data.aws_availability_zones.available.names, count.index), var.region, ""))}"
	Env	= "${var.env}"
	VPCName = "${var.vpc_name}"
    }
    depends_on	 = ["aws_nat_gateway.app_nat_gw"]
}

resource "aws_route_table_association" "app_subnets_assoc" {

    count		= "${var.env == "production" ? local.azs_count : 1 }"

    subnet_id		= "${element(aws_subnet.app_vpc_subnets.*.id, count.index)}"
    route_table_id	= "${var.env == "production" ? element(aws_route_table.app_rtb.*.id, count.index) : element(aws_route_table.app_rtb.*.id, 0)}"
    depends_on		= ["aws_subnet.app_vpc_subnets", "aws_route_table.app_rtb"]

}

################
#
# Service Endpoints
#
################


# S3

resource "aws_vpc_endpoint"	"s3_app" {

    count			= "${var.env == "production" ? local.azs_count : 1 }"

    vpc_id			= "${aws_vpc.vpc_root.id}"
    service_name		= "${format("com.amazonaws.%s.s3", var.region)}"

    route_table_ids		= ["${element(aws_route_table.app_rtb.*.id, count.index)}"]

    depends_on			= ["aws_route_table.app_rtb"]
}


################
#
# Storage Layer routing
#
################


resource "aws_route_table" "stor_rtb" {

    vpc_id = "${aws_vpc.vpc_root.id}"

    tags {
	Name	= "StorageSubnetsRtb"
	Env	= "${var.env}"
	VPCName = "${var.vpc_name}"
    }
}


resource "aws_route_table_association" "stor_subnets_assoc" {

    count		= "${local.azs_count}"

    subnet_id		= "${element(aws_subnet.stor_vpc_subnets.*.id, count.index)}"
    route_table_id	= "${aws_route_table.stor_rtb.id}"
    depends_on		= ["aws_subnet.stor_vpc_subnets"]

}

################
#
# Service Endpoints
#
################


# S3

resource "aws_vpc_endpoint"	"s3_storage" {

    count			= "${var.env == "production" ? local.azs_count : 1 }"

    vpc_id			= "${aws_vpc.vpc_root.id}"
    service_name		= "${format("com.amazonaws.%s.s3", var.region)}"

    route_table_ids		= ["${element(aws_route_table.app_rtb.*.id, count.index)}"]

    depends_on			= ["aws_route_table.app_rtb"]
}

# DynamoDb

