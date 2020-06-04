#!/usr/bin/env bash

_Main::ctrl_c() {
  # Exit with the proper code when Ctrl+C is pressed
  exit 130
}

trap _Main::ctrl_c INT

_main(){ unused(){ :;} }
shopt -s expand_aliases

_Main::Relpath() {
    local -r source=${1}
    local -r target=${2}

    local common_part=${source}
    local result=""

    while [[ "${target#"$common_part"}" == "${target}" ]]; do
        common_part=$(dirname "${common_part}")
        if [[ -z "${result}" ]]; then
            result=..
        else
            result=../${result}
        fi
    done

    forward_part=${target#"$common_part"}

    if [[ -n "${result}" ]] && [[ -n "${forward_part}" ]]; then
        result=${result}${forward_part}
    elif [[ -n "${forward_part}" ]]; then
        result=${forward_part#?}
    fi

    printf '%s\n' "${result}"
}

_Main::Import() {
  local _Reimport="false"
  [[ ${1} == "-f" ]] && _Reimport="true" && shift
  local _Path="${1}"
  local _relpath
  if [[ -d ${_Path} ]]; then
    for _File in "${1}"/*; do
      if [[ -f "${_File}" ]] && [[ "${_File}" == *.sh ]]; then
        local _Filename="${_File##*/}"
        # shellcheck disable=SC2154
        _relpath=$(_Main::Relpath "${_curr_repo}" "${_Path}")
        # shellcheck disable=SC2154
        if ! declare -F "_${_repo_alias}_${_relpath}_${_Filename%.sh}" &>/dev/null; then
          eval "_${_repo_alias}_${_relpath}_${_Filename%.sh}(){ unused(){ :;} }"
          builtin source "${_File}"
        fi 
      elif [[ -d ${_File} ]]; then
        _Main::Import "${_File}"
      fi
    done
  elif [[ -s "${_Path}" ]] || [[ -s "${_Path}.sh" ]]; then
    [[ -s "${_Path}" ]] && local _LocalPath="${_Path}"
    [[ -s "${_Path}.sh" ]] && local _LocalPath="${_Path}.sh"
    local _Filename="${_LocalPath##*/}"
    local _FilePath="${_LocalPath%/*}"
    _relpath=$(_Main::Relpath "${_curr_repo}" "${_FilePath}")
    if ! declare -F "_${_repo_alias}_${_relpath}_${_Filename%.sh}" &>/dev/null || [[ ${_Reimport} == "true" ]]; then
      # shellcheck disable=SC2154
      eval "_${_repo_alias}_${_relpath}_${_Filename%.sh}(){ unused(){ :;} }"
      builtin source "${_Path}"
    fi
  fi
}

alias import="_Main::Import"
alias reimport="_Main::Import -f"

# shellcheck disable=SC2154
import "${_core_repo}/lib"
import "${_core_repo}/lib/config"