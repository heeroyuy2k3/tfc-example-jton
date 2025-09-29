# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_version = ">=1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Create a resource group using the generated random name
resource "azurerm_resource_group" "example" {
  location = "eastus"
  name     = "MITS-TF-RG"
}

#provider "aws" {
#  region = var.region
#}
#
#data "aws_ami" "ubuntu" {
#  most_recent = true
#
#  filter {
#    name   = "name"
#    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
#  }
#
#  filter {
#    name   = "virtualization-type"
#    values = ["hvm"]
#  }
#
#  owners = ["099720109477"] # Canonical
#}
#
#resource "aws_instance" "ubuntu" {
#  ami           = data.aws_ami.ubuntu.id
#  instance_type = var.instance_type
#
#  tags = {
#    Name = var.instance_name
#  }
#}
