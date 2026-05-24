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
#                     OR   aws ec2 describe-images \
#                            --owners 099720109477 --region ap-northeast-1 \
#                            --filters \
#                              "Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*" \
#                              "Name=state,Values=available" \
#                            --query "sort_by(Images, &CreationDate)[-1].ImageId" \
#                            --output text
#                         ※　--owners 099720109477: Canonical（Ubuntu の公式 AWS アカウント ID）
#                         ※　--filters: Ubuntu 24.04 (Noble) の gp3 AMI に絞り込み
#                         ※　sort_by(Images, &CreationDate)[-1]: 最新のものを取得
#
# --- test-integration / test-integration-stages 実行時 ---
#   TEST_AMI_ID          : Ubuntu 24.04 LTS の AMI ID（上記コマンドで取得）
#   ※ S3 バケット・リージョン・DB 認証情報はテストコードの定数 / Terraform デフォルト値を使用
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

# =============================================================================
# validate パターンルール設定
# モジュール追加時: validate_path_<名前> と VALIDATE_TARGETS を編集するだけでよい
# =============================================================================

validate_path_state          := global-resources/state-management
validate_path_alb            := global-modules/alb
validate_path_asg            := global-modules/asg
validate_path_mysql          := global-modules/mysql
validate_path_network        := global-modules/network
validate_path_example-alb     := global-modules/_examples/alb
validate_path_example-asg     := global-modules/_examples/asg
validate_path_example-mysql   := global-modules/_examples/mysql
validate_path_example-network := global-modules/_examples/network

validate_path_hw-app         := hello-world-cluster/modules/hello-world-app
validate_path_example-hw-app := hello-world-cluster/_examples/hello-world-app
validate_path_native-network := hello-world-cluster/live/terraform-native/network
validate_path_native-mysql   := hello-world-cluster/live/terraform-native/data-stores/mysql
validate_path_native-app     := hello-world-cluster/live/terraform-native/services/hello-world-app

VALIDATE_TARGETS := \
	state \
	alb asg mysql network \
	example-alb example-asg example-mysql example-network \
	hw-app example-hw-app \
	native-network native-mysql native-app

# =============================================================================
# deploy/destroy example パターンルール設定
# example 追加時: example_path_<名前> と EXAMPLE_TARGETS を編集するだけでよい
# =============================================================================

example_path_asg         := global-modules/_examples/asg
example_path_alb         := global-modules/_examples/alb
example_path_mysql       := global-modules/_examples/mysql
example_path_network     := global-modules/_examples/network

example_path_hello-world := hello-world-cluster/_examples/hello-world-app

EXAMPLE_TARGETS := asg alb mysql network hello-world

# =============================================================================
# test-global パターンルール設定
# テスト追加時: test_func_<名前> と GLOBAL_TEST_TARGETS を編集するだけでよい
# =============================================================================

test_func_network      := TestNetworkExample
test_func_network-plan := TestNetworkExamplePlan
test_func_alb          := TestAlbExample
test_func_alb-plan     := TestAlbExamplePlan
test_func_asg          := TestAsgExample
test_func_mysql        := TestMySqlExample

GLOBAL_TEST_TARGETS := network network-plan alb alb-plan asg mysql

# =============================================================================
# .PHONY
# =============================================================================

.PHONY: \
	check-state check-state-sh \
	check fmt-check fmt lint opa-check \
	validate $(addprefix validate-,$(VALIDATE_TARGETS)) \
	test-global-modules $(addprefix test-global-,$(GLOBAL_TEST_TARGETS)) \
	deploy-state destroy-state \
	$(addprefix deploy-example-,$(EXAMPLE_TARGETS)) \
	$(addprefix destroy-example-,$(EXAMPLE_TARGETS)) \
	test-example test-integration test-integration-stages test-opa \
	deploy-native destroy-native \
	deploy-tg destroy-tg \
	drift drift-native drift-tg

# =============================================================================
# state チェック
# S3 の全 .tfstate をスキャンし、リソースが残存しているものを報告する
# =============================================================================

check-state: # Windows PowerShell 版
	powershell -ExecutionPolicy Bypass -File scripts/check-state.ps1

check-state-sh: # Linux / macOS Bash 版
	bash scripts/check-state.sh

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

# =============================================================================
# validate
# 全実行: make validate
# 個別実行: make validate-alb / make validate-example-alb など
# =============================================================================

validate: $(addprefix validate-,$(VALIDATE_TARGETS))

$(addprefix validate-,$(VALIDATE_TARGETS)): validate-%:
	terraform -chdir=$(validate_path_$*) init -backend=false -input=false
	terraform -chdir=$(validate_path_$*) validate

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
# deploy: make deploy-example-alb / make deploy-example-asg など
# destroy: make destroy-example-alb / make destroy-example-asg など
# 注意: mysql は TF_VAR_db_username / TF_VAR_db_password の設定が必要
# =============================================================================

$(addprefix deploy-example-,$(EXAMPLE_TARGETS)): deploy-example-%:
	terraform -chdir=$(example_path_$*) init -backend-config=$(BACKEND_CONFIG)
	terraform -chdir=$(example_path_$*) apply

$(addprefix destroy-example-,$(EXAMPLE_TARGETS)): destroy-example-%:
	terraform -chdir=$(example_path_$*) init -backend-config=$(BACKEND_CONFIG)
	terraform -chdir=$(example_path_$*) destroy

# =============================================================================
# テスト
# =============================================================================

# global-modules/_tests/ 配下の全テストを一括実行
test-global-modules:
	cd $(GLOBAL_TESTS) && go test -v -timeout 30m ./...

# global-modules/_tests/ 配下の個別テスト実行
# 全実行: make test-global-modules
# 個別実行: make test-global-alb / make test-global-asg など
$(addprefix test-global-,$(GLOBAL_TEST_TARGETS)): test-global-%:
	cd $(GLOBAL_TESTS) && go test -v -timeout 30m -run '^$(test_func_$*)$$' ./...

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
	cd $(TGRUNT_DIR) && terragrunt run-all apply --terragrunt-non-interactive -auto-approve --terragrunt-download-dir C:/tgcache

destroy-tg:
	cd $(TGRUNT_DIR) && terragrunt run-all destroy --terragrunt-non-interactive -auto-approve --terragrunt-download-dir C:/tgcache

# =============================================================================
# drift 検知 — 手動変更のみを表示 (コード差分は含まない)
# -refresh-only: state と実環境の差分だけを plan する
# drift:        terraform-native と terragrunt の両方をチェック
# drift-native: terraform-native 配下の各モジュールを個別にチェック
# drift-tg:     terragrunt run-all で全モジュールをまとめてチェック
# =============================================================================

drift: drift-native drift-tg

drift-native:
	terraform -chdir=$(NATIVE_DIR)/network init -backend-config=$(BACKEND_CONFIG) -input=false
	terraform -chdir=$(NATIVE_DIR)/network plan -refresh-only
	terraform -chdir=$(NATIVE_DIR)/data-stores/mysql init -backend-config=$(BACKEND_CONFIG) -input=false
	terraform -chdir=$(NATIVE_DIR)/data-stores/mysql plan -refresh-only \
		-var network_remote_state_bucket=$(STATE_BUCKET) \
		-var network_remote_state_key=$(NETWORK_STATE_KEY)
	terraform -chdir=$(NATIVE_DIR)/services/hello-world-app init -backend-config=$(BACKEND_CONFIG) -input=false
	terraform -chdir=$(NATIVE_DIR)/services/hello-world-app plan -refresh-only \
		-var network_remote_state_bucket=$(STATE_BUCKET) \
		-var network_remote_state_key=$(NETWORK_STATE_KEY) \
		-var db_remote_state_bucket=$(STATE_BUCKET) \
		-var db_remote_state_key=$(DB_STATE_KEY)

drift-tg:
	cd $(TGRUNT_DIR) && terragrunt run-all plan -refresh-only --terragrunt-non-interactive --terragrunt-download-dir C:/tgcache
