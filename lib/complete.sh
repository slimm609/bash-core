#/usr/bin/env bash

_core_help() {
   IFS=$'\n' # make newlines the only separator
   set -f    # disable globbing
   for f in $(declare -F); do
       if [[ ! ${f:11} =~ ^_.* ]]; then
           string+=" ${f:11}" # build string of options
        fi
   done
   echo $string | sed -e 's/^[[:space:]]*//' # trim spaces
}

_completion() {
  local shell=${1:-bash}
  if [[ "$shell" == "zsh" ]]; then
    echo "autoload bashcompinit"
    echo "bashcompinit"
  fi 

cat <<EOF
_core_completions() {
  comp_list="$(_core_help)"
  if [ \${#COMP_WORDS[@]} -ge 2 ] && [ "\${COMP_WORDS[1]}" =~ \$(echo ^\(\$(echo \$comp_list | sed 's/ /|/g')\$\)) ]; then
    return
  fi

  COMPREPLY=(\$(compgen -W "\$comp_list" -- "\${COMP_WORDS[1]}"))
}

complete -F _core_completions core
export LC_ALL="en_US.UTF-8"
EOF
}