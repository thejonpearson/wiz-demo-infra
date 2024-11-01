data "aws_default_tags" "demo" {}

resource "random_string" "name-addition" {
  length  = 5
  special = false
  numeric = false
  upper   = false
}

locals {
  # name we append component info to when building items
  # tracks runs and also ensures globally unique names for
  # things like s3 buckets...
  name_base = "demo-${random_string.name-addition.result}"
}

module "vpc" {
  source = "./modules/vpc"
  name   = local.name_base
}

module "eks" {
  source              = "./modules/eks"
  name                = local.name_base
  vpcid               = module.vpc.vpc_id
  vpc_private_subnets = module.vpc.private_subnets
}