# CLAUDE.md

## プロジェクト

aglabo の共有開発インフラ - 自動化による OSS 品質保証:

This repository provides shared development infrastructure for aglabo OSS projects.
It enforces consistency through automation rather than documentation.

- Lint configs are shared from a global config directory and run through `runners/`.
- CI uses shared reusable workflows from [aglabo/ci-platform](https://github.com/aglabo/ci-platform).
- Organization-wide GitHub files: issue/PR templates, labels, community guidelines, and `profile/README.md`.

## 技術スタック

lefthook, dprint, betterleaks, secretlint, commitlint, markdownlint-cli2, textlint, cspell,
actionlint (jactionlint), ghalint, pnpm 12

## コア原則

1. **Configuration as Truth** - All rules live in config files, not documentation
2. **Automate Everything** - Linters, formatters, and hooks prevent issues before commit
3. **AI-Powered Workflow** - Commit messages and documentation are AI-generated
4. **Zero Manual Checks** - CI/CD catches what local hooks miss

## 禁止事項

- Never bypass pre-commit hooks (`--no-verify`)
- Never commit secrets (betterleaks and secretlint will block)
- Never manually format code (dprint handles it)
- Always follow Conventional Commits format (header max 76 chars)

## 重要コマンド

```bash
pnpm install              # Install deps and run scripts/setup-dev-env.sh (prepare)
lefthook install          # Install git hooks
pnpm run format:dprint    # Format all files
pnpm run check:dprint     # Check formatting
pnpm run lint:markdown    # markdownlint  (runners/run-markdownlint.sh)
pnpm run lint:text        # textlint      (runners/run-textlint.sh)
pnpm run lint:gha         # actionlint + ghalint
pnpm run lint:spells      # cspell
pnpm run scan:secrets     # betterleaks + secretlint
git commit                # Commit with AI-generated message
```

## Git Hooks (lefthook)

- **pre-commit**: betterleaks, secretlint
- **prepare-commit-msg**: `scripts/prepare-commit-msg.sh` generates the message with AI
- **commit-msg**: commitlint

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
- `merge`: Merge commits (e.g. `merge (#55): config(repo): ...`)
- `build`: Build system changes
- `style`: Code style changes
- `deps`: Dependency updates

## Lint Runners

`runners/run-*.sh` find the config file with `resolve_config_file` (`runners/libs/utils.lib.sh`).
They look in the global config directory (`$XDG_CONFIG_HOME` or `~/.config`) first,
then fall back to the file in `configs/`.

| Runner                        | Global config                                  | Local fallback                    |
| ----------------------------- | ---------------------------------------------- | --------------------------------- |
| `runners/run-markdownlint.sh` | `linters/markdownlint/.markdownlint-cli2.yaml` | `configs/.markdownlint-cli2.yaml` |
| `runners/run-textlint.sh`     | `linters/textlint/textlintrc.yaml`             | `configs/textlintrc.yaml`         |
| `runners/run-actionlint.sh`   | `jactionlint/jactionlint.yaml`                 | `configs/jactionlint.yaml`        |
| `runners/run-ghalint.sh`      | `linters/ghalint/ghalint.yaml`                 | `configs/ghalint.yaml`            |

Note: markdownlint and textlint configs are no longer in this repository. Set them up in the global config directory.

### global-configs submodule

`global-configs/` is a git submodule of [aglabo/global-configs](https://github.com/aglabo/global-configs),
the shared source for these configs. Run `git submodule update --init` after cloning.
The runners do not read `global-configs/` directly; they still use the lookup order above.

## 設定ファイル

| Category       | Tool               | Config File                                                   |
| -------------- | ------------------ | ------------------------------------------------------------- |
| **Formatting** | dprint             | `dprint.jsonc`                                                |
|                | EditorConfig       | `.editorconfig`                                               |
| **Linting**    | cspell             | `.vscode/cspell.json`                                         |
|                | jactionlint        | `configs/jactionlint.yaml`                                    |
|                | ghalint            | `configs/ghalint.yaml`                                        |
| **Git Hooks**  | lefthook           | `lefthook.yml`                                                |
| **Commit**     | commitlint         | `configs/commitlint.config.mjs`                               |
|                | prepare-commit-msg | `scripts/prepare-commit-msg.sh`                               |
| **Security**   | betterleaks        | `configs/betterleaks.toml`                                    |
|                | secretlint         | `configs/secretlint.config.yaml`                              |
| **Setup**      | dev environment    | `scripts/setup-dev-env.sh`                                    |
| **GitHub**     | Labels             | `.github/labels.yml`                                          |
|                | Templates          | `.github/ISSUE_TEMPLATE/`, `.github/PULL_REQUEST_TEMPLATE.md` |
| **CI/CD**      | Secret scan        | `.github/workflows/ci-scan-secrets.yml`                       |
|                | Workflows QA       | `.github/workflows/ci-workflows-qa.yml`                       |
| **Deps**       | Renovate           | `renovate.json`                                               |

## リリース

- Tags use the `rX.Y.Z` format (e.g. `r2.0.0`).
- Release notes: `ChangeLog.md` (all changes) and `Release-Note.md` (highlights, breaking changes, upgrade steps).

## リポジトリ情報

- **Organization**: aglabo
- **License**: MIT License
- **Copyright**: (c) 2025- aglabo

## コミュニティガイドライン

- [行動規範 (Code of Conduct)](.github/CODE_of_CONDUCT.md) - Community code of conduct
- [セキュリティポリシー (Security Policy)](.github/SECURITY.md) - Vulnerability reporting procedures
