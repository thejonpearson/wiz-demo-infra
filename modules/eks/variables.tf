variable "name" {
    type = string
}

variable "vpcid" {
  type = string
}

variable "vpc_private_subnets" {
  type = list(string)
}