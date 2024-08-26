terraform {
  required_version = ">= 1.6.6"
  backend "s3" {
    bucket  = "inspector-terraform-state"
    key     = "terraform.tfstate"
    region  = "ap-northeast-1"
  }
}

provider "aws" {
  region  = "ap-northeast-1"
}
