## マニュアル

### 初期化

- terrafrom の初期化（使用するプロバイダのコードをダウンロードする など）
  $ terraform init

※ .hcl ファイルの存在する各階層で初期化を実施する必要がある(っぽい)

- 整形ツール（tflint）のルールを取得する
  $ tflit --init

### 構築/削除

- 構築
  $ terraform apply

- 削除
  $ terraform destroy

### 検証環境の簡易作成（ワークスペース）

- 作成
  $ terraform workspace new [workspace名]

- 切り替え
  $ terraform workspace select [workspace名]

- 確認
  $ terraform workspace show
  $ terraform workspace list

※　default ワークスペースとそれ以外のワークスペースで、リモートステートファイルの置き場所が異なる。

・defaultの場合
　s3::[backend S3名] / [ terraform文で指定したプレフィックス ] / terraform.tfstate
・それ以外の場合
　s3::[backend S3名] / env: / [ terraform文で指定したプレフィックス ] / terraform.tfstate

※　workspace を切り替え忘れたまま destroy してしまうなど人為的ミスのリスクが高いので環境分離には不適

### 開発

- 整形
  $ terraform fmt

- 構文検証
  $ terraform validate
  $ tflint

### テスト（terratest）

- テストコード(.go) 実行
  1. テストフォルダに移動し、 $ go mod init [ NAME (ex: github.com/[org]/[project]) ]
     - go の依存関係管理ファイル(go.mod)を生成する
  2. terratest をインストールするために、 $ go mod tidy
     - 前提条件などはガイド（https://terratest.gruntwork.io/docs/getting-started/quick-start/）参照
  3. テストフォルダで、 $ go test (-v) -timeout 30m (-parallel [並列数]) (-run '[テストメソッド名(Test~)]')
     - デフォルトの10分でテストが中断し、destroyコマンドが実行され損ねるのを回避するために、timeout設定はほぼ必須
     - テストステージの管理を入れる場合
       - `$ SKIP_[ステージ名]=true go test ...`
       - ex: $ SKIP_teardowm_db=true go test ... (DBを使いまわす想定)

### レビュー

- 構築されるリソース内容を確認する
  $ terraform plan

- 構築されるリソースの依存関係を確認する（graphviz 形式）
  $ terraform graph

- 過去の構築時の出力内容を再確認する
  $ terraform output

## special thanks

- 書籍：　詳解 terraform
  - https://www.oreilly.co.jp/books/9784814400522/
  - repo: https://github.com/brikis98/terraform-up-and-running-code
