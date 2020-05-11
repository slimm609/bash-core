_Help::Fzf() {
  local -r function_name=${1}
  local found="false"
  if [[ ! -n "$(LC_ALL=C type -t ${function_name})" ]] || [[ "$(LC_ALL=C type -t ${function_name})" != function ]]; then
    if [[ "${core_history:-short}" == "full" ]]; then
      history=$(_History::List ${function_name})
      if [[ ${#history} -gt 0 ]]; then
          _History::List ${function_name} | awk '{ print substr($0, index($0,$2)) }'
          found="true"
      fi
      # clear history for full searches
      history=""
    else
      history=$(_History::List ${function_name})
      if [[ ${#history} -gt 0 ]]; then
          _History::List ${function_name} | awk '{ print $2 }' | uniq
          found="true"
      fi
    fi
    IFS=$'\n' # make newlines the only separator
    set -f    # disable globbing
    for f in $(declare -F); do
      if [[ ${f:11} =~ ${function_name} ]] && [[ ! ${history} =~ ${f:11} ]] && [[ ! ${f:11} =~ ^_.* ]]; then
        echo "${f:11}"
        found="true"
      fi
    done
    if [[ ${found} == "false" ]]; then
      echo "Error: ${function_name} not found"
      exit 255
    fi
    exit 0
  fi
  exit 0
}

# display the help function to show possible options and parameters for each option.
_Help::Help() {
  local -r function_name=${1}
  local found="false"
  if [[ "${function_name}" =~ "--help" ]]; then
    echo "###Help###"
    echo "To list all functions run `core help`"
    echo "To see help for a function run `core \$function --help`"
    exit 0
  fi
  if [[ ! -n "$(LC_ALL=C type -t ${function_name})" ]] || [[ "$(LC_ALL=C type -t ${function_name})" != function ]]; then
    IFS=$'\n' # make newlines the only separator
    set -f    # disable globbing
    for f in $(declare -F); do
      if [[ ${f:11} =~ ${function_name} ]] && [[ ! ${f:11} =~ ^_.* ]]; then
        echo "${f:11}"
        found="true"
      fi
    done
    if [[ ${found} == "false" ]]; then
      echo "Error: ${function_name} is not an option"
      exit 255
    fi
    exit 0
  fi
  echo "Core Help"
  echo "****Auto Generated***"
  echo
  unset options
  options=""
  for input in $(declare -f ${function_name} | grep local | grep -E '=\${[0-9].*}|=\$[0-9].*|="\${[0-9].*}"|="\{[0-9].*"' | awk '{ print $2 }' | awk -F= '{ print $1 }'); do
    options+="${input} "
  done
  echo "Expected input: Core $function_name $options"
}

# automatically provide help when inputs do not match
_Help::Autohelp() {
  local -r function_name=${1}
  unset options
  local required=""
  for input in $(declare -f ${function_name} | grep local | grep -E '=\${[0-9].*}|=\$[0-9].*|="\${[0-9].*}"|="\{[0-9].*"' | grep -v '=\${[0-9]:.*}|="\${[0-9]:.*}"' | awk '{ print $2 }' | awk -F= '{ print $1 }'); do
    required+="${input} "
  done
  local options=""
  for input in $(declare -f ${function_name} | grep local | grep -E '=\${[0-9]:.*}|="\${[0-9]:.*}"' | awk '{ print $2 }' | awk -F= '{ print $1 }'); do
    options+="[${input}] "
  done
  printf "\r\033[2K  [\033[0;31mError\033[0m] Expected input: Core ${function_name} ${required}${options}\n"
}

_Help::Input_count(){
  local -r function_name=${1}
  local override=0
  for input in $(declare -f ${function_name} | grep local | grep -E '=\${@.*}|=\$@|="\${@.*}"|="\$@"' | awk '{ print $2 }' | awk -F= '{ print $1 }'); do
    override=$((override+1))
  done
  if [[ ${override} -gt 0 ]]; then
    override=99
  fi
  #start at one because we want to account for the function itself
  local required=1
  for input in $(declare -f ${function_name} | grep local | grep -E '=\${[0-9].*}|=\$[0-9].*|="\${[0-9].*}"|="\{[0-9].*"' | grep -v '=\${[0-9]:.*}|="\${[0-9]:.*}"' | awk '{ print $2 }' | awk -F= '{ print $1 }'); do
    required=$((required+1))
  done
  local all=1
  for input in $(declare -f ${function_name} | grep local | grep -E '=\${[0-9]:.*}|="\${[0-9]:.*}"' | awk '{ print $2 }' | awk -F= '{ print $1 }'); do
    all=$((all+1))
  done
  echo "$required:$all:$override"
}
