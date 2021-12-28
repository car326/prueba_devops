provider "aws" {

 region     = "us-east-1"
}

data "aws_availability_zones" "available" {
  state = "available"
}

### AWS VPC
resource "aws_vpc" "vpc" {
    cidr_block ="${var.vpc_cidr_range}"
    enable_dns_support = "true" 
    enable_dns_hostnames = "true"
    enable_classiclink = "false"
    instance_tenancy = "${var.instance_tenancy}"
    
    tags = {
        Name = "${var.name_vpc}"
        Environment = "${var.environment}"
    }
}
### Private Subnets
# Loop over this as many times as necessary to create the correct number of Private Subnets
resource "aws_subnet" "private_subnet" {
  count             = "${var.availability_zones_count}"
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${element(var.private_subnets, count.index)}"
  availability_zone = "${element(data.aws_availability_zones.available.names, count.index)}"

  tags = "${merge(
    tomap({"Name" = "${format("%s-private-subnet-az%d", var.name_account,count.index + 1  )}"}),
    var.additional_tags
  )}"
}

### Public Subnets
# Loop over this as many times as necessary to create the correct number of Public Subnets
resource "aws_subnet" "public_subnet" {
  count             = "${var.availability_zones_count}"
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${element(var.public_subnets, count.index)}"
  availability_zone = "${element(data.aws_availability_zones.available.names, count.index)}"

  tags = "${merge(
    tomap({"Name" = "${format("%s-public-subnet-az%d", var.name_account,count.index + 1  )}"}),
    var.additional_tags
  )}"
}

### Internet Gateway
resource "aws_internet_gateway" "igw" {
    vpc_id = "${aws_vpc.vpc.id}"
    tags = {
        Name = "${var.name_account}-IGW"
        Environment = "${var.environment}"
    }
}


### Elastic IPs
# Need one per AZ for the NAT Gateways
resource "aws_eip" "nat_gw_eip" {
  count = "${var.availability_zones_count}"
  vpc   = true
}

### NAT Gateways
# Loops as necessary to create one per AZ in the Public Subnets, and associate the provisioned Elastic IP
resource "aws_nat_gateway" "nat" {
  allocation_id = "${element(aws_eip.nat_gw_eip.*.id, count.index)}"
  count         = "${var.availability_zones_count}"
  subnet_id     = "${element(aws_subnet.public_subnet.*.id, count.index)}"

  tags = "${merge(
    tomap({"Name" = "${format("%s-nat-gateway-az%d", var.name_vpc, count.index + 1 )}"}),
    var.additional_tags
  )}"
}


### Public Route Tables
# Routes traffic destined for `0.0.0.0/0` to the Internet Gateway for the VPC
resource "aws_route_table" "route_table_public" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = "${merge(
    tomap({"Name" = "${format("%s-PublicRT", var.name_vpc)}"}),
    var.additional_tags
  )}"
}

resource "aws_route" "default_public_route" {
  route_table_id         = "${element(aws_route_table.route_table_public.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${element(aws_internet_gateway.igw.*.id, count.index)}"
}

### Private Subnet Route Tables
# Routes traffic destined for `0.0.0.0/0` to the NAT Gateway in the same AZ
resource "aws_route_table" "route_table_private" {
  count  = "${var.availability_zones_count}"
  vpc_id = "${aws_vpc.vpc.id}"

  tags = "${merge(
    tomap({"Name" = "${format("%s-PrivateRT-AZ%d", var.name_vpc, count.index +1)}"}),
    var.additional_tags
  )}"
}

resource "aws_route" "default_private_route" {
  route_table_id         = "${element(aws_route_table.route_table_private.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.nat.*.id, count.index)}"
}

###Public Subnet Route Table Associations
resource "aws_route_table_association" "associaton-public-subnet" {
  count          = "${var.availability_zones_count}"
  subnet_id      = "${element(aws_subnet.public_subnet.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.route_table_public.*.id, count.index)}"
 }

###Private Subnet Route Table Associations
resource "aws_route_table_association" "associaton-private-subnet" {
    count     = "${var.availability_zones_count}"
    subnet_id = "${element(aws_subnet.private_subnet.*.id, count.index)}"
    route_table_id = "${element(aws_route_table.route_table_private.*.id, count.index)}"
 }
