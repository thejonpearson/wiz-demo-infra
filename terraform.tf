## terraform specific ##

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

## AWS Specific ##

provider "aws" {
  region = "us-west-2"

  default_tags {
    tags = {
      project = "wiz-demo"
    }
  }
}