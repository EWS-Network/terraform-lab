#!/usr/bin/env bash

INSTANCE_ID=`curl 169.254.169.254/latest/meta-data/instance-id`
REGION=`curl -s 169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/[a-z]$//g'`


echo `date +%Y%m%d-%H%M%S` >> /var/log/execution_time

pip --version || curl https://bootstrap.pypa.io/get-pip.py | python
aws || pip install awscli

aws configure set region $REGION

aws ec2 associate-address --instance-id $INSTANCE_ID --public-ip ${eip_ipv4}

