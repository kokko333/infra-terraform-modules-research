### マニュアル

##### 使用するCLIツール

- terraform: v1.14.7
- tenv: v4.9.3
  - terraformのバージョン管理のため（必須ではない）
- tflint: v0.61.0
  - ruleset:
    - aws (0.46.0)
    - terraform (0.14.1-bundled)
- terragrunt: v0.63.6
  - コードのスリム化のため
- opa: v0.28.0
  - コードのポリシーチェックのため

##### 初期化

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

##### 構築/削除

- 構築
  $ terraform apply

- 削除
  $ terraform destroy

##### 開発

- 整形
  $ terraform fmt

- 構文検証
  $ terraform validate
  $ tflint

##### レビュー

- 構築されるリソース内容を確認する
  $ terraform plan

- 構築されるリソースの依存関係を確認する（graphviz 形式）
  $ terraform graph

- 過去の構築時の出力内容を再確認する
  $ terraform output

##### テスト（terratest）

- テストコード(.go) 実行
  1. $ cd [test-folder-path] & go mod init [ 任意のTestSuite名 (※) ]
     - ※ ex: github.com/[org]/[project]
     - go の依存関係管理ファイル(go.mod)を生成する
  2. $ go mod tidy
     - terratest をインストールするため
     - 前提条件などはガイド(↓) 参照
       - https://terratest.gruntwork.io/docs/getting-started/quick-start/
  3. $ go test (-v) -timeout 30m (-parallel [並列数]) (-run '[テストメソッド名(Test~)]')
     - デフォルトでは10分でテストが中断する
       - sam destroy が実行され損ねるのを回避するために、timeout設定はほぼ必須
     - テストステージを管理することでテスト実行を効率化できる
       - `$ SKIP_[ステージ名]=true go test ...`
         - ex: $ SKIP_teardowm_db=true go test ... (DBを使いまわす想定の例)

### Tips

##### 検証環境の簡易作成（ワークスペース）

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

##### module のバージョニング（gitの場合）

moduleはローカルパス指定のほかに、github URL + TAG での指定も可能。
ex: git@github.com:<owner>/<repo>.git//<module_path>?ref=<version_tag>

※ privateリポジトリから取得する場合は認証が必要。
　 ssh設定をしておけばよい（git clone <URL> できるかで設定済みか確認できる）

##### 管理外リソースの取り込み

- terraformと実環境とのの取り込み
  - 管理内のリソースのドリフト(手動変更)を取り込む
    - コマンド：　$ terraform { plan / apply } -refresh-only
      - 実環境→state の反映まで。stateと.tfを整合させるための実装が別途必要
  - 管理外のリソースを取り込む
    - ツール： terraformer / terracognita
    - コマンド：　$ terraform import (aws_instance.web {instance-id})
      - 実環境→state の反映まで。stateと.tfを整合させるための実装が別途必要
    - terraformブロック：　importブロック
      - 実環境→state→.tf の反映ができ、かつ、resource として操作もできる。（↓は例）

```
import {
  to = aws_instance.web
  id = "i-1234567890abcdef0"
}
resource "aws_instance" "web" {
  ami           = "ami-12345"
  instance_type = "t3.medium"  # 実際はt3.smallだとしても更新される
}
```

- コードリファクタリング
  - movedブロックで実環境のリソース影響を回避するケアが必要
    - リソースネームの変更を伴うリファクタをすると、terraformは既存リソースが削除されたと理解して既存リソースの削除（＆リファクタ後のリソースの新規デプロイ）をしてしまう。
    - 例えば以下のケースが使いどころ
      - terraform resource の名前を変更した
      - リソースをモジュールに切出した
      - countによる複製から for_eachによる複製に切り替えた

- terraform vs cloudformation
  - 違い
    - plan等のIaCコードとの比較対象：
      - terraform は実環境と、cloudformation はstateファイㇽと
        - "--refresh=false" を設定すると、terraform でもstateファイルとの比較になる（デプロイに失敗して実環境が壊れ、refresh ができなくなった場合などに使いうる）
    - デプロイ失敗時のロールバック：
      - terraform はロールバックしないが、cloudformationはする（aws謹製なので）
  - plan時の挙動
    - 1. stateファイルの読み取り
    - 2. AWS API を叩いて実際のリソース状態を取得しstateに反映（refresh）　←　※ terraformのみ
    - 3. IaCファイルの定義 と stateファイルを比較

##### security

- stateファイルは構築時に指定された秘密情報も平文で保持する
  - データ保護：暗号化可能なファイルストレージに保存する、など
  - アクセス制御：IAMポリシーによるアクセス管理、など

### special thanks

- 書籍：　詳解 terraform
  - https://www.oreilly.co.jp/books/9784814400522/
  - repo: https://github.com/brikis98/terraform-up-and-running-code
