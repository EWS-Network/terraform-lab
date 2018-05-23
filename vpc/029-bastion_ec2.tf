# Bastion

resource "aws_launch_configuration" "bastion_lc" {
  image_id      = "${data.aws_ami.centos.id}"
  instance_type = "${var.instance_type}"

  user_data = "${data.template_cloudinit_config.config.rendered}"

  key_name = "${var.keypair_name}"

  iam_instance_profile = "${aws_iam_instance_profile.bastion_profile.name}"

  security_groups = ["${aws_security_group.bastion_sg.id}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "bastion_asg" {
  availability_zones   = ["${data.aws_availability_zones.available.names}"]
  desired_capacity     = 1
  max_size             = 1
  min_size             = 1
  launch_configuration = "${aws_launch_configuration.bastion_lc.name}"

  vpc_zone_identifier = ["${aws_subnet.pub_vpc_subnets.*.id}"]

  tag {
    key                 = "Name"
    value               = "${format("bastion-%s", aws_vpc.vpc_root.id)}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Usage"
    value               = "Bastion"
    propagate_at_launch = true
  }

  tag {
    key                 = "VPCName"
    value               = "${var.vpc_name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Terraform"
    value               = "True"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
