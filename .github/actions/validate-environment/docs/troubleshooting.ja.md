---
title: Validate Environment Action - トラブルシューティング
description: よくあるエラーと解決策、制限事項
metadata:
  - Version: 1.2.2
  - Created: 2026-02-05
  - Last Updated: 2026-02-05
Changelog:
  - 2026-02-05: README.ja.md から分離、トラブルシューティング情報を統合
Copyright:
  - Copyright (c) 2026- aglabo
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

<!-- textlint-disable ja-technical-writing/sentence-length -->
<!-- textlint-disable ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length no-duplicate-heading -->

## トラブルシューティング

このドキュメントは validate-environment アクションの制限事項、よくあるエラー、解決策を提供します。

**通常の使用方法は [README.ja.md](../README.ja.md) を参照してください。**

## 目次

- [制限事項](#制限事項)
- [よくあるエラーと解決策](#よくあるエラーと解決策)
- [gh CLI 関連のトラブルシューティング](#gh-cli-関連のトラブルシューティング)
- [ローカル実行](#ローカル実行)

## 制限事項

### このアクションが行わないこと

validate-environment アクションは検証のみを行います。以下のことは行いません。

#### ランナーの選択やプロビジョニング

- ✗ ランナーの選択やプロビジョニングを行いません
- ✓ **代わりに使用**: ワークフローの `runs-on` で指定

```yaml
jobs:
  build:
    runs-on: ubuntu-latest # ← ここでランナーを選択
    steps:
      - uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
        with:
          architecture: "amd64" # ← 検証のみ（選択ではない）
```

#### アプリケーションのインストール

- ✗ アプリケーションのインストールを行いません
- ✓ **代わりに使用**: 専用のセットアップアクション

```yaml
steps:
  # アプリケーションをインストール
  - uses: actions/setup-node@v4
    with:
      node-version: "18"

  # その後、検証
  - uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
    with:
      additional_apps: "node|Node.js|regex:v([0-9.]+)|18.0"
```

### サポートしていない環境

このアクションは以下の環境をサポートしていません。

#### Windows ランナー

```yaml
# ✗ サポートされません
runs-on: windows-latest

# ✓ 使用してください
runs-on: ubuntu-latest
```

**エラー例**:

```text
::error::Unsupported operating system: windows
::error::This action requires Linux
```

#### macOS ランナー

```yaml
# ✗ サポートされません
runs-on: macos-latest
runs-on: macos-14 # M1/M2 も非サポート

# ✓ 使用してください
runs-on: ubuntu-latest
```

**エラー例**:

```text
::error::Unsupported operating system: darwin
::error::This action requires Linux
```

#### セルフホストランナー

- 必須: `RUNNER_ENVIRONMENT=github-hosted`（GitHub により自動設定）
- セルフホストランナーは非サポート
- 上書きやシミュレート不可

**理由**: aglabo CI インフラストラクチャは GitHub-hosted ランナーのみをサポート（一貫性、安全性、再現性を保証）

#### ローカル実行

- GitHub Actions 環境が必須
- ローカルでのスクリプト実行は非サポート

詳細は [ローカル実行](#ローカル実行) を参照してください。

### ARM64 アーキテクチャに関する注記

このアクションのコードは Linux での ARM64 (aarch64) 検証をサポートしています。

#### 現在の状況（2026 年）

- ✓ コード: ARM64 検証をサポート済み
- ✗ macOS ARM ランナー (macos-14 M1/M2): 拒否されます（macOS 非サポート）
- ✗ Linux ARM64 ランナー: GitHub が提供していない

#### 将来の対応

- GitHub が Linux ARM64 ホストランナーを提供すれば動作します
- `architecture: "arm64"` でコード変更なしに動作します

#### テスト済み環境

- ✓ AMD64 (x86_64): ubuntu-latest、ubuntu-22.04、ubuntu-20.04

## よくあるエラーと解決策

### エラー: "Unsupported operating system"

#### エラーメッセージ

```text
::error::Unsupported operating system: darwin
::error::This action requires Linux
::error::Please use a Linux runner (e.g., ubuntu-latest)
```

#### 原因

- Windows または macOS ランナーで実行している
- このアクションは Linux のみをサポート

#### 解決策

ワークフローを Linux ランナーを使用するように変更:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest # ← Linux ランナーに変更
    steps:
      - uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
```

#### 推奨ランナー

- `ubuntu-latest` (推奨、常に最新の LTS)
- `ubuntu-22.04` (特定バージョンが必要な場合)
- `ubuntu-20.04` (レガシーサポート)

### エラー: "Not running in GitHub Actions environment"

#### エラーメッセージ

```text
::error::Not running in GitHub Actions environment
::error::This action must run in a GitHub Actions workflow
::error::GITHUB_ACTIONS environment variable is not set to 'true'
```

#### 原因

- GitHub Actions 環境外でスクリプトを実行している
- 必須環境変数 `GITHUB_ACTIONS=true` が設定されていない

#### 解決策

このアクションは GitHub Actions ワークフロー内でのみ実行されます。

**✗ 実行しないでください**。

```bash
# ローカル環境で直接実行
./validate-git-runner.sh  # エラーが発生
```

**✓ 実行してください**。

```yaml
# GitHub Actions ワークフロー内で実行
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
```

詳細は [ローカル実行](#ローカル実行) を参照してください。

### エラー: "Git is not installed"

#### エラーメッセージ

```text
::error::Git is not installed
```

#### 原因

- Git がインストールされていないランナーを使用している（まれ）
- カスタム Docker コンテナで実行している可能性

#### 解決策

Git がプリインストールされたランナーを使用してください。

**通常の場合**: すべての GitHub-hosted ランナーには Git がプリインストールされています。

```yaml
runs-on: ubuntu-latest # Git プリインストール済み
```

**カスタムコンテナの場合**: Git をインストール。

```yaml
jobs:
  validate:
    runs-on: ubuntu-latest
    container: custom-image:latest
    steps:
      # Git をインストール（カスタムコンテナの場合）
      - run: apt-get update && apt-get install -y git

      # その後、検証
      - uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
```

## gh CLI 関連のトラブルシューティング

### エラー: "gh is not authenticated"

gh CLI を `additional_apps` で検証する際に**最も一般的なエラー**です。

#### エラーメッセージ

```text
::error::gh is not authenticated. Run 'gh auth login' or set GH_TOKEN
::error::To resolve: Add 'env: GH_TOKEN: ${{ github.token }}' to your workflow step
```

#### 原因

1. **ワークフローステップに `env: GH_TOKEN` が設定されていない**（最も一般的）
2. gh CLI は認証情報なしで `gh auth status` が失敗する
3. GitHub Actions ランナーには gh CLI がプリインストールされているが、デフォルトでは認証されていない
4. `github.token` コンテキストが利用できない（まれなケース）

#### なぜ GH_TOKEN が必要か

- GitHub Actions ランナーには gh CLI がプリインストールされています
- しかし、**デフォルトでは認証情報が設定されていません**
- gh CLI は `GH_TOKEN` 環境変数から認証トークンを読み取ります
- GitHub Actions は `github.token` を提供しますが、**明示的に渡す必要があります**

### 解決策

#### 解決策 1: ステップに env: GH_TOKEN を追加（推奨）

**最も簡単で推奨される方法**:

```yaml
- name: Validate with gh CLI
  uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
  with:
    additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0"
  env:
    GH_TOKEN: ${{ github.token }} # ← これを追加
```

#### 解決策 2: ジョブレベルで env を設定

**複数のステップで gh CLI を使用する場合**:

```yaml
jobs:
  validate:
    runs-on: ubuntu-latest
    env:
      GH_TOKEN: ${{ github.token }} # ← ジョブ全体に適用
    steps:
      - name: Validate with gh CLI
        uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
        with:
          additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0"

      # 他のステップでも GH_TOKEN が利用可能
      - name: Use gh CLI
        run: gh repo view
```

#### 解決策 3: GITHUB_TOKEN シークレットを使用（代替）

`github.token` の代わりに `secrets.GITHUB_TOKEN` を使用:

```yaml
- name: Validate with gh CLI
  uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
  with:
    additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0"
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }} # github.token と同等
```

注意: `github.token` と `secrets.GITHUB_TOKEN` は同じトークンです。

### よくある誤り

#### ❌ 誤り 1: トークンを渡さない

```yaml
- uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
  with:
    additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0"
  # env: GH_TOKEN がない → エラー
```

**結果**: `gh is not authenticated` エラーが発生。

#### ❌ 誤り 2: env を with のなかに書く

```yaml
- uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
  with:
    additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0"
    env: GH_TOKEN: ${{ github.token }} # ← YAML 構文エラー
```

**結果**: YAML パースエラーが発生。

#### ❌ 誤り 3: 間違ったトークン変数名

```yaml
- uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
  with:
    additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0"
  env:
    GITHUB_TOKEN: ${{ github.token }} # ← GH_TOKEN ではない
```

**結果**: gh CLI は `GITHUB_TOKEN` ではなく `GH_TOKEN` を読み取るため、認証失敗。

#### ❌ 誤り 4: インデントが間違っている

```yaml
- uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
  with:
    additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0"
    env:
      GH_TOKEN: ${{ github.token }} # ← env が with の子要素になっている
```

**結果**: YAML パースエラーまたは env が無視される。

#### ✓ 正しい: ステップレベルで env を指定

```yaml
- uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
  with:
    additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0"
  env:
    GH_TOKEN: ${{ github.token }} # ← with: と同じインデントレベル
```

ポイント: `env:` は `with:` と同じレベル（ステップの直下）に配置。

### 関連セクション

- [README.ja.md - gh CLI 特殊処理](../README.ja.md#gh-cli-特殊処理) - 認証メカニズムの詳細
- [README.ja.md - 使用方法 > 例 2](../README.ja.md#例-2-gh-cli-を含む検証) - 正しい設定例
- [README.ja.md - 設定 > additional_apps 入力](../README.ja.md#additional_apps-入力) - DSL 形式の説明

## ローカル実行

### 制限

GitHub Actions 外でスクリプトを実行すると、明確なエラーメッセージで失敗します。

重要: 検証スクリプトをローカルで実行しないでください - これらは GitHub Actions ワークフロー専用に設計されています。

### エラー例

```bash
# ローカルで実行を試みる
./validate-git-runner.sh

# エラーメッセージ
::error::Not running in GitHub Actions environment
::error::This action must run in a GitHub Actions workflow
::error::GITHUB_ACTIONS environment variable is not set to 'true'
```

### 理由

このアクションは以下の GitHub Actions 固有の機能に依存しています。

1. **環境変数**:
   - `GITHUB_ACTIONS=true`
   - `RUNNER_ENVIRONMENT=github-hosted`
   - `GITHUB_OUTPUT`
   - `RUNNER_TEMP`

2. **出力メカニズム**:
   - `$GITHUB_OUTPUT` への key=value 書き込み
   - GitHub Actions による出力の自動取得

3. **ランナー環境**:
   - GitHub-hosted ランナーの保証された環境
   - プリインストールされたツール (Git, curl, gh, GNU coreutils)

これらはローカル環境では利用できません。

## まとめ

### よくあるエラーのクイックリファレンス

| エラー                        | 原因                   | 解決策                          |
| ----------------------------- | ---------------------- | ------------------------------- |
| Unsupported operating system  | Windows/macOS ランナー | `runs-on: ubuntu-latest` に変更 |
| Not running in GitHub Actions | ローカル実行           | ワークフロー内で実行            |
| Git is not installed          | Git がない（まれ）     | GitHub-hosted ランナーを使用    |
| gh is not authenticated       | GH_TOKEN がない        | `env: GH_TOKEN` を追加          |

### サポート

問題が解決しない場合:

- [.github-aglabo リポジトリ](https://github.com/aglabo/.github-aglabo/issues) で Issue を開く
- [README.ja.md](../README.ja.md) の使用例を確認
- [docs/abi.ja.md](abi.ja.md) の技術仕様を確認
