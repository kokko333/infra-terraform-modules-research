package test

import (
	"fmt"

	"github.com/stretchr/testify/require"

	"testing"
	"time"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestAlbExample(t *testing.T) {

	t.Parallel()

	uniqueId := random.UniqueId()

	opts := &terraform.Options{
		TerraformDir: "../_examples/alb",
		Reconfigure:  true,

		Vars: map[string]interface{}{
			"alb_name": fmt.Sprintf("test-%s", uniqueId),
		},

		BackendConfig: map[string]interface{}{
			"bucket":  TerraformStateBucket,
			"region":  TerraformStateRegion,
			"key":     fmt.Sprintf("%s/%s/alb/terraform.tfstate", t.Name(), uniqueId),
			"encrypt": true,
		},
	}

	// テスト終了時にリソースをすべて削除する
	defer terraform.Destroy(t, opts)

	// example をデプロイする
	terraform.InitAndApply(t, opts)

	// ALB の URL を取得する
	albDnsName := terraform.OutputRequired(t, opts, "alb_dns_name")
	url := fmt.Sprintf("http://%s", albDnsName)

	// ALB のデフォルトアクションが 404 を返すことを確認する
	expectedStatus := 404
	expectedBody := "404: page not found"
	maxRetries := 10
	timeBetweenRetries := 10 * time.Second

	http_helper.HttpGetWithRetry(
		t,
		url,
		nil,
		expectedStatus,
		expectedBody,
		maxRetries,
		timeBetweenRetries,
	)

}

func TestAlbExamplePlan(t *testing.T) {
	t.Parallel()

	uniqueId := random.UniqueId()
	albName := fmt.Sprintf("test-%s", uniqueId)

	opts := &terraform.Options{
		TerraformDir: "../_examples/alb",
		Reconfigure:  true,
		NoColor:      true, // ANSIコードで GetResourceCount の正規表現がマッチしない問題が発生したため設定
		Vars: map[string]interface{}{
			"alb_name": albName,
		},
		BackendConfig: map[string]interface{}{
			"bucket":  TerraformStateBucket,
			"region":  TerraformStateRegion,
			"key":     fmt.Sprintf("%s/%s/alb/terraform.tfstate", t.Name(), uniqueId),
			"encrypt": true,
		},
	}

	planString := terraform.InitAndPlan(t, opts)

	// plan 出力の add/change/destroy 件数を検証する
	resourceCounts := terraform.GetResourceCount(t, planString)
	require.Equal(t, 5, resourceCounts.Add)
	require.Equal(t, 0, resourceCounts.Change)
	require.Equal(t, 0, resourceCounts.Destroy)

	// plan 出力内の特定の値を検証する
	planStruct :=
		terraform.InitAndPlanAndShowWithStructNoLogTempPlanFile(t, opts)

	alb, exists :=
		planStruct.ResourcePlannedValuesMap["module.alb.aws_lb.example"]
	require.True(t, exists, "aws_lb リソースが存在するはずです")

	name, exists := alb.AttributeValues["name"]
	require.True(t, exists, "name パラメータが存在するはずです")
	require.Equal(t, albName, name)
}

