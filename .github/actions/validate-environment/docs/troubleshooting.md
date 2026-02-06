---
title: Validate Environment Action - Troubleshooting
description: Common errors and solutions, limitations
metadata:
  - Version: 1.2.0
  - Created: 2026-02-05
  - Last Updated: 2026-02-05
Changelog:
  - 2026-02-05: Separated from README.md, consolidated troubleshooting information
Copyright:
  - Copyright (c) 2026- aglabo
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

<!-- textlint-disable ja-technical-writing/sentence-length -->
<!-- textlint-disable ja-technical-writing/max-comma -->
<!-- textlint-disable ja-technical-writing/no-exclamation-question-mark -->
<!-- markdownlint-disable line-length no-duplicate-heading -->

## Troubleshooting

This document provides limitations, common errors, and solutions for the validate-environment action.

**For normal usage, refer to [README.md](../README.md).**

## Table of Contents

- [Limitations](#limitations)
- [Common Errors and Solutions](#common-errors-and-solutions)
- [gh CLI Troubleshooting](#gh-cli-troubleshooting)
- [Local Execution](#local-execution)

## Limitations

### What This Action Does NOT Do

The validate-environment action only performs validation. It does NOT:

#### Runner Selection or Provisioning

- ✗ Does not select or provision runners
- ✓ **Use instead**: Specify in workflow `runs-on`

```yaml
jobs:
  build:
    runs-on: ubuntu-latest # ← Select runner here
    steps:
      - uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
        with:
          architecture: "amd64" # ← Validation only (not selection)
```

#### Application Installation

- ✗ Does not install applications
- ✓ **Use instead**: Dedicated setup actions

```yaml
steps:
  # Install application
  - uses: actions/setup-node@v4
    with:
      node-version: "18"

  # Then validate
  - uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
    with:
      additional_apps: "node|Node.js|regex:v([0-9.]+)|18.0"
```

### Unsupported Environments

This action does not support the following environments:

#### Windows Runners

```yaml
# ✗ Not supported
runs-on: windows-latest

# ✓ Use this
runs-on: ubuntu-latest
```

**Error example**:

```text
::error::Unsupported operating system: windows
::error::This action requires Linux
```

#### macOS Runners

```yaml
# ✗ Not supported
runs-on: macos-latest
runs-on: macos-14 # M1/M2 also not supported

# ✓ Use this
runs-on: ubuntu-latest
```

**Error example**:

```text
::error::Unsupported operating system: darwin
::error::This action requires Linux
```

#### Self-hosted Runners

- Required: `RUNNER_ENVIRONMENT=github-hosted` (automatically set by GitHub)
- Self-hosted runners not supported
- Cannot be overridden or simulated

**Reason**: aglabo CI infrastructure supports only GitHub-hosted runners (ensures consistency, security, reproducibility)

#### Local Execution

- GitHub Actions environment required
- Local script execution not supported

See [Local Execution](#local-execution) for details.

### ARM64 Architecture Notes

This action's code supports ARM64 (aarch64) validation on Linux.

#### Current Status (2026)

- ✓ Code: ARM64 validation supported
- ✗ macOS ARM runners (macos-14 M1/M2): Rejected (macOS not supported)
- ✗ Linux ARM64 runners: GitHub does not offer them

#### Future Support

- If GitHub offers Linux ARM64 hosted runners, this will work
- Will work with `architecture: "arm64"` without code changes

#### Tested Environments

- ✓ AMD64 (x86_64): ubuntu-latest, ubuntu-22.04, ubuntu-20.04

## Common Errors and Solutions

### Error: "Unsupported operating system"

#### Error Message

```text
::error::Unsupported operating system: darwin
::error::This action requires Linux
::error::Please use a Linux runner (e.g., ubuntu-latest)
```

#### Cause

- Running on Windows or macOS runner
- This action supports Linux only

#### Solution

Change workflow to use Linux runner:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest # ← Change to Linux runner
    steps:
      - uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
```

#### Recommended Runners

- `ubuntu-latest` (recommended, always latest LTS)
- `ubuntu-22.04` (if specific version needed)
- `ubuntu-20.04` (legacy support)

### Error: "Not running in GitHub Actions environment"

#### Error Message

```text
::error::Not running in GitHub Actions environment
::error::This action must run in a GitHub Actions workflow
::error::GITHUB_ACTIONS environment variable is not set to 'true'
```

#### Cause

- Running script outside GitHub Actions environment
- Required environment variable `GITHUB_ACTIONS=true` not set

#### Solution

This action only runs within GitHub Actions workflows.

**✗ Do not run**:

```bash
# Direct local execution
./validate-git-runner.sh  # Error occurs
```

**✓ Run instead**:

```yaml
# Run within GitHub Actions workflow
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
```

See [Local Execution](#local-execution) for details.

### Error: "Git is not installed"

#### Error Message

```text
::error::Git is not installed
```

#### Cause

- Using runner without Git installed (rare)
- Possibly running in custom Docker container

#### Solution

Use runner with Git pre-installed.

**Normal case**: All GitHub-hosted runners have Git pre-installed

```yaml
runs-on: ubuntu-latest # Git pre-installed
```

**Custom container case**: Install Git

```yaml
jobs:
  validate:
    runs-on: ubuntu-latest
    container: custom-image:latest
    steps:
      # Install Git (for custom containers)
      - run: apt-get update && apt-get install -y git

      # Then validate
      - uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
```

## gh CLI Troubleshooting

### Error: "gh is not authenticated"

The **most common error** when validating gh CLI with `additional_apps`.

#### Error Message

```text
::error::gh is not authenticated. Run 'gh auth login' or set GH_TOKEN
::error::To resolve: Add 'env: GH_TOKEN: ${{ github.token }}' to your workflow step
```

#### Cause

1. **Workflow step does not have `env: GH_TOKEN` set** (most common)
2. gh CLI fails `gh auth status` without authentication credentials
3. GitHub Actions runners have gh CLI pre-installed but not authenticated by default
4. `github.token` context not available (rare case)

#### Why GH_TOKEN is Needed

- GitHub Actions runners have gh CLI pre-installed
- However, **authentication credentials are not configured by default**
- gh CLI reads authentication tokens from `GH_TOKEN` environment variable
- GitHub Actions provides `github.token`, but **you must explicitly pass it**

### Solutions

#### Solution 1: Add env: GH_TOKEN to Step (Recommended)

**Easiest and recommended method**:

```yaml
- name: Validate with gh CLI
  uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
  with:
    additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0"
  env:
    GH_TOKEN: ${{ github.token }} # ← Add this
```

#### Solution 2: Set env at Job Level

**When using gh CLI in multiple steps**:

```yaml
jobs:
  validate:
    runs-on: ubuntu-latest
    env:
      GH_TOKEN: ${{ github.token }} # ← Apply to entire job
    steps:
      - name: Validate with gh CLI
        uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
        with:
          additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0"

      # Other steps also have GH_TOKEN available
      - name: Use gh CLI
        run: gh repo view
```

#### Solution 3: Use GITHUB_TOKEN Secret (Alternative)

Use `secrets.GITHUB_TOKEN` instead of `github.token`:

```yaml
- name: Validate with gh CLI
  uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
  with:
    additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0"
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }} # Equivalent to github.token
```

**Note**: `github.token` and `secrets.GITHUB_TOKEN` are the same token.

### Common Mistakes

#### ❌ Mistake 1: Not Passing Token

```yaml
- uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
  with:
    additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0"
  # env: GH_TOKEN missing → Error
```

**Result**: `gh is not authenticated` error occurs

#### ❌ Mistake 2: Writing env Inside with

```yaml
- uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
  with:
    additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0"
    env: GH_TOKEN: ${{ github.token }} # ← YAML syntax error
```

**Result**: YAML parsing error occurs

#### ❌ Mistake 3: Wrong Token Variable Name

```yaml
- uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
  with:
    additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0"
  env:
    GITHUB_TOKEN: ${{ github.token }} # ← Not GH_TOKEN
```

**Result**: gh CLI reads `GH_TOKEN` not `GITHUB_TOKEN`, so authentication fails

#### ❌ Mistake 4: Wrong Indentation

```yaml
- uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
  with:
    additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0"
    env:
      GH_TOKEN: ${{ github.token }} # ← env is child element of with
```

**Result**: YAML parsing error or env ignored

#### ✓ Correct: Specify env at Step Level

```yaml
- uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
  with:
    additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0"
  env:
    GH_TOKEN: ${{ github.token }} # ← Same indentation level as with:
```

**Point**: `env:` placed at same level as `with:` (directly under step)

### Related Sections

- [README.md - gh CLI Special Handling](../README.md#gh-cli-special-handling) - Authentication mechanism details
- [README.md - Usage > Example 2](../README.md#example-2-validation-with-gh-cli) - Correct configuration example
- [README.md - Configuration > additional_apps Input](../README.md#additional_apps-input) - DSL format explanation

## Local Execution

### Limitations

Running scripts outside GitHub Actions fails with clear error messages.

IMPORTANT: Do not run validation scripts locally - they are designed exclusively for GitHub Actions workflows.

### Error Example

```bash
# Attempt local execution
./validate-git-runner.sh

# Error message
::error::Not running in GitHub Actions environment
::error::This action must run in a GitHub Actions workflow
::error::GITHUB_ACTIONS environment variable is not set to 'true'
```

### Reason

This action depends on the following GitHub Actions-specific features:

1. **Environment variables**:
   - `GITHUB_ACTIONS=true`
   - `RUNNER_ENVIRONMENT=github-hosted`
   - `GITHUB_OUTPUT`
   - `RUNNER_TEMP`

2. **Output mechanism**:
   - key=value write to `$GITHUB_OUTPUT`
   - Automatic output retrieval by GitHub Actions

3. **Runner environment**:
   - Guaranteed GitHub-hosted runner environment
   - Pre-installed tools (Git, curl, gh, GNU coreutils)

These are not available in local environments.

## Summary

### Quick Reference for Common Errors

| Error                         | Cause                | Solution                           |
| ----------------------------- | -------------------- | ---------------------------------- |
| Unsupported operating system  | Windows/macOS runner | Change to `runs-on: ubuntu-latest` |
| Not running in GitHub Actions | Local execution      | Run within workflow                |
| Git is not installed          | No Git (rare)        | Use GitHub-hosted runners          |
| gh is not authenticated       | No GH_TOKEN          | Add `env: GH_TOKEN`                |

### Support

If issue not resolved:

- Open issue in [.github-aglabo repository](https://github.com/aglabo/.github-aglabo/issues)
- Check usage examples in [README.md](../README.md)
- Check technical specifications in [docs/abi.md](abi.md)
