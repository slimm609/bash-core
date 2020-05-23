_Log::Die() {
  local code="$?"
  if [[ "$1" != *[^0-9]* ]]; then
    code="$1"
    shift
  fi
  _Log::Warn "$@"
  exit "$code"
}

_Log::Warn() {
  local fmt="$1"
  printf "\r\033[2K  \033[0;31mCore: ${fmt}\033[0m\n"  >&2
}

_Log::Success() {
  local msg="$1"
  printf "\r\033[2K  \033[0;32mCore: ${msg}\033[0m\n"
}