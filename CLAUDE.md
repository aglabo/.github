# CLAUDE.md

## プロジェクト

共有開発インフラ - 自動化による OSS 品質保証:

This repository provides shared development infrastructure for OSS projects.
It enforces consistency through automation rather than documentation.

## 技術スタック

<!-- textlint-disable ja-technical-writing/max-comma -->

lefthook, dprint, gitleaks, secretlint,commitlint, markdownlint-cli2, textlint, cspell

<!-- textlint-enable -->

## コア原則

1. **Configuration as Truth** - All rules live in config files, not documentation
2. **Automate Everything** - Linters, formatters, and hooks prevent issues before commit
3. **AI-Powered Workflow** - Commit messages and documentation are AI-generated
4. **Zero Manual Checks** - CI/CD catches what local hooks miss

## 禁止事項

- Never bypass pre-commit hooks (--no-verify)
- Never commit secrets (gitleaks will block)
- Never manually format code (dprint handles it)
- Always follow Conventional Commits format

## 重要コマンド

```bash
lefthook install        # Install git hooks
dprint fmt              # Format all code
git commit              # Commit with AI-generated message
```

## Commit Types

### Standard

- `feat`: New features
- `fix`: Bug fixes
- `chore`: Maintenance tasks
- `docs`: Documentation
- `test`: Tests
- `refactor`: Code restructuring
- `perf`: Performance improvements
- `ci`: CI/CD changes

### Custom

- `config`: Configuration changes
- `release`: Release commits
- `merge`: Merge commits
- `build`: Build system changes
- `style`: Code style changes
- `deps`: Dependency updates

## 設定ファイル

| Category       | Tool               | Config File                                 |
| -------------- | ------------------ | ------------------------------------------- |
| **Formatting** | dprint             | `dprint.jsonc`                              |
|                | EditorConfig       | `.editorconfig`                             |
| **Linting**    | markdownlint       | `configs/.markdownlint.yaml`                |
|                | textlint           | `configs/textlintrc.yaml`                   |
|                | cspell             | `.vscode/cspell.json`                       |
| **Git Hooks**  | lefthook           | `lefthook.yml`                              |
| **Commit**     | commitlint         | `configs/commitlint.config.js`              |
|                | prepare-commit-msg | `scripts/prepare-commit-msg.sh`             |
| **Security**   | gitleaks           | `configs/gitleaks.toml`                     |
|                | secretlint         | `configs/secretlint.config.yaml`            |
| **CI/CD**      | Secret scan        | `.github/workflows/ci-secrets-scan.yml`     |
|                | CodeQL             | `.github/workflows/codeql-actions-only.yml` |

## リポジトリ情報

- **Organization**: aglabo
- **License**: MIT License
- **Copyright**: (c) 2025- aglabo

## コミュニティガイドライン

- [行動規範 (Code of Conduct)](.github/CODE_of_CONDUCT.md) - Community code of conduct
- [セキュリティポリシー (Security Policy)](.github/SECURITY.md) - Vulnerability reporting procedures

## 詳細ドキュメント (Serena Memories)

プロジェクトの詳細情報は `.serena/memories/` に格納されています:

- `project_overview.md` - プロジェクト詳細・目的・構成
- `tech_stack.md` - 技術スタック詳細・ツール統合フロー
- `code_style_and_conventions.md` - コーディング規約・命名規則
- `suggested_commands.md` - コマンドリファレンス・日常操作
- `task_completion_checklist.md` - タスク完了チェックリスト
- `windows_system_utilities.md` - Windows固有のユーティリティ・コマンド
