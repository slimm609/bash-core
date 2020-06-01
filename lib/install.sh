#!/usr/bin/env bash

Install::Git() {
  local _cmd="${1:-core}"
  local _path="${REPO}/core"
  pushd "$(git --exec-path)" >/dev/null || exit 
  if [[ -w git-fetch ]]; then
    if [[ -e git-"${_cmd}" ]] && [[ ! -L git-"${_cmd}" ]]; then
      _Log::Die 255 "git-${_cmd} exists and is not a symlink"
    else
      rm -f git-"${_cmd}"
    fi
    ln -s "${_path}" git-"${_cmd}"
    _Log::Success "git-${_cmd} installed successfully"
  else
    _Log::Die 254 "Git exec path not writable!"
  fi
}

Install::Path() {
  if ! [[ ":${PATH}:" == *":${REPO}:"* ]]; then
    echo "Path: \"export PATH=${REPO}/:\$PATH\""
  fi
}

Install::Completion() {
 echo "add 'source <(core _completion)' to your bashrc/zshrc"
}