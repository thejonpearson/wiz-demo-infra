data "aws_default_tags" "demo" {}

locals {
  # name we append component info to when building items
  name_base = "demo"
}

module "vpc" {
  source = "./modules/vpc"
  name = local.name_base
}