variable "region" {
  type        = string
  default     = "us-west-2"
  description = "region in which resource will be created"
}

variable "vpc_cidr" {
  type    = string
  default = "192.168.0.0/16"
}

variable "aws_subnet" {
  type    = list(string)
  default = ["subnet1", "sub2"]

}

variable "availability_zone" {
  type = list(string)
  default = ["b","c"]
}

 