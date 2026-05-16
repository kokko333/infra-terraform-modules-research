package test

import (
	"fmt"
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"strings"
	"testing"
	"time"
)

const networkDir = "../live/terraform-native/network"
const dbDir      = "../live/terraform-native/data-stores/mysql"
const appDir     = "../live/terraform-native/services/hello-world-app"

func TestHelloWorldApp(t *testing.T) {
	t.Parallel()

	uniqueId := random.UniqueId()

	networkOpts := createNetworkOpts(t, uniqueId, networkDir)
	defer terraform.Destroy(t, networkOpts)
	terraform.InitAndApply(t, networkOpts)

	dbOpts := createDbOpts(t, uniqueId, networkOpts, dbDir)
	defer terraform.Destroy(t, dbOpts)
	terraform.InitAndApply(t, dbOpts)

	helloOpts := createHelloOpts(t, uniqueId, dbOpts, networkOpts, appDir)
	defer terraform.Destroy(t, helloOpts)
	terraform.InitAndApply(t, helloOpts)

	validateHelloApp(t, helloOpts)
}

func createNetworkOpts(t *testing.T, uniqueId string, terraformDir string) *terraform.Options {
	return &terraform.Options{
		TerraformDir: terraformDir,
		Reconfigure:  true,
		BackendConfig: map[string]interface{}{
			"bucket":  TerraformStateBucket,
			"region":  TerraformStateRegion,
			"key":     fmt.Sprintf("%s/%s/network/terraform.tfstate", t.Name(), uniqueId),
			"encrypt": true,
		},
	}
}

func createDbOpts(t *testing.T, uniqueId string, networkOpts *terraform.Options, terraformDir string) *terraform.Options {
	return &terraform.Options{
		TerraformDir: terraformDir,
		Reconfigure:  true,

		Vars: map[string]interface{}{
			"db_name":                     fmt.Sprintf("test%s", strings.ToLower(uniqueId)),
			"network_remote_state_bucket": networkOpts.BackendConfig["bucket"],
			"network_remote_state_key":    networkOpts.BackendConfig["key"],
		},

		BackendConfig: map[string]interface{}{
			"bucket":  TerraformStateBucket,
			"region":  TerraformStateRegion,
			"key":     fmt.Sprintf("%s/%s/db/terraform.tfstate", t.Name(), uniqueId),
			"encrypt": true,
		},
	}
}

func createHelloOpts(
	t *testing.T,
	uniqueId string,
	dbOpts *terraform.Options,
	networkOpts *terraform.Options,
	terraformDir string) *terraform.Options {

	return &terraform.Options{
		TerraformDir: terraformDir,
		Reconfigure:  true,

		Vars: map[string]interface{}{
			"db_remote_state_bucket":      dbOpts.BackendConfig["bucket"],
			"db_remote_state_key":         dbOpts.BackendConfig["key"],
			"network_remote_state_bucket": networkOpts.BackendConfig["bucket"],
			"network_remote_state_key":    networkOpts.BackendConfig["key"],
			"environment":                 dbOpts.Vars["db_name"],
			"ami_id":                      GetRequiredEnvVar(t, TerraformAmiIdForTestEnvVarName),
		},

		BackendConfig: map[string]interface{}{
			"bucket":  dbOpts.BackendConfig["bucket"],
			"region":  dbOpts.BackendConfig["region"],
			"key":     fmt.Sprintf("%s/%s/hello-world-app/terraform.tfstate", t.Name(), uniqueId),
			"encrypt": true,
		},

		MaxRetries:         3,
		TimeBetweenRetries: 5 * time.Second,
		RetryableTerraformErrors: map[string]string{
			"RequestError: send request failed": "Throttling issue?",
		},
	}
}

func validateHelloApp(t *testing.T, helloOpts *terraform.Options) {
	albDnsName := terraform.OutputRequired(t, helloOpts, "alb_dns_name")
	url := fmt.Sprintf("http://%s", albDnsName)

	maxRetries := 10
	timeBetweenRetries := 10 * time.Second

	http_helper.HttpGetWithRetryWithCustomValidation(
		t,
		url,
		nil,
		maxRetries,
		timeBetweenRetries,
		func(status int, body string) bool {
			return status == 200 &&
				strings.Contains(body, "Hello, World")
		},
	)
}

func TestHelloWorldAppWithStages(t *testing.T) {
	t.Parallel()

	stage := test_structure.RunTestStage

	defer stage(t, "teardown_network", func() { teardownNetwork(t, networkDir) })
	stage(t, "deploy_network", func() { deployNetwork(t, networkDir) })

	defer stage(t, "teardown_db", func() { teardownDb(t, dbDir) })
	stage(t, "deploy_db", func() { deployDb(t, networkDir, dbDir) })

	defer stage(t, "teardown_app", func() { teardownApp(t, appDir) })
	stage(t, "deploy_app", func() { deployApp(t, networkDir, dbDir, appDir) })

	stage(t, "validate_app", func() { validateApp(t, appDir) })
}

func teardownNetwork(t *testing.T, networkDir string) {
	networkOpts := test_structure.LoadTerraformOptions(t, networkDir)
	defer terraform.Destroy(t, networkOpts)
}

func deployNetwork(t *testing.T, networkDir string) {
	uniqueId := random.UniqueId()
	test_structure.SaveString(t, networkDir, "uniqueId", uniqueId)
	networkOpts := createNetworkOpts(t, uniqueId, networkDir)
	test_structure.SaveTerraformOptions(t, networkDir, networkOpts)
	terraform.InitAndApply(t, networkOpts)
}

func teardownDb(t *testing.T, dbDir string) {
	dbOpts := test_structure.LoadTerraformOptions(t, dbDir)
	defer terraform.Destroy(t, dbOpts)
}

func deployDb(t *testing.T, networkDir string, dbDir string) {
	uniqueId := test_structure.LoadString(t, networkDir, "uniqueId")
	networkOpts := test_structure.LoadTerraformOptions(t, networkDir)
	dbOpts := createDbOpts(t, uniqueId, networkOpts, dbDir)
	test_structure.SaveTerraformOptions(t, dbDir, dbOpts)
	terraform.InitAndApply(t, dbOpts)
}

func teardownApp(t *testing.T, appDir string) {
	helloOpts := test_structure.LoadTerraformOptions(t, appDir)
	defer terraform.Destroy(t, helloOpts)
}

func deployApp(t *testing.T, networkDir string, dbDir string, appDir string) {
	uniqueId := test_structure.LoadString(t, networkDir, "uniqueId")
	networkOpts := test_structure.LoadTerraformOptions(t, networkDir)
	dbOpts := test_structure.LoadTerraformOptions(t, dbDir)
	helloOpts := createHelloOpts(t, uniqueId, dbOpts, networkOpts, appDir)
	test_structure.SaveTerraformOptions(t, appDir, helloOpts)
	terraform.InitAndApply(t, helloOpts)
}

func validateApp(t *testing.T, appDir string) {
	helloOpts := test_structure.LoadTerraformOptions(t, appDir)
	validateHelloApp(t, helloOpts)
}
