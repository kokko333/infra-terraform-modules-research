package test

import (
	"fmt"
	"sort"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"
)

func TestNetworkExamplePlan(t *testing.T) {
	t.Parallel()

	opts := &terraform.Options{
		TerraformDir: "../_examples/network",
		Vars: map[string]interface{}{
			"name": fmt.Sprintf("test-%s", random.UniqueId()),
		},
	}

	planStruct := terraform.InitAndPlanAndShowWithStructNoLogTempPlanFile(t, opts)

	subnetCount := 0
	for key := range planStruct.ResourcePlannedValuesMap {
		if strings.HasPrefix(key, "module.network.aws_subnet.public[") {
			subnetCount++
		}
	}

	require.Equal(t, 2, subnetCount, "expected 2 public subnets to be planned")
}

func TestNetworkExample(t *testing.T) {
	t.Parallel()

	awsRegion := "ap-northeast-1"

	opts := &terraform.Options{
		TerraformDir: "../_examples/network",
		Vars: map[string]interface{}{
			"name": fmt.Sprintf("test-%s", random.UniqueId()),
		},
	}

	defer terraform.Destroy(t, opts)
	terraform.InitAndApply(t, opts)

	vpcId := terraform.OutputRequired(t, opts, "vpc_id")

	subnets := aws.GetSubnetsForVpc(t, vpcId, awsRegion)
	require.Len(t, subnets, 2, "expected 2 subnets in VPC")

	azs := make([]string, 0, len(subnets))
	for _, subnet := range subnets {
		azs = append(azs, subnet.AvailabilityZone)
	}

	sort.Strings(azs)
	expectedAZs := []string{"ap-northeast-1a", "ap-northeast-1c"}
	require.Equal(t, expectedAZs, azs, "subnets must be in ap-northeast-1a and ap-northeast-1c")
}
