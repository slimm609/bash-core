#!/usr/bin/env bash

Enable::Repo() {
# Are we currently in a git repo, that is not core? 
if git rev-parse --show-toplevel &> /dev/null; then
  _enable_repo=$(git rev-parse --show-toplevel)
  # shellcheck disable=SC2154
  if [[ "${_enable_repo}" != "${_core_repo}" ]]; then
    if [[ ! -f "${_enable_repo}/.core_enabled" ]]; then 
      #enable repo
      touch "${_enable_repo}"/.core_enabled
      if [[ -f "${_enable_repo}/.gitignore" ]]; then
        grep -q ".core_history" "${_enable_repo}"/.gitignore || echo -en "\n#Ignore history\n.core_history" >> "${_enable_repo}"/.gitignore 
      else
        echo -en "\n#Ignore history\n.core_history" >> "${_enable_repo}"/.gitignore
      fi
    else
      _Log::Die 1 "Repo is already enabled for core support"
    fi
  else
    _Log::Die 1 "Core repo is already enabled"
  fi
else
  _Log::Die 1 "Not in a git repo"
fi
}