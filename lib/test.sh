#!/usr/bin/env bash

Test::Main() {
  local input=${1}
  local output=${2}
  local optional=${3:-nothing}
  local therest=${*:4}
  echo "Input: ${input}, Output: ${output}, Optional: ${optional}, TheRest: ${therest}"
}

