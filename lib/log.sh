#!/usr/bin/env bash

_Log::Die() {
  local code="$?"
  if [[ "$1" != *[^0-9]* ]]; then
    if [[ "${1}" -le 0 ]] || [[ "${1}" -ge 255 ]]; then
      code=255
      shift
    else 
      code="${1}"
      shift
    fi
  fi
  _Log::Warn "$@"
  exit "$code"
}

_Log::Warn() {
  local fmt="$1"
  printf "\r\033[2K  \033[0;31mCore: %s\033[0m\n" "${fmt}" >&2
}

_Log::Success() {
  local msg="$1"
  printf "\r\033[2K  \033[0;32mCore: %s\033[0m\n" "${msg}"
}

# Exit codes
# 1	Catch-all for general errors
# 2	Misuse of shell builtins 
# 126	Command invoked cannot execute	
# 127	"command not found"
# 128	Invalid argument to exit
# 128+n	Fatal error signal "n"	
# 130	Script terminated by Control-C
# 255*	Exit status out of range