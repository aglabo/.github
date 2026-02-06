#!/usr/bin/env bash
# src: ./.github/actions/validate-environment/tests/assert-outputs.sh
# @(#) : Helper script to validate action outputs
#
# Copyright (c) 2025- aglabo <https://github.com/aglabo>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -euo pipefail

# Usage: assert-outputs.sh <expected-status> <actual-status> <message> <validated-apps> <validated-count>
#
# Arguments:
#   $1: expected-status    - Expected status value ('success' or 'error')
#   $2: actual-status      - Actual status value from action
#   $3: message            - Message output from action
#   $4: validated-apps     - Comma-separated list of validated apps
#   $5: validated-count    - Count of validated apps
#
# Exit codes:
#   0: All validations passed
#   1: Validation failure

EXPECTED_STATUS="${1:-}"
ACTUAL_STATUS="${2:-}"
MESSAGE="${3:-}"
VALIDATED_APPS="${4:-}"
VALIDATED_COUNT="${5:-}"

# Validation functions
validate_status_match() {
  if [ "$ACTUAL_STATUS" != "$EXPECTED_STATUS" ]; then
    echo "::error::Status mismatch: expected '$EXPECTED_STATUS', got '$ACTUAL_STATUS'"
    return 1
  fi
}

validate_message_nonempty() {
  if [ -z "$MESSAGE" ]; then
    echo "::error::Message must not be empty"
    return 1
  fi
}

validate_success_outputs() {
  if [ "$EXPECTED_STATUS" != "success" ]; then
    return 0
  fi

  # Validate validated-apps contains expected default apps
  if ! echo "$VALIDATED_APPS" | grep -q "Git"; then
    echo "::error::validated-apps must contain 'Git', got: $VALIDATED_APPS"
    return 1
  fi

  if ! echo "$VALIDATED_APPS" | grep -q "curl"; then
    echo "::error::validated-apps must contain 'curl', got: $VALIDATED_APPS"
    return 1
  fi

  # Validate count >= 2 (at least Git and curl)
  if [ "$VALIDATED_COUNT" -lt 2 ]; then
    echo "::error::validated-count must be >= 2, got: $VALIDATED_COUNT"
    return 1
  fi

  # Validate comma-separated list format
  if [[ ! "$VALIDATED_APPS" =~ ^[a-zA-Z0-9._-]+(,[a-zA-Z0-9._-]+)*$ ]]; then
    echo "::error::validated-apps format invalid: $VALIDATED_APPS"
    return 1
  fi

  # Validate count is positive integer
  if [[ ! "$VALIDATED_COUNT" =~ ^[0-9]+$ ]]; then
    echo "::error::validated-count must be positive integer, got: $VALIDATED_COUNT"
    return 1
  fi
}

# Run all validations
validate_status_match
validate_message_nonempty
validate_success_outputs

echo "::notice::All output validations passed"
exit 0
