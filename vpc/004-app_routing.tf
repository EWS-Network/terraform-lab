##
## Application layer routing
##

resource "aws_eip" "eip_nat_gw" {
  count = "${var.env == "production" ? local.azs_count : 1 }"
  vpc   = true
}

resource "aws_nat_gateway" "app_nat_gw" {
  count = "${var.env == "production" ? local.azs_count : 1 }"

  allocation_id = "${var.env == "production" ? element(aws_eip.eip_nat_gw.*.id, count.index)		: element(aws_eip.eip_nat_gw.*.id, 0)}"
  subnet_id     = "${var.env == "production" ? element(aws_subnet.pub_vpc_subnets.*.id, count.index)	: element(aws_subnet.pub_vpc_subnets.*.id, 0) }"

  tags {
    Name = "NAT GW"
  }

  depends_on = ["aws_eip.eip_nat_gw"]
}

resource "aws_route_table" "app_rtb" {
  count = "${var.env == "production" ? local.azs_count : 1 }"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${var.env == "production" ? element(aws_nat_gateway.app_nat_gw.*.id, count.index) : element(aws_nat_gateway.app_nat_gw.*.id, 0)}"
  }

  vpc_id = "${aws_vpc.vpc_root.id}"

  tags {
    Name    = "${format("ApplicationRtb-%s", replace(element(data.aws_availability_zones.available.names, count.index), var.region, ""))}"
    Env     = "${var.env}"
    VPCName = "${var.vpc_name}"
  }

  depends_on = ["aws_nat_gateway.app_nat_gw"]
}

resource "aws_route_table_association" "app_subnets_assoc" {
  count = "${local.azs_count}"

  subnet_id      = "${element(aws_subnet.app_vpc_subnets.*.id, count.index)}"
  route_table_id = "${var.env == "production" ? element(aws_route_table.app_rtb.*.id, count.index) : element(aws_route_table.app_rtb.*.id, 0)}"
  depends_on     = ["aws_subnet.app_vpc_subnets", "aws_route_table.app_rtb"]
}
