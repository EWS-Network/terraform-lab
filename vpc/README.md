
VPC Template
------------

As part of my experiment, this template and other pieces put together to create a new VPC with subnets etc.

If you put var.env == production, it will create 1 NAT Gateway per subnet and 1 RTB for each AZ for the application layer.

It also creates a SSH Bastion with an EIP, and via Cloud-Init, will reassign the EIP to itself.
