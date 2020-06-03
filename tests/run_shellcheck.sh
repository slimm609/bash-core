#!/usr/bin/env bash
res=0
cd "$(git rev-parse --show-toplevel)"
printf "checking Core\n"
docker-compose run shellcheck #run against core itself
res=$((${res}+$?))
for file in $(find lib -type f -iname "*.sh"); do
  printf "checking %s\n" "${file}"
  docker-compose run shellcheck ${file}
  res=$((${res}+$?))
done

exit ${res}