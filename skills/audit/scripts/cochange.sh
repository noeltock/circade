#!/usr/bin/env bash
# Change coupling from git log only: file pairs that keep changing in the same commit
# without one importing the other is a hidden seam (Tornhill). Recent window on purpose.
# Usage: cochange.sh [--since 3.months] [--min 4] [paths...]
set -u; . "$(dirname "$0")/lib.sh"; shallow_guard; since="3.months"; min=4; paths=()
maxf=15; while [ $# -gt 0 ]; do case "$1" in --since) since="$2"; shift 2;; --min) min="$2"; shift 2;; --max-files) maxf="$2"; shift 2;; *) paths+=("$1"); shift;; esac; done
first=$(git log --since="$since" --reverse --format=%at | head -1); span_d=$(( first>0 ? ( $(date +%s) - first ) / 86400 : 0 ))
[ "$span_d" -lt 28 ] && echo "# only ${span_d}d of history in window; co-change is weak below 4 weeks"
git log --since="$since" --no-merges -M --name-status --format='%x40%x40' -- "${paths[@]:-.}" \
 | awk '/^@@$/{print; next} /^R[0-9]*\t/{split($0,a,"\t"); print a[3]; next} /^[AMDTC][0-9]*\t/{split($0,a,"\t"); print a[2]; next}' \
 | grep -vE '^$|\.(lock|md|json|png|jpg|svg|snap)$|^(package-lock|yarn)' \
 | awk -v min="$min" -v maxf="$maxf" '
   /^@@$/ { if (n>1 && n<=maxf) { for(i=1;i<=n;i++) for(j=i+1;j<=n;j++){k=(f[i]<f[j]?f[i]"\t"f[j]:f[j]"\t"f[i]); pair[k]++} } n=0; next }
   { f[++n]=$0; rev[$0]++ }
   END { for (k in pair) if (pair[k]>=min) { split(k,a,"\t"); pct=int(100*pair[k]/(rev[a[1]]<rev[a[2]]?rev[a[1]]:rev[a[2]])); print pair[k]"\t"pct"%\t"a[1]"\t"a[2] } }' \
 | sort -rn | head -25 | awk -F'\t' 'BEGIN{print "co-commits\tof-smaller\tfile A\tfile B"}{print}'
