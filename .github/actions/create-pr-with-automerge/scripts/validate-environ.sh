#!/usr/bin/env bash
# src: ./.github/actions/create-pr-with-automerge/scripts/validate-environ.sh
# @(#) : Validate environment for create-pr-with-automerge action
#
# Copyright (c) 2026- aglabo <https://github.com/aglabo>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @file validate-environ.sh
# @brief Validate OS and GitHub CLI environment for PR creation
# @description
#   Validates the execution environment for create-pr-with-automerge action:
#   - OS compatibility (Linux only)
#   - GitHub CLI (gh) installation and authentication
#   - GitHub API rate limit availability
#
#   **Required Environment Variables:**
#   - RUNNER_OS: OS identifier from GitHub Actions
#   - GH_TOKEN or GITHUB_TOKEN: GitHub authentication token
#
#   **Checks:**
#   1. Runner OS is Linux
#   2. gh command is installed
#   3. gh is authenticated with provided token
#   4. GitHub API rate limit has sufficient remaining calls (>10)
#
# @example
#   RUNNER_OS=Linux GH_TOKEN=${{ secrets.GITHUB_TOKEN }} ./validate-environ.sh
#
# @exitcode 0 All validations passed
# @exitcode 1 Validation failed
#
# @author aglabo
# @version 1.0.0
# @license MIT

set -euo pipefail

echo "=== Environment Validation for create-pr-with-automerge ==="
echo ""

# ============================================================================
# OS Validation
# ============================================================================
echo "Checking OS compatibility..."

if [[ "${RUNNER_OS}" != "Linux" ]]; then
  echo "::error::This action only supports Linux runners"
  echo "::error::Current OS: ${RUNNER_OS}"
  exit 1
fi

echo "✓ OS validation passed (Linux)"
echo ""

# ============================================================================
# GitHub CLI Installation Check
# ============================================================================
echo "Checking GitHub CLI installation..."

if ! command -v gh &> /dev/null; then
  echo "::error::GitHub CLI (gh) is not installed"
  echo "::error::Please ensure 'gh' is available in the runner environment"
  exit 1
fi

echo "✓ GitHub CLI (gh) is installed"
gh --version | head -1
echo ""

# ============================================================================
# GitHub CLI Authentication Check
# ============================================================================
echo "Checking GitHub CLI authentication..."

if ! gh auth status &> /dev/null; then
  echo "::error::GitHub CLI is not authenticated"
  echo "::error::Please set GH_TOKEN or GITHUB_TOKEN environment variable"
  exit 1
fi

echo "✓ GitHub CLI is authenticated"
echo ""

# ============================================================================
# GitHub API Rate Limit Check
# ============================================================================
echo "Checking GitHub API rate limit..."

RATE_LIMIT_JSON=$(gh api rate_limit 2>&1) || {
  echo "::error::Failed to check GitHub API rate limit"
  exit 1
}

REMAINING=$(echo "$RATE_LIMIT_JSON" | jq -r '.rate.remaining')
LIMIT=$(echo "$RATE_LIMIT_JSON" | jq -r '.rate.limit')
RESET_TIME=$(echo "$RATE_LIMIT_JSON" | jq -r '.rate.reset')

echo "GitHub API rate limit: $REMAINING / $LIMIT remaining"

# Warn if rate limit is low (less than 10 requests remaining)
if [ "$REMAINING" -lt 10 ]; then
  RESET_DATE=$(date -d "@$RESET_TIME" 2>/dev/null || date -r "$RESET_TIME" 2>/dev/null || echo "unknown")
  echo "::warning::GitHub API rate limit is low: $REMAINING / $LIMIT remaining"
  echo "::warning::Rate limit resets at: $RESET_DATE"

  # Exit with error if completely exhausted
  if [ "$REMAINING" -eq 0 ]; then
    echo "::error::GitHub API rate limit exhausted. Please wait for reset."
    exit 1
  fi
else
  echo "✓ GitHub API rate limit check passed"
fi

echo ""
echo "=== All environment validations passed ==="
