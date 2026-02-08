---
title: Validate Environment Action - ABI and Contracts
description: Internal ABI specifications, input/output contracts, security model
metadata:
  - Version: 1.2.2
  - Created: 2026-02-05
  - Last Updated: 2026-02-05
Changelog:
  - 2026-02-05: Separated from README.md, documented technical specifications independently
Copyright:
  - Copyright (c) 2026- aglabo
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

<!-- textlint-disable ja-technical-writing/sentence-length -->
<!-- textlint-disable ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length no-duplicate-heading -->

## ABI and Contracts

This document describes the internal technical specifications of the validate-environment action.

**Target Audience**: Developers, maintainers, technical users who need to understand internal behavior

**Regular workflow authors should refer to [README.md](../README.md).**

## Table of Contents

- [Internal ABI Requirements](#internal-abi-requirements)
- [Input Contracts](#input-contracts)
- [Output Contracts](#output-contracts)
- [Security Model](#security-model)

## Overview

This action consists of multiple shell scripts operating on clearly defined ABI (Application Binary Interface) contracts. These contracts guarantee interfaces between action.yml and scripts.

### Contract Types

1. **Internal ABI Requirements**: Runtime environment dependencies
2. **Input Contracts**: Transformation rules from workflow inputs to scripts
3. **Output Contracts**: Output availability based on validation status
4. **Security Model**: Input validation and injection prevention

## Internal ABI Requirements

This action requires the following runtime dependencies (enforced by validate-git-runner.sh):

### 1. Operating System: Linux

- Detection: `uname -s` returns `linux`
- Accepted: `linux` only
- Rejected: Windows, macOS, other OSes
- Reason: aglabo CI infrastructure supports Linux only

### 2. Shell: bash

- Requirement: bash shell
- Reason: Composite action requirement (GitHub Actions constraint)
- Impact: All scripts executed with bash

### 3. GNU coreutils

Required commands:

- `sort -V`: Used for version comparison (validate-apps.sh)
- `grep`: Used for pattern matching
- `sed`: Used for version extraction
- `cut`: Used for field splitting
- `tr`: Used for character conversion

**Availability**: Pre-installed on all GitHub-hosted Linux runners

### 4. Standard Commands

- `uname`: System information retrieval
- `command`: Command existence check
- `type`: Command type detection

### 5. GitHub Actions Runtime Variables

Required environment variables:

- `GITHUB_ACTIONS=true`: Action environment detection
- `RUNNER_ENVIRONMENT=github-hosted`: Hosted runner validation
- `GITHUB_OUTPUT`: Output mechanism (scripts write key=value format)
- `RUNNER_TEMP`: Temporary file directory
- `GITHUB_PATH`: PATH modification mechanism

### When Dependencies Are Not Met

Action fails with clear error messages:

```text
::error::Unsupported operating system: darwin
::error::This action requires Linux
::error::Please use a Linux runner (e.g., ubuntu-latest)
```

## Input Contracts

Action inputs are passed to internal scripts in the following ways.

### architecture Input

#### Workflow Syntax

```yaml
with:
  architecture: "amd64"
```

#### Internal Representation

Passed to validate-git-runner.sh as environment variable `EXPECTED_ARCHITECTURE`.

#### Processing Flow

1. action.yml receives `inputs.architecture` (default: `"amd64"`)
2. Composite action sets environment variable `EXPECTED_ARCHITECTURE`
3. validate-git-runner.sh reads `$EXPECTED_ARCHITECTURE` and compares with `uname -m` output

#### Implementation Example

```yaml
# action.yml
inputs:
  architecture:
    default: "amd64"

# Composite action env setting
env:
  EXPECTED_ARCHITECTURE: ${{ inputs.architecture }}

# validate-git-runner.sh usage
EXPECTED_ARCH="${EXPECTED_ARCHITECTURE}"  # Get from environment variable
DETECTED_ARCH=$(uname -m | tr '[:upper:]' '[:lower:]')
# Normalize and compare...
```

#### Reference

- action.yml:128 - Environment variable setting
- validate-git-runner.sh - Architecture validation logic

### additional-apps Input

#### Workflow Syntax

```yaml
with:
  additional_apps: "gh|gh|regex:version ([0-9.]+)|2.0 node|Node.js|regex:v([0-9.]+)|18.0"
```

#### Internal Representation

Passed to validate-apps.sh as positional arguments.

#### Processing Flow

1. action.yml receives `inputs.additional-apps` (default: `""`)
2. Composite action splits by space and passes each definition as positional argument
3. validate-apps.sh receives arguments via `"$@"` and parses each definition

#### Implementation Example

```yaml
# action.yml
inputs:
  additional-apps:
    default: ""

# Composite action invocation
run: |
  if [ -n "${{ inputs.additional-apps }}" ]; then
    "${GITHUB_ACTION_PATH}/scripts/validate-apps.sh" ${{ inputs.additional-apps }}
  else
    "${GITHUB_ACTION_PATH}/scripts/validate-apps.sh"
  fi
```

```bash
# validate-apps.sh processing
for app_def in "$@"; do
  IFS='|' read -r cmd app_name version_extractor min_version <<< "$app_def"
  # Parse and validate each definition
done
```

#### DSL Format

- Delimiter: Pipe (`|`) - avoids conflicts with regex patterns
- 4 elements required: `cmd|app_name|version_extractor|min_version`
- Multiple apps: Space-separated (each definition becomes individual positional argument)

#### Safety Constraints

Command names and patterns cannot contain the following characters:

- `;` (semicolon): Command chaining
- `|` (pipe): Used as DSL delimiter, cannot be used within patterns
- `&` (ampersand): Background execution
- `$` (dollar): Variable expansion
- `` ` `` (backtick): Command substitution
- `\` (backslash): Escape character
- `#` (hash): Comment

If these characters are present, validate-apps.sh returns error before execution.

#### Version Extraction Patterns

prefix-typed extractors (safe sed only):

1. `field:N` - Extract Nth field (space-delimited)
2. `regex:PATTERN` - sed -E regex with capture group `\1`
3. `(empty)` - Auto semver extraction (X.Y or X.Y.Z pattern)

IMPORTANT: eval is never used. All extraction done with sed only.

#### Reference

- action.yml:140 - Positional argument passing
- validate-apps.sh:145-184 - Input validation and parsing logic

## Output Contracts

Action outputs are **conditionally set** based on validation status.

### Output Types

| Output            | Type   | Condition                  |
| ----------------- | ------ | -------------------------- |
| `runner-status`   | string | Always set                 |
| `runner-message`  | string | Always set                 |
| `apps-status`     | string | When runner-status=success |
| `apps-message`    | string | When runner-status=success |
| `validated-apps`  | string | When apps-status=success   |
| `validated-count` | number | When apps-status=success   |
| `failed-apps`     | string | When apps-status=error     |
| `failed-count`    | number | When apps-status=error     |

### Scenario 1: OS Validation Failure (Runner Validation Error)

When OS validation fails, application validation does not run and workflow immediately stops.

#### Outputs Set

- `runner-status`: `"error"`
- `runner-message`: Error details (e.g., `"Unsupported OS: darwin (Linux required)"`)

#### Outputs NOT Set (undefined)

- `apps-status`, `apps-message`
- `validated-apps`, `validated-count`
- `failed-apps`, `failed-count`

#### Example

```yaml
# When run on macOS runner
runner-status: error
runner-message: "Unsupported operating system: darwin"
# Other outputs undefined (apps validation never runs)
```

#### Workflow Impact

validate-git-runner.sh exits with `exit 1`, causing workflow to immediately fail. Subsequent steps do not run.

### Scenario 2: Application Validation Failure

When OS validation succeeds but application validation fails, all outputs are set.

#### Outputs Set

- `runner-status`: `"success"`
- `runner-message`: OS info (e.g., `"GitHub runner validated: Linux amd64, github-hosted"`)
- `apps-status`: `"error"`
- `apps-message`: Error details (e.g., `"Git not exist"`)
- `failed-apps`: Comma-separated failed app list (e.g., `"Git"`)
- `failed-count`: Number of failed apps (e.g., `1`)

#### Outputs NOT Set (undefined)

- `validated-apps` (not set on failure)
- `validated-count` (not set on failure)

#### Example

```yaml
# When Git not found
runner-status: success
runner-message: "GitHub runner validated: Linux amd64, github-hosted"
apps-status: error
apps-message: "Git not exist"
failed-apps: "Git"
failed-count: 1
# validated-apps and validated-count undefined
```

#### Workflow Impact

validate-apps.sh exits with `exit 1`, causing workflow to fail. However, runner-status is success, so OS validation passed.

### Scenario 3: All Validations Succeed

When both OS and application validations succeed, all outputs are set.

#### Outputs Set

- `runner-status`: `"success"`
- `runner-message`: OS info
- `apps-status`: `"success"`
- `apps-message`: Validated app details
- `validated-apps`: Comma-separated validated app list (e.g., `"Git,curl,gh"`)
- `validated-count`: Number of validated apps (e.g., `3`)
- `failed-apps`: `""` (empty string)
- `failed-count`: `0`

#### Example

```yaml
# All succeed
runner-status: success
runner-message: "GitHub runner validated: Linux amd64, github-hosted"
apps-status: success
apps-message: "Applications validated: Git git version 2.45.0, curl curl 7.88.1, gh gh version 2.60.1"
validated-apps: "Git,curl,gh"
validated-count: 3
failed-apps: ""
failed-count: 0
```

#### Workflow Impact

Both scripts exit with `exit 0` and workflow continues normally.

### Output Usage Patterns

#### Recommended Pattern

Always check `apps-status` before referencing outputs in workflows.

```yaml
- name: Use outputs
  if: steps.validate.outputs.apps-status == 'success'
  run: |
    echo "Validated: ${{ steps.validate.outputs.validated-apps }}"
```

#### Reason

Referencing `validated-apps` or `validated-count` on failure may cause undefined value errors.

#### Defensive Coding

As a gate action, workflow stops entirely on validation failure. The `if:` condition above is optional but recommended as explicit check.

### Reference

- action.yml:95-114 - Output contract definitions
- validate-git-runner.sh - runner-status/runner-message setting
- validate-apps.sh - apps-status and related output setting

## Security Model

This action uses **sed only** to extract version information. `eval` is never used.

### Design Principles

1. Trusted Workflow Author Model: Assumes workflow authors are trusted
2. Defensive Programming: Protects against misconfiguration and typos
3. Injection Prevention: Prevents command injection from malicious patterns
4. Least Privilege: No GITHUB_TOKEN or special permissions needed by default

### Threat Model

#### Assumed Threats

1. Misconfiguration: Workflow author specifies incorrect patterns
2. Typos: Input errors in command names or patterns
3. Command Injection Attempts: Injection via malicious patterns (rare)

#### Not Assumed Threats

- Deliberate exploitation by workflow authors
- Attacks on GitHub Actions environment itself
- Attacks on self-hosted runners (self-hosted runners not supported)

### Input Validation

All inputs validated before execution.

#### Rejected Characters

Returns error if command names and patterns contain the following characters:

| Character | Reason               | Attack Example            |
| --------- | -------------------- | ------------------------- |
| `;`       | Command chaining     | `git;rm -rf /`            |
| `\|`      | Pipe (DSL conflict)  | Misuse within patterns    |
| `&`       | Background execution | `git & malicious_command` |
| `$`       | Variable expansion   | `$MALICIOUS_CMD`          |
| `` ` ``   | Command substitution | `` `rm -rf /` ``          |
| `\`       | Escape character     | `\; rm -rf /`             |
| `#`       | Comment              | `git # ignore rest`       |

#### Validation Example

Rejection by validate-apps.sh:

```bash
# ❌ Command injection attempt
additional_apps: "git;rm -rf /|Git||"
# → Error: "Invalid command name: git;rm (contains forbidden characters)"

# ❌ Variable expansion attempt
additional_apps: "$MALICIOUS_CMD|App||"
# → Error: "Invalid command name: $MALICIOUS_CMD (contains forbidden characters)"

# ✓ Normal pattern
additional_apps: "git|Git|regex:version ([0-9.]+)|2.0"
# → Safely processed
```

### sed-only Extraction

Version extraction runs with **sed only**. No shell evaluation.

#### Extraction Methods

##### 1. field:N Method

Split `--version` output by space and get Nth field:

```bash
# Implementation
version_output=$(command "$cmd" --version 2>&1)
extracted_version=$(echo "$version_output" | cut -d' ' -f "$field_num")

# Example: Extract "2.52.0" from "git version 2.52.0"
# field:3 → "2.52.0"
```

##### 2. regex:PATTERN Method

Use sed regex with capture group `\1`:

```bash
# Implementation
version_output=$(command "$cmd" --version 2>&1)
extracted_version=$(echo "$version_output" | sed -E "s#^.*$pattern.*\$#\\1#")

# Example: Extract "2.60.1" from "gh version 2.60.1 (2024-01-01)"
# regex:version ([0-9.]+) → "2.60.1"
```

IMPORTANT: Using `#` as delimiter avoids conflicts with `/` in patterns.

##### 3. Auto-extraction Method (empty pattern)

Auto-detect semver pattern (`X.Y` or `X.Y.Z`):

```bash
# Implementation
version_output=$(command "$cmd" --version 2>&1)
extracted_version=$(echo "$version_output" | sed -E 's#^.*([0-9]+\.[0-9]+(\.[0-9]+)?).*$#\1#')

# Example: Auto-extract "3.12.1" from "Python 3.12.1"
```

### Safety Guarantees

#### sed Execution Model

- sed patterns passed directly as strings (no expansion)
- Command substitution not executed: `$(...)`, `` `...` ``
- Variable expansion not executed: `$VAR`
- sed `-E` flag uses extended regex only (no executable code)

#### Implementation Example

```bash
# Actual code in validate-apps.sh
version_output=$(command "$cmd" --version 2>&1)
extracted_version=$(echo "$version_output" | sed -E "s#^.*$pattern.*\$#\\1#")

# Command passed to sed (shell does not interpret):
# sed -E 's#^.*version ([0-9.]+).*$#\1#'
# → Extracts "2.60.1" from "gh version 2.60.1 (2024-01-01)"
```

IMPORTANT: `"$pattern"` is quoted and interpreted as sed regex. Never executed as code.

### Injection Prevention Mechanism

#### Multi-layered Defense

1. Input validation: Pre-reject inputs containing dangerous characters
2. sed isolated execution: sed runs as isolated process, unaffected by shell variable expansion/command substitution
3. Quoting: All variables quoted to prevent unintended expansion
4. prefix-typed extractors: `field:` and `regex:` prefixes explicitly specify extraction method

#### Worst Case

Even if malicious pattern bypasses input validation:

- sed pattern matching fails
- Version extraction fails
- Action returns error

**Command injection does not occur.**

### Default Security Profile

#### Git and curl Only (Default)

- No token needed: GITHUB_TOKEN or special permissions not required
- No secrets access: No access to secrets
- Safe usage: Can be used in any workflow

#### When Adding gh CLI

- GH_TOKEN needed: Add `env: GH_TOKEN: ${{ github.token }}`
- Authentication check: Confirmation via `gh auth status`
- Least privilege: Auto-generated `github.token` sufficient (repository scope only)

### Reference

- validate-apps.sh:145-184 - Input validation logic
- validate-apps.sh:248-256 - gh authentication check
- action.yml:31-41 - Security model comments

## Summary

### ABI Contract Importance

1. Internal ABI Requirements: Clarify runtime environment dependencies
2. Input Contracts: Guarantee transformation rules from workflow inputs to script arguments
3. Output Contracts: Define output availability based on validation status
4. Security Model: Prevent injection with sed-only extraction

### Maintenance Considerations

#### Breaking Change Examples

- Environment variable name changes (`EXPECTED_ARCHITECTURE` → different name)
- Positional argument order changes
- Output name changes (`runner-status` → different name)
- DSL format changes

These changes require major version bump.

#### Non-breaking Change Examples

- Adding new validations (backward compatible)
- Improving error messages
- Internal implementation optimization (interface unchanged)

### External References

- [README.md](../README.md) - User documentation
- [action.yml](../action.yml) - Action definition and contracts
- [scripts/validate-git-runner.sh](../scripts/validate-git-runner.sh) - OS/runner validation
- [scripts/validate-apps.sh](../scripts/validate-apps.sh) - Application validation
