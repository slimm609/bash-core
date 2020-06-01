#!/usr/bin/env bash

_main(){ unused(){ :;} }
shopt -s expand_aliases

_Main::Import() {
  local _Reimport="false"
  [[ ${1} == "-f" ]] && _Reimport="true" && shift
  local _Path="${1}"
  if [[ -d ${_Path} ]]; then
    for _File in "${1}"/*.sh; do
      local _Filename="${_File##*/}"
      if ! declare -F "_${_Filename%.sh}" &>/dev/null; then
        # shellcheck disable=SC2154
        eval "_${_repo_alias}_${_Filename%.sh}(){ unused(){ :;} }"
        builtin source "${_File}"
      fi 
    done
  elif [[ -s "${_Path}" ]] || [[ -s "${_Path}.sh" ]]; then
    [[ -s "${_Path}" ]] && local _LocalPath="${_Path}"
    [[ -s "${_Path}.sh" ]] && local _LocalPath="${_Path}.sh"
    local _Filename="${_LocalPath##*/}"
    if ! declare -F "_${_Filename%.sh}" &>/dev/null || [[ ${_Reimport} == "true" ]]; then
      # shellcheck disable=SC2154
      eval "_${_repo_alias}_${_Filename%.sh}(){ unused(){ :;} }"
      builtin source "${_Path}"
    fi
  fi
}

alias import="_Main::Import"
alias reimport="_Main::Import -f"

# shellcheck disable=SC2154
import "${_core_repo}/lib"
import "${_core_repo}/lib/config"