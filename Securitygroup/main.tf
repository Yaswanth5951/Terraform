resource "aws_vpc" "primary_network" {
  cidr_block = var.vpc_cidr

  tags = {   Name = "VPC"
  
  }
}

 resource "aws_subnet" "vpcsubnet" {
   count      = length(var.subnet_name)
  vpc_id     = aws_vpc.primary_network.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)

   tags = {
     Name = var.subnet_name[count.index]
   }

}


