#!/usr/bin/env bash


RESULT=`python /vol0/home/john/ews/cloudformation-templates/network/vpc/vpc_subnets_terraform.py $1 $2`
echo $RESULT


