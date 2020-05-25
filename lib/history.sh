#!/usr/bin/env bash
#
# Add fzf weighted history
#

history() {
  echo "Count      Command"
  echo "-----      -------"
  _History::List
}

_History::List() {
    local input=${@}
    [[ -d "${REPO}/.core_history" ]] && {
        echo "ERROR: history datafile (${REPO}/.core_history) is a directory." 
    }
 
    local datafile="${REPO}/.core_history"
    local -r OWNER="$(id -un)"

    # if symlink, dereference
    [[ -h "$datafile" ]] && datafile=$(readlink "$datafile") || touch $datafile

    _History::Line () {
        local line
        while read line; do
             echo "$line"
        done < "$datafile"
        return 0
    }
    
        # no file yet
        [[ -f "$datafile" ]] || return

        local match
        match="$( < <( _History::Line ) awk -v t="$(date +%s)" -v list="1" -v typ="rank" -v q="$input" -F"|" '
                function frecent(rank, time) {
                dx = t - time
                return int(10000 * rank * (3.75/((0.0001 * dx + 1) + 0.25)))
                }
                function output(matches, best_match, common) {
                  if( list ) {
                        cmd = "sort -r -n"
                        for( x in matches ) {
                        if( matches[x] ) {
                                printf "%-10s %s\n", matches[x], x | cmd
                        }
                    }
                  }
                }
                function common(matches) {
                  for( x in matches ) {
                        if( matches[x] && (!short || length(x) < length(short)) ) {
                        short = x
                        }
                  }
                }
                BEGIN {
                    gsub(" ", ".*", q)
                    hi_rank = ihi_rank = -9999999999
                }
                {
                    if( typ == "rank" ) {
                        rank = $2
                } 
                if( $1 ~ q ) {
                        matches[$1] = rank
                } else if( tolower($1) ~ tolower(q) ) imatches[$1] = rank
                if( matches[$1] && matches[$1] > hi_rank ) {
                        best_match = $1
                        hi_rank = matches[$1]
                } else if( imatches[$1] && imatches[$1] > ihi_rank ) {
                        ibest_match = $1
                        ihi_rank = imatches[$1]
                    }
                }
                END {
                    if( best_match ) {
                            output(matches)
                            exit
                    } else if( ibest_match ) {
                            output(imatches)
                            exit
                    }
                exit(0)
                }
        ')"
        if [[ ${#match} -gt 0 ]]; then
            echo "${match}" 
        fi
}

_History::Add(){
    local input=${@}
    [[ -d "${REPO}/.core_history" ]] && {
        echo "ERROR: history datafile (${REPO}/.core_history) is a directory." 
    }
 
    local datafile="${REPO}/.core_history"
    local -r OWNER="$(id -un)"

    # if symlink, dereference
    [[ -h "$datafile" ]] && datafile=$(readlink "$datafile") || touch $datafile
    
    # if the function begins with `_` do not add to history,  its an internal function
    [[ ${input} =~ ^_.* ]] && return 0

    _History::Line () {
        local line
        while read line; do
             echo "$line"
        done < "$datafile"
        return 0
    }
    
        # maintain the data file
        local tempfile="$datafile.$RANDOM"
        local score=${_MAX_SCORE:-1000}
        _History::Line | awk -v path="$*" -v now="$(date +%s)" -v score=$score -F"|" '
            BEGIN {
                rank[path] = 1
                time[path] = now
            }
            $2 >= 1 {
                if( $1 == path ) {
                    rank[$1] = $2 + 1
                    time[$1] = now
                } else {
                    rank[$1] = $2
                    time[$1] = $3
                }
                count += $2
            }
            END {
                if( count > score ) {
                    for( x in rank ) print x "|" 0.99*rank[x] "|" time[x]
                } else for( x in rank ) print x "|" rank[x] "|" time[x]
            }
        ' 2>/dev/null >| "$tempfile"
        # do our best to avoid clobbering the datafile in a race condition.
        if [ $? -ne 0 -a -f "$datafile" ]; then
            env rm -f "$tempfile"
        else
            [ "$OWNER" ] && chown $OWNER:"$(id -ng $OWNER)" "$tempfile"
            env mv -f "$tempfile" "$datafile" || env rm -f "$tempfile"
        fi
}