resource "aws_vpc" "VPC" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "vpc"
  }

}

resource "aws_subnet" "name" {
  count      = length(var.aws_subnet)
  vpc_id     = aws_vpc.VPC.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = "${var.region}${var.availability_zone[count.index]}"

  tags = {
    Name = var.aws_subnet[count.index]


  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.VPC.id

  tags = {
    Name = "network"
  }

}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "igw"
  }
  depends_on = [
    aws_internet_gateway.igw
  ]


}
resource "aws_route_table_association" "at_association" {
  count          = length(var.aws_subnet)
  subnet_id      = aws_subnet.name[count.index].id
  route_table_id = aws_route_table.route_table.id

  depends_on = [aws_route_table.route_table]
}

resource "aws_security_group" "sg" {
  name        = "sg"
  description = "allow to 22 port"
  vpc_id      = aws_vpc.VPC.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
  


  tags = {
    Name = "sg"
  }

}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "ec2" {
  instance_type               = "t2.micro"
  associate_public_ip_address = "true"
  ami                         = "ami-008fe2fc65df48dac"
  subnet_id                   = aws_subnet.name[0].id
  vpc_security_group_ids      = [aws_security_group.sg.id]
  user_data                 = file("tomcat9.sh")
  key_name                    = "deployer-key"

  tags = {
    Name = "compute-engine"
  }

  depends_on = [
    aws_security_group.sg
  ]

}

resource "aws_instance" "nginx" {
  instance_type = "t2.micro"
  associate_public_ip_address = "true"
  ami = "ami-008fe2fc65df48dac"
  subnet_id = aws_subnet.name[0].id
  vpc_security_group_ids = [aws_security_group.sg.id]
  user_data = file("nginx.sh")
  key_name = "deployer-key"

  tags = {
    Name = "compute"
  }

  depends_on = [ aws_security_group.sg ]
}



