
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc.cidr_block
  enable_dns_hostnames = true

  tags = {
    Name        = var.vpc.tags.name
    Environment = var.environment
  }
}

resource "aws_subnet" "subnets" {
  for_each                = var.subnets
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = each.value.public ? true : false

  tags = {
    Name        = each.value.tags.name
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = var.internet_gateway.tags.name
    Environment = var.environment
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name        = "public-route-table"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public_route_table_associations" {
  for_each       = {for key, subnet in aws_subnet.subnets: key=>subnet if subnet.map_public_ip_on_launch}

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table" "private_route_tables" {
  for_each = var.nat_gateways
  vpc_id   = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateways[each.value].id
  }

  tags = {
    Name        = "${each.key}-private-route-table"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "private_route_table_association" {
  for_each       = {for key, subnet in aws_subnet.subnets: key=>subnet if !subnet.map_public_ip_on_launch}

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_route_tables[each.value.availability_zone].id
}

resource "aws_eip" "eips" {
  for_each  = {for key, subnet in aws_subnet.subnets: key=>subnet if subnet.map_public_ip_on_launch}

  tags = {
    Name        = "${each.key}-eip"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "nat_gateways" {
  for_each  = {for key, subnet in aws_subnet.subnets: key=>subnet if subnet.map_public_ip_on_launch}

  allocation_id = aws_eip.eips[each.key].id
  subnet_id     = each.value.id

  tags = {
    Name        = "${each.key}-nat-gateway"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.internet_gateway]
}
