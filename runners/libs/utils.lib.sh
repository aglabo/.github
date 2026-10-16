#!/usr/bin/env bash
# utils.lib.sh - common utility library for runner scripts
# Provides helpers shared by multiple runners
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Guard against double sourcing
[[ -n "${_UTILS_LIB_SH:-}" ]] && return 0
readonly _UTILS_LIB_SH=1

#
# @description Resolve the global (user) config directory.
#              Use XDG_CONFIG_HOME when it points to an existing directory,
#              otherwise fall back to ${HOME}/.config
# @stdout Path to the config directory; an empty line when no directory exists
# @exitcode 0 always
#
resolve_global_configdir() {
  local __xdg_config="${XDG_CONFIG_HOME:-}"
  local __home_config="${HOME:-}/.config"

  if [[ -n "$__xdg_config" && -d "$__xdg_config" ]]; then
    echo "$__xdg_config"
  elif [[ -n "${HOME:-}" && -d "$__home_config" ]]; then
    echo "$__home_config"
  else
    echo ""
  fi
}
