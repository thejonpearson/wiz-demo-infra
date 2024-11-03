## set & define default tags once ##
data "aws_default_tags" "demo" {}

## grab a list of AZs available
data "aws_availability_zones" "available" {
    state = "available"
}

locals {
  name   = "${var.name}-vpc"
  region = "us-west-2"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
}

## create VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.14.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs

  private_subnets = [
    "10.0.0.0/21",
    "10.0.8.0/21",
    "10.0.16.0/21"
  ]

  public_subnets = [
    "10.0.24.0/21",
    "10.0.32.0/21",
    "10.0.40.0/21"
  ]

  public_subnet_tags = {
    Type = "public",
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    Type = "private",
    "kubernetes.io/role/internal-elb" = "1"
  }

  enable_dns_hostnames = true
  enable_dns_support = true
  enable_nat_gateway = true
  single_nat_gateway = true

}

