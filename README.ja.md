---
header:
  - src: README.ja.md
  - @(#): .github Shared Development Infrastructure
title: .github - 共有開発インフラ
description: OSS品質を自動化で保証する共通開発基盤 - Configuration as Truth
version: 1.0.0
created: 2025-11-08
authors:
  - atsushifx
changes:
  - 2025-11-08: 初版作成
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

<!-- textlint-disable ja-technical-writing/ja-no-mixed-period -->

[English](README.md) | 日本語

<!-- textlint-enable -->

## 🛠 `.github` 共有開発インフラ

## 自動化によるOSS品質保証 - ドキュメントではなく、設定で品質を強制する開発基盤

このリポジトリは、OSS プロジェクトで実際に運用されている共通の開発インフラです。
Issue・PR テンプレート、自動フォーマット、Lint、セキュリティスキャン、Git Hooks など、
品質を手動チェックではなく自動化で保証する仕組みを提供します。

## 📖 このリポジトリの目的

### 解決する課題

- コードスタイルの不統一
- コミットメッセージの品質ばらつき
- セキュリティリスク(秘密情報の誤コミット)
- レビュー負荷の増大
- ドキュメント整備の手間

### アプローチ

1. **Configuration as Truth** - ルールは設定ファイルに記述、ドキュメント不要
2. **Automate Everything** - フォーマッタ・Linter・Hooks で問題を事前防止
3. **AI-Powered Workflow** - コミットメッセージ・ドキュメントは AI 生成
4. **Zero Manual Checks** - ローカル Hooks と CI/CD の二段構え

## 🏗 リポジトリ構成

### コア機能

| カテゴリ         | 機能                         | 提供するもの                         |
| ---------------- | ---------------------------- | ------------------------------------ |
| **テンプレート** | Issue/PR                     | バグ報告・機能提案・PRチェックリスト |
| **フォーマット** | dprint                       | Markdown/JSON/YAML/TOML自動整形      |
| **Lint**         | markdownlint/textlint/cspell | 文書品質チェック・スペルチェック     |
| **セキュリティ** | gitleaks/secretlint          | 秘密情報検出・コミットブロック       |
| **Git Hooks**    | lefthook                     | コミット前自動チェック               |
| **Commit**       | commitlint                   | Conventional Commits強制             |
| **CI/CD**        | GitHub Actions               | 秘密スキャン・CodeQL                 |

### 設定ファイル一覧

| カテゴリ         | ツール             | 設定ファイル                                |
| ---------------- | ------------------ | ------------------------------------------- |
| **フォーマット** | dprint             | `dprint.jsonc`                              |
|                  | EditorConfig       | `.editorconfig`                             |
| **Lint**         | markdownlint       | `configs/.markdownlint.yaml`                |
|                  | textlint           | `configs/textlintrc.yaml`                   |
|                  | cspell             | `.vscode/cspell.json`                       |
| **Git Hooks**    | lefthook           | `lefthook.yml`                              |
| **Commit**       | commitlint         | `configs/commitlint.config.js`              |
|                  | prepare-commit-msg | `scripts/prepare-commit-msg.sh`             |
| **セキュリティ** | gitleaks           | `configs/gitleaks.toml`                     |
|                  | secretlint         | `configs/secretlint.config.yaml`            |
| **CI/CD**        | Secret scan        | `.github/workflows/ci-secrets-scan.yml`     |
|                  | CodeQL             | `.github/workflows/codeql-actions-only.yml` |

## 🚀 使い方

### 1. セットアップ

```bash
# このリポジトリをプロジェクトの.github/に配置
git clone https://github.com/atsushifx/.github.git

# Git Hooksをインストール
lefthook install

# フォーマット設定を確認
dprint fmt
```

### 2. 日常的な使い方

```bash
# コードを書く → dprintが自動フォーマット
# (保存時に.editorconfig適用)

# コミット → Hooksが自動チェック
git commit
# - gitleaksが秘密情報検出
# - markdownlint/textlintが文書チェック
# - commitlintがメッセージ検証
# - AI生成メッセージが準備される

# プッシュ → CIが最終チェック
git push
```

### 3. テンプレート利用

- Issue 作成: リポジトリの Issues タブで自動的にテンプレート選択可能
  - バグ報告 (`bug_report.yml`)
  - 機能提案 (`feature_request.yml`)
  - 自由トピック (`open_topic.yml`)
  - リリース (`release.yml`)

- PR 作成: PR を開くとチェックリスト付きテンプレート自動適用

## 📋 重要な使用ルール

### 禁止事項

- `--no-verify`で Hooks をバイパスしない
- 秘密情報をコミットしない (gitleaks がブロック)
- 手動でコードフォーマットしない (dprint に任せる)
- Conventional Commits 形式を守る

### Commit Types

**標準タイプ:**

- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメント
- `chore`: 雑務・メンテナンス
- `test`: テスト
- `refactor`: リファクタリング
- `perf`: パフォーマンス改善
- `ci`: CI/CD 変更

**カスタムタイプ:**

- `config`: 設定変更
- `release`: リリース
- `merge`: マージ
- `build`: ビルドシステム
- `style`: スタイル変更
- `deps`: 依存関係更新

## 📚 詳細情報

技術的な詳細や AI 開発ガイドは [`CLAUDE.md`](./CLAUDE.md) を参照してください。

### コミュニティガイドライン

- [行動規範 (Code of Conduct)](.github/CODE_of_CONDUCT.ja.md) - コミュニティでの行動規範
- [セキュリティポリシー (Security Policy)](.github/SECURITY.md) - 脆弱性報告の手順

## 📄 ライセンス

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).

Copyright (c) 2025- aglabo

## 🙏 Thanks

本リポジトリは、下記の AI エージェントのサポートのもと作成・整備されました。

- 🤖 Elpha（エルファ）
- 🤖 Kobeni（小紅）
- 🤖 Tsumugi（つむぎ）
