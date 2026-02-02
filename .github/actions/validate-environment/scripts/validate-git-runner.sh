#!/usr/bin/env bash
# src: ./.github/actions/validate-environment/scripts/validate-git-runner.sh
# @(#) : Validate GitHub Actions runner environment
#
# Copyright (c) 2026- aglabo <https://github.com/aglabo>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @file validate-git-runner.sh
# @brief Validate GitHub Actions runner environment comprehensively
# @description
#   Validates the execution environment for GitHub Actions workflows.
#   Ensures OS is Linux, architecture matches expectations (amd64|arm64),
#   and runner is GitHub-hosted with required environment variables.
#
#   **Checks:**
#   1. Operating System is Linux
#   2. Expected architecture input is valid (amd64 or arm64)
#   3. Detected architecture matches expected architecture
#   4. GitHub Actions environment (GITHUB_ACTIONS=true)
#   5. GitHub-hosted runner (RUNNER_ENVIRONMENT=github-hosted)
#   6. Required runtime variables (RUNNER_TEMP, GITHUB_OUTPUT, GITHUB_PATH)
#
# @exitcode 0 GitHub runner validation successful
# @exitcode 1 GitHub runner validation failed
#
# @author   atsushifx
# @version  1.2.0
# @license  MIT

set -euo pipefail

# Safe output file handling - fallback to /dev/null if not in GitHub Actions
GITHUB_OUTPUT_FILE="${GITHUB_OUTPUT:-/dev/null}"

echo "=== Validating GitHub Runner Environment ==="
echo ""

# Detect OS
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
echo "Operating System: ${OS}"

if [ "${OS}" != "linux" ]; then
  echo "::error::Unsupported operating system: ${OS}"
  echo "::error::This action requires Linux"
  echo "::error::Please use a Linux runner (e.g., ubuntu-latest)"
  echo "status=error" >> "$GITHUB_OUTPUT_FILE"
  echo "message=Unsupported OS: ${OS} (Linux required)" >> "$GITHUB_OUTPUT_FILE"
  exit 1
fi

echo "✓ Operating system validated: Linux"
echo ""

# Validate expected architecture input
EXPECTED_ARCH="${EXPECTED_ARCHITECTURE:-amd64}"
echo "Expected architecture: ${EXPECTED_ARCH}"

case "${EXPECTED_ARCH}" in
  amd64|arm64)
    # Valid input
    ;;
  *)
    echo "::error::Invalid architecture input: ${EXPECTED_ARCH}"
    echo "::error::Supported values: amd64, arm64"
    echo "status=error" >> "$GITHUB_OUTPUT_FILE"
    echo "message=Invalid architecture input: ${EXPECTED_ARCH}" >> "$GITHUB_OUTPUT_FILE"
    exit 1
    ;;
esac

# Detect actual architecture
ARCH=$(uname -m)
echo "Detected architecture: ${ARCH}"

# Normalize architecture name
case "${ARCH}" in
  x86_64|amd64|x64)
    NORMALIZED_ARCH="amd64"
    ;;
  aarch64|arm64)
    NORMALIZED_ARCH="arm64"
    ;;
  *)
    echo "::error::Unsupported architecture: ${ARCH}"
    echo "::error::Supported architectures: amd64 (x86_64), arm64 (aarch64)"
    echo "status=error" >> "$GITHUB_OUTPUT_FILE"
    echo "message=Unsupported architecture: ${ARCH}" >> "$GITHUB_OUTPUT_FILE"
    exit 1
    ;;
esac

# Compare expected vs actual
if [ "${EXPECTED_ARCH}" != "${NORMALIZED_ARCH}" ]; then
  echo "::error::Architecture mismatch"
  echo "::error::Expected: ${EXPECTED_ARCH}"
  echo "::error::Detected: ${NORMALIZED_ARCH} (${ARCH})"
  echo "::error::Please use a runner with ${EXPECTED_ARCH} architecture"
  echo "status=error" >> "$GITHUB_OUTPUT_FILE"
  echo "message=Architecture mismatch: expected ${EXPECTED_ARCH}, got ${NORMALIZED_ARCH}" >> "$GITHUB_OUTPUT_FILE"
  exit 1
fi

echo "✓ Architecture validated: ${NORMALIZED_ARCH}"
echo ""

# Check GitHub Actions environment variables
echo "Checking GitHub Actions environment..."

# First check: Authoritative GitHub Actions flag
if [ "${GITHUB_ACTIONS:-}" != "true" ]; then
  echo "::error::Not running in GitHub Actions environment"
  echo "::error::This action must run in a GitHub Actions workflow"
  echo "::error::GITHUB_ACTIONS environment variable is not set to 'true'"
  echo "status=error" >> "$GITHUB_OUTPUT_FILE"
  echo "message=Not running in GitHub Actions environment" >> "$GITHUB_OUTPUT_FILE"
  exit 1
fi
echo "✓ GITHUB_ACTIONS is set to 'true'"

# Second check: GitHub-hosted runner requirement
if [ "${RUNNER_ENVIRONMENT:-}" != "github-hosted" ]; then
  echo "::error::This action requires a GitHub-hosted runner"
  echo "::error::Self-hosted runners are not supported"
  echo "::error::RUNNER_ENVIRONMENT is not set to 'github-hosted' (current: ${RUNNER_ENVIRONMENT:-unset})"
  echo "status=error" >> "$GITHUB_OUTPUT_FILE"
  echo "message=Requires GitHub-hosted runner (not self-hosted)" >> "$GITHUB_OUTPUT_FILE"
  exit 1
fi
echo "✓ RUNNER_ENVIRONMENT is 'github-hosted'"

# Third check: Runtime variables
MISSING_VARS=()

for VAR in RUNNER_TEMP GITHUB_OUTPUT GITHUB_PATH; do
  if [ -z "${!VAR:-}" ]; then
    MISSING_VARS+=("$VAR")
  else
    echo "✓ ${VAR} is set"
  fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
  echo "::error::Required environment variables are not set: ${MISSING_VARS[*]}"
  echo "::error::This action must run in a GitHub Actions environment"
  echo "status=error" >> "$GITHUB_OUTPUT_FILE"
  echo "message=Missing environment variables: ${MISSING_VARS[*]}" >> "$GITHUB_OUTPUT_FILE"
  exit 1
fi
echo ""

echo "=== GitHub runner validation passed ==="
echo "status=success" >> "$GITHUB_OUTPUT_FILE"
echo "message=GitHub runner validated: Linux ${NORMALIZED_ARCH}, github-hosted" >> "$GITHUB_OUTPUT_FILE"
exit 0
