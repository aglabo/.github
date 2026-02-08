---
title: Validate Environment Action
description: Validate Environment composite action
metadata
  - Version: 1.2.2
  - Created: 2026-02-03
  - Last Updated: 2026-02-05
  - Last Updated: 2026-02-05
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

## Overview

Gate-focused composite action that validates GitHub Actions runner environment before executing workflow jobs.

This action operates as a **gate action**: it fails immediately on the first validation error, stopping the entire workflow. There is no partial success or error collection mode.

Validates: OS (Linux), architecture (amd64/arm64), runner type (GitHub-hosted), and required applications with version requirements.

## Prerequisites

**CRITICAL**: This action requires specific runtime conditions and will fail if not met.

### Required Environment

- Runner Type: GitHub-hosted runners ONLY
  - Requires `RUNNER_ENVIRONMENT=github-hosted` (automatically set by GitHub)
  - Self-hosted runners are NOT supported
  - Cannot be overridden or simulated
- Operating System: Linux only
  - Validated: `ubuntu-latest`, `ubuntu-22.04`, `ubuntu-20.04`
  - NOT supported: Windows, macOS, or any non-Linux OS
- Architecture: AMD64 (x86_64) or ARM64 (aarch64)
  - AMD64 is default and most common
  - ARM64 support exists but GitHub doesn't offer Linux ARM64 hosted runners yet
- Execution Context: GitHub Actions workflow only
  - Local execution will fail with clear error messages
- Dependencies: GNU coreutils (grep, sed, sort) - pre-installed on GitHub-hosted runners

### Default Application Checks

- Git: Required (fails if not found), warns if version < 2.30
- curl: Required (fails if not found), any version accepted

Additional applications can be validated via `additional_apps` input.

## Design Principles

This action embodies the following principles for aglabo CI infrastructure:

1. **Gate-Focused Validation**
   - Fails immediately on first error (no partial success)
   - Stops workflow execution to prevent running in invalid environments

2. **GitHub-Hosted Runners Only**
   - Requires `RUNNER_ENVIRONMENT=github-hosted`
   - Ensures consistent, secure, reproducible CI environment
   - Cannot be overridden or simulated

3. **Linux-Only by Design**
   - Supports only GitHub-hosted Linux runners (ubuntu-*)
   - Reduces complexity and maintenance burden
   - Optimized for aglabo infrastructure needs

4. **Safe Version Extraction**
   - sed-based extraction only (no eval)
   - Input validation prevents command injection
   - Rejects shell metacharacters and control characters

5. **Breaking Change Detection**
   - Intentionally fails if GitHub changes `RUNNER_ENVIRONMENT` specification
   - Protects against silent behavior changes in CI infrastructure

6. **Trusted Workflow Author Model**
   - Assumes workflow authors are trusted
   - Focuses on preventing accidental misconfiguration rather than malicious attacks
   - Defends against human error, not deliberate exploitation

## Usage

### Basic Example

```yaml
steps:
  - name: Validate Environment
    uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
```

### Complete Workflow Example

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
          gh --version
          # Your workflow using gh CLI
```

**Note**: Without `env: GH_TOKEN`, `gh auth status` check will fail with "gh is not authenticated" error. See [gh CLI Special Handling](#gh-cli-special-handling) and [Troubleshooting](docs/troubleshooting.md) for details.

#### Example 3: Multiple Applications Validation

Validating gh CLI and Node.js together:

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
          GH_TOKEN: ${{ github.token }} # ← REQUIRED for gh CLI

      - name: Use validated tools
        if: steps.validate.outputs.apps-status == 'success'
        run: |
          echo "Validated apps: ${{ steps.validate.outputs.validated-apps }}"
          gh --version
          node --version
```

## Configuration

### Inputs

| Input             | Required | Default | Description                                                 |
| ----------------- | -------- | ------- | ----------------------------------------------------------- |
| `architecture`    | No       | `amd64` | Validates runner architecture: `amd64` (x86_64) or `arm64`  |
|                   |          |         | (aarch64). Does NOT select runner - use `runs-on` for that  |
| `additional_apps` | No       | `""`    | Additional applications to validate (DSL format, see below) |

#### Architecture Input

**Important**: This input validates architecture - it does NOT select or provision runners. Use workflow `runs-on` to select runners.

- `amd64` = Intel/AMD 64-bit (x86_64). Most common on `ubuntu-latest`, `ubuntu-22.04`
- `arm64` = ARM 64-bit (aarch64). Code supports it, but GitHub doesn't offer Linux ARM64 hosted runners yet

Example:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest # ← Selects runner (GitHub provides AMD64)
    steps:
      - uses: .github/actions/validate-environment
        with:
          architecture: "amd64" # ← Validates runner IS AMD64
```

If validation fails (e.g., specified `arm64` but got `amd64`), change `runs-on` or `architecture` input to match.

#### Additional Applications Input

Application definition format (DSL):

```text
cmd|app_name|version_extractor|min_version
```

DSL Rules:

- Delimiter: Pipe (`|`) - avoids conflicts with regex patterns
- All 4 elements required - use empty string to skip version check
- Multiple apps: Space-separated (no spaces within app definitions)
- Stability: This DSL format may change in future versions (breaking change with major version bump)

Version Extractor Options (prefix-typed, sed-only for security):

1. `field:N` - Extract Nth field (space-delimited) from `--version` output
   - Example: `field:3` extracts "2.52.0" from "git version 2.52.0"
2. `regex:PATTERN` - sed -E regex with capture group `\1`
   - Example: `regex:version ([0-9.]+)` extracts version number
   - Example: `regex:v([0-9.]+)` for Node.js "v18.0.0" format
3. `(empty)` - Auto-extract semver (X.Y or X.Y.Z pattern)

Examples:

```yaml
# Single application
additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0"

# Multiple applications
additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0 node|Node.js|regex:v([0-9.]+)|18.0"

# Common applications
# - GitHub CLI: "gh|gh|regex:version ([0-9.]+)|2.0"
# - Node.js: "node|Node.js|regex:v([0-9.]+)|18.0"
# - Python: "python|Python||3.8"
# - Docker: "docker|Docker|regex:version ([0-9.]+)|20.0"
```

> **Important note for gh CLI**: When specifying gh CLI in `additional_apps`, you MUST add `env: GH_TOKEN: ${{ github.token }}` to your workflow step. Without this, gh authentication check (`gh auth status`) will fail. See [gh CLI Special Handling](#gh-cli-special-handling) for details.

#### gh CLI Special Handling

gh CLI (GitHub CLI) differs from other applications - it has an **authentication check** automatically performed.

##### Authentication Mechanism

When gh CLI is specified in `additional_apps`, validate-apps.sh performs these checks:

1. **Existence check**: `command -v gh` confirms gh CLI exists
2. **Version check**: `gh --version` confirms minimum version requirement
3. **Authentication check**: `gh auth status` confirms authentication state

**Authentication check implementation** (validate-apps.sh:248-256):

```bash
check_gh_authentication() {
  # Check authentication status using gh auth status
  # Exit code 0 = authenticated, 1 = not authenticated or auth issues
  gh auth status >/dev/null 2>&1
  return $?
}
```

This check ONLY runs for gh CLI. Other applications (node, python, etc.) have no authentication checks.

##### GH_TOKEN Requirement

In GitHub Actions, **GH_TOKEN environment variable** is required for `gh auth status` to succeed.

**Why**:

- GitHub Actions runners come with gh CLI pre-installed
- However, by default, no authentication credentials are configured
- The `gh` command reads authentication tokens from `GH_TOKEN` environment variable
- GitHub Actions automatically provides `github.token` context, but you must explicitly pass it

**Required configuration**:

```yaml
- name: Validate with gh CLI
  uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
  with:
    additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0"
  env:
    GH_TOKEN: ${{ github.token }} # ← Without this, auth check fails
```

IMPORTANT: The `env:` section must be specified at the step level. It can also be specified at job level, but as a security best practice, it's recommended to limit the scope to only the steps that need the token.

##### Authentication Scenarios

There are 3 scenarios for gh CLI validation:

Scenario 1: With GH_TOKEN (Normal)

```yaml
- name: Validate with gh CLI
  uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
  with:
    additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0"
  env:
    GH_TOKEN: ${{ github.token }}
```

Result:

- `gh auth status` succeeds (exit code 0)
- Validation succeeds: `apps-status: success`
- Workflow steps using gh CLI work correctly

Scenario 2: Without GH_TOKEN (Error)

```yaml
- name: Validate with gh CLI (incorrect configuration)
  uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
  with:
    additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0"
  # env: GH_TOKEN not specified
```

Result:

- `gh auth status` fails (exit code 1)
- Error: `"gh is not authenticated. Run 'gh auth login' or set GH_TOKEN"`
- Validation fails: `apps-status: error`
- Workflow stops

Error message example:

```text
::error::gh is not authenticated. Run 'gh auth login' or set GH_TOKEN
::error::To resolve: Add 'env: GH_TOKEN: ${{ github.token }}' to your workflow step
```

Scenario 3: Not using gh CLI (No impact)

```yaml
- name: Validate without gh CLI
  uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
  # additional_apps not specified or doesn't include gh
```

Result:

- No authentication check performed (gh CLI not specified)
- GH_TOKEN not required
- Only default Git and curl validated

##### Troubleshooting

**If you get "gh is not authenticated" error**:

The most common cause is forgetting to set `env: GH_TOKEN`.

**Quick fix**:

```yaml
- uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
  with:
    additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0"
  env:
    GH_TOKEN: ${{ github.token }} # ← Add this
```

For detailed troubleshooting steps, common mistakes, and debugging methods, see **[docs/troubleshooting.md - gh CLI Troubleshooting](docs/troubleshooting.md#gh-cli-troubleshooting)**.

##### Security Notes

**GH_TOKEN scope**:

- `github.token` is automatically generated by GitHub Actions
- Only has read/write access to repository contents
- No access to entire user account
- Automatically invalidated after workflow execution

**Best practices**:

1. **Principle of least privilege**: Pass GH_TOKEN only to steps using gh CLI
2. **Don't log token**: Token is not logged (GitHub automatically masks it)
3. **Use custom token**: If stronger permissions needed, use `secrets.MY_CUSTOM_TOKEN`

**Example** (least privilege):

```yaml
steps:
  # This step doesn't need GH_TOKEN
  - name: Validate basic environment
    uses: aglabo/.github-aglabo/.github/actions/validate-environment@main

  # Only this step uses GH_TOKEN
  - name: Validate with gh CLI
    uses: aglabo/.github-aglabo/.github/actions/validate-environment@main
    with:
      additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0"
    env:
      GH_TOKEN: ${{ github.token }} # ← Only this step has scope
```

For details, see [docs/troubleshooting.md - gh CLI Troubleshooting](docs/troubleshooting.md#gh-cli-troubleshooting).

### Outputs

| Output            | Type   | Description                                               |
| ----------------- | ------ | --------------------------------------------------------- |
| `os-status`       | string | OS validation status: `success` or `error`                |
| `os-message`      | string | OS validation message (e.g., OS type, architecture)       |
| `apps-status`     | string | Applications validation status: `success` or `error`      |
| `apps-message`    | string | Applications validation message                           |
| `validated-apps`  | string | Comma-separated validated app names (e.g., `Git,curl,gh`) |
| `validated-count` | number | Number of successfully validated apps                     |
| `failed-apps`     | string | Comma-separated failed app names (empty if all passed)    |
| `failed-count`    | number | Number of failed apps (0 if all passed)                   |

#### Output Behavior (Gate Action)

This action fails immediately on first error. Output availability:

- OS validation fails: Only `os-status` and `os-message` are set (apps validation never runs)
- Apps validation fails: All outputs set with `os-status=success`, `apps-status=error`
- Both succeed: All outputs show success status

Examples:

```text
# Success
os-status: success
os-message: GitHub runner validated: Linux amd64, github-hosted
apps-status: success
apps-message: Applications validated: Git git version 2.45.0, curl curl 7.88.1
validated-apps: Git,curl
validated-count: 2

# Failure (Unsupported OS)
os-status: error
os-message: Unsupported OS: darwin (Linux required)

# Failure (Missing Application)
os-status: success
apps-status: error
apps-message: Git not exist
failed-count: 1
```

Recommended usage:

```yaml
- if: steps.validate.outputs.apps-status == 'success'
  run: echo "All validations passed"
```

**Note**: This is a gate action - workflows stop automatically on validation failure. The `if:` condition in the example above is optional and serves as defensive coding. In most workflows, explicit `if:` conditions are unnecessary because the action fails the entire workflow on error.

## Validation Details

The action performs these checks in order:

### 1. Operating System

- Detects OS using `uname -s`
- Accepts: `linux`
- Rejects: `darwin` (macOS), `windows`, `msys`, `cygwin`, etc.

### 2. Architecture

- Detects architecture using `uname -m`
- Accepts: `x86_64`, `amd64`, `x64` → normalized as `amd64`
- Accepts: `aarch64`, `arm64` → normalized as `arm64`

### 3. GitHub Actions Environment

Critical checks:

1. `GITHUB_ACTIONS=true` must be set
2. `RUNNER_ENVIRONMENT=github-hosted` must be set (see Design Principles)
3. Runtime variables must exist: `RUNNER_TEMP`, `GITHUB_OUTPUT`, `GITHUB_PATH`

### 4. Applications

- Default: `git` (warns if version < 2.30), `curl` (any version)
- Additional: Applications specified in `additional_apps` input

## Limitations & Troubleshooting

### What This Action Does NOT Do

- Does NOT select or provision runners - Use workflow `runs-on` for that
- Does NOT install applications - Use `actions/setup-node`, etc. for that
- Does NOT support:
  - Windows runners (`windows-latest`, etc.)
  - macOS runners (`macos-latest`, `macos-14`, etc.)
  - Self-hosted runners (requires `RUNNER_ENVIRONMENT=github-hosted`)
  - Local execution (GitHub Actions environment required)

### ARM64 Architecture Notes

This action's code supports ARM64 (aarch64) validation on Linux. However:

- macOS ARM runners (macos-14 M1/M2) are rejected (macOS not supported)
- Linux ARM64 runners would work IF GitHub offered them as hosted runners
- As of 2026, GitHub does not offer Linux ARM64 hosted runners
- If GitHub adds them in the future, this action will work with `architecture: "arm64"` without code changes

Tested: AMD64 (ubuntu-latest, ubuntu-22.04, ubuntu-20.04)

### Common Errors & Solutions

#### Error: "Unsupported operating system"

```text
::error::Unsupported operating system: darwin
::error::This action requires Linux
::error::Please use a Linux runner (e.g., ubuntu-latest)
```

Solution: Change workflow to use Linux runner: `runs-on: ubuntu-latest`

#### Error: "Not running in GitHub Actions environment"

```text
::error::Not running in GitHub Actions environment
::error::This action must run in a GitHub Actions workflow
::error::GITHUB_ACTIONS environment variable is not set to 'true'
```

Solution: This action only runs in GitHub Actions workflows. Do not execute scripts locally.

#### Error: "Git is not installed"

```text
::error::Git is not installed
```

Solution: Use a runner with Git pre-installed (all GitHub-hosted runners include Git).

### Local Execution

Scripts fail with clear error messages when run outside GitHub Actions. Do not run validation scripts locally - they are designed exclusively for GitHub Actions workflows.

## License

MIT License

Copyright (c) 2026- aglabo

See [LICENSE](../../../LICENSE) for details.

## Support

For issues or questions:

- Open an issue in the [.github-aglabo repository](https://github.com/aglabo/.github-aglabo/issues)
- Check existing documentation in `.serena/memories/`
- Review workflow examples in `.github/workflows/`
