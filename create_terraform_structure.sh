#! /bin/bash

echo "使用するAWS profileを指定してください"
echo "## profile一覧 ##"
aws configure list-profiles
echo "#################"
echo -n "AWS profile名："
read profile

echo "使用するS3 Bucket名を指定してください"
read bucket_name

echo "使用するregionを指定してください(空欄の場合はap-northeast-1です)"
read region
region=${region:-ap-northeast-1}

set -x
aws s3 mb s3://$bucket_name --profile $profile --region $region

# バージョニングの有効化
aws s3api put-bucket-versioning --bucket $bucket_name --versioning-configuration Status=Enabled --profile $profile

# 暗号化の有効化
aws s3api put-bucket-encryption --bucket $bucket_name --server-side-encryption-configuration '{
    "Rules": [
        {
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }
    ]
}' --profile $profile

# バケットポリシーの設定
cat <<EOT > tmp_bucket-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::$bucket_name",
                "arn:aws:s3:::$bucket_name/*"
            ],
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        }
    ]
}
EOT

aws s3api put-bucket-policy --bucket $bucket_name --policy file://tmp_bucket-policy.json --profile $profile
rm tmp_bucket-policy.json

set +x
echo "S3の作成が終了しました"
echo "Terraformプロジェクト構造の作成を開始します"

create_environment() {
  environment=$1
  region=$2
  bucket_name=$3
  profile=$4

  set -x
  mkdir -p environments/$environment
  set +x

  echo "create environments/$environment/provider.tf"
  # provider.tfファイルの作成
  cat <<-EOT > environments/$environment/provider.tf
	provider "aws" {
	  region  = var.region
	  profile = "$profile"
	}
	EOT

  echo "create environments/$environment/main.tf"
  # main.tfファイルの作成
  cat <<-EOT > environments/$environment/main.tf
	# main.tf for $environment environment

	module "s3_bucket" {
	  source = "../../modules/s3_bucket"
	  bucket_name = var.bucket_name
	  environment = "$environment"
	}
	EOT

  echo "create environments/$environment/variables.tf"
  # variables.tfファイルの作成
  cat <<-EOT > environments/$environment/variables.tf
	variable "region" {
	  description = "The AWS region to deploy into"
	  type        = string
	  default     = "$region"
	}

	variable "bucket_name" {
	  description = "The name of the S3 bucket"
	  type        = string
	}
	variable "example_secret_data" {
	  description = "example secret data"
	  type        = string
	}
	EOT

  echo "create environments/$environment/backend.tf"
  # backend.tfファイルの作成
  cat <<-EOT > environments/$environment/backend.tf
	terraform {
	  backend "s3" {
	    bucket  = "$bucket_name"
	    key     = "$environment/terraform.tfstate"
	    region  = "$region"
	    profile = "$profile"
	  }
	}
	EOT

  echo "create environments/$environment/terraform.tfvars"
  cat <<-EOT > environments/$environment/terraform.tfvars
	exmaple_secret_data      = "dummy_data"
	EOT

  echo "$environment 環境のセットアップが完了しました。"
}

create_terraform_structure() {
  region=$1
  bucket_name=$2
  profile=$3

  # 環境ディレクトリの作成
  create_environment "dev" $region $bucket_name $profile
  create_environment "stg" $region $bucket_name $profile
  create_environment "prd" $region $bucket_name $profile

  # modulesディレクトリの作成
  set -x
  mkdir -p modules

  # .gitignoreにterraform.tfvarsを追加
  echo "environments/*/terraform.tfvars" >> .gitignore
  set +x

  echo "Terraformプロジェクト構造のセットアップが完了しました。"
}

create_terraform_structure $region $bucket_name $profile
