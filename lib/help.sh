#!/usr/bin/env bash

_Help::Fzf() {
  local -r function_name=${1}
  local found="false"
  if [[ -z "$(LC_ALL=C type -t "${function_name}")" ]] || [[ "$(LC_ALL=C type -t "${function_name}")" != function ]]; then
    if [[ "${core_history:-short}" == "full" ]]; then
      history=$(_History::List "${function_name}")
      if [[ ${#history} -gt 0 ]]; then
          _History::List "${function_name}" | awk '{ print substr($0, index($0,$2)) }'
          found="true"
      fi
      # clear history for full searches
      history=""
    else
      history=$(_History::List "${function_name}")
      if [[ ${#history} -gt 0 ]]; then
          _History::List "${function_name}" | awk '{ print $2 }' | uniq
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
    # if not found, split and search on the first letter of each part
    if [[ ${found} == "false" ]]; then
      IFS=':' read -r -a func <<< "${function_name}"
      for f in $(declare -F); do
        if [[ ${#func[@]} -eq 2 ]]; then
          if [[ ${f:11} == "${func[0]:0:1}"*:"${func[1]:0:1}"* ]]; then
            echo "${f:11}"
            found="true"
          fi
        elif [[ ${#func[@]} -eq 3 ]]; then
          if [[ ${f:11} == "${func[0]:0:1}"*:"${func[1]:0:1}"*:"${func[2]:0:1}"* ]]; then
            echo "${f:11}"
            found="true"
          fi
        fi
      done
    fi
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
    echo "To list all functions run \`core help\`"
    echo "To see help for a function run \`core \$function --help\`"
    exit 0
  fi
  if [[ -z "$(LC_ALL=C type -t "${function_name}")" ]] || [[ "$(LC_ALL=C type -t "${function_name}")" != function ]]; then
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
  # shellcheck disable=SC2016
  for input in $(declare -f "${function_name}" | grep local | grep -E '=\${[0-9].*}|=\$[0-9].*|="\${[0-9].*}"|="\{[0-9].*"' | awk -F= '{ print $1 }' | awk '{print $NF}'); do
    options+="${input} "
  done
  echo "Expected input: Core $function_name $options"
}

# automatically provide help when inputs do not match
_Help::Autohelp() {
  local -r function_name=${1}
  unset options
  local required=""
  # shellcheck disable=SC2016
  for input in $(declare -f "${function_name}" | grep local | grep -E '=\${[0-9].*}|=\$[0-9].*|="\${[0-9].*}"|="\{[0-9].*"' | grep -Ev '=\${[0-9]:.*}|="\${[0-9]:.*}"' | awk -F= '{ print $1 }' | awk '{print $NF}'); do
    required+="${input} "
  done
  local options=""
  # shellcheck disable=SC2016
  for input in $(declare -f "${function_name}" | grep local | grep -E '=\${[0-9]:.*}|="\${[0-9]:.*}"' | awk -F= '{ print $1 }' | awk '{print $NF}'); do
    options+="[${input}] "
  done
  printf "\r\033[2K  [\033[0;31mError\033[0m] Expected input: Core %s %s%s\n" "${function_name}" "${required}" "${options}"
}

_Help::Input_count(){
  local -r function_name=${1}
  local override=0
  # shellcheck disable=SC2016
  for input in $(declare -f "${function_name}" | grep local | grep -E '=\${@.*}|=\$@|="\${@.*}"|="\$@"|=\${\*.*}|=\$\*|="\${\*.*}"|="\$\*"' | awk -F= '{ print $1 }' | awk '{print $NF}'); do
    override=$((override+1))
  done
  if [[ ${override} -gt 0 ]]; then
    override=99
  fi
  #start at one because we want to account for the function itself
  local required=1
  # shellcheck disable=SC2016
  for input in $(declare -f "${function_name}" | grep local | grep -E '=\${[0-9].*}|=\$[0-9].*|="\${[0-9].*}"|="\{[0-9].*"' | grep -Ev '=\${[0-9]:.*}|="\${[0-9]:.*}"' | awk -F= '{ print $1 }' | awk '{print $NF}'); do
    required=$((required+1))
  done
  local all=1
  # shellcheck disable=SC2016
  for input in $(declare -f "${function_name}" | grep local | grep -E '=\${[0-9].*}|=\$[0-9].*|="\${[0-9].*}"|="\{[0-9].*"' | awk -F= '{ print $1 }' | awk '{print $NF}'); do
    all=$((all+1))
  done
  echo "$required:$all:$override"
}
