###
### Storage Layer
###

resource "aws_route_table" "stor_rtb" {
  vpc_id = "${aws_vpc.vpc_root.id}"

  tags {
    Name    = "StorageSubnetsRtb"
    Env     = "${var.env}"
    VPCName = "${var.vpc_name}"
  }
}

resource "aws_route_table_association" "stor_subnets_assoc" {
  count = "${local.azs_count}"

  subnet_id      = "${element(aws_subnet.stor_vpc_subnets.*.id, count.index)}"
  route_table_id = "${aws_route_table.stor_rtb.id}"
  depends_on     = ["aws_subnet.stor_vpc_subnets"]
}
