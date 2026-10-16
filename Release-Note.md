# Release r2.0.0

Release date: 2026-10-16

## Overview

This release moves the shared lint and CI setup to common tools.
Lint configs and CI workflows now live in shared places,
so each repository can use the same rules with less setup.

## Highlights

- **Lint runners**: New scripts in `runners/` run markdownlint, textlint, actionlint, and ghalint.
- **Shared CI**: CI now uses shared ci-platform workflows (v0.4.0).
- **Secret scanning**: betterleaks replaces gitleaks.
- **Easy setup**: `scripts/setup-dev-env.sh` installs the dev tools and aglabo tools.
- **Templates**: New issue/PR templates and a labels definition.

## Breaking Changes

- gitleaks is removed. Use betterleaks.
- Lint configs are loaded from the global config directory (`$XDG_CONFIG_HOME` or `~/.config`).
- The commitlint config is now `configs/commitlint.config.mjs`.
- pnpm 12 or later is required.

## Upgrade

1. Install pnpm 12 or later.
2. Run `scripts/setup-dev-env.sh`.
3. Run `lefthook install` to update git hooks.

See [ChangeLog.md](ChangeLog.md) for the full list of changes.
