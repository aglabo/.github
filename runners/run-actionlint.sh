#!/usr/bin/env bash
# src: runners/run-actionlint.sh
# @(#) : action lint runner
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

# @description Run jactionlint with the global config,
#              or with the checked-in config when the global one is absent
# @arg $@ Arguments forwarded to jactionlint
# @exitcode Exit code of jactionlint
main() {
  local configDir
  configDir="$(resolve_global_configdir)"
  local configFile

  if [[ -z "$configDir" ]]; then
    configFile="${PROJECT_ROOT}/configs/jactionlint.yaml"
  else
    configFile="${configDir}/jactionlint/jactionlint.yaml"
  fi

  jactionlint --config-file "$configFile" "$@"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
