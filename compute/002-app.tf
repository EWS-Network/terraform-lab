provider "aws" {
  region = "${var.region}"
}



data "template_file" "cloud-init" {
  template = "${file("${path.module}/templates/os-settings.yml")}"
  vars     = {}
}

data "template_file" "repos" {
  template = "${file("${path.module}/templates/repos.yml")}"
  vars     = {}
}

data "template_file" "ansible_playbook" {
  template = "${file("${path.module}/templates/site.yml")}"

  vars = {
    ansible_vars_file_path = "${local.ansible_vars_file_path}"
  }
}

data "template_file" "ansible_vars" {
  template = "${file("${path.module}/templates/vars.yml")}"
  vars     = {}
}

data "template_file" "ansible_config" {
  template = "${file("${path.module}/templates/ansible-config.yml")}"

  vars {
    ansible_vars_file_path = "${local.ansible_vars_file_path}"
    b64_content_site_yaml  = "${base64encode(data.template_file.ansible_playbook.rendered)}"
    b64_content_vars_yaml  = "${base64encode(data.template_file.ansible_vars.rendered)}"
  }
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "000-repos.yml"
    content_type = "text/cloud-config"
    content      = "${data.template_file.repos.rendered}"
  }

  part {
    filename     = "001-os_settings.yml"
    content_type = "text/cloud-config"
    content      = "${data.template_file.cloud-init.rendered}"
  }

  part {
    filename     = "002-ansible_settings.yml"
    content_type = "text/cloud-config"
    content      = "${data.template_file.ansible_config.rendered}"
  }
}

resource "aws_iam_instance_profile" "app_profile" {
  name = "${format("ec2App-%s", var.app_name)}"
  role = "${aws_iam_role.role.name}"
}

resource "aws_iam_role" "role" {
    name = "${format("ec2App-%s", var.app_name)}"
    path = "/"
    assume_role_policy = "${file("${path.module}/files/iam_ec2_assume.json")}"
}


resource "aws_instance" "web_test" {
  ami           = "${data.aws_ami.centos.id}"
  instance_type = "${var.instance_type}"
  subnet_id     = "${data.aws_subnet_ids.app.ids[0]}"

  user_data = "${data.template_cloudinit_config.config.rendered}"

  key_name = "${var.keypair_name}"

  iam_instance_profile = "${aws_iam_instance_profile.app_profile.name}"

  tags {
    Name  = "${format("web-%s", var.app_name)}"
    Usage = "Web"
  }
}



