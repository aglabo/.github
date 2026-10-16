#!/usr/bin/env bash
# src: runners/run-ghalint.sh
# @(#) : ghalint runner
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1091

set -euo pipefail

# shellcheck source=runners/libs/init-vars.lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/libs/init-vars.lib.sh"

# shellcheck source=runners/libs/utils.lib.sh
. "${SCRIPT_ROOT}/libs/utils.lib.sh"

# @description Run ghalint (run|act) with the global config,
#              or with the checked-in config when the global one is absent
# @arg $1 string Subcommand: run (workflows) or act (actions)
# @arg $@ string Remaining arguments forwarded to ghalint
# @exitcode 0 All checks passed
# @exitcode 1 Lint error or invalid subcommand
main() {
  local subcommand="${1:-}"

  case "$subcommand" in
  run | act)
    shift
    ;;
  *)
    echo "Usage: run-ghalint.sh <run|act> [args...]" >&2
    exit 1
    ;;
  esac

  local -a args=("$@")
  local configDir
  local configFile

  configDir="$(resolve_global_configdir)"

  if [[ -z "$configDir" ]]; then
    configFile="${PROJECT_ROOT}/configs/ghalint.yaml"
  else
    configFile="${configDir}/linters/ghalint/ghalint.yaml"
  fi

  pnpm exec ghalint "$subcommand" --config "$configFile" "${args[@]+"${args[@]}"}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
