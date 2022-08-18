#Provider
provider "aws" {
  region = "eu-central-1"
}

#VPC
resource "aws_vpc" "production" {
  cidr_block       = "30.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "production"
  }
}

#Public Subnets

resource "aws_subnet" "sb1-pub" {
  vpc_id     = aws_vpc.production.id
  cidr_block = "30.0.1.0/24"
  availability_zone = "eu-central-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "sb1-pub"
  }
}

resource "aws_subnet" "sb2-pub" {
  vpc_id     = aws_vpc.production.id
  cidr_block = "30.0.2.0/24"
  availability_zone = "eu-central-1b"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "sb2-pub"
  }
}

#Private Subnets

resource "aws_subnet" "sb1-private" {
  vpc_id     = aws_vpc.production.id
  cidr_block = "30.0.10.0/24"
  availability_zone = "eu-central-1a"
  map_public_ip_on_launch = "false"

  tags = {
    Name = "sb1-private"
  }
}

resource "aws_subnet" "sb2-private" {
  vpc_id     = aws_vpc.production.id
  cidr_block = "30.0.11.0/24"
  availability_zone = "eu-central-1b"
  map_public_ip_on_launch = "false"

  tags = {
    Name = "sb2-private"
  }
}

#Internet Gateway

resource "aws_internet_gateway" "gw-production" {
  vpc_id = aws_vpc.production.id

  tags = {
    Name = "igw-prod"
  }
}

#Route table for public subnets
resource "aws_route_table" "rt-production" {
  vpc_id = aws_vpc.production.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw-production.id
  }

  tags = {
    Name = "rt-production"
  }
}

#Route table association (PUBLIC)

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.sb1-pub.id
  route_table_id = aws_route_table.rt-production.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.sb2-pub.id
  route_table_id = aws_route_table.rt-production.id
}

#Elastic ip for NAT 

resource "aws_eip" "nat-ip" {
  depends_on = [aws_internet_gateway.gw-production]
  vpc      = true
  tags = {
    Name = "EIP-NAT"
  }
}

#Public NAT Gateway (Needs to be located on public subnet)

resource "aws_nat_gateway" "pub-nat-gw" {
  allocation_id = aws_eip.nat-ip.id
  subnet_id     = aws_subnet.sb1-pub.id
  depends_on = [
    aws_internet_gateway.gw-production
  ]

  tags = {
    Name = "gw NAT"
  }
}

#Route table for private subnets
resource "aws_route_table" "rt-production-private" {
  vpc_id = aws_vpc.production.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.pub-nat-gw.id
  }

  tags = {
    Name = "rt-production-private"
  }
}

#Association

resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.sb1-private.id
  route_table_id = aws_route_table.rt-production-private.id
}

resource "aws_route_table_association" "d" {
  subnet_id      = aws_subnet.sb2-private.id
  route_table_id = aws_route_table.rt-production-private.id
}