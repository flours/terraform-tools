#!/bin/bash

set -e

# AWSアカウント番号を取得する
account_number=$(aws sts get-caller-identity --query 'Account' --output text || { 
    echo "エラーが発生しました。AWS CLIのセットアップをし、Captain Duckから対応するプロジェクトの認証情報をコピーして貼り付けてください" >&2
    exit 1;
})

echo "現在のAWSアカウント番号は: $account_number です。"

# IAMユーザー一覧を表示
echo "現在のIAMユーザー一覧:"
aws iam list-users --query 'Users[*].UserName' --output table

# IAMユーザー作成確認
read -p "IAMユーザー 'Terraform-user' を作成しますか？ [Y/n]: " response

# プロファイル名を入力させる
read -p "AWS CLI プロファイル名を入力してください: " profile_name

# ユーザーの確認
if [[ "$response" == "Y" || "$response" == "y" || "$response" == "" ]]; then
    # IAMユーザーの作成
    echo "IAMユーザー 'Terraform-user' を作成中..."
    aws iam create-user --user-name Terraform-user

    # 管理者権限ポリシーをアタッチ
    echo "AdministratorAccess ポリシーを 'Terraform-user' にアタッチ中..."
    aws iam attach-user-policy --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --user-name Terraform-user

    # アクセスキーの作成
    echo "アクセスキーを発行中..."
    access_key_output=$(aws iam create-access-key --user-name Terraform-user --output json)
    access_key_id=$(echo $access_key_output | jq -r '.AccessKey.AccessKeyId')
    secret_access_key=$(echo $access_key_output | jq -r '.AccessKey.SecretAccessKey')

    echo "アクセスキーが発行されました。"

    # aws configure を実行して入力したプロファイル名で設定
    echo "AWS CLIのプロファイルに '$profile_name' を設定します。"
    aws configure set aws_access_key_id "$access_key_id" --profile "$profile_name"
    aws configure set aws_secret_access_key "$secret_access_key" --profile "$profile_name"
    aws configure set region "us-east-1" --profile "$profile_name"  # 必要に応じてリージョンを変更

    echo "設定が完了しました。"
    echo "AWSプロファイル '$profile_name' が作成されました。"

else
    echo "IAMユーザーの作成をキャンセルしました。"
fi

# IAMのユーザー定義ポリシー一覧を表示
echo "現在のIAMユーザー定義ポリシー一覧:"
aws iam list-policies --scope Local --query 'Policies[*].PolicyName' --output table
