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

	terraformOptions := &terraform.Options{
		TerraformDir: "../_examples/mysql",
		Vars: map[string]interface{}{
			"db_name":     strings.ToLower(fmt.Sprintf("test%s", random.UniqueId())), // db_name では大文字不可
			"db_username": "admin",
			"db_password": "password",
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}
