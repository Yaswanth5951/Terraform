resource "aws_vpc" "net" {
  cidr_block = var.vpc-info.vpc_cidr
  tags = {
    Name = "New-VPC"
  }

}

resource "aws_subnet" "subnets" {
  count      = length(var.vpc-info.subnet_names)
  vpc_id     = aws_vpc.net.id
  cidr_block = cidrsubnet(var.vpc-info.vpc_cidr, 8, count.index)

  tags = {
    Name = var.vpc-info.subnet_names[count.index]
  }

}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.net.id

  tags = {
    Name = "igw"
  }

  depends_on = [aws_vpc.net]

}

resource "aws_eip" "my_eip" {
  vpc = true
}

resource "aws_nat_gateway" "example" {
  allocation_id = aws_eip.my_eip.id 
  subnet_id     = aws_subnet.subnets[1].id

  tags = {
    Name = "gw NAT"
  }
  depends_on = [aws_internet_gateway.igw]
}


resource "aws_route_table" "route1" {
  vpc_id = aws_vpc.net.id

  tags = {
    Name = "public-route-table"
  }
  depends_on = [aws_subnet.subnets]
}

resource "aws_route_table" "route2" {
  vpc_id = aws_vpc.net.id

  tags = {
    Name = "private-route-table"
  }
  depends_on = [aws_subnet.subnets]
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.subnets)
  route_table_id = aws_route_table.route2.id
  subnet_id      = aws_subnet.subnets[count.index].id

  depends_on = [aws_internet_gateway.igw, aws_subnet.subnets, aws_vpc.net, aws_route_table.route2]
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.subnets)
  route_table_id = aws_route_table.route1.id
  subnet_id      = aws_subnet.subnets[count.index].id

  depends_on = [aws_internet_gateway.igw, aws_subnet.subnets, aws_vpc.net]
}




