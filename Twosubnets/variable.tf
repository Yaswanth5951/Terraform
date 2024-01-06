variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "vpc-info" {
  type = object({
    vpc_cidr          = string
    subnet_names      = list(string)
    Private-subnets   = list(string)
    Public-subnets    = list(string)
    availability_zone = list(string)

  })

  default = {
    vpc_cidr          = "10.10.0.0/16"
    subnet_names      = ["public", "private"]
    Private-subnets   = ["app1"]
    Public-subnets    = ["web2"]
    availability_zone = ["a", "b"]
  }
}