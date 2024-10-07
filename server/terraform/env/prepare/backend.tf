terraform {
  # このbucketは手動で作っておく
  backend "s3" {
    bucket  = "sample-bucket-aaffxxffss"
    key     = "prepare.tfstate"
    region  = "ap-northeast-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.21"
    }
  }
}
