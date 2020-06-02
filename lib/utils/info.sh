#!/usr/bin/env bash

help() {
   echo "Core Help"

   IFS=$'\n' # make newlines the only separator
   set -f    # disable globbing
   for f in $(declare -F); do
       if [[ ! ${f:11} =~ ^_.* ]]; then
           echo "  ${f:11}"
        fi
   done
}