#!/usr/bin/env bash
# Hotspots = churn × size over a recent window (Tornhill), git log only.
# Refuses repos younger than 8 weeks: before that, churn is the build, not a signal.
# Usage: hotspots.sh [--since 10.weeks] [--max-files 15] [paths...]
set -u; export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"; since="10.weeks"; maxf=15; paths=()
while [ $# -gt 0 ]; do case "$1" in --since) since="$2"; shift 2;; --max-files) maxf="$2"; shift 2;; *) paths+=("$1"); shift;; esac; done
first=$(git log --reverse --format=%at | head -1); age_w=$(( ( $(date +%s) - first ) / 604800 ))
[ "$age_w" -lt 8 ] && { echo "repo is ${age_w}w old; hotspots need >=8w of history (churn is the build). skipped"; exit 3; }
tot=$(git log --since="$since" --no-merges --format=%H -- "${paths[@]:-.}" | wc -l | tr -d ' ')
big=$(git log --since="$since" --no-merges --name-only --format='%x40%x40' -- "${paths[@]:-.}" | awk -v maxf="$maxf" '/^@@$/{ if (n>maxf) b++; n=0; next } NF{ n++ } END{ print b+0 }')
echo "window: $since · repo age ${age_w}w · commits in window $tot · dropped $big commits touching >$maxf files (bulk/agent commits; raise --max-files if a known-hot file shows 0 revs)"
ren=$(git log --since="$since" --no-merges -M --diff-filter=R --name-status --format= -- "${paths[@]:-.}" | grep -c '^R' || true)
[ "$ren" -gt 0 ] && echo "renames in window: $ren (old paths aliased to new; run scripts/renames.sh for the restructure check)"
git log --since="$since" --no-merges -M --name-status --format='%x40%x40' -- "${paths[@]:-.}" \
 | awk -v maxf="$maxf" '
     /^@@$/{ if (n>0 && n<=maxf) for(i=1;i<=n;i++) c[f[i]]++; n=0; next }
     /^R[0-9]*\t/{ split($0,a,"\t"); alias[a[2]]=a[3]; f[++n]=a[3]; next }
     /^[AMDTC][0-9]*\t/{ split($0,a,"\t"); f[++n]=a[2]; next }
     END{ for (k in c) { t=k; while (t in alias) t=alias[t]; m[t]+=c[k] } for (k in m) print m[k]"\t"k }' \
 | grep -E '\.(php|ts|tsx|js|jsx|py)$' | grep -vE '\.(test|spec)\.|/tests?/|__tests__' \
 | while IFS=$'\t' read -r n f; do [ -f "$f" ] || continue; l=$(wc -l < "$f" | tr -d ' '); printf "%s\t%s\t%s\t%s\n" "$n" "$l" "$(( n * l ))" "$f"; done \
 | sort -t$'\t' -k3 -rn | head -15 | awk -F'\t' 'BEGIN{print "revs\tlines\tscore\tfile"}{print}'
