#!/usr/bin/env bash
# src: ./.github/actions/scripts/validate-os.sh
# @(#) : Validate OS compatibility for GitHub tool installation
#
# Copyright (c) 2026- aglabo <https://github.com/aglabo>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @file validate-os.sh
# @brief Validate OS compatibility (Linux only)
# @description
#   Validates that the runner OS is Linux. This script is designed for
#   GitHub Actions composite actions that install Linux-only binaries.
#
#   **Required Environment Variables:**
#   - RUNNER_OS: OS identifier from GitHub Actions
#
# @example
#   RUNNER_OS=Linux ./validate-os.sh
#
# @exitcode 0 OS is Linux
# @exitcode 1 OS is not Linux
#
# @author aglabo
# @version 1.0.0
# @license MIT

set -euo pipefail

if [[ "${RUNNER_OS}" != "Linux" ]]; then
  echo "::error::This action only supports Linux runners (amd64 architecture)"
  echo "::error::Current OS: ${RUNNER_OS}"
  exit 1
fi

echo "✓ OS validation passed (Linux)"
