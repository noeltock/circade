#!/usr/bin/env bash
# Rename check for history lenses. Prints "renames: N of T tracked (P%)" and exits 3 when a
# restructure sits inside the window (P >= 10%), because plain git log cannot see across it.
# Usage: renames.sh [--since 10.weeks]
set -u; . "$(dirname "$0")/lib.sh"; since="10.weeks"; [ "${1:-}" = "--since" ] && since="$2"
r=$(git log --since="$since" --no-merges -M --diff-filter=R --name-status --format= | grep -c '^R' || true)
t=$(git ls-files | wc -l | tr -d ' '); p=$(( t > 0 ? r * 100 / t : 0 ))
echo "renames in window ($since): $r of $t tracked (${p}%)"
[ "$p" -ge 10 ] && { echo "RESTRUCTURE IN WINDOW: history lenses alias old paths to new (hotspots, cochange) and trend archives the whole tree; treat churn and co-change as weak"; exit 3; }
exit 0
