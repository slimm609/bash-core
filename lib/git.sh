#!/usr/bin/env bash

Git::Fetch-all() {
  local fetchrepo
  cd "${_core_repo}" || _Log::Die 1 "Could not change to core repo"
  if git diff-index --quiet HEAD -- ; then
    for remote in $(git remote -v | awk '{ print $1 }' | sort -u); do
        git fetch "${remote}"
    done
  fi
  for fetchrepo in $(cat "${_core_repo}"/.core_repos); do
    cd "${fetchrepo}" || _Log::Die 1 "Could not change to ${fetchrepo} repo"
    if git diff-index --quiet HEAD -- ; then
        for remote in $(git remote -v | awk '{ print $1 }' | sort -u); do
            git fetch "${remote}"
        done
    fi
  done
}