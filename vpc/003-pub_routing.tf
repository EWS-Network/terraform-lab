##
## Public Layer routing
##

resource "aws_internet_gateway" "vpc_gw" {
  vpc_id = "${aws_vpc.vpc_root.id}"
}

resource "aws_route_table" "pub_rtb" {
  vpc_id = "${aws_vpc.vpc_root.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.vpc_gw.id}"
  }

  tags {
    Name    = "PublicSubnetsRtb"
    Env     = "${var.env}"
    VPCName = "${var.vpc_name}"
  }
}

resource "aws_route_table_association" "pub_subnets_assoc" {
  count = "${local.azs_count}"

  subnet_id      = "${element(aws_subnet.pub_vpc_subnets.*.id, count.index)}"
  route_table_id = "${aws_route_table.pub_rtb.id}"
  depends_on     = ["aws_subnet.pub_vpc_subnets"]
}
