package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestMySqlExample(t *testing.T) {
	t.Parallel()

	uniqueId := random.UniqueId()

	terraformOptions := &terraform.Options{
		TerraformDir: "../_examples/mysql",
		Reconfigure:  true,

		Vars: map[string]interface{}{
			"db_name":     strings.ToLower(fmt.Sprintf("test%s", uniqueId)), // db_name では大文字不可
			"db_username": "admin",
			"db_password": "password",
		},

		BackendConfig: map[string]interface{}{
			"bucket":  TerraformStateBucket,
			"region":  TerraformStateRegion,
			"key":     fmt.Sprintf("%s/%s/mysql/terraform.tfstate", t.Name(), uniqueId),
			"encrypt": true,
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}
