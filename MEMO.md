## マニュアル

### 初期化

- terrafrom の初期化（使用するプロバイダのコードをダウンロードする など）
  $ terraform init

※ backendやproviderを持つルートモジュールのあるディレクトリごとに実行が必要
※ 以下の場合に実行する
　・初回セットアップ時（まだ .terraform/ が存在しない時）
　・backend 設定を変更した時
　・required_providers 設定を変更した時
　・module を追加変更した時

- 整形ツール（tflint）のルールを取得する
  $ tflint --init

### 構築/削除

- 構築
  $ terraform apply

- 削除
  $ terraform destroy

### 開発

- 整形
  $ terraform fmt

- 構文検証
  $ terraform validate
  $ tflint

### レビュー

- 構築されるリソース内容を確認する
  $ terraform plan

- 構築されるリソースの依存関係を確認する（graphviz 形式）
  $ terraform graph

- 過去の構築時の出力内容を再確認する
  $ terraform output

### テスト（terratest）

- テストコード(.go) 実行
  1. $ cd [test-folder-path] & go mod init [ NAME (ex: github.com/[org]/[project]) ]
     - go の依存関係管理ファイル(go.mod)を生成する
  2. $ go mod tidy
     - terratest をインストールするため
     - 前提条件などはガイド（https://terratest.gruntwork.io/docs/getting-started/quick-start/）参照
  3. $ go test (-v) -timeout 30m (-parallel [並列数]) (-run '[テストメソッド名(Test~)]')
     - デフォルトの10分でテストが中断し、destroyコマンドが実行され損ねるのを回避するために、timeout設定はほぼ必須
     - テストステージの管理を入れる場合
       - `$ SKIP_[ステージ名]=true go test ...`
       - ex: $ SKIP_teardowm_db=true go test ... (DBを使いまわす想定)

## Tips

### 検証環境の簡易作成（ワークスペース）

- 作成
  $ terraform workspace new [workspace名]

- 切り替え
  $ terraform workspace select [workspace名]

- 確認
  $ terraform workspace show
  $ terraform workspace list

※ "terraform.workspace"変数でコード内で選択中のワークスペースを参照できる

※ default ワークスペースとそれ以外のワークスペースで、リモートステートファイルの置き場所が異なる。
・defaultの場合
　s3::[backend S3名] / [ backend.key ] / terraform.tfstate
・それ以外の場合
　s3::[backend S3名] / env: / [ backend.key ] / terraform.tfstate

※ workspace を切り替え忘れたまま destroy してしまうなど人為的ミスのリスクが高いので環境分離には不適

### module のバージョニング（gitの場合）

moduleはローカルパス指定のほかに、github URL + TAG での指定も可能。
ex: git@github.com:<owner>/<repo>.git//<module_path>?ref=<version_tag>

※ privateリポジトリから取得する場合は認証が必要。
　 ssh設定をしておけばよい（git clone <URL> できるかで設定済みか確認できる）

### security

- stateファイルは構築時に指定された秘密情報も平文で保持する
  - データ保護：暗号化可能なファイルストレージに保存する、など
  - アクセス制御：IAMポリシーによるアクセス管理、など

### practices

- count vs for_each
  - count は三項演算子と組み合わせ、リソースを作成有無を条件付きで切り替える際に有用
  - for_each は↑以外の用途全般に使う

## special thanks

- 書籍：　詳解 terraform
  - https://www.oreilly.co.jp/books/9784814400522/
  - repo: https://github.com/brikis98/terraform-up-and-running-code

## TODO

・tips系

target指定によるモジュールのテストデプロイ
localsブロック（モジュールのローカル定数定義）
for_each によるカスタムタグ指定
instance_refreshインラインブロックでデプロイ方式を指定（awsネイティブなデプロイ機能）

・module系

ec2クラスター
ecsコンテナ構成
API GW + lambda + cognito認証
SQS + lambda + alert

・リファクタ系

terraform import コマンドによる既存インフラのtf取り込み
　→　terraformer や terracognita でまとめて取り込む方法もあるらしい
moved ブロックによる環境影響のないリネーム

・CICD系

github actions 経由でのデプロイ（OAuth前提）
circle ci 経由でのデプロイ（OAuth前提）
