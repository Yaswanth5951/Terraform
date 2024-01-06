resource "aws_vpc" "newvpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "New-vpc"
  }

}

resource "aws_subnet" "sub1" {
  vpc_id     = aws_vpc.newvpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Sub1"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.newvpc.id

  tags = {
    Name = "igw"
  }
  depends_on = [aws_subnet.sub1]
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.newvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "network"
  }
  depends_on = [aws_internet_gateway.igw]

}

resource "aws_route_table_association" "at_association" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.route_table.id
  depends_on     = [aws_route_table.route_table]

}

resource "aws_security_group" "sg" {
  name        = "sg"
  description = "allow to 22 port"
  vpc_id      = aws_vpc.newvpc.id

  ingress {
    from_port   = 0
    to_port     = 65535
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
  key_name   = "deployer"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "web" {
  subnet_id                   = aws_subnet.sub1.id
  ami                         = "ami-0c7217cdde317cfec"
  vpc_security_group_ids      = [aws_security_group.sg.id]
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  key_name                    = "deployer"

  tags = {
    Name = "ec2"
  }

    connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip

  }

  provisioner "file" {
    source      = "springpetclinic11.service"
    destination = "/home/ubuntu/springpetclinic11.service"

  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install openjdk-17-jdk -y",
      "wget https://referenceapplicationskhaja.s3.us-west-2.amazonaws.com/spring-petclinic-3.1.0-SNAPSHOT.jar",
      "sudo systemctl daemon-reload",
      "sudo systemctl start springpetclinic11.service",
      "java -jar spring-petclinic-3.1.0-SNAPSHOT.jar"
    ]

  }
}
