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
<!-- markdownlint-disable line-length -->

## 概要

ワークフロージョブ実行前に GitHub Actions ランナー環境を検証するゲート型コンポジットアクション。

このアクションは **ゲートアクション** として動作します。最初の検証エラーで即座に失敗し、ワークフロー全体を停止します。部分的な成功やエラー収集モードはありません。

検証項目: OS (Linux)、アーキテクチャ (amd64/arm64)、ランナータイプ (GitHub-hosted)、バージョン要件を持つ必須アプリケーション。

## 前提条件

重要: このアクションは特定のランタイム条件を必要とし、満たされない場合は失敗します。

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

```yaml
name: Example Workflow

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Validate Environment
        id: validate
        uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
        with:
          architecture: "amd64"
          additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0 node|Node.js|regex:v([0-9.]+)|18.0"

      - name: Continue with validated environment
        if: steps.validate.outputs.apps-status == 'success'
        run: |
          echo "Environment validated successfully"
          # Your workflow steps here
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
# 単一アプリケーション
additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0"

# 複数アプリケーション
additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0 node|Node.js|regex:v([0-9.]+)|18.0"

# よく使われるアプリケーション
# - GitHub CLI: "gh|gh|regex:version ([0-9.]+)|2.0"
# - Node.js: "node|Node.js|regex:v([0-9.]+)|18.0"
# - Python: "python|Python||3.8"
# - Docker: "docker|Docker|regex:version ([0-9.]+)|20.0"
```

### 出力

| 出力              | 型     | 説明                                                       |
| ----------------- | ------ | ---------------------------------------------------------- |
| `os-status`       | string | OS 検証ステータス: `success` または `error`                |
| `os-message`      | string | OS 検証メッセージ (OS タイプ、アーキテクチャなど)          |
| `apps-status`     | string | アプリケーション検証ステータス: `success` または `error`   |
| `apps-message`    | string | アプリケーション検証メッセージ                             |
| `validated-apps`  | string | 検証されたアプリ名のカンマ区切りリスト (例: `Git,curl,gh`) |
| `validated-count` | number | 正常に検証されたアプリの数                                 |
| `failed-apps`     | string | 失敗したアプリ名のカンマ区切りリスト (すべて成功時は空)    |
| `failed-count`    | number | 失敗したアプリの数 (すべて成功時は 0)                      |

#### 出力動作 (ゲートアクション)

このアクションは最初のエラーで即座に失敗します。出力の利用可能性:

- OS 検証が失敗: `os-status` と `os-message` のみ設定 (アプリ検証は実行されない)
- アプリ検証が失敗: すべての出力が設定され、`os-status=success`、`apps-status=error`
- 両方成功: すべての出力が成功ステータスを示す

例:

```text
# 成功
os-status: success
os-message: GitHub runner validated: Linux amd64, github-hosted
apps-status: success
apps-message: Applications validated: Git git version 2.45.0, curl curl 7.88.1
validated-apps: Git,curl
validated-count: 2

# 失敗 (非サポート OS)
os-status: error
os-message: Unsupported OS: darwin (Linux required)

# 失敗 (アプリケーションが見つからない)
os-status: success
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

アクションは以下のチェックを順番に実行します:

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

## 制限事項とトラブルシューティング

### このアクションが行わないこと

- ランナーの選択やプロビジョニングを行いません - それには `runs-on` を使用
- アプリケーションのインストールを行いません - それには `actions/setup-node` などを使用
- 以下をサポートしません:
  - Windows ランナー (`windows-latest` など)
  - macOS ランナー (`macos-latest`、`macos-14` など)
  - セルフホストランナー (`RUNNER_ENVIRONMENT=github-hosted` が必須)
  - ローカル実行 (GitHub Actions 環境が必須)

### ARM64 アーキテクチャに関する注記

このアクションのコードは Linux での ARM64 (aarch64) 検証をサポートしています。
ただし、以下の制限があります。

- macOS ARM ランナー (macos-14 M1/M2) は拒否されます (macOS 非サポート)
- Linux ARM64 ランナーは、GitHub が提供すれば動作します
- 2026 年現在、GitHub は Linux ARM64 ホストランナーを提供していません
- GitHub が将来追加した場合、このアクションは `architecture: "arm64"` でコード変更なしに動作します

テスト済み: AMD64 (ubuntu-latest、ubuntu-22.04、ubuntu-20.04)

### よくあるエラーと解決策

#### エラー: "Unsupported operating system"

```text
::error::Unsupported operating system: darwin
::error::This action requires Linux
::error::Please use a Linux runner (e.g., ubuntu-latest)
```

解決策: ワークフローを Linux ランナーを使用するように変更: `runs-on: ubuntu-latest`

#### エラー: "Not running in GitHub Actions environment"

```text
::error::Not running in GitHub Actions environment
::error::This action must run in a GitHub Actions workflow
::error::GITHUB_ACTIONS environment variable is not set to 'true'
```

解決策: このアクションは GitHub Actions ワークフロー内でのみ実行されます。スクリプトをローカルで実行しないでください。

#### エラー: "Git is not installed"

```text
::error::Git is not installed
```

解決策: Git がプリインストールされたランナーを使用してください (すべての GitHub-hosted ランナーには Git が含まれています)。

### ローカル実行

GitHub Actions 外でスクリプトを実行すると、明確なエラーメッセージで失敗します。検証スクリプトをローカルで実行しないでください - これらは GitHub Actions ワークフロー専用に設計されています。

## ライセンス

MIT License

Copyright (c) 2026- aglabo

詳細は [LICENSE](../../../LICENSE) を参照してください。

## サポート

問題や質問がある場合:

- [.github-aglabo リポジトリ](https://github.com/aglabo/.github-aglabo/issues) で Issue を開く
- `.serena/memories/` の既存ドキュメントを確認
- `.github/workflows/` のワークフロー例を確認
