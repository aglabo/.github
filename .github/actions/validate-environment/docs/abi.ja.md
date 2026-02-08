---
title: Validate Environment Action - ABI と契約
description: 内部 ABI 仕様、入力/出力契約、セキュリティモデル
metadata:
  - Version: 1.2.2
  - Created: 2026-02-05
  - Last Updated: 2026-02-05
Changelog:
  - 2026-02-05: README.ja.md から分離、技術仕様を独立ドキュメント化
Copyright:
  - Copyright (c) 2026- aglabo
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

<!-- textlint-disable ja-technical-writing/sentence-length -->
<!-- textlint-disable ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length no-duplicate-heading -->

## ABI と契約

このドキュメントは validate-environment アクションの内部技術仕様を文書化しています。

**対象読者**: 開発者、メンテナー、内部動作を理解する必要がある技術者。

**通常のワークフロー作成者は [README.ja.md](../README.ja.md) を参照してください。**

## 目次

- [内部 ABI 要件](#内部-abi-要件)
- [入力契約](#入力契約)
- [出力契約](#出力契約)
- [セキュリティモデル](#セキュリティモデル)

## 概要

このアクションは複数のシェルスクリプトで構成され、明確に定義された ABI (Application Binary Interface) 契約に基づいて動作します。この契約により、action.yml とスクリプト間のインターフェースが保証されます。

### 契約の種類

1. **内部 ABI 要件**: ランタイム環境の依存関係
2. **入力契約**: ワークフロー入力からスクリプトへの変換ルール
3. **出力契約**: 検証ステータスに応じた出力の利用可能性
4. **セキュリティモデル**: 入力検証とインジェクション防止

## 内部 ABI 要件

このアクションは以下のランタイム依存関係を必要とします (validate-git-runner.sh で強制):

### 1. オペレーティングシステム: Linux

- 検出: `uname -s` が `linux` を返すこと
- 許可: `linux` のみ
- 拒否: Windows、macOS、その他の OS
- 理由: aglabo CI インフラストラクチャは Linux のみをサポート

### 2. シェル: bash

- 要件: bash シェル
- 理由: コンポジットアクション要件 (GitHub Actions の制約)
- 影響: すべてのスクリプトは bash で実行される

### 3. GNU coreutils

必須コマンド:

- `sort -V`: バージョン比較に使用 (validate-apps.sh)
- `grep`: パターンマッチングに使用
- `sed`: バージョン抽出に使用
- `cut`: フィールド分割に使用
- `tr`: 文字変換に使用

**利用可能性**: すべての GitHub-hosted Linux ランナーにプリインストール済み。

### 4. 標準コマンド

- `uname`: システム情報取得
- `command`: コマンド存在チェック
- `type`: コマンドタイプ検出

### 5. GitHub Actions ランタイム変数

必須環境変数:

- `GITHUB_ACTIONS=true`: アクション環境検出
- `RUNNER_ENVIRONMENT=github-hosted`: ホストランナー検証
- `GITHUB_OUTPUT`: 出力メカニズム（スクリプトが key=value 形式で書き込む）
- `RUNNER_TEMP`: 一時ファイル用ディレクトリ
- `GITHUB_PATH`: PATH 変更メカニズム

### 依存関係が満たされない場合

アクションは明確なエラーメッセージで失敗します。

```text
::error::Unsupported operating system: darwin
::error::This action requires Linux
::error::Please use a Linux runner (e.g., ubuntu-latest)
```

## 入力契約

アクションの入力は内部スクリプトに以下の方法で渡されます。

### architecture 入力

#### ワークフロー構文

```yaml
with:
  architecture: "amd64"
```

#### 内部表現

環境変数 `EXPECTED_ARCHITECTURE` として validate-git-runner.sh に渡される。

#### 処理フロー

1. action.yml が `inputs.architecture` を受け取る (デフォルト: `"amd64"`)
2. composite action が環境変数 `EXPECTED_ARCHITECTURE` を設定
3. validate-git-runner.sh が `$EXPECTED_ARCHITECTURE` を読み取り、`uname -m` 出力と比較

#### 実装例

```yaml
# action.yml
inputs:
  architecture:
    default: "amd64"

# composite action の env 設定
env:
  EXPECTED_ARCHITECTURE: ${{ inputs.architecture }}

# validate-git-runner.sh での使用
EXPECTED_ARCH="${EXPECTED_ARCHITECTURE}"  # 環境変数から取得
DETECTED_ARCH=$(uname -m | tr '[:upper:]' '[:lower:]')
# 正規化して比較...
```

#### 参照

- action.yml:128 - 環境変数の設定
- validate-git-runner.sh - アーキテクチャ検証ロジック

### additional-apps 入力

#### ワークフロー構文

```yaml
with:
  additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0 node|Node.js|regex:v([0-9.]+)|18.0"
```

#### 内部表現

位置引数として validate-apps.sh に渡される。

#### 処理フロー

1. action.yml が `inputs.additional-apps` を受け取る (デフォルト: `""`)
2. composite action がスペースで分割し、各定義を位置引数として渡す
3. validate-apps.sh が `"$@"` で引数を受け取り、各定義を解析

#### 実装例

```yaml
# action.yml
inputs:
  additional-apps:
    default: ""

# composite action での呼び出し
run: |
  if [ -n "${{ inputs.additional-apps }}" ]; then
    "${GITHUB_ACTION_PATH}/scripts/validate-apps.sh" ${{ inputs.additional-apps }}
  else
    "${GITHUB_ACTION_PATH}/scripts/validate-apps.sh"
  fi
```

```bash
# validate-apps.sh での処理
for app_def in "$@"; do
  IFS='|' read -r cmd app_name version_extractor min_version <<< "$app_def"
  # 各定義を解析して検証
done
```

#### DSL 形式

- デリミタ: パイプ (`|`) - 正規表現パターンとの競合を回避
- 4 要素必須: `cmd|app_name|version_extractor|min_version`
- 複数アプリ: スペース区切り (各定義が個別の位置引数になる)

#### 安全性制約

コマンド名とパターンには以下の文字を含めることができません。

- `;` (セミコロン): コマンド連鎖
- `|` (パイプ): DSL デリミタとして使用されるため、パターン内では不可
- `&` (アンパサンド): バックグラウンド実行
- `$` (ドル記号): 変数展開
- `` ` `` (バッククォート): コマンド置換
- `\` (バックスラッシュ): エスケープ文字
- `#` (ハッシュ): コメント

これらの文字が含まれている場合、validate-apps.sh は実行前にエラーを返します。

#### バージョン抽出パターン

prefix-typed extractors (安全な sed のみ):

1. `field:N` - N 番目のフィールドを抽出 (スペース区切り)
2. `regex:PATTERN` - sed -E 正規表現でキャプチャグループ `\1` を使用
3. `(空)` - 自動セマンティックバージョン抽出 (X.Y または X.Y.Z パターン)

重要: eval は一切使用されません。すべての抽出は sed のみで実行されます。

#### 参照

- action.yml:140 - 位置引数の渡し方
- validate-apps.sh:145-184 - 入力検証とパースロジック

## 出力契約

アクションの出力は検証ステータスに応じて **条件付きで設定** されます。

### 出力の種類

| 出力              | 型     | 条件                         |
| ----------------- | ------ | ---------------------------- |
| `runner-status`   | string | 常に設定                     |
| `runner-message`  | string | 常に設定                     |
| `apps-status`     | string | runner-status=success のとき |
| `apps-message`    | string | runner-status=success のとき |
| `validated-apps`  | string | apps-status=success のとき   |
| `validated-count` | number | apps-status=success のとき   |
| `failed-apps`     | string | apps-status=error のとき     |
| `failed-count`    | number | apps-status=error のとき     |

### シナリオ 1: OS 検証失敗 (ランナー検証エラー)

OS 検証が失敗した場合、アプリケーション検証は実行されず、ワークフローは即座に停止します。

#### 設定される出力

- `runner-status`: `"error"`
- `runner-message`: エラー詳細 (例: `"Unsupported OS: darwin (Linux required)"`)

#### 設定されない出力 (未定義)

- `apps-status`, `apps-message`
- `validated-apps`, `validated-count`
- `failed-apps`, `failed-count`

#### 例

```yaml
# macOS ランナーで実行した場合
runner-status: error
runner-message: "Unsupported operating system: darwin"
# その他の出力は未定義 (アプリ検証は実行されない)
```

#### ワークフローへの影響

validate-git-runner.sh が `exit 1` で終了するため、ワークフローは即座に失敗します。後続のステップは実行されません。

### シナリオ 2: アプリケーション検証失敗

OS 検証は成功したが、アプリケーション検証が失敗した場合、すべての出力が設定されます。

#### 設定される出力

- `runner-status`: `"success"`
- `runner-message`: OS 情報 (例: `"GitHub runner validated: Linux amd64, github-hosted"`)
- `apps-status`: `"error"`
- `apps-message`: エラー詳細 (例: `"Git not exist"`)
- `failed-apps`: 失敗したアプリのカンマ区切りリスト (例: `"Git"`)
- `failed-count`: 失敗したアプリの数 (例: `1`)

#### 設定されない出力 (未定義)

- `validated-apps` (失敗時は設定されない)
- `validated-count` (失敗時は設定されない)

#### 例

```yaml
# Git が見つからない場合
runner-status: success
runner-message: "GitHub runner validated: Linux amd64, github-hosted"
apps-status: error
apps-message: "Git not exist"
failed-apps: "Git"
failed-count: 1
# validated-apps と validated-count は未定義
```

#### ワークフローへの影響

validate-apps.sh が `exit 1` で終了するため、ワークフローは失敗します。ただし、runner-status は success なので、OS 検証は通過しています。

### シナリオ 3: すべての検証が成功

OS とアプリケーション検証の両方が成功した場合、すべての出力が設定されます。

#### 設定される出力

- `runner-status`: `"success"`
- `runner-message`: OS 情報
- `apps-status`: `"success"`
- `apps-message`: 検証されたアプリの詳細
- `validated-apps`: 検証されたアプリのカンマ区切りリスト (例: `"Git,curl,gh"`)
- `validated-count`: 検証されたアプリの数 (例: `3`)
- `failed-apps`: `""` (空文字列)
- `failed-count`: `0`

#### 例

```yaml
# すべて成功
runner-status: success
runner-message: "GitHub runner validated: Linux amd64, github-hosted"
apps-status: success
apps-message: "Applications validated: Git git version 2.45.0, curl curl 7.88.1, gh gh version 2.60.1"
validated-apps: "Git,curl,gh"
validated-count: 3
failed-apps: ""
failed-count: 0
```

#### ワークフローへの影響

両スクリプトが `exit 0` で終了し、ワークフローは正常に続行されます。

### 出力の使用パターン

#### 推奨パターン

ワークフローで出力を参照する前に、必ず `apps-status` をチェックしてください。

```yaml
- name: Use outputs
  if: steps.validate.outputs.apps-status == 'success'
  run: |
    echo "Validated: ${{ steps.validate.outputs.validated-apps }}"
```

#### 理由

失敗時に `validated-apps` や `validated-count` を参照すると、未定義値エラーの可能性があります。

#### 防御的コーディング

ゲートアクションのため、検証失敗時はワークフロー全体が停止します。上記の `if:` 条件はオプションですが、明示的なチェックとして推奨されます。

### 参照

- action.yml:95-114 - 出力契約の定義
- validate-git-runner.sh - runner-status/runner-message の設定
- validate-apps.sh - apps-status と関連出力の設定

## セキュリティモデル

このアクションは **sed のみ** を使用してバージョン情報を抽出します。`eval` は一切使用されません。

### 設計原則

1. 信頼されたワークフロー作成者モデル: ワークフロー作成者は信頼されていると想定
2. 防御的プログラミング: 誤った設定やタイポミスから保護
3. インジェクション防止: 悪意のあるパターンによるコマンドインジェクションを防止
4. 最小権限: デフォルトでは GITHUB_TOKEN や特別な権限を必要としない

### 脅威モデル

#### 想定する脅威

1. 誤った設定: ワークフロー作成者が誤ったパターンを指定
2. タイポミス: コマンド名やパターンの入力ミス
3. コマンドインジェクション試行: 悪意のあるパターンによるインジェクション（稀）

#### 想定しない脅威

- ワークフロー作成者による意図的な悪用
- GitHub Actions 環境自体への攻撃
- セルフホストランナーへの攻撃（セルフホストランナーは非サポート）

### 入力検証

すべての入力は実行前に検証されます。

#### 拒否される文字

コマンド名とパターンに以下の文字が含まれている場合、エラーを返します。

| 文字    | 理由                 | 攻撃例                    |
| ------- | -------------------- | ------------------------- |
| `;`     | コマンド連鎖         | `git;rm -rf /`            |
| `\|`    | パイプ (DSL 競合)    | パターン内での誤用        |
| `&`     | バックグラウンド実行 | `git & malicious_command` |
| `$`     | 変数展開             | `$MALICIOUS_CMD`          |
| `` ` `` | コマンド置換         | `` `rm -rf /` ``          |
| `\`     | エスケープ文字       | `\; rm -rf /`             |
| `#`     | コメント             | `git # ignore rest`       |

#### 検証例

validate-apps.sh による拒否:

```bash
# ❌ コマンドインジェクション試行
additional_apps: "git;rm -rf /|Git||"
# → エラー: "Invalid command name: git;rm (contains forbidden characters)"

# ❌ 変数展開試行
additional_apps: "$MALICIOUS_CMD|App||"
# → エラー: "Invalid command name: $MALICIOUS_CMD (contains forbidden characters)"

# ✓ 正常なパターン
additional_apps: "git|Git|regex:version ([0-9.]+)|2.0"
# → 安全に処理
```

### sed のみの抽出

バージョン抽出は **sed のみ** で実行されます。シェル評価は行われません。

#### 抽出方法

##### 1. field:N 方式

`--version` 出力をスペースで分割し、N 番目のフィールドを取得:

```bash
# 実装
version_output=$(command "$cmd" --version 2>&1)
extracted_version=$(echo "$version_output" | cut -d' ' -f "$field_num")

# 例: "git version 2.52.0" から "2.52.0" を抽出
# field:3 → "2.52.0"
```

##### 2. regex:PATTERN 方式

sed の正規表現でキャプチャグループ `\1` を使用:

```bash
# 実装
version_output=$(command "$cmd" --version 2>&1)
extracted_version=$(echo "$version_output" | sed -E "s#^.*$pattern.*\$#\\1#")

# 例: "gh version 2.60.1 (2024-01-01)" から "2.60.1" を抽出
# regex:version ([0-9.]+) → "2.60.1"
```

重要: デリミタとして `#` を使用することで、パターン内の `/` と競合を回避。

##### 3. 自動抽出方式 (パターン空)

semver パターン (`X.Y` または `X.Y.Z`) を自動検出:

```bash
# 実装
version_output=$(command "$cmd" --version 2>&1)
extracted_version=$(echo "$version_output" | sed -E 's#^.*([0-9]+\.[0-9]+(\.[0-9]+)?).*$#\1#')

# 例: "Python 3.12.1" から "3.12.1" を自動抽出
```

### 安全性の保証

#### sed の実行モデル

- sed のパターンは直接文字列として渡される (展開なし)
- コマンド置換は実行されない: `$(...)`, `` `...` ``
- 変数展開は実行されない: `$VAR`
- sed の `-E` フラグで拡張正規表現のみ使用 (実行可能コードなし)

#### 実装例

```bash
# validate-apps.sh の実際のコード
version_output=$(command "$cmd" --version 2>&1)
extracted_version=$(echo "$version_output" | sed -E "s#^.*$pattern.*\$#\\1#")

# sed に渡されるコマンド (シェルが解釈しない):
# sed -E 's#^.*version ([0-9.]+).*$#\1#'
# → "gh version 2.60.1 (2024-01-01)" から "2.60.1" を抽出
```

重要: `"$pattern"` はクォートされ、sed の正規表現として解釈されます。コードとして実行されることはありません。

### インジェクション防止の仕組み

#### 多層防御

1. 入力検証: 危険な文字を含む入力を事前に拒否
2. sed の独立実行: sed は独立したプロセスとして実行され、シェルの変数展開・コマンド置換の影響を受けない
3. クォート: すべての変数はクォートされ、意図しない展開を防止
4. prefix-typed extractors: `field:` と `regex:` プレフィックスで抽出方法を明示的に指定

#### 最悪のケース

悪意のあるパターンが入力検証を突破したとしても、以下のようになります。

- sed がパターンマッチに失敗
- バージョン抽出が失敗
- アクションがエラーを返す

**コマンドインジェクションは発生しません。**

### デフォルトのセキュリティプロファイル

#### Git と curl のみ (デフォルト)

- トークン不要: GITHUB_TOKEN や特別な権限は不要
- シークレットアクセス不要: secrets へのアクセスなし
- 安全な使用: 任意のワークフローで使用可能

#### gh CLI 追加時

- GH_TOKEN 必要: `env: GH_TOKEN: ${{ github.token }}` を追加
- 認証チェック: `gh auth status` による認証確認
- 最小権限: GitHub Actions が自動生成する `github.token` で十分（リポジトリスコープのみ）

### 参照

- validate-apps.sh:145-184 - 入力検証ロジック
- validate-apps.sh:248-256 - gh 認証チェック
- action.yml:31-41 - セキュリティモデルのコメント

## まとめ

### ABI 契約の重要性

1. 内部 ABI 要件: ランタイム環境の依存関係を明確化
2. 入力契約: ワークフロー入力とスクリプト引数の変換ルールを保証
3. 出力契約: 検証ステータスに応じた出力の利用可能性を定義
4. セキュリティモデル: sed のみの抽出でインジェクションを防止

### メンテナンス時の注意

#### 破壊的変更の例

- 環境変数名の変更 (`EXPECTED_ARCHITECTURE` → 別名)
- 位置引数の順序変更
- 出力名の変更 (`runner-status` → 別名)
- DSL フォーマットの変更

これらの変更はメジャーバージョンアップが必要です。

#### 非破壊的変更の例

- 新しい検証の追加（後方互換性あり）
- エラーメッセージの改善
- 内部実装の最適化（インターフェース不変）

### 外部参照

- [README.ja.md](../README.ja.md) - 利用者向けドキュメント
- [action.yml](../action.yml) - アクション定義と契約
- [scripts/validate-git-runner.sh](../scripts/validate-git-runner.sh) - OS/runner 検証
- [scripts/validate-apps.sh](../scripts/validate-apps.sh) - アプリケーション検証
