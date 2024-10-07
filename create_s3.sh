#! /bin/bash

# S3バケット一覧の表示
echo "## 現在のS3バケット一覧 ##"
aws s3 ls

echo "使用するS3 Bucket名を指定してください"
read bucket_name


echo "使用するregionを指定してください(空欄の場合はap-northeast-1です)"
read region
region=${region:-ap-northeast-1}

# バケットの存在を確認
if aws s3api head-bucket --bucket "$bucket_name" 2>/dev/null; then
  echo "バケット $bucket_name は既に存在しています。"
else
  set -x
  # バケットの作成
  aws s3 mb s3://$bucket_name --region $region
  set +x
fi

# バージョニングの状態を確認
versioning_status=$(aws s3api get-bucket-versioning --bucket $bucket_name --query "Status" --output text)
if [ "$versioning_status" != "Enabled" ]; then
  set -x
  # バージョニングの有効化
  aws s3api put-bucket-versioning --bucket $bucket_name --versioning-configuration Status=Enabled
  set +x
else
  echo "バージョニングは既に有効化されています。"
fi

# 暗号化の状態を確認
encryption_status=$(aws s3api get-bucket-encryption --bucket $bucket_name 2>/dev/null)
if [ -z "$encryption_status" ]; then
  set -x
  # 暗号化の有効化
  aws s3api put-bucket-encryption --bucket $bucket_name --server-side-encryption-configuration '{
      "Rules": [
          {
              "ApplyServerSideEncryptionByDefault": {
                  "SSEAlgorithm": "AES256"
              }
          }
      ]
  }'
  set +x
else
  echo "暗号化は既に有効化されています。"
fi

# バケットポリシーの状態を確認
policy_status=$(aws s3api get-bucket-policy --bucket $bucket_name 2>/dev/null)
if [ -z "$policy_status" ]; then
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
  set -x
  aws s3api put-bucket-policy --bucket $bucket_name --policy file://tmp_bucket-policy.json
  rm tmp_bucket-policy.json
  set +x
else
  echo "バケットポリシーは既に設定されています。"
fi

echo "S3の設定が終了しました"
