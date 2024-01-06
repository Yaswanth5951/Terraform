variable "region" {
  type        = string
  default     = "us-west-2"
  description = "region in which resource will be created"
}

variable "vpc_cidr" {
  type    = string
  default = "10.100.0.0/16"
}

variable "subnet_count" {
  type    = number
  default = 3

}
variable "subnet_name" {
  type    = list(string)
  default = ["app", "web", "abc"]

}


variable "security_group_info" {
  type = object({
    name        = string
    vpc_id      = string
    description = string
    rules = list(object({
      from_port   = string
      to_port     = string
      protocol    = string
      type        = string
      cidr_blocks = list(string)

    }))
  })

  default = {
    name        = "private"
    description = "this is new security group"
    vpc_id      = ""
    rules = [{
      from_port   = "22"
      to_port     = "22"
      type        = "ingress"
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      },

      {
        from_port   = "80"
        to_port     = "80"
        type        = "ingress"
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }

    ]

  }
}

