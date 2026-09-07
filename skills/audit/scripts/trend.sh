#!/usr/bin/env bash
# Repo-only trend: the same cheap shape metrics at N evenly spaced commits over a window.
# Slope, not snapshot. Read-only: uses `git archive` into a temp dir, never checks out.
# Usage: trend.sh [--since 6.months] [--points 4] [paths...]
set -u; . "$(dirname "$0")/lib.sh"
shallow_guard; since="6.months"; points=4; paths=()
while [ $# -gt 0 ]; do case "$1" in --since) since="$2"; shift 2;; --points) points="$2"; shift 2;; *) paths+=("$1"); shift;; esac; done
[ ${#paths[@]} -eq 0 ] && paths=(.)
# restructure handling: keep the requested paths, add the pre-rename paths that map into them
ren=$(git log --since="$since" --no-merges -M --diff-filter=R --name-status --format= | grep -c '^R' || true); trk=$(git ls-files | wc -l | tr -d ' ')
oldpaths=()
if [ "$ren" -gt 0 ] && [ "${paths[*]}" != "." ]; then
  while IFS=$'\t' read -r _ old new; do
    for pth in "${paths[@]}"; do case "$new" in "$pth"/*|"$pth") oldpaths+=("$old");; esac; done
  done < <(git log --since="$since" --no-merges -M --diff-filter=R --name-status --format= | grep '^R')
  [ ${#oldpaths[@]} -gt 0 ] && echo "# $ren renames in window ($(( ren * 100 / trk ))% of tracked): archiving ${#oldpaths[@]} pre-rename paths alongside ${paths[*]} so early points are not zero"
fi
shas=$(git log --since="$since" --date-order --format=%H --reverse | awk -v n="$points" '{a[NR]=$0} END{if(NR==0)exit; for(i=1;i<=n;i++){idx=int(1+(NR-1)*(i-1)/(n-1+(n==1))); print a[idx]}}' | awk '!s[$0]++')
[ -z "$shas" ] && { echo "no commits in window"; exit 1; }
printf "%-10s %-10s %7s %7s %7s %7s %7s %7s %7s %7s\n" date sha files src_loc test_loc t/s fns exports imports dup%
tmp=$(mktemp -d)
for s in $shas; do
  d="$tmp/$s"; mkdir -p "$d"; { git archive "$s" -- "${paths[@]}" 2>/dev/null; for op in ${oldpaths[@]+"${oldpaths[@]}"}; do git archive "$s" -- "$op" 2>/dev/null; done; } | tar -x -C "$d" 2>/dev/null; [ -n "$(ls -A "$d")" ] || { printf "%-10s %-10s  (none of the paths exist at this commit)\n" "$(git log -1 --format=%cs $s)" "${s:0:8}"; continue; }
  G=(-g '!node_modules' -g '!vendor' -g '!dist' -g '!build' -g '!*.min.*' -g '!*.lock' -g '!package-lock.json')
  files=$(rg --files "${G[@]}" -g "$RG_SRC_GLOB" "$d" | wc -l | tr -d ' ')
  test_loc=$(rg --files "${G[@]}" -g "$RG_SRC_GLOB" "$d" | rg -i "$TEST_RE" | xargs -I{} cat {} 2>/dev/null | wc -l | tr -d ' ')
  all_loc=$(rg --files "${G[@]}" -g "$RG_SRC_GLOB" "$d" | xargs -I{} cat {} 2>/dev/null | wc -l | tr -d ' ')
  src_loc=$((all_loc - test_loc))
  fns=$(rg -c "${G[@]}" -g "$RG_SRC_GLOB" -e "$FN_RE" "$d" | awk -F: '{s+=$NF}END{print s+0}')
  exports=$(rg -c "${G[@]}" -g "$RG_SRC_GLOB" -e "$EXPORT_RE" "$d" | awk -F: '{s+=$NF}END{print s+0}')
  imports=$(rg -c "${G[@]}" -g "$RG_SRC_GLOB" -e "$IMPORT_RE" "$d" | awk -F: '{s+=$NF}END{print s+0}')
  dup="n/a"; if command -v npx >/dev/null && [ "$src_loc" -gt 0 ]; then dup=$(npx -y jscpd --silent --reporters json --output "$d/.jscpd" --ignore "**/node_modules/**,**/vendor/**,**/tests/**,**/test/**,**/*.min.*" "$d" >/dev/null 2>&1 && jq -r '(.statistics.total.percentage // 0) * 10 | round / 10' "$d/.jscpd/jscpd-report.json" 2>/dev/null || echo "-"); fi
  if [ "$src_loc" -gt 0 ]; then ts="$(( test_loc * 100 / src_loc ))%"; else ts="n/a"; fi
  printf "%-10s %-10s %7s %7s %7s %7s %7s %7s %7s %7s\n" "$(git log -1 --format=%cs $s)" "${s:0:8}" "$files" "$src_loc" "$test_loc" "$ts" "$fns" "$exports" "$imports" "$dup"
done
rm -rf "$tmp"
