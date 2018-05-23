resource "aws_iam_instance_profile" "bastion_profile" {
  name = "${format("ec2Bastion-%s", aws_vpc.vpc_root.id)}"
  role = "${aws_iam_role.bastion_role.name}"
}

resource "aws_iam_role" "bastion_role" {
  name               = "${format("ec2Bastion-%s", aws_vpc.vpc_root.id)}"
  path               = "/"
  assume_role_policy = "${file("${path.module}/files/iam_ec2_assume.json")}"
}

resource "aws_iam_role_policy" "ec2_policy" {
  name = "test_policy"
  role = "${aws_iam_role.bastion_role.id}"

  policy = "${file("${path.module}/files/iam_bastion_ec2_policy.json")}"
}
