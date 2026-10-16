# Changelog

All notable changes to this project will be documented in this file.

## [r2.0.0] - 2026-10-16

### 🚀 Features

- Add lint runners for markdownlint, textlint, actionlint, and ghalint (`runners/`)
- Add a setup script for the development environment and aglabo tools
- Add repository templates and a labels definition

### 🐛 Bug Fixes

- Support markdown code blocks in AI commit messages
- Fix config paths in lint runners and setup errors in scripts

### ⚙️ Configuration

- Replace gitleaks with betterleaks for secret scanning
- Move lint configs to a shared global config directory
- Change commitlint config to ESM (`commitlint.config.mjs`)
- Use an allowlist policy in `.gitignore`
- Update dprint plugins and add TOML/MDX support
- Require pnpm 12

### 👷 CI/CD

- Replace local workflows with shared ci-platform workflows (v0.4.0)

### 📚 Documentation

- Update README and PR/issue templates

### 📦 Dependencies

- Update GitHub Actions and dev tool packages
