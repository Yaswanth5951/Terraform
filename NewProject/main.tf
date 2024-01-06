resource "aws_key_pair" "deployer" {
  key_name   = "Project-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_vpc" "Project" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "custom"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.Project.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnet"
  }
  depends_on = [aws_vpc.Project]
}


resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.Project.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "PrivateSubnet"
  }
  depends_on = [aws_vpc.Project,
  aws_subnet.public_subnet]
}

resource "aws_internet_gateway" "Internet_Gateway" {

  vpc_id = aws_vpc.Project.id

  tags = {
    Name = "IG-Public-&-Private-VPC"
  }
  depends_on = [
    aws_vpc.Project,
    aws_subnet.public_subnet,
    aws_subnet.private_subnet
  ]
}


resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.Project.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Internet_Gateway.id
  }

  tags = {
    Name = "PublicRouteTable"
  }
  depends_on = [
    aws_vpc.Project,
    aws_internet_gateway.Internet_Gateway
  ]
}

resource "aws_route_table_association" "RT-Association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id

  depends_on = [
    aws_vpc.Project,
    aws_subnet.public_subnet,
    aws_subnet.private_subnet,
    aws_route_table.public_route_table
  ]
}

resource "aws_eip" "Nat-Gateway-EIP" {
  vpc = true

  depends_on = [
    aws_route_table_association.RT-Association
  ]
}

resource "aws_nat_gateway" "NAT_GATEWAY" {

  allocation_id = aws_eip.Nat-Gateway-EIP.id
  subnet_id     = aws_subnet.public_subnet.id
  tags = {
    Name = "Nat-Gateway_Project"
  }
  depends_on = [
    aws_eip.Nat-Gateway-EIP
  ]
}

resource "aws_route_table" "NAT-Gateway-RT" {

  vpc_id = aws_vpc.Project.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NAT_GATEWAY.id
  }

  tags = {
    Name = "Route Table for NAT Gateway"
  }
  depends_on = [
    aws_nat_gateway.NAT_GATEWAY
  ]

}

resource "aws_route_table_association" "Nat-Gateway-RT-Association" {

  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.NAT-Gateway-RT.id

  depends_on = [
    aws_route_table.NAT-Gateway-RT
  ]

}

resource "aws_security_group" "WS-SG" {

  description = "HTTP, PING, SSH"
  name        = "webserver-sg"
  vpc_id      = aws_vpc.Project.id

  ingress {
    description = "HTTP for webserver"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Ping"
    from_port   = 0
    to_port     = 0
    protocol    = "ICMP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "output from webserver"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = [
    aws_vpc.Project,
    aws_subnet.public_subnet,
    aws_subnet.private_subnet

  ]

}

resource "aws_security_group" "MySQL-SG" {

  description = "MySQL Access only from the Webserver Instances!"
  name        = "mysql-sg"
  vpc_id      = aws_vpc.Project.id

  ingress {
    description     = "MySQL Access"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.WS-SG.id]
  }

  egress {
    description = "output from MySQL"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = [
    aws_vpc.Project,
    aws_subnet.public_subnet,
    aws_subnet.private_subnet,
    aws_security_group.WS-SG
  ]

}

resource "aws_security_group" "BH-SG" {

  description = "MySQL Access only from the Webserver Instances!"
  name        = "bastion-host-sg"
  vpc_id      = aws_vpc.Project.id

  ingress {
    description = "Bastion Host SG"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "output from Bastion Host"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  depends_on = [
    aws_vpc.Project,
    aws_subnet.public_subnet,
    aws_subnet.private_subnet

  ]
}

resource "aws_security_group" "DB-SG-SSH" {

  description = "MySQL Bastion host access for updates!"
  name        = "mysql-sg-bastion-host"
  vpc_id      = aws_vpc.Project.id


  ingress {
    description     = "Bastion Host SG"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.BH-SG.id]
  }

  egress {
    description = "output from MySQL BH"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  depends_on = [
    aws_vpc.Project,
    aws_subnet.public_subnet,
    aws_subnet.private_subnet,
    aws_security_group.WS-SG
  ]
}

resource "aws_instance" "webserver" {
  ami           = "ami-04b4d3355a2e2a403"
  associate_public_ip_address = "true"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  user_data     = file("Database.sh")
  key_name      = "Project-key"

  vpc_security_group_ids = [aws_security_group.WS-SG.id]

  tags = {
    Name = "Webserver_From_Terraform"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = aws_instance.webserver.public_ip
  }

  depends_on = [
    aws_vpc.Project,
    aws_subnet.public_subnet,
    aws_subnet.private_subnet,
    aws_security_group.BH-SG,
    aws_security_group.DB-SG-SSH
  ]
}

resource "aws_instance" "MySQL" {

  ami           = "ami-04b4d3355a2e2a403"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet.id

  key_name = "Project-key"

  vpc_security_group_ids = [aws_security_group.MySQL-SG.id, aws_security_group.DB-SG-SSH.id]

  tags = {
    Name = "MySQL_From_Terraform"
  }
  depends_on = [
    aws_instance.webserver,
  ]
}

resource "aws_instance" "Bastion-Host" {

  ami           = "ami-04b4d3355a2e2a403"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id

  key_name = "Project-key"

  vpc_security_group_ids = [aws_security_group.BH-SG.id]
  tags = {
    Name = "Bastion_Host_From_Terraform"
  }
  depends_on = [
    aws_instance.webserver,
    aws_instance.MySQL
  ]
}

