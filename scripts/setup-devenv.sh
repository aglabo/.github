#!/usr/bin/env bash
# src: ./scripts/prepare.sh
# @(#) : Setup development environment and install tools
#
# Copyright (c) 2025 aglabo <https://github.com/aglabo>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
#
# @file prepare.sh
# @brief Install and update development tools
# @description
#   Manages development tools installation in .tools/ directory.
#   Supports multiple tools with consistent install/update pattern.
#
#   **Supported Tools:**
#   - Lefthook: Git hooks manager (installs hooks if not present)
#   - ShellSpec: BDD-style testing framework for shell scripts
#
#   **Features:**
#   - Modular design: each tool has dedicated install/setup functions
#   - Idempotent: safe to run multiple times (skips if already installed)
#   - Extensible: easy to add new tools
#
# @usage
#   ./scripts/setup-devenv.sh              # Setup all tools
#   ./scripts/setup-devenv.sh lefthook     # Setup only lefthook
#   ./scripts/setup-devenv.sh shellspec    # Setup only ShellSpec
#
# @exitcode 0 All tools installed/updated successfully
# @exitcode 1 Installation/update failed
#
# @author   aglabo
# @version  1.0.0
# @license  MIT

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

TOOLS_DIR=".tools"

# ShellSpec configuration
readonly SHELLSPEC_DIR="${TOOLS_DIR}/shellspec"
readonly SHELLSPEC_REPO="https://github.com/shellspec/shellspec.git"
readonly SHELLSPEC_VERSION="master"  # or specific version tag like "0.28.1"

# Lefthook configuration
readonly LEFTHOOK_CONFIG="lefthook.yml"
readonly GIT_HOOKS_DIR=".git/hooks"

# ============================================================================
# Helper Functions
# ============================================================================

# @description Print colored status message
# @arg $1 string Message type (info, success, error, warning)
# @arg $2 string Message text
print_status() {
  local type="$1"
  local message="$2"

  case "$type" in
    info)
      echo "📦 ${message}"
      ;;
    success)
      echo "✓ ${message}"
      ;;
    error)
      echo "✗ ${message}" >&2
      ;;
    warning)
      echo "⚠ ${message}" >&2
      ;;
  esac
}

# @description Create tools directory if it doesn't exist
ensure_tools_dir() {
  if [ ! -d "${TOOLS_DIR}" ]; then
    mkdir -p "${TOOLS_DIR}"
    print_status info "Created tools directory: ${TOOLS_DIR}"
  fi
}

# ============================================================================
# ShellSpec Installation Functions
# ============================================================================

# @description Check if ShellSpec is already installed
# @exitcode 0 ShellSpec is installed and functional
# @exitcode 1 ShellSpec is not installed or broken
shellspec_check() {
  [ -d "${SHELLSPEC_DIR}" ] && [ -x "${SHELLSPEC_DIR}/shellspec" ]
}

# @description Install ShellSpec from GitHub
# @exitcode 0 Installation successful
# @exitcode 1 Installation failed
shellspec_install() {
  print_status info "Installing ShellSpec..."

  ensure_tools_dir

  if ! git clone --depth 1 --branch "${SHELLSPEC_VERSION}" \
       "${SHELLSPEC_REPO}" "${SHELLSPEC_DIR}" >/dev/null 2>&1; then
    print_status error "Failed to clone ShellSpec repository"
    return 1
  fi

  print_status success "ShellSpec installed to ${SHELLSPEC_DIR}"
  return 0
}

# @description Display ShellSpec version and location
shellspec_info() {
  if [ -x "${SHELLSPEC_DIR}/shellspec" ]; then
    local version
    version=$("${SHELLSPEC_DIR}/shellspec" --version 2>&1 | head -1 || echo "unknown")
    print_status info "ShellSpec version: ${version}"
    print_status info "Location: ${SHELLSPEC_DIR}"
  else
    print_status warning "ShellSpec executable not found"
  fi
}

# @description Setup ShellSpec (install if not present)
# @exitcode 0 Operation successful (installed or already present)
# @exitcode 1 Installation failed
shellspec_setup() {
  # Check if ShellSpec is already installed
  if shellspec_check; then
    print_status success "ShellSpec is already installed"
    shellspec_info
    return 0
  fi

  # Check if directory exists but is broken
  if [ -d "${SHELLSPEC_DIR}" ]; then
    print_status warning "ShellSpec directory exists but is not functional"
    print_status info "Removing and reinstalling..."
    rm -rf "${SHELLSPEC_DIR}"
  fi

  # Install ShellSpec
  if ! shellspec_install; then
    return 1
  fi

  shellspec_info
  return 0
}

# ============================================================================
# Lefthook Git Hooks Setup Functions
# ============================================================================

# @description Check if lefthook command is available
# @exitcode 0 lefthook command is available
# @exitcode 1 lefthook is not installed
lefthook_check_command() {
  command -v lefthook &> /dev/null
}

# @description Check if lefthook hooks are installed in .git/hooks
# @exitcode 0 Hooks are installed
# @exitcode 1 Hooks are not installed
lefthook_check_install() {
  # Check if git hooks directory exists and contains lefthook hooks
  if [ ! -d "${GIT_HOOKS_DIR}" ]; then
    return 1
  fi

  # Check if pre-commit hook exists and is from lefthook
  if [ -f "${GIT_HOOKS_DIR}/pre-commit" ]; then
    if grep -q "LEFTHOOK" "${GIT_HOOKS_DIR}/pre-commit" 2>/dev/null; then
      return 0
    fi
  fi

  return 1
}

# @description Install lefthook git hooks via 'lefthook install'
# @exitcode 0 Installation successful
# @exitcode 1 Installation failed
lefthook_install() {
  print_status info "Setting up lefthook git hooks..."

  if ! lefthook install >/dev/null 2>&1; then
    print_status error "Failed to install lefthook hooks"
    return 1
  fi

  print_status success "Lefthook git hooks configured"
  return 0
}

# @description Display lefthook version and hook status
lefthook_info() {
  if lefthook_check_command; then
    local version
    version=$(lefthook version 2>&1 || echo "unknown")
    print_status info "Lefthook version: ${version}"
  fi

  if lefthook_check_install; then
    print_status info "Git hooks: configured"
  else
    print_status warning "Git hooks: not configured"
  fi
}

# @description Setup lefthook (configure hooks if not present)
# @exitcode 0 Operation successful (configured or already present)
# @exitcode 1 Setup failed
lefthook_setup() {
  # Check if lefthook command is available
  if ! lefthook_check_command; then
    print_status error "lefthook command not found"
    print_status info "Please install lefthook: https://github.com/evilmartians/lefthook"
    return 1
  fi

  # Check if lefthook.yml exists
  if [ ! -f "${LEFTHOOK_CONFIG}" ]; then
    print_status error "lefthook.yml not found in repository root"
    return 1
  fi

  # Check if hooks are already configured
  if lefthook_check_install; then
    print_status success "Lefthook git hooks are already configured"
    lefthook_info
    return 0
  fi

  # Configure hooks via lefthook install
  if ! lefthook_install; then
    return 1
  fi

  lefthook_info
  return 0
}

# ============================================================================
# Tool Registry
# ============================================================================

# @description List of all available tools with their setup functions
# Format: "tool_name:setup_function_name"
declare -a AVAILABLE_TOOLS=(
  "lefthook:lefthook_setup"
  "shellspec:shellspec_setup"
)

# @description Setup specific tool by name
# @arg $1 string Tool name
# @exitcode 0 Tool setup successful
# @exitcode 1 Tool setup failed or tool not found
setup_tool() {
  local tool_name="$1"
  local found=0

  for tool_entry in "${AVAILABLE_TOOLS[@]}"; do
    local name="${tool_entry%%:*}"
    local setup_func="${tool_entry#*:}"

    if [ "${name}" = "${tool_name}" ]; then
      found=1
      echo ""
      echo "=== Setting up ${tool_name} ==="
      if ! "${setup_func}"; then
        print_status error "Failed to setup ${tool_name}"
        return 1
      fi
      break
    fi
  done

  if [ $found -eq 0 ]; then
    print_status error "Unknown tool: ${tool_name}"
    print_status info "Available tools: $(list_tools)"
    return 1
  fi

  return 0
}

# @description List all available tool names
# @stdout Comma-separated list of tool names
list_tools() {
  local tools=()
  for tool_entry in "${AVAILABLE_TOOLS[@]}"; do
    tools+=("${tool_entry%%:*}")
  done

  local IFS=','
  echo "${tools[*]}"
}

# @description Setup all available tools
# @exitcode 0 All tools setup successful
# @exitcode 1 One or more tools failed
setup_all_tools() {
  local failed=0

  for tool_entry in "${AVAILABLE_TOOLS[@]}"; do
    local name="${tool_entry%%:*}"
    if ! setup_tool "${name}"; then
      failed=1
    fi
  done

  return $failed
}

# ============================================================================
# Main Execution
# ============================================================================

# @description Display usage information
show_usage() {
  cat <<EOF
Usage: $(basename "$0") [TOOL_NAME]

Setup development environment and install tools.

Arguments:
  TOOL_NAME    Optional. Name of specific tool to setup.
               If omitted, all tools will be setup.

Available tools:
  $(list_tools)

Examples:
  $(basename "$0")              # Setup all tools
  $(basename "$0") lefthook     # Setup only lefthook
  $(basename "$0") shellspec    # Setup only ShellSpec

EOF
}

# @description Main entry point
# @arg $@ Optional tool names to setup
main() {
  # Handle help flag
  if [ $# -gt 0 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; then
    show_usage
    exit 0
  fi

  echo "=== Development Environment Setup ==="

  local exit_code=0

  if [ $# -eq 0 ]; then
    # No arguments - setup all tools
    if ! setup_all_tools; then
      exit_code=1
    fi
  else
    # Setup specific tools
    for tool_name in "$@"; do
      if ! setup_tool "${tool_name}"; then
        exit_code=1
      fi
    done
  fi

  echo ""
  if [ $exit_code -eq 0 ]; then
    echo "=== Setup completed successfully ==="
    echo ""
    echo "Next steps:"
    echo "  - Lefthook: Git hooks are now active (pre-commit, prepare-commit-msg)"
    echo "  - ShellSpec: Create spec files in spec/ directory"
    echo "  - Run tests: .tools/shellspec/shellspec"
  else
    echo "=== Setup completed with errors ==="
  fi

  exit $exit_code
}

main "$@"
