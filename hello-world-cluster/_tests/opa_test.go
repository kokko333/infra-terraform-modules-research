package test

import (
	"github.com/gruntwork-io/terratest/modules/opa"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"testing"
)

func TestOPA(t *testing.T) {
	t.Parallel()

	tfOpts := &terraform.Options{
		TerraformDir: "../_examples/hello-world-app",
	}

	opaOpts := &opa.EvalOptions{
		RulePath: "../../global-opa/enforce_tagging.rego",
		FailMode: opa.FailUndefined,
	}

	terraform.OPAEval(t, tfOpts, opaOpts, "data.enforce_specified_tags.allow")
}
