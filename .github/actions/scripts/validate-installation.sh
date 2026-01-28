#!/usr/bin/env bash
# src: ./.github/actions/scripts/validate-installation.sh
# @(#) : Validate GitHub tool installation
#
# Copyright (c) 2026- aglabo <https://github.com/aglabo>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @file validate-installation.sh
# @brief Validate tool installation by running version command
# @description
#   Validates that the installed tool is executable and working correctly
#   by running the version command. The tool must be in BIN_DIR and
#   BIN_DIR must be in PATH.
#
#   **Required Environment Variables:**
#   - TOOL_NAME: Tool binary name
#   - BIN_DIR: Installation directory (added to PATH)
#
#   **Optional Environment Variables:**
#   - VERSION_CMD: Version check command (default: "${TOOL_NAME} --version")
#
# @example
#   # Using command-line arguments
#   ./validate-installation.sh actionlint /tmp/bin "actionlint -version"
#
#   # Using environment variables
#   TOOL_NAME=actionlint BIN_DIR=/tmp/bin VERSION_CMD="actionlint -version" \
#   ./validate-installation.sh
#
# @exitcode 0 Validation succeeds
# @exitcode 5 Validation fails
#
# @author aglabo
# @version 1.0.0
# @license MIT

set -euo pipefail

# Parse arguments with environment variable fallback
readonly TOOL_NAME="${1:-${TOOL_NAME:?Error: TOOL_NAME required (arg 1 or env var)}}"
readonly BIN_DIR="${2:-${BIN_DIR:?Error: BIN_DIR required (arg 2 or env var)}}"
readonly VERSION_CMD="${3:-${VERSION_CMD:-${TOOL_NAME} --version}}"

echo "Verifying installation..."

# Add BIN_DIR to PATH for this check
export PATH="${BIN_DIR}:${PATH}"

if ! eval "${VERSION_CMD}"; then
  echo "::error::Failed to execute version command: ${VERSION_CMD}"
  exit 5
fi

echo "✓ ${TOOL_NAME} is ready to use"
