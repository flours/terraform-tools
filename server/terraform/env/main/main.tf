# Terraform のプロバイダーを設定
provider "aws" {
  region = "ap-northeast-1"  
  profile = "tada-develop"   
}

terraform {
  backend "s3" {
    bucket  = "sample-bucket-aaffxxffss"
    region  = "ap-northeast-1"
    profile = "tada-develop"
    key     = "production.tfstate"
    encrypt = true
  }
}

# EC2 インスタンスを作成
# resource "aws_instance" "example" {
#   ami           = "ami-0ef29ab52ff72213b"
#   instance_type = "t2.micro"               # インスタンスタイプ

#   tags = {
#     Name = "example-instance"              # インスタンスに付けるタグ
#   }
# }

# # 出力変数（インスタンスの公開 IP を表示）
# output "instance_public_ip" {
#   value = aws_instance.example.public_ip
# }
