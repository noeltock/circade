#!/usr/bin/env bash
# Aggregate jscpd JSON into file pairs ranked by cloned lines.
# Usage: npx jscpd --reporters json --output <dir> <paths>; jscpd-pairs.sh <dir>/jscpd-report.json
jq -r '.duplicates[] | [.firstFile.name, .secondFile.name, (.lines|tostring)] | @tsv' "${1:?report json}" \
 | awk -F'\t' '{k=($1<$2?$1"\t"$2:$2"\t"$1); n[k]++; l[k]+=$3} END{for(k in n) print l[k]"\t"n[k]"\t"k}' \
 | sort -rn | head -40 | awk -F'\t' 'BEGIN{print "lines\tclones\tfile A\tfile B"}{print}'
