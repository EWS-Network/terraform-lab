output "vpc_id" {
  value = "${data.aws_vpc.root.id}"
}

output "subnet_ids" {
  value = "${data.aws_subnet_ids.app.ids}"
}

output "ami_id" {
  value = "${data.aws_ami.centos.id}"
}

output "instance_ip" {
  value = "${aws_instance.web_test.public_ip}"
}
n