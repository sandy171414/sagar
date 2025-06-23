provider "aws" {
  region = "eu-north-1"
}

# VPC
resource "aws_vpc" "dpp-vpc" {
  cidr_block = "10.1.0.0/16"

  tags = {
    Name = "dpp-vpc"
  }
}

# Subnets
resource "aws_subnet" "dpp-public-subnet-01" {
  vpc_id                  = aws_vpc.dpp-vpc.id
  cidr_block              = "10.1.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-north-1a"

  tags = {
    Name = "dpp-public-subnet-01"
  }
}

resource "aws_subnet" "dpp-public-subnet-02" {
  vpc_id                  = aws_vpc.dpp-vpc.id
  cidr_block              = "10.1.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-north-1b"

  tags = {
    Name = "dpp-public-subnet-02"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "dpp-igw" {
  vpc_id = aws_vpc.dpp-vpc.id

  tags = {
    Name = "dpp-igw"
  }
}

# Route Table
resource "aws_route_table" "dpp-public-rt" {
  vpc_id = aws_vpc.dpp-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dpp-igw.id
  }

  tags = {
    Name = "dpp-public-rt"
  }
}

# Route Table Associations
resource "aws_route_table_association" "dpp-rta-public-subnet-01" {
  subnet_id      = aws_subnet.dpp-public-subnet-01.id
  route_table_id = aws_route_table.dpp-public-rt.id
}

resource "aws_route_table_association" "dpp-rta-public-subnet-02" {
  subnet_id      = aws_subnet.dpp-public-subnet-02.id
  route_table_id = aws_route_table.dpp-public-rt.id
}

# Security Group
resource "aws_security_group" "demo-sg" {
  name        = "demo-sg"
  description = "Allow SSH and Jenkins"
  vpc_id      = aws_vpc.dpp-vpc.id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins access"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "demo-sg"
  }
}

locals {
  instance_configs = {
    "Jenkins-master" = {
      instance_type = "t3.micro"
      ami           = "ami-0becc523130ac9d5d"
    }
    "build-slave" = {
      instance_type = "t3.micro"
      ami           = "ami-0becc523130ac9d5d"
    }
    "ansible" = {
      instance_type = "t3.micro"
      ami           = "ami-0becc523130ac9d5d"
    }
  }
}


resource "aws_instance" "demo-server" {
  for_each = local.instance_configs

  ami                         = each.value.ami
  instance_type               = each.value.instance_type
  key_name                    = "dpp"
  vpc_security_group_ids      = [aws_security_group.demo-sg.id]
  subnet_id                   = aws_subnet.dpp-public-subnet-01.id
  associate_public_ip_address = true

  tags = {
    Name = each.key
  }
}
