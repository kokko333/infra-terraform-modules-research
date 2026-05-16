# =============================================================================
# 事前に設定が必要な環境変数
#
# --- global-modules/_examples/mysql デプロイ時 ---
#   TF_VAR_db_username   : RDS MySQL ユーザー名
#   TF_VAR_db_password   : RDS MySQL パスワード
#
# --- live/terraform-native デプロイ時 ---
#   TF_VAR_db_username   : RDS MySQL ユーザー名
#   TF_VAR_db_password   : RDS MySQL パスワード
#   TF_VAR_ami_id        : Ubuntu 24.04 LTS の AMI ID
#                          aws ssm get-parameter \
#                            --name /aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id \
#                            --region ap-northeast-1 --query "Parameter.Value" --output text
#
# --- test-integration / test-integration-stages 実行時 ---
#   TEST_STATE_S3_BUCKET : テスト用 Terraform state S3 バケット名
#   TEST_STATE_REGION    : テスト用 S3 バケットのリージョン
#   TEST_DB_USERNAME     : RDS MySQL ユーザー名
#   TEST_DB_PASSWORD     : RDS MySQL パスワード
#   TEST_AMI_ID          : Ubuntu 24.04 LTS の AMI ID（上記コマンドで取得）
#
# --- test-integration-stages のステージ制御 ---
#   SKIP_<ステージ名>=true を付けると該当ステージをスキップできる
#   例: SKIP_deploy_network=true make test-integration-stages
# =============================================================================

BACKEND_CONFIG    := $(CURDIR)/backend.hcl
STATE_BUCKET      := terraform-state-kokko-sample
NETWORK_STATE_KEY := hello-world-cluster/network/terraform.tfstate
DB_STATE_KEY      := hello-world-cluster/data-stores/mysql/terraform.tfstate

NATIVE_DIR   := hello-world-cluster/live/terraform-native
TGRUNT_DIR   := hello-world-cluster/live/terragrunt
GLOBAL_TESTS := global-modules/_tests
HW_TESTS     := hello-world-cluster/_tests

.PHONY: \
	check fmt-check fmt lint opa-check \
	validate \
	validate-state \
	validate-alb validate-asg validate-mysql validate-network \
	validate-example-alb validate-example-asg validate-example-mysql \
	validate-hw-app validate-example-hw-app \
	validate-native-network validate-native-mysql validate-native-app \
	deploy-state destroy-state \
	deploy-example-asg    destroy-example-asg \
	deploy-example-alb    destroy-example-alb \
	deploy-example-mysql  destroy-example-mysql \
	deploy-example-hello-world destroy-example-hello-world \
	test-global-modules \
	test-example test-integration test-integration-stages test-opa \
	deploy-native destroy-native \
	deploy-tg destroy-tg

# =============================================================================
# 静的チェック (AWSアクセス不要)
# check: fmt-check / validate / lint / opa-check を一括実行
# =============================================================================

check: fmt-check validate lint opa-check

# 書式チェック（差分があれば非ゼロ終了）
fmt-check:
	terraform fmt -recursive -check

# 書式を自動修正
fmt:
	terraform fmt -recursive

# tflint による Lint チェック
lint:
	tflint --recursive

# OPA ポリシーの構文チェック
opa-check:
	opa check global-opa/enforce_tagging.rego


# 全モジュール・example の構文検証（個別実行も可: make validate-alb など）
validate: \
	validate-state \
	validate-alb validate-asg validate-mysql validate-network \
	validate-example-alb validate-example-asg validate-example-mysql \
	validate-hw-app validate-example-hw-app \
	validate-native-network validate-native-mysql validate-native-app

# --- global-resources ---
validate-state:
	terraform -chdir=global-resources/state-management init -backend=false -input=false
	terraform -chdir=global-resources/state-management validate

# --- global-modules (モジュール本体) ---
validate-alb:
	terraform -chdir=global-modules/alb init -backend=false -input=false
	terraform -chdir=global-modules/alb validate

validate-asg:
	terraform -chdir=global-modules/asg init -backend=false -input=false
	terraform -chdir=global-modules/asg validate

validate-mysql:
	terraform -chdir=global-modules/mysql init -backend=false -input=false
	terraform -chdir=global-modules/mysql validate

validate-network:
	terraform -chdir=global-modules/network init -backend=false -input=false
	terraform -chdir=global-modules/network validate

# --- global-modules/_examples ---
validate-example-alb:
	terraform -chdir=global-modules/_examples/alb init -backend=false -input=false
	terraform -chdir=global-modules/_examples/alb validate

validate-example-asg:
	terraform -chdir=global-modules/_examples/asg init -backend=false -input=false
	terraform -chdir=global-modules/_examples/asg validate

validate-example-mysql:
	terraform -chdir=global-modules/_examples/mysql init -backend=false -input=false
	terraform -chdir=global-modules/_examples/mysql validate

# --- hello-world-cluster (モジュール本体 / example) ---
validate-hw-app:
	terraform -chdir=hello-world-cluster/modules/hello-world-app init -backend=false -input=false
	terraform -chdir=hello-world-cluster/modules/hello-world-app validate

validate-example-hw-app:
	terraform -chdir=hello-world-cluster/_examples/hello-world-app init -backend=false -input=false
	terraform -chdir=hello-world-cluster/_examples/hello-world-app validate

# --- hello-world-cluster/live/terraform-native ---
validate-native-network:
	terraform -chdir=hello-world-cluster/live/terraform-native/network init -backend=false -input=false
	terraform -chdir=hello-world-cluster/live/terraform-native/network validate

validate-native-mysql:
	terraform -chdir=hello-world-cluster/live/terraform-native/data-stores/mysql init -backend=false -input=false
	terraform -chdir=hello-world-cluster/live/terraform-native/data-stores/mysql validate

validate-native-app:
	terraform -chdir=hello-world-cluster/live/terraform-native/services/hello-world-app init -backend=false -input=false
	terraform -chdir=hello-world-cluster/live/terraform-native/services/hello-world-app validate

# =============================================================================
# state 管理リソース (S3 バケット + DynamoDB テーブル)
# 注意: destroy-state を実行すると他の全 Terraform リソースの state が失われます
# =============================================================================

deploy-state:
	terraform -chdir=global-resources/state-management init
	terraform -chdir=global-resources/state-management apply

destroy-state:
	terraform -chdir=global-resources/state-management init
	terraform -chdir=global-resources/state-management destroy

# =============================================================================
# examples — 個別デプロイ / 削除
# =============================================================================

deploy-example-asg:
	terraform -chdir=global-modules/_examples/asg init
	terraform -chdir=global-modules/_examples/asg apply

destroy-example-asg:
	terraform -chdir=global-modules/_examples/asg init
	terraform -chdir=global-modules/_examples/asg destroy

deploy-example-alb:
	terraform -chdir=global-modules/_examples/alb init
	terraform -chdir=global-modules/_examples/alb apply

destroy-example-alb:
	terraform -chdir=global-modules/_examples/alb init
	terraform -chdir=global-modules/_examples/alb destroy

# TF_VAR_db_username / TF_VAR_db_password の設定が必要
deploy-example-mysql:
	terraform -chdir=global-modules/_examples/mysql init
	terraform -chdir=global-modules/_examples/mysql apply

destroy-example-mysql:
	terraform -chdir=global-modules/_examples/mysql init
	terraform -chdir=global-modules/_examples/mysql destroy

deploy-example-hello-world:
	terraform -chdir=hello-world-cluster/_examples/hello-world-app init
	terraform -chdir=hello-world-cluster/_examples/hello-world-app apply

destroy-example-hello-world:
	terraform -chdir=hello-world-cluster/_examples/hello-world-app init
	terraform -chdir=hello-world-cluster/_examples/hello-world-app destroy

# =============================================================================
# テスト
# =============================================================================

# global-modules/_tests/ 配下の全テストを一括実行
test-global-modules:
	cd $(GLOBAL_TESTS) && go test -v -timeout 30m ./...

# hello-world-cluster/_tests/ の各テストを個別実行
test-example:
	cd $(HW_TESTS) && go test -v -timeout 30m -run '^TestHelloWorldAppExample$$' ./...

test-integration:
	cd $(HW_TESTS) && go test -v -timeout 60m -run '^TestHelloWorldApp$$' ./...

test-integration-stages:
	cd $(HW_TESTS) && go test -v -timeout 60m -run '^TestHelloWorldAppWithStages$$' ./...

test-opa:
	cd $(HW_TESTS) && go test -v -timeout 10m -run '^TestOPA$$' ./...

# =============================================================================
# live / terraform-native
# deploy: network → db → app の順でデプロイ
# destroy: app → db → network の逆順で削除
# =============================================================================

deploy-native:
	terraform -chdir=$(NATIVE_DIR)/network init -backend-config=$(BACKEND_CONFIG)
	terraform -chdir=$(NATIVE_DIR)/network apply
	terraform -chdir=$(NATIVE_DIR)/data-stores/mysql init -backend-config=$(BACKEND_CONFIG)
	terraform -chdir=$(NATIVE_DIR)/data-stores/mysql apply \
		-var network_remote_state_bucket=$(STATE_BUCKET) \
		-var network_remote_state_key=$(NETWORK_STATE_KEY)
	terraform -chdir=$(NATIVE_DIR)/services/hello-world-app init -backend-config=$(BACKEND_CONFIG)
	terraform -chdir=$(NATIVE_DIR)/services/hello-world-app apply \
		-var network_remote_state_bucket=$(STATE_BUCKET) \
		-var network_remote_state_key=$(NETWORK_STATE_KEY) \
		-var db_remote_state_bucket=$(STATE_BUCKET) \
		-var db_remote_state_key=$(DB_STATE_KEY)

destroy-native:
	terraform -chdir=$(NATIVE_DIR)/services/hello-world-app init -backend-config=$(BACKEND_CONFIG)
	terraform -chdir=$(NATIVE_DIR)/services/hello-world-app destroy \
		-var network_remote_state_bucket=$(STATE_BUCKET) \
		-var network_remote_state_key=$(NETWORK_STATE_KEY) \
		-var db_remote_state_bucket=$(STATE_BUCKET) \
		-var db_remote_state_key=$(DB_STATE_KEY)
	terraform -chdir=$(NATIVE_DIR)/data-stores/mysql init -backend-config=$(BACKEND_CONFIG)
	terraform -chdir=$(NATIVE_DIR)/data-stores/mysql destroy \
		-var network_remote_state_bucket=$(STATE_BUCKET) \
		-var network_remote_state_key=$(NETWORK_STATE_KEY)
	terraform -chdir=$(NATIVE_DIR)/network init -backend-config=$(BACKEND_CONFIG)
	terraform -chdir=$(NATIVE_DIR)/network destroy

# =============================================================================
# live / terragrunt
# dependency ブロックに基づき自動的に順序を解決してデプロイ / 削除
# =============================================================================

deploy-tg:
	cd $(TGRUNT_DIR) && terragrunt run-all apply

destroy-tg:
	cd $(TGRUNT_DIR) && terragrunt run-all destroy
