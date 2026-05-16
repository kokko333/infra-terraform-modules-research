package test

import (
	"os"
	"testing"
)

// S3 バックエンド（backend.hcl）の共通設定値
const (
	TerraformStateBucket = "terraform-state-kokko-sample"
	TerraformStateRegion = "ap-northeast-1"
)

// AMI ID（Ubuntu 24.04 LTS、ap-northeast-1）
// 以下のコマンドで最新値を取得できる:
//
//	aws ec2 describe-images \
//	  --owners 099720109477 --region ap-northeast-1 \
//	  --filters \
//	    "Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*" \
//	    "Name=state,Values=available" \
//	  --query "sort_by(Images, &CreationDate)[-1].ImageId" \
//	  --output text
const TerraformAmiIdForTestEnvVarName = "TEST_AMI_ID"

// 指定した名前の環境変数の値を返す。環境変数が未設定の場合はテストを失敗させる。
func GetRequiredEnvVar(t *testing.T, envVarName string) string {
	envVarValue := os.Getenv(envVarName)
	if envVarValue == "" {
		t.Fatalf("Required environment variable '%s' is not set", envVarName)
	}
	return envVarValue
}

