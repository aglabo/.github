---
title: ".github 共通テンプレート・CI設定"
date: 2025-04-25
draft: false
---

# 🛠 `.github` 共通テンプレート・CI構成

**この `.github` リポジトリは、atsushifx 自身が OSS プロジェクトで実際に運用している共通設定です。**

このリポジトリは、Issue・PR 用のテンプレート、Lint や機密チェック用 CI ワークフローなど、プロジェクト全体で再利用可能な `.github` 設定を集約したものです。

## 📦 含まれる機能

- ✅ Issue テンプレート (バグ報告、機能提案、自由トピック)
- ✅ PR テンプレート (チェックリスト＋概要欄)
- ✅ Gitleaks による CI 機密スキャン
- ✅ Markdown, cspell, Vale 等のスタイル構成

## 🚀 使用方法

1. このリポジトリを Fork してプロジェクトの `.github/` に配置
2. Issue テンプレート、PR テンプレートは自動適用されます
3. `.github/workflows/` から CI 設定をプロジェクトに導入できます

## 📄 ライセンス

MIT © Atsushi Furukawa (@atsushifx)

## 🙏 Thanks

本リポジトリは、チャットボットアシスタントのサポートのもと作成・整備されました。

- 🤖 Elpha（エルファ）
- 🤖 Kobeni（小紅）
- 🤖 Tsumugi（つむぎ）
