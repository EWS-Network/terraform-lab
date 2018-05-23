################
#
# Subnets
#
################

# APP

resource "aws_subnet" "app_vpc_subnets" {
  count = "${local.azs_count}"

  vpc_id            = "${aws_vpc.vpc_root.id}"
  availability_zone = "${element(data.aws_availability_zones.available.names, count.index)}"
  cidr_block        = "${element(local.app_cidrs, count.index)}"

  tags = {
    Name      = "${format("Application-%s", replace(element(data.aws_availability_zones.available.names, count.index), var.region, ""))}"
    Usage     = "Application"
    Terraform = "True"
    VPCName   = "${var.vpc_name}"
  }
}

# Public

resource "aws_subnet" "pub_vpc_subnets" {
  count = "${local.azs_count}"

  vpc_id                  = "${aws_vpc.vpc_root.id}"
  availability_zone       = "${element(data.aws_availability_zones.available.names, count.index)}"
  cidr_block              = "${element(local.pub_cidrs, count.index)}"
  map_public_ip_on_launch = true

  tags = {
    Name      = "${format("Public-%s", replace(element(data.aws_availability_zones.available.names, count.index), var.region, ""))}"
    Usage     = "Public"
    Terraform = "True"
    VPCName   = "${var.vpc_name}"
  }
}

# Private - Storage

resource "aws_subnet" "stor_vpc_subnets" {
  count = "${local.azs_count}"

  vpc_id            = "${aws_vpc.vpc_root.id}"
  availability_zone = "${element(data.aws_availability_zones.available.names, count.index)}"
  cidr_block        = "${element(local.stor_cidrs, count.index)}"

  tags = {
    Name      = "${format("Storage-%s", replace(element(data.aws_availability_zones.available.names, count.index), var.region, ""))}"
    Usage     = "Storage"
    Terraform = "True"
    VPCName   = "${var.vpc_name}"
  }
}
