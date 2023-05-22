variable "sta_ver" {
  type = string
  default = "pr-434"
}
variable "sta_bucket" {
  type = string
  default = "pr-434"
}
variable "tmf" {
  type = string
  default = "tmf-0c1712afce2504a07"
}
variable "wazuh_nlb" {
  type = string
  default = "WazuhNLB-nmng7wm1-73d16e7a63fa77b7.elb.eu-west-1.amazonaws.com"
}
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-west-1"
}

resource "aws_vpc" "ThreatLabVPC3-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
   Name = "ThreatLabVPC3-vpc"
 }
}

resource "aws_vpc" "ThreatLabVPC2-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
   Name = "ThreatLabVPC2-vpc"
 }
}

resource "aws_vpc" "ThreatHuntingLab-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
   Name = "ThreatHuntingLab-vpc"
 }
}


resource "aws_vpc" "ThreatLab-vpc" {
  cidr_block = "172.31.0.0/16"
  tags = {
   Name = "ThreatLab-vpc"
 }
}


resource "aws_subnet" "ThreatHuntingLab-subnet-private1-eu-west-1a" {
 count      = 1
 vpc_id     = aws_vpc.ThreatHuntingLab-vpc.id
 cidr_block = "10.0.128.0/20"
 
 tags = {
   Name = "ThreatHuntingLab-subnet-private1-eu-west-1a"
 }
}

resource "aws_subnet" "ThreatHuntingLab-subnet-public1-eu-west-1a" {
 count      = 1
 vpc_id     = aws_vpc.ThreatHuntingLab-vpc.id
 cidr_block = "10.0.0.0/20"
 
 tags = {
   Name = "ThreatHuntingLab-subnet-public1-eu-west-1a"
 }
}

resource "aws_subnet" "ThreatLabVPC3-subnet-public1-eu-west-1a" {
 count      = 1
 vpc_id     = aws_vpc.ThreatLabVPC3-vpc.id
 cidr_block = "10.0.0.0/20"
 
 tags = {
   Name = "ThreatLabVPC3-subnet-public1-eu-west-1a"
 }
}

resource "aws_subnet" "ThreatLabVPC2-subnet-private1-us-east-1a" {
 count      = 1
 vpc_id     = aws_vpc.ThreatLabVPC2-vpc.id
 cidr_block = "10.0.0.0/20"
 
 tags = {
   Name = "ThreatLabVPC2-subnet-private1-us-east-1a"
 }
}

resource "aws_subnet" "ThreatLab" {
 count      = 1
 vpc_id     = aws_vpc.ThreatLab-vpc.id
 cidr_block = "10.0.0.0/20"
 
 tags = {
   Name = "ThreatLab"
 }
}


resource "aws_instance" "AttackerServer" {
  count = 5
  ami                       = "ami-0fca156077b31b56b"
  instance_type             = "t3a.nano"
  key_name                  = "ninio-aws_yk"
  subnet_id                 = aws_subnet.ThreatHuntingLab-subnet-public1-eu-west-1a.id
  vpc_id										= aws_vpc.ThreatLabVPC3-vpc.id
  tags                      = tomap({
    "Name" = "AttackerServer"
    format("sta.%s.coralogix.com:mirror-filter-id", var.sta_bucket) = var.tmf
    "Owner" = "zina.m@coralogix.com"
  })
}

resource "aws_instance" "C2Server" {
  count = 5
  ami                       = "ami-09718765df8c6a87f"
  instance_type             = "t3a.nano"
  key_name                  = "snowbit_course" 
  subnet_id                 = aws_subnet.ThreatHuntingLab-subnet-public1-eu-west-1a.id
  vpc_id										= aws_vpc.ThreatLabVPC3-vpc.id
  tags                      = tomap({
    "Name" = "C2Server"
    format("sta.%s.coralogix.com:mirror-filter-id", var.sta_bucket) = var.tmf
    "Owner" = "zina.m@coralogix.com"
  })
}

resource "aws_instance" "ThreatLab Backend MySQL Server wazuh" {
  count = 5
  ami                       = "ami-059fa0eb4f748fecf"
  instance_type             = "t3a.nano"
  key_name                  = "snowbit_course"
  subnet_id                 = aws_subnet.ThreatHuntingLab-subnet-private1-eu-west-1a.id
  vpc_id										= aws_vpc.ThreatLabVPC3-vpc.id
  tags                      = tomap({
    "Name" = "ThreatLab_Backend+MySQL-Server+wazuh"
    format("sta.%s.coralogix.com:mirror-filter-id", var.sta_bucket) = var.tmf
    "Owner" = "zina.m@coralogix.com"
  })
}

resource "aws_instance" "ThreatLabClient" {
  count = 5
  ami                       = "ami-098d8b68baa0c6835"
  instance_type             = "t3a.nano"
  key_name                  = "snowbit_course"
  subnet_id                 = aws_subnet.ThreatLab.id
  vpc_id										= aws_vpc.ThreatLab.id
  tags                      = tomap({
    "Name" = "ThreatLabClient"
    format("sta.%s.coralogix.com:mirror-filter-id", var.sta_bucket) = var.tmf
    "Owner" = "zina.m@coralogix.com"
  })
}

resource "aws_instance" "ThreatLabAdmin" {
  count = 5
  ami                       = "ami-0976e55dd6890875e"
  instance_type             = "t3a.nano"
  key_name                  = "snowbit_course"
  subnet_id                 = aws_subnet.ThreatLab.id
  vpc_id										= aws_vpc.ThreatLab.id
  tags                      = tomap({
    "Name" = "ThreatLabAdmin"
    format("sta.%s.coralogix.com:mirror-filter-id", var.sta_bucket) = var.tmf
    "Owner" = "zina.m@coralogix.com"
  })
}

resource "aws_instance" "ThreatLabBastion" {
  count = 5
  ami                       = "ami-0f055b54b66f35cba"
  instance_type             = "t3a.nano"
  key_name                  = "snowbit_course"
  subnet_id                 = aws_subnet.ThreatHuntingLab-subnet-public1-eu-west-1a.id
  vpc_id										= aws_vpc.ThreatHuntingLab-vpc.id
  tags                      = tomap({
    "Name" = "ThreatLabBastion"
    format("sta.%s.coralogix.com:mirror-filter-id", var.sta_bucket) = var.tmf
    "Owner" = "zina.m@coralogix.com"
  })
}