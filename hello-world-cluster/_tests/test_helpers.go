package test

import (
	"os"
	"testing"
)

// S3 バックエンド用: terraform-state を保存するバケット名とリージョン
const TerraformStateBucketForTestEnvVarName = "TEST_STATE_S3_BUCKET"
const TerraformStateRegionForTestEnvVarName = "TEST_STATE_REGION"

// AMI ID（Ubuntu 24.04 LTS、ap-northeast-1）
const TerraformAmiIdForTestEnvVarName = "TEST_AMI_ID"

// 指定した名前の環境変数の値を返す。環境変数が未設定の場合はテストを失敗させる。
func GetRequiredEnvVar(t *testing.T, envVarName string) string {
	envVarValue := os.Getenv(envVarName)
	if envVarValue == "" {
		t.Fatalf("Required environment variable '%s' is not set", envVarName)
	}
	return envVarValue
}

