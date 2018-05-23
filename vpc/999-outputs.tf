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
