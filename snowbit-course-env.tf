variable "sta_ver" {
  type = string
  default = "2.1.188"
}
variable "sta_bucket" {
  type = string
  default = "sta-config-sta-zina-aarhgf1c"
}
variable "tmf" {
  type = string
  default = "tmf-015bcb25fa896e69a"
}
variable "wazuh_nlb" {
  type = string
  default = "WazuhNLB-aarhgf1c-403962d4e68b9cdb.elb.eu-west-1.amazonaws.com"
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

resource "aws_vpc" "main-vpc" {
  cidr_block = "10.0.0.0/16"
   tags = {
   Name = "main-vpc"
 }
}

resource "aws_vpc" "attacker-vpc" {
  cidr_block = "10.0.0.0/16"
   tags = {
   Name = "attacker-vpc"
 }
}

resource "aws_vpc" "client-vpc" {
  cidr_block = "10.0.0.0/16"
   tags = {
   Name = "client-vpc"
 }
}


resource "aws_subnet" "subnet-private" {
 vpc_id     = aws_vpc.main-vpc.id
 cidr_block = "10.0.1.0/24"
 
 tags = {
   Name = "subnet-private"
 }
}

resource "aws_subnet" "subnet-public" {
 vpc_id     = aws_vpc.main-vpc.id
 cidr_block = "10.0.2.0/24"
 
 tags = {
   Name = "subnet-public"
 }
}

resource "aws_subnet" "attacker-subnet" {
 vpc_id     = aws_vpc.attacker-vpc.id
 cidr_block = "10.0.0.0/16"
 
 tags = {
   Name = "attacker-subnet"
 }
}

resource "aws_subnet" "client-subnet" {
 vpc_id     = aws_vpc.client-vpc.id
 cidr_block = "10.0.0.0/16"
 
 tags = {
   Name = "client-subnet"
 }
}

resource "aws_internet_gateway" "gw-main" {
  vpc_id = aws_vpc.main-vpc.id

  tags = {
    Name = "main_gw"
  }
}

resource "aws_internet_gateway" "gw-attacker" {
  vpc_id = aws_vpc.attacker-vpc.id

  tags = {
    Name = "attacker_gw"
  }
}

resource "aws_internet_gateway" "gw-client" {
  vpc_id = aws_vpc.client-vpc.id

  tags = {
    Name = "client_gw"
  }
}

resource "aws_eip" "nat-eip" {
}

resource "aws_nat_gateway" "nat-gateway" {
  allocation_id = aws_eip.nat-eip.id
  subnet_id     = aws_subnet.subnet-public.id

  tags = {
    Name = "gw NAT"
  }
  depends_on = [aws_internet_gateway.gw-main]
}


resource "aws_route_table" "rb-nat-main" {
  vpc_id =  aws_vpc.main-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-gateway.id
  }
  
  tags = {
    Name = "rb-nat-main"
  }
}

resource "aws_route_table" "rb-main" {
  vpc_id =  aws_vpc.main-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw-main.id
  }
  
  tags = {
    Name = "rb-main"
  }
}

resource "aws_route_table" "rb-attacker" {
  vpc_id =  aws_vpc.attacker-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw-attacker.id
  }
  
  tags = {
    Name = "rb-attacker"
  }
}


resource "aws_route_table" "rb-client" {
  vpc_id =  aws_vpc.client-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw-client.id
  }
  
  tags = {
    Name = "rb-client"
  }
}

resource "aws_route_table_association" "nat" {
  subnet_id      = aws_subnet.subnet-private.id
  route_table_id = aws_route_table.rb-nat-main.id
}
resource "aws_route_table_association" "client" {
  subnet_id      = aws_subnet.client-subnet.id
  route_table_id = aws_route_table.rb-client.id
}
resource "aws_route_table_association" "attacker" {
  subnet_id      = aws_subnet.attacker-subnet.id
  route_table_id = aws_route_table.rb-attacker.id
}
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.subnet-public.id
  route_table_id = aws_route_table.rb-main.id
}

resource "aws_security_group" "sq-webserver" {
	name = "sq-webserver"
	vpc_id = aws_vpc.main-vpc.id
	ingress {
    description      = "any"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sq-webserver"
  }
}

resource "aws_security_group" "sg-bastion" {
	name = "sg bastion"
	vpc_id = aws_vpc.main-vpc.id
	ingress {
    description      = "any"
    from_port        = 0
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-bastion"
  }
}

resource "aws_security_group" "default-client" {
	name = "default-client"
	vpc_id = aws_vpc.client-vpc.id
	ingress {
    description      = "any"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "default-client"
  }
}

resource "aws_security_group" "default-attacker" {
	name = "default-attacker"
	vpc_id = aws_vpc.attacker-vpc.id
	ingress {
    description      = "any"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "default-attacker"
  }
}

resource "aws_security_group" "sg-backend-db" {
	name = "securitygroup-backend-db"
	vpc_id = aws_vpc.main-vpc.id
	ingress {
        description      = "allow web server"
        from_port        = 8000
        to_port          = 8000
        protocol         = "tcp"
        cidr_blocks      = [aws_vpc.main-vpc.cidr_block]
      }

    egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
    }

    tags = {
      Name = "sg-backend-db"
    }
}


resource "aws_security_group_rule" "security_group_rule_allow_ssh_from_bastion_to_db" {
  from_port = 22
  protocol = "tcp"
  security_group_id = aws_security_group.sg-backend-db.id
  to_port = 22
  type = "ingress"
  cidr_blocks = [aws_vpc.main-vpc.cidr_block]
}

resource "aws_security_group_rule" "security_group_rule_allow_ssh_from_bastion_to_webserver" {
  from_port = 22
  protocol = "tcp"
  security_group_id = aws_security_group.sq-webserver.id
  to_port = 22
  type = "ingress"
  cidr_blocks = [aws_vpc.main-vpc.cidr_block]
}

//resource "aws_security_group_rule" "security_group_rule_allow_8080_from_webserver_to_db" {
//  from_port = 8000
//  protocol = "tcp"
//  security_group_id = aws_security_group.sg-backend-db.id
//  to_port = 8000
//  type = "ingress"
//  cidr_blocks = [aws_vpc.main-vpc.cidr_block]
//}
resource "aws_security_group_rule" "security_group_rule_allow_3306_from_webserver_to_db" {
  from_port = 3306
  protocol = "tcp"
  security_group_id = aws_security_group.sg-backend-db.id
  to_port = 3306
  type = "ingress"
  cidr_blocks = [aws_vpc.main-vpc.cidr_block]
}


resource "aws_instance" "AttackerServer" {
  ami                       = "ami-0e6156a34567a0030"
  instance_type             = "t3a.nano"
  key_name                  = "snowbit_course"
  associate_public_ip_address = true
  subnet_id                 = aws_subnet.attacker-subnet.id
  vpc_security_group_ids = [aws_security_group.default-attacker.id]
  user_data                 = <<EOF
#!/bin/bash

sudo yum install docker
sudo usermod -a -G docker ec2-user
newgrp docker
sudo systemctl enable docker.service
sudo systemctl start docker.service
  EOF
  tags                      = tomap({
    "Name" = "AttackerServer"
    format("sta.%s.coralogix.com:mirror-filter-id", var.sta_bucket) = var.tmf
    "Owner" = "zina.m@coralogix.com"
  })
}

resource "aws_instance" "C2Server" {
  ami                       = "ami-041f4bb04be13d823"
  instance_type             = "t3a.nano"
  key_name                  = "snowbit_course"
  associate_public_ip_address = true 
  subnet_id                 = aws_subnet.attacker-subnet.id
  vpc_security_group_ids = [aws_security_group.default-attacker.id]
  tags                      = tomap({
    "Name" = "C2Server"
    format("sta.%s.coralogix.com:mirror-filter-id", var.sta_bucket) = var.tmf
    "Owner" = "zina.m@coralogix.com"
  })
}

resource "aws_instance" "ThreatLabBackendMySQLServerWazuh" {
  ami                       = "ami-0dc49c274808f323a"
  instance_type             = "t3a.small"
  key_name                  = "snowbit_course"
  subnet_id                 = aws_subnet.subnet-private.id
  vpc_security_group_ids = [aws_security_group.sg-backend-db.id]
  tags                      = tomap({
    "Name" = "ThreatLab_Backend+MySQL-Server+wazuh"
    format("sta.%s.coralogix.com:mirror-filter-id", var.sta_bucket) = var.tmf
    "Owner" = "zina.m@coralogix.com"
  })
}

resource "aws_instance" "ThreatLabClient" {
  ami                       = "ami-07e7d134798438b53"
  instance_type             = "t3a.nano"
  key_name                  = "snowbit_course"
  subnet_id                 = aws_subnet.client-subnet.id
  vpc_security_group_ids = [aws_security_group.default-client.id]
  associate_public_ip_address = true
  tags                      = tomap({
    "Name" = "ThreatLabClient"
    format("sta.%s.coralogix.com:mirror-filter-id", var.sta_bucket) = var.tmf
    "Owner" = "zina.m@coralogix.com"
  })
}

resource "aws_instance" "ThreatLabAdmin" {
  ami                       = "ami-09b3b214fd8201296"
  instance_type             = "t3a.nano"
  key_name                  = "snowbit_course"
  associate_public_ip_address = true
  subnet_id                 = aws_subnet.client-subnet.id
  vpc_security_group_ids = [aws_security_group.default-client.id]
  tags                      = tomap({
    "Name" = "ThreatLabAdmin"
    format("sta.%s.coralogix.com:mirror-filter-id", var.sta_bucket) = var.tmf
    "Owner" = "zina.m@coralogix.com"
  })
}

resource "aws_instance" "ThreatLabBastion" {
  ami                       = "ami-0ea0e95a758859b9e"
  instance_type             = "t3a.nano"
  key_name                  = "snowbit_course"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.sg-bastion.id]
  subnet_id                 = aws_subnet.subnet-public.id
  tags                      = tomap({
    "Name" = "ThreatLabBastion"
    format("sta.%s.coralogix.com:mirror-filter-id", var.sta_bucket) = var.tmf
    "Owner" = "zina.m@coralogix.com"
  })
}

resource "aws_instance" "ThreatLabWebServer" {
  ami                       = "ami-01efa2a55e499c0e9"
  instance_type             = "t3a.nano"
  key_name                  = "snowbit_course"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.sq-webserver.id]
  subnet_id                 = aws_subnet.subnet-public.id
  tags                      = tomap({
    "Name" = "ThreatLabWebServer"
    format("sta.%s.coralogix.com:mirror-filter-id", var.sta_bucket) = var.tmf
    "Owner" = "zina.m@coralogix.com"
  })
}
