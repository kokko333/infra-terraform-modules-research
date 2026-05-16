package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestAsgExample(t *testing.T) {
	t.Parallel()

	uniqueId := random.UniqueId()

	terraformOptions := &terraform.Options{
		TerraformDir: "../_examples/asg",
		Reconfigure:  true,

		Vars: map[string]interface{}{
			"cluster_name": fmt.Sprintf("test-%s", uniqueId),
		},

		BackendConfig: map[string]interface{}{
			"bucket":  TerraformStateBucket,
			"region":  TerraformStateRegion,
			"key":     fmt.Sprintf("%s/%s/asg/terraform.tfstate", t.Name(), uniqueId),
			"encrypt": true,
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}
