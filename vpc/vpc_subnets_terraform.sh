#!/usr/bin/env bash


RESULT=`python ./vpc_subnets_terraform.py $1 $2`
echo $RESULT


