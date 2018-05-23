##
## Makefile for vpc in /home/john/terraform-lab/vpc
##
## Made by John Mille
## Login   <john@epitech.net>
##
## Started on  Wed May 23 10:30:46 2018 John Mille
## Last update Wed May 23 13:28:34 2018 John Mille
##

# http://clarkgrubb.com/makefile-style-guide

MAKEFLAGS += --warn-undefined-variables --no-print-directory
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:

REGION=eu-west-1
ENVTYPE=dev
STACK=vpc
TFSTATE_BUCKET=$(shell whoami)-${ENVTYPE}-tfstate

export AWS_DEFAULT_REGION=$(REGION)


RM		= rm
ECHO		= echo -e
TERRAFORM	= terraform



modules:
	@$(MAKE) all --directory=../
	@$(TERRAFORM) get .

clean:
	-@$(RM) -fr .terraform
	@$(ECHO) '\033[0;35m> Deleted .terraform folder \033[0m'

init:
	@$(TERRAFORM) init -backend=true -backend-config="bucket=$(TFSTATE_BUCKET)" -backend-config="key=$(ENVTYPE)-$(STACK).tfstate" -get=true

fmt:
	@$(TERRAFORM) fmt

plan:
	@$(TERRAFORM) plan -var-file=params/$(ENVTYPE)/$(STACK)/params.tfvars .

tfapply:
	@$(TERRAFORM) apply -var-file=params/$(ENVTYPE)/$(STACK)/params.tfvars .

tfdestroy:
	@$(TERRAFORM) destroy -var-file=params/$(ENVTYPE)/$(STACK)/params.tfvars .


tfshow:
	@$(TERRAFORM) show


all: modules clean init fmt plan


apply: modules clean init fmt tfapply


show: tfshow

destroy: all tfdestroy

.PHONY	: all apply destroy modules clean init fmt plan tfapply tfdestroy show tfshow

