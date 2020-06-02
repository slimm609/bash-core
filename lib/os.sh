#!/usr/bin/env bash

_os::check() {
  local os
  case "$(uname -s)" in
    Darwin*) 
      os=darwin
      ;;
    Linux*) 
      os=linux 
      ;;
    *) 
      os=unk 
      ;;
  esac
  echo "${os}"
}