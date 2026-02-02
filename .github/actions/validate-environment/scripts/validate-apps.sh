#!/usr/bin/env bash
# src: ./.github/actions/validate-environment/scripts/validate-apps.sh
# @(#) : Validate required applications (Git, curl, gh CLI)
#
# Copyright (c) 2026- aglabo <https://github.com/aglabo>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @file validate-apps.sh
# @brief Validate required applications for GitHub Actions with safe version extraction
# @description
#   Validates that required applications are installed with configurable fail-fast behavior.
#   Uses SAFE extraction methods WITHOUT eval - prevents arbitrary code execution.
#
#   **Default Checks:**
#   1. Git is installed (version 2.30+ required)
#   2. curl is installed
#   3. gh (GitHub CLI) is installed (version 2.0+ required)
#
#   **Features:**
#   - Gate action design: exits immediately on first validation error
#   - Generic version checking using sort -V (handles semver, prerelease, etc.)
#   - Safe declarative version extraction (NO EVAL)
#   - Backward compatible with field-number extraction (legacy)
#   - Machine-readable outputs for downstream actions
#   - Extensible: additional applications can be specified as arguments
#
#   **Version Extraction (Security Hardened):**
#   - Prefix-typed extractors: field:N or regex:PATTERN (explicit method declaration)
#   - sed-only with # delimiter (allows / in patterns)
#   - NO eval usage - prevents arbitrary code execution
#   - Input validation: Rejects shell metacharacters, control chars, sed delimiter (#)
#   - sed injection prevention: # character rejection prevents breaking out of pattern
#   - Examples: "regex:version ([0-9.]+)" extracts version number from "git version 2.52.0"
#
#   **Environment Variables:**
#   - FAIL_FAST: Internal implementation detail (always true for gate behavior)
#   - GITHUB_OUTPUT: Output file for GitHub Actions (optional, fallback to /dev/null)
#
#   **Outputs (machine-readable):**
#   - status: "success" or "error"
#   - message: Human-readable summary
#   - validated_apps: Comma-separated list of validated app names
#   - validated_count: Number of successfully validated apps
#   - failed_apps: Comma-separated list of failed app names (on error)
#   - failed_count: Number of failed apps
#
# @exitcode 0 Application validation successful
# @exitcode 1 Application validation failed (one or more apps missing or invalid)
#
# @author   atsushifx
# @version  3.0.0
# @license  MIT

set -euo pipefail

# Safe output file handling - fallback to /dev/null if not in GitHub Actions
GITHUB_OUTPUT_FILE="${GITHUB_OUTPUT:-/dev/null}"

# Fail-fast mode: INTERNAL ONLY (not exposed as action input)
# This action is a gate - errors mean the workflow cannot continue
# Always defaults to true (fail on first error)
FAIL_FAST="${FAIL_FAST:-true}"

# Error tracking (used only when FAIL_FAST=false for internal testing/debugging)
declare -a VALIDATION_ERRORS=()

# Validated applications (populated by validate_apps function)
declare -a VALIDATED_APPS=()        # Application names only
declare -a VALIDATED_VERSIONS=()    # Version strings only

# Extract version number from full version string
# Parameters: $1=full_version (e.g., "git version 2.52.0"), $2=version_extractor
# Returns: extracted version number to stdout (e.g., "2.52.0")
# Note: Safe extraction using sed only - no eval, prefix-typed extractors only
#
# Supported formats (prefix-typed):
#   field:N         - Extract Nth field (space-delimited, 1-indexed)
#   regex:PATTERN   - sed -E 's/PATTERN/\1/' with capture group
#   (empty)         - Default: extract semver (X.Y or X.Y.Z)
#
# Examples:
#   extract_version_number "git version 2.52.0" "field:3"                    → "2.52.0"
#   extract_version_number "git version 2.52.0" "regex:.*version ([0-9.]+).*" → "2.52.0"
#   extract_version_number "node v18.0.0" "regex:v([0-9.]+)"                 → "18.0.0"
#   extract_version_number "curl 8.17.0" ""                                  → "8.17.0" (auto semver)
extract_version_number() {
  local full_version="$1"
  local version_extractor="$2"

  # Default: extract semver (X.Y or X.Y.Z) if extractor is empty
  if [ -z "$version_extractor" ]; then
    local extracted
    extracted=$(echo "$full_version" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)

    if [ -z "$extracted" ]; then
      echo "::error::Version extraction failed - no semver pattern found in: $full_version" >&2
      return 1
    fi

    echo "$extracted"
    return 0
  fi

  # Parse extractor format: method:argument
  local method="${version_extractor%%:*}"
  local argument="${version_extractor#*:}"

  case "$method" in
    field)
      # Extract Nth field (space-delimited)
      if [[ ! "$argument" =~ ^[0-9]+$ ]]; then
        echo "::error::Invalid field number: $argument" >&2
        return 1
      fi
      echo "$full_version" | cut -d' ' -f"$argument"
      ;;

    regex)
      # Extract using sed -E regex with capture group
      # Use # delimiter to allow / in regex patterns
      if [ -z "$argument" ]; then
        echo "::error::Empty regex pattern" >&2
        return 1
      fi

      # Security: Validate regex pattern to prevent injection
      # Reject our delimiter (#) to prevent breaking out of sed pattern
      if [[ "$argument" == *"#"* ]]; then
        echo "::error::Regex pattern cannot contain '#' character (reserved as sed delimiter): $argument" >&2
        return 1
      fi

      # Reject shell metacharacters that shouldn't appear in version extraction regex
      if [[ "$argument" =~ [\;\|\&\$\`\\] ]]; then
        echo "::error::Regex pattern contains dangerous shell metacharacters: $argument" >&2
        return 1
      fi

      # Reject newlines and control characters
      if [[ "$argument" =~ $'\n'|$'\r'|$'\t' ]]; then
        echo "::error::Regex pattern contains control characters" >&2
        return 1
      fi

      local extracted
      extracted=$(echo "$full_version" | sed -E "s#${argument}#\1#")

      # Check if extraction succeeded (result differs from input)
      if [ "$extracted" = "$full_version" ]; then
        echo "::error::Version extraction failed - pattern did not match: $argument" >&2
        echo "::error::Full version string: $full_version" >&2
        return 1
      fi

      echo "$extracted"
      ;;

    *)
      echo "::error::Unknown extraction method: $method (expected: field, regex)" >&2
      return 1
      ;;
  esac
}

# Check version meets minimum requirement (pure comparison function)
# Parameters: $1=version (e.g., "2.52.0"), $2=min_version (e.g., "2.30")
# Returns: 0 if version >= min_version, 1 if version < min_version
# Note: Uses sort -V for stable version comparison (handles semver, prerelease, etc.)
#       Requires GNU coreutils (available on all GitHub-hosted runners)
check_version() {
  local version="$1"
  local min_version="$2"

  # Use sort -V (version sort) to compare
  # If min_version comes first or equal, version meets requirement
  # printf outputs: min_version, version (in that order)
  # sort -V sorts them in version order
  # If first line after sort == min_version, then version >= min_version
  local sorted_min=$(printf '%s\n%s\n' "$min_version" "$version" | sort -V | head -1)

  if [ "$sorted_min" = "$min_version" ]; then
    return 0  # version >= min_version
  else
    return 1  # version < min_version
  fi
}

# Validate applications from list
# Parameters: $@ = array of app definitions (cmd|app_name|version_extractor|min_version)
# Side effects: Populates global VALIDATED_APPS and VALIDATED_VERSIONS arrays,
#               updates VALIDATION_ERRORS on errors
#
# Version extractor formats (prefix-typed):
#   - field:N = Extract Nth field from --version output (space-delimited)
#   - regex:PATTERN = sed -E regex with capture group (\1)
validate_apps() {
  local -a app_list=("$@")

  for app_def in "${app_list[@]}"; do
    # Parse app definition: cmd|app_name|version_extractor|min_version
    # Fixed 4-element format with pipe delimiter (no regex conflicts)
    IFS='|' read -r cmd app_name version_extractor min_ver <<< "$app_def"

    # Security: Validate command name (reject shell metacharacters)
    if [[ "$cmd" =~ [\;\|\&\$\`\(\)\ \t] ]]; then
      echo "::error::Invalid command name contains shell metacharacters: $cmd" >&2
      if [ "$FAIL_FAST" = "true" ]; then
        echo "status=error" >> "$GITHUB_OUTPUT_FILE"
        echo "message=Invalid command name: $cmd" >> "$GITHUB_OUTPUT_FILE"
        exit 1
      else
        VALIDATION_ERRORS+=("Invalid command name: $cmd")
        continue
      fi
    fi

    # Check if command exists (avoid subshell to preserve VALIDATION_ERRORS array)
    echo "Checking ${app_name}..." >&2

    if ! command -v "$cmd" &> /dev/null; then
      local error_msg="${app_name} is not installed"
      echo "::error::${error_msg}" >&2

      if [ "$FAIL_FAST" = "true" ]; then
        echo "status=error" >> "$GITHUB_OUTPUT_FILE"
        echo "message=${app_name} not exist" >> "$GITHUB_OUTPUT_FILE"
        exit 1
      else
        VALIDATION_ERRORS+=("${error_msg}")
        continue  # Skip to next app
      fi
    fi

    # Get full version string
    local VERSION=$("$cmd" --version 2>&1 | head -1)
    echo "  ✓ ${VERSION}" >&2
    echo "" >&2

    # Store app name and version separately (structured data)
    VALIDATED_APPS+=("${app_name}")
    VALIDATED_VERSIONS+=("${VERSION}")

    # Check minimum version if min_ver is specified
    # (version_extractor defaults to semver auto-extraction if empty)
    if [ -n "$min_ver" ]; then
      # Extract version number from full version string
      local version_num=$(extract_version_number "$VERSION" "$version_extractor")

      # Validate version against minimum requirement
      if ! check_version "$version_num" "$min_ver"; then
        local error_msg="${app_name} version ${version_num} is below minimum required ${min_ver}"
        echo "::error::${error_msg}" >&2

        if [ "$FAIL_FAST" = "true" ]; then
          echo "status=error" >> "$GITHUB_OUTPUT_FILE"
          echo "message=${error_msg}" >> "$GITHUB_OUTPUT_FILE"
          exit 1
        else
          VALIDATION_ERRORS+=("${error_msg}")
          continue  # Skip to next app
        fi
      fi
    else
      # Version check skipped (no extractor or min_version specified)
      echo "  ::warning::${app_name}: version check skipped (no minimum version specified)" >&2
    fi
  done
}

echo "=== Validating Required Applications ==="
echo ""

# Default application definitions: cmd|app_name|version_extractor|min_version
# Format: "command|app_name|version_extractor|min_version"
# - command: The command to check (e.g., "git", "curl")
# - app_name: Display name for the application (e.g., "Git", "curl")
# - version_extractor: Safe extraction method (NO EVAL):
#     * field:N = Extract Nth field (space-delimited, 1-indexed)
#     * regex:PATTERN = sed -E regex with capture group (\1)
#     * Empty string = auto-extract semver (X.Y or X.Y.Z)
# - min_version: Minimum required version (triggers ERROR and exit 1 if lower)
#     * Empty string = skip version check
#
# Delimiter: | (pipe) to avoid conflicts with regex patterns
#
# Examples:
#   "git|Git|field:3|2.30"                              - Extract 3rd field, check min 2.30
#   "curl|curl||"                                       - No version check (both empty)
#   "gh|gh|regex:version ([0-9.]+)|2.0"                 - sed regex with capture group
#   "node|Node.js|regex:v([0-9.]+)|18.0"                - Extract after 'v' prefix
#
# Security advantages:
#   - NO eval usage - prevents arbitrary code execution
#   - sed only - safe and standard
#   - Prefix-typed extractors (field:/regex:) - explicit and auditable
#   - Pipe delimiter - no conflict with regex patterns or colons
declare -a DEFAULT_APPS=(
  "git|Git|field:3|2.30"                   # Extract 3rd field, check min 2.30
  "curl|curl||"                            # No version check
)

# Always check default apps, add command line arguments if provided
declare -a APPS=("${DEFAULT_APPS[@]}")
if [ $# -gt 0 ]; then
  APPS+=("$@")
fi

# Validate all applications (populates VALIDATED_VERSIONS and VALIDATION_ERRORS arrays)
validate_apps "${APPS[@]}"

# Check for collected errors (in collect-errors mode)
if [ ${#VALIDATION_ERRORS[@]} -gt 0 ]; then
  echo "=== Application validation failed ==="
  echo "::error::Application validation failed with ${#VALIDATION_ERRORS[@]} error(s):"

  # Extract failed app names from error messages
  declare -a FAILED_APPS=()
  for error in "${VALIDATION_ERRORS[@]}"; do
    echo "::error::  - ${error}"
    # Extract app name from error message (before " is not installed" or " version")
    failed_app=$(echo "$error" | sed -E 's/ (is not installed|version).*//')
    FAILED_APPS+=("$failed_app")
  done

  # Combine all errors into a single message
  IFS='; '
  error_summary="${VALIDATION_ERRORS[*]}"
  IFS=' '  # Reset IFS

  # Machine-readable output for GitHub Actions
  echo "status=error" >> "$GITHUB_OUTPUT_FILE"
  echo "message=Application validation failed: ${error_summary}" >> "$GITHUB_OUTPUT_FILE"

  # Additional structured outputs
  IFS=','
  echo "failed_apps=${FAILED_APPS[*]}" >> "$GITHUB_OUTPUT_FILE"
  IFS=' '  # Reset IFS
  echo "failed_count=${#FAILED_APPS[@]}" >> "$GITHUB_OUTPUT_FILE"
  echo "validated_count=${#VALIDATED_APPS[@]}" >> "$GITHUB_OUTPUT_FILE"

  exit 1
fi

# Create human-readable summary message
declare -a summary_parts=()
for i in "${!VALIDATED_APPS[@]}"; do
  summary_parts+=("${VALIDATED_APPS[$i]} ${VALIDATED_VERSIONS[$i]}")
done

IFS=', '
all_versions="${summary_parts[*]}"
IFS=' '  # Reset IFS

echo "=== Application validation passed ==="

# Machine-readable output for GitHub Actions
echo "status=success" >> "$GITHUB_OUTPUT_FILE"
echo "message=Applications validated: ${all_versions}" >> "$GITHUB_OUTPUT_FILE"

# Additional structured outputs (use structured arrays directly)
IFS=','
echo "validated_apps=${VALIDATED_APPS[*]}" >> "$GITHUB_OUTPUT_FILE"
IFS=' '  # Reset IFS
echo "validated_count=${#VALIDATED_APPS[@]}" >> "$GITHUB_OUTPUT_FILE"
echo "failed_count=0" >> "$GITHUB_OUTPUT_FILE"

exit 0
