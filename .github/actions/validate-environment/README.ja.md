---
title: Validate Environment Action
description: Validate Environment composite action
metadata
  - Version: 1.2.0
  - Created: 2026-02-03
  - Last Updated: 2026-02-03
Changelog:
  - 2026-02-03: Version unified to 1.2.0 across all components
Copyright
  - Copyright (c) 2026- aglabo
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

<!-- textlint-disable ja-technical-writing/sentence-length -->
<!-- textlint-disable ja-technical-writing/max-comma -->
<!-- textlint-disable ja-technical-writing/no-exclamation-question-mark -->s
<!-- markdownlint-disable line-length -->

## 概要

ワークフロージョブ実行前に GitHub Actions ランナー環境を検証するゲート型コンポジットアクション。

このアクションは **ゲートアクション** として動作します。最初の検証エラーで即座に失敗し、ワークフロー全体を停止します。部分的な成功やエラー収集モードはありません。

検証項目: OS (Linux)、アーキテクチャ (amd64/arm64)、ランナータイプ (GitHub-hosted)、バージョン要件を持つ必須アプリケーション。

## 読者ガイド

- とりあえず使いたい人:
  → [使用方法](#使用方法) の「基本例」を参照してください
- gh CLI を使いたい人:
  → [gh CLI 特殊処理](#gh-cli-特殊処理) を必ず読んでください
- 内部仕様を知りたい人:
  → [docs/abi.ja.md](docs/abi.ja.md) (開発者向け技術仕様) を参照してください

## 前提条件

重要: このアクションは特定のランタイム条件を必要とし、満たされない場合は失敗します。

開発者向けの詳細な技術仕様は [docs/abi.ja.md](docs/abi.ja.md) を参照してください。

### 必須環境

- ランナータイプ: GitHub-hosted ランナーのみ
  - 必須: `RUNNER_ENVIRONMENT=github-hosted` (GitHub により自動設定)
  - セルフホストランナーは非サポート
  - 上書きやシミュレート不可
- オペレーティングシステム: Linux のみ
  - 検証済み: `ubuntu-latest`, `ubuntu-22.04`, `ubuntu-20.04`
  - 非サポート: Windows、macOS、Linux 以外の OS
- アーキテクチャ: AMD64 (x86_64) または ARM64 (aarch64)
  - AMD64 がデフォルトで最も一般的
  - ARM64 サポートは存在するが、GitHub は Linux ARM64 ホストランナーをまだ提供していない
- 実行コンテキスト: GitHub Actions ワークフローのみ
  - ローカル実行は明確なエラーメッセージで失敗
- 依存関係: GNU coreutils (grep、sed、sort) - GitHub-hosted ランナーにプリインストール済み

### デフォルトアプリケーションチェック

- Git: 必須 (見つからない場合は失敗)、バージョン < 2.30 の場合は警告
- curl: 必須 (見つからない場合は失敗)、任意のバージョンを許可

追加のアプリケーションは `additional_apps` 入力で検証できます。

> 注意:
> gh CLI が検証される場合、`gh auth status` による認証チェックが自動的に実行されます。

## ABI と契約

> 対象読者:
> 開発者、メンテナー、内部動作を理解する必要がある技術者

**通常のワークフロー作成者はこのセクションをスキップしてください。**

このアクションは明確に定義された ABI (Application Binary Interface) 契約に基づいて動作します。

### 契約の種類

1. **内部 ABI 要件**: Linux、bash、GNU coreutils などのランタイム依存関係
2. **入力契約**: ワークフロー入力 (`architecture`, `additional-apps`) がスクリプトに渡される方法
3. **出力契約**: 検証ステータスに応じた出力の条件付き設定
4. **セキュリティモデル**: sed のみの抽出、入力検証、インジェクション防止

### 詳細ドキュメント

完全な技術仕様は **[docs/abi.ja.md](docs/abi.ja.md)** を参照してください。

以下のトピックが含まれます。

- 内部 ABI 要件の詳細（OS、シェル、coreutils、環境変数）
- 入力契約の実装例（`architecture` → `EXPECTED_ARCHITECTURE`、`additional-apps` → 位置引数）
- 出力契約の 3 つのシナリオ（OS 失敗、アプリ失敗、すべて成功）
- セキュリティモデルの詳細（脅威モデル、入力検証、sed のみの抽出、インジェクション防止）

### 重要なポイント（概要）

#### 出力の条件付き設定

- OS 検証失敗時: `runner-status`, `runner-message` のみ設定（アプリ検証は実行されない）
- アプリ検証失敗時: すべての出力が設定されるが、`validated-apps`/`validated-count` は未定義
- すべて成功時: すべての出力が設定される

ワークフローで出力を参照する前に、必ず `apps-status` をチェックしてください。

```yaml
- name: Use outputs
  if: steps.validate.outputs.apps-status == 'success'
  run: |
    echo "Validated: ${{ steps.validate.outputs.validated-apps }}"
```

#### セキュリティ

- eval は一切使用されません - すべてのバージョン抽出は sed のみで実行
- 危険な文字 (`;`, `|`, `&`, `$`, `` ` ``, `\`, `#`) を含む入力は拒否
- sed は独立したプロセスとして実行され、コマンドインジェクションは発生しない

## 設計原則

このアクションは aglabo CI インフラストラクチャのために以下の原則を体現しています。

1. **ゲート型検証**
   - 最初のエラーで即座に失敗 (部分的な成功なし)
   - 無効な環境での実行を防ぐためワークフローの実行を停止

2. **GitHub-Hosted ランナー専用**
   - `RUNNER_ENVIRONMENT=github-hosted` が必須
   - 一貫性、安全性、再現性のある CI 環境を保証
   - 上書きやシミュレート不可

3. **Linux 専用設計**
   - GitHub-hosted Linux ランナー (ubuntu-*) のみをサポート
   - 複雑さとメンテナンス負荷を軽減
   - aglabo インフラストラクチャのニーズに最適化

4. **安全なバージョン抽出**
   - sed ベースの抽出のみ (eval 不使用)
   - 入力検証によりコマンドインジェクションを防止
   - シェルメタ文字と制御文字を拒否
   - 詳細: [docs/abi.ja.md - セキュリティモデル](docs/abi.ja.md#セキュリティモデル) を参照

5. **破壊的変更検出**
   - GitHub が `RUNNER_ENVIRONMENT` 仕様を変更した場合は意図的に失敗
   - CI インフラストラクチャの黙示的な動作変更から保護

6. **信頼されたワークフロー作成者モデル**
   - ワークフロー作成者は信頼されていると想定
   - 悪意のある攻撃ではなく、誤った設定の防止に焦点
   - 意図的な悪用ではなく、人的エラーから防御

## 使用方法

### 基本例

```yaml
steps:
  - name: Validate Environment
    uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
```

### 完全なワークフロー例

#### 例 1: 基本検証 (Git と curl のみ)

デフォルトでは Git と curl を検証します。GH_TOKEN は不要です。

```yaml
name: Basic Validation

on: [push]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Validate Environment
        id: validate
        uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
        with:
          architecture: "amd64"

      - name: Continue with validated environment
        run: |
          echo "Environment validated: Git and curl ready"
```

#### 例 2: gh CLI を含む検証

重要: gh CLI を検証する場合、必ず `env: GH_TOKEN` を設定してください。

```yaml
name: Validation with gh CLI

on: [push]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Validate Environment with gh CLI
        id: validate
        uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
        with:
          architecture: "amd64"
          additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0"
        env:
          GH_TOKEN: ${{ github.token }} # ← gh CLI 認証に必須

      - name: Use gh CLI
        if: steps.validate.outputs.apps-status == 'success'
        run: |
          gh --version
          # gh CLI を使用したワークフロー
```

注意: `env: GH_TOKEN` がない場合、`gh auth status` チェックが失敗し、"gh is not authenticated" エラーが発生します。詳細は [gh CLI 特殊処理](#gh-cli-特殊処理) および [トラブルシューティング](#エラー-gh-is-not-authenticated) を参照してください。

#### 例 3: 複数アプリケーションの検証

gh CLI と Node.js を同時に検証する例:

```yaml
name: Multi-App Validation

on: [push]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "18"

      - name: Validate Environment
        id: validate
        uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
        with:
          architecture: "amd64"
          additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0 node|Node.js|regex:v([0-9.]+)|18.0"
        env:
          GH_TOKEN: ${{ github.token }} # ← gh CLI に必須

      - name: Use validated tools
        if: steps.validate.outputs.apps-status == 'success'
        run: |
          echo "Validated apps: ${{ steps.validate.outputs.validated-apps }}"
          gh --version
          node --version
```

## 設定

### 入力

| 入力              | 必須 | デフォルト | 説明                                                                      |
| ----------------- | ---- | ---------- | ------------------------------------------------------------------------- |
| `architecture`    | No   | `amd64`    | ランナーアーキテクチャを検証: `amd64` (x86_64) または `arm64` (aarch64)。 |
|                   |      |            | ランナーを選択しません - それには `runs-on` を使用                        |
| `additional_apps` | No   | `""`       | 検証する追加アプリケーション (DSL 形式、下記参照)                         |

#### architecture 入力

重要: この入力はアーキテクチャを検証します - ランナーを選択またはプロビジョニングしません。ランナーの選択にはワークフローの `runs-on` を使用してください。

- `amd64` = Intel/AMD 64 ビット (x86_64)。`ubuntu-latest`、`ubuntu-22.04` で最も一般的
- `arm64` = ARM 64 ビット (aarch64)。コードはサポートしているが、GitHub はまだ Linux ARM64 ホストランナーを提供していない

例:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest # ← ランナーを選択 (GitHub は AMD64 を提供)
    steps:
      - uses: .github/actions/validate-environment
        with:
          architecture: "amd64" # ← ランナーが AMD64 であることを検証
```

検証が失敗した場合 (例: `arm64` を指定したが `amd64` が提供された)、一致するように `runs-on` または `architecture` 入力を変更してください。

#### additional_apps 入力

アプリケーション定義形式 (DSL):

```text
cmd|app_name|version_extractor|min_version
```

DSL ルール:

- デリミタ: パイプ (`|`) - 正規表現パターンとの競合を回避
- 4 要素すべて必須 - バージョンチェックをスキップする場合は空文字列を使用
- 複数アプリ: スペース区切り (アプリ定義内にスペース不可)
- 安定性: この DSL 形式は将来のバージョンで変更される可能性があります (メジャーバージョンアップで破壊的変更)

バージョン抽出オプション (プレフィックス型、安全な sed のみ):

1. `field:N` - `--version` 出力から N 番目のフィールドを抽出 (スペース区切り)
   - 例: `field:3` は "git version 2.52.0" から "2.52.0" を抽出
2. `regex:PATTERN` - sed -E 正規表現でキャプチャグループ `\1` を使用
   - 例: `regex:version ([0-9.]+)` はバージョン番号を抽出
   - 例: `regex:v([0-9.]+)` は Node.js の "v18.0.0" 形式用
3. `(空)` - 自動セマンティックバージョン抽出 (X.Y または X.Y.Z パターン)

例:

```yaml
# 単一アプリケーション (gh CLI)
additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0"

# 複数アプリケーション (gh CLI + Node.js)
additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0 node|Node.js|regex:v([0-9.]+)|18.0"

# よく使われるアプリケーション
# - GitHub CLI: "gh|gh|regex:version ([0-9.]+)|2.0" (認証チェック含む)
# - Node.js: "node|Node.js|regex:v([0-9.]+)|18.0"
# - Python: "python|Python||3.8"
# - Docker: "docker|Docker|regex:version ([0-9.]+)|20.0"
```

> **gh CLI を使用する場合の重要な注意事項**: gh CLI を `additional_apps` で指定する場合、ワークフローステップに `env: GH_TOKEN: ${{ github.token }}` を追加してください。これがないと、gh の認証チェック (`gh auth status`) が失敗します。詳細は [gh CLI 特殊処理](#gh-cli-特殊処理) を参照してください。

#### gh CLI 特殊処理

gh CLI (GitHub CLI) は他のアプリケーションと異なり、**認証チェック**が自動的に実行されます。

##### 認証メカニズム

gh CLI が `additional_apps` で指定されている場合、validate-apps.sh は以下のチェックを実行します。

1. **存在チェック**: `command -v gh` で gh CLI が存在するか確認
2. **バージョンチェック**: `gh --version` で最小バージョン要件を確認
3. **認証チェック**: `gh auth status` で認証状態を確認

**認証チェックの実装** (validate-apps.sh:248-256):

```bash
check_gh_authentication() {
  # Check authentication status using gh auth status
  # Exit code 0 = authenticated, 1 = not authenticated or auth issues
  gh auth status >/dev/null 2>&1
  return $?
}
```

このチェックは gh CLI に対してのみ実行されます。他のアプリケーション (node、python など) には認証チェックはありません。

##### GH_TOKEN 要件

GitHub Actions では、`gh auth status` が成功するために **GH_TOKEN 環境変数** が必要です。

**理由**:

- GitHub Actions ランナーには gh CLI がプリインストールされています
- しかし、デフォルトでは認証情報が設定されていません
- `gh` コマンドは `GH_TOKEN` 環境変数から認証トークンを読み取ります
- GitHub Actions は自動的に `github.token` コンテキストを提供しますが、明示的に渡す必要があります

**必須の設定**:

```yaml
- name: Validate with gh CLI
  uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
  with:
    additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0"
  env:
    GH_TOKEN: ${{ github.token }} # ← これがないと認証チェックが失敗
```

重要: `env:` セクションはステップレベルで指定してください。ジョブレベルでも指定できますが、セキュリティのベストプラクティスとして、トークンを必要とするステップのみに制限することを推奨します。

##### 認証シナリオ

gh CLI 検証には 3 つのシナリオがあります:

**シナリオ 1: GH_TOKEN あり (正常)**

```yaml
- name: Validate with gh CLI
  uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
  with:
    additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0"
  env:
    GH_TOKEN: ${{ github.token }}
```

**結果**:

- `gh auth status` が成功 (exit code 0)
- 検証成功: `apps-status: success`
- gh CLI を使用したワークフローステップが正常に動作

**シナリオ 2: GH_TOKEN なし (エラー)**

```yaml
- name: Validate with gh CLI (誤った設定)
  uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
  with:
    additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0"
  # env: GH_TOKEN が指定されていない
```

**結果**:

- `gh auth status` が失敗 (exit code 1)
- エラー: `"gh is not authenticated. Run 'gh auth login' or set GH_TOKEN"`
- 検証失敗: `apps-status: error`
- ワークフローが停止

**エラーメッセージ例**:

```text
::error::gh is not authenticated. Run 'gh auth login' or set GH_TOKEN
::error::To resolve: Add 'env: GH_TOKEN: ${{ github.token }}' to your workflow step
```

**シナリオ 3: gh CLI を使用しない (影響なし)**

```yaml
- name: Validate without gh CLI
  uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
  # additional_apps を指定しない、または gh を含まない
```

**結果**:

- 認証チェックは実行されない (gh CLI が指定されていないため)
- GH_TOKEN は不要
- デフォルトの Git と curl のみ検証

##### トラブルシューティング

**"gh is not authenticated" エラーが発生した場合**:

最も一般的な原因は `env: GH_TOKEN` の設定忘れです。

**クイック解決策**:

```yaml
- uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
  with:
    additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0"
  env:
    GH_TOKEN: ${{ github.token }} # ← これを追加
```

詳細なトラブルシューティング手順、よくある誤り、デバッグ方法は **[docs/troubleshooting.ja.md - gh CLI 関連のトラブルシューティング](docs/troubleshooting.ja.md#gh-cli-関連のトラブルシューティング)** を参照してください。

##### セキュリティに関する注意事項

**GH_TOKEN のスコープ**:

- `github.token` は GitHub Actions が自動生成するトークン
- リポジトリのコンテンツへの読み取り/書き込みアクセスのみ
- ユーザーアカウント全体へのアクセスはなし
- ワークフロー実行後に自動的に無効化

**ベストプラクティス**:

1. **最小権限の原則**: gh CLI を使用するステップのみに GH_TOKEN を渡す
2. **ログに出力しない**: トークンはログに記録されません (GitHub が自動的にマスク)
3. **カスタムトークンの使用**: より強い権限が必要な場合は、`secrets.MY_CUSTOM_TOKEN` を使用

例 (最小権限):

```yaml
steps:
  # このステップには GH_TOKEN 不要
  - name: Validate basic environment
    uses: aglabo/.github-aglabo/.github/actions/validate-environment@main

  # このステップのみ GH_TOKEN を使用
  - name: Validate with gh CLI
    uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
    with:
      additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0"
    env:
      GH_TOKEN: ${{ github.token }} # ← このステップのみスコープを持つ
```

詳細は [docs/troubleshooting.ja.md - gh CLI 関連のトラブルシューティング](docs/troubleshooting.ja.md#gh-cli-関連のトラブルシューティング) を参照してください。

### 出力

| 出力              | 型     | 説明                                                       |
| ----------------- | ------ | ---------------------------------------------------------- |
| `runner-status`   | string | OS 検証ステータス: `success` または `error`                |
| `runner-message`  | string | OS 検証メッセージ (OS タイプ、アーキテクチャなど)          |
| `apps-status`     | string | アプリケーション検証ステータス: `success` または `error`   |
| `apps-message`    | string | アプリケーション検証メッセージ                             |
| `validated-apps`  | string | 検証されたアプリ名のカンマ区切りリスト (例: `Git,curl,gh`) |
| `validated-count` | number | 正常に検証されたアプリの数                                 |
| `failed-apps`     | string | 失敗したアプリ名のカンマ区切りリスト (すべて成功時は空)    |
| `failed-count`    | number | 失敗したアプリの数 (すべて成功時は 0)                      |

#### 出力動作 (ゲートアクション)

このアクションは最初のエラーで即座に失敗します。出力の利用可能性は検証ステータスによって条件付きで設定されます。

詳細な契約仕様は [docs/abi.ja.md - 出力契約](docs/abi.ja.md#出力契約) を参照してください。

**概要**:

- OS 検証が失敗: `runner-status` と `runner-message` のみ設定 (アプリ検証は実行されない)
- アプリ検証が失敗: すべての出力が設定され、`runner-status=success`、`apps-status=error`
- 両方成功: すべての出力が成功ステータスを示す

例:

```text
# 成功
runner-status: success
runner-message: GitHub runner validated: Linux amd64, github-hosted
apps-status: success
apps-message: Applications validated: Git git version 2.45.0, curl curl 7.88.1
validated-apps: Git,curl
validated-count: 2

# 失敗 (非サポート OS)
runner-status: error
runner-message: Unsupported OS: darwin (Linux required)

# 失敗 (アプリケーションが見つからない)
runner-status: success
apps-status: error
apps-message: Git not exist
failed-count: 1
```

推奨される使用方法:

```yaml
- if: steps.validate.outputs.apps-status == 'success'
  run: echo "All validations passed"
```

注記: これはゲートアクションです - 検証が失敗するとワークフローは自動的に停止します。上記の例の `if:` 条件はオプションであり、防御的コーディングとして機能します。ほとんどのワークフローでは、アクションがエラー時にワークフロー全体を失敗させるため、明示的な `if:` 条件は不要です。

## 検証詳細

アクションは以下のチェックを順番に実行します。

入力がどのように内部スクリプトに渡されるかの詳細は [docs/abi.ja.md - 入力契約](docs/abi.ja.md#入力契約) を参照してください。

### 1. オペレーティングシステム

- `uname -s` を使用して OS を検出
- 許可: `linux`
- 拒否: `darwin` (macOS)、`windows`、`msys`、`cygwin` など

### 2. アーキテクチャ

- `uname -m` を使用してアーキテクチャを検出
- 許可: `x86_64`、`amd64`、`x64` → `amd64` として正規化
- 許可: `aarch64`、`arm64` → `arm64` として正規化

### 3. GitHub Actions 環境

重要チェック:

1. `GITHUB_ACTIONS=true` が設定されている必要があります
2. `RUNNER_ENVIRONMENT=github-hosted` が設定されている必要があります (設計原則を参照)
3. ランタイム変数が必要です: `RUNNER_TEMP`、`GITHUB_OUTPUT`、`GITHUB_PATH`

### 4. アプリケーション

- デフォルト: `git` (バージョン < 2.30 の場合は警告)、`curl` (任意のバージョン)
- 追加: `additional_apps` 入力で指定されたアプリケーション

## 制限事項

### このアクションが行わないこと

- ランナーの選択やプロビジョニング - それには `runs-on` を使用
- アプリケーションのインストール - それには `actions/setup-node` などを使用

### サポートしていない環境

- Windows ランナー (`windows-latest` など)
- macOS ランナー (`macos-latest`、`macos-14` など)
- セルフホストランナー（`RUNNER_ENVIRONMENT=github-hosted` が必須）
- ローカル実行（GitHub Actions 環境が必須）

### よくあるエラー

| エラー                         | 解決策                          |
| ------------------------------ | ------------------------------- |
| "Unsupported operating system" | `runs-on: ubuntu-latest` に変更 |
| "Git is not installed"         | GitHub-hosted ランナーを使用    |
| "gh is not authenticated"      | `env: GH_TOKEN` を追加          |

### 詳細なトラブルシューティング

- 制限事項の詳細 → [docs/troubleshooting.ja.md - 制限事項](docs/troubleshooting.ja.md#制限事項)
- エラーの詳細と解決策 → [docs/troubleshooting.ja.md - よくあるエラーと解決策](docs/troubleshooting.ja.md#よくあるエラーと解決策)
- gh CLI エラー → [docs/troubleshooting.ja.md - gh CLI 関連のトラブルシューティング](docs/troubleshooting.ja.md#gh-cli-関連のトラブルシューティング)
- ローカル実行 → [docs/troubleshooting.ja.md - ローカル実行](docs/troubleshooting.ja.md#ローカル実行)

## ライセンス

MIT License

Copyright (c) 2026- aglabo

詳細は [LICENSE](../../../LICENSE) を参照してください。

## サポート

問題や質問がある場合:

- [.github-aglabo リポジトリ](https://github.com/aglabo/.github-aglabo/issues) で Issue を開く
- `.github/workflows/` のワークフロー例を確認
