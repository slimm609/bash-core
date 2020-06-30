#!/usr/bin/env bash

Git::Fetch-all() {
  local fetchrepo
  # shellcheck disable=SC2154
  cd "${_core_repo}" || _Log::Die 1 "Could not change to core repo"
  if git diff-index --quiet HEAD -- ; then
    for remote in $(git remote -v | awk '{ print $1 }' | sort -u); do
        git fetch "${remote}"
    done
  fi
  while IFS= read -r fetchrepo; do
    cd "${fetchrepo}" || _Log::Die 1 "Could not change to ${fetchrepo} repo"
    if git diff-index --quiet HEAD -- ; then
        for remote in $(git remote -v | awk '{ print $1 }' | sort -u); do
            git fetch "${remote}"
        done
    fi
  done < <(cat "${_core_repo}"/.core_repos)
}

Git::InstallHelpers() {
  pushd "$(git --exec-path)" >/dev/null || exit
  if [[ ! -w git-fetch ]]; then
    _Log::Die 254 "Git exec path not writable!"
  fi

  cat <<EOF > git-amend
  #!/usr/bin/env bash
  git commit --amend -C HEAD
EOF

  cat <<EOF > git-delete-local-merged
  #!/usr/bin/env bash
  git branch -d \$(git branch --merged | grep -v '^*' | grep -v 'master' | tr -d '\n')
EOF

cat <<EOF > git-rank-contributers
#!/usr/bin/env ruby

## git-rank-contributors: a simple script to trace through the logs and
## rank contributors by the total size of the diffs they're responsible for.
## A change counts twice as much as a plain addition or deletion.
##
## Output may or may not be suitable for inclusion in a CREDITS file.
## Probably not without some editing, because people often commit from more
## than one address.
##
## git-rank-contributors Copyright 2008 William Morgan <wmorgan-git-wt-add@masanjin.net>.
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or (at
## your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You can find the GNU General Public License at:
##   http://www.gnu.org/licenses/

class String
  def obfuscate; gsub(/@/, " at the ").gsub(/\.(\w+)(>|$)/, ' dot \1s\2') end
  def htmlize; gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;") end
  # Fix for invalid encodings http://stackoverflow.com/a/24037885
  def clean
    if RUBY_VERSION >= "2.1"
      scrub
    elsif RUBY_VERSION >= "1.9"
      encode("UTF-16be", :invalid => :replace).encode("UTF-8")
    else
      self
    end
  end
end

lines = {}
verbose = ARGV.delete("-v")
obfuscate = ARGV.delete("-o")
htmlize = ARGV.delete("-h")

author = nil
state = :pre_author
\`git log -M -C -C -p --no-color\`.clean.split("\n").each do |l|
  case
  when (state == :pre_author || state == :post_author) && l =~ /Author: (.*)$/
    author = \$1
    state = :post_author
    lines[author] ||= 0
  when state == :post_author && l =~ /^\+\+\+/
    state = :in_diff
  when state == :in_diff && l =~ /^[\+\-]/
    lines[author] += 1
  when state == :in_diff && l =~ /^commit /
    state = :pre_author
  end
end

lines.sort_by { |a, c| -c }.each do |a, c|
  a = a.obfuscate if obfuscate
  a = a.htmlize if htmlize
  if verbose
    puts "#{a}: #{c} lines of diff"
  else
    puts a
  end
end
EOF
chmod +x git-amend git-rank-contributers git-delete-local-merged
}