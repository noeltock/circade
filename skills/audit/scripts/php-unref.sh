#!/usr/bin/env bash
# Zero-install PHP dead-code candidates from declarations only (never comments).
# Output: kind<TAB>name<TAB>file:line<TAB>note. Candidates, not verdicts:
#   function → run wp-refs.sh <name>;  method → run wp-refs.sh AND php-parent-chain.sh <Class> <name>.
# Methods of classes registered via WP_CLI::add_command are command surface and are skipped.
# Usage: php-unref.sh [paths...]
set -u; export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"
command -v rg >/dev/null || { echo "rg required" >&2; exit 2; }
paths=("${@:-.}")
G=(-g '*.php' -g '!vendor' -g '!node_modules' -g '!dist' -g '!build' -g '!**/tests/**' -g '!**/test/**' -g '!**/fixtures/**' -g '!**/*Test.php')
R=(-g '*.php' -g '*.js' -g '*.jsx' -g '*.ts' -g '*.tsx' -g '!vendor' -g '!node_modules' -g '!dist' -g '!build')
cli_classes=$(rg -o --no-filename "${G[@]}" -e "WP_CLI::add_command\([^,]+,\s*'?\\\\?([A-Za-z0-9_\\\\]+)(::class|')" -r '$1' "${paths[@]}" 2>/dev/null | sed 's/.*\\//' | sort -u)
skip="^(__construct|__destruct|__get|__set|__call|__callStatic|__toString|__invoke|__clone|setUp|tearDown|setUpBeforeClass|tearDownAfterClass|test[A-Z_]|jsonSerialize|offsetGet|offsetSet|offsetExists|offsetUnset|getIterator|count|current|key|next|rewind|valid)$"
rg -n --no-heading "${G[@]}" -e '^\s*(abstract\s+|final\s+)?(public\s+|protected\s+|private\s+)?(static\s+)?function\s+&?\s*[A-Za-z_][A-Za-z0-9_]*\s*\(' "${paths[@]}" 2>/dev/null \
 | grep -vE ':\s*(\*|//|#)' \
 | while IFS=: read -r file line rest; do
     name=$(echo "$rest" | sed -E 's/.*function[[:space:]]+&?[[:space:]]*([A-Za-z_][A-Za-z0-9_]*).*/\1/')
     echo "$name" | grep -qE "$skip" && continue
     if echo "$rest" | grep -qE '^[[:space:]]+(abstract|final|public|protected|private|static)'; then kind=method
       cls=$(rg -o -m1 -e '^\s*(abstract\s+|final\s+)?class\s+\K[A-Za-z0-9_]+' -P "$file" 2>/dev/null | head -1)
       [ -n "$cli_classes" ] && echo "$cli_classes" | grep -qx "$cls" && continue
     else kind=function; cls=""; fi
     n=$(rg -c --no-filename "${R[@]}" -e "\\b${name}\\b" "${paths[@]}" 2>/dev/null | awk '{s+=$1} END{print s+0}')
     if [ "$n" -le 1 ]; then
       if [ "$kind" = method ]; then printf "method\t%s::%s\t%s:%s\trun php-parent-chain.sh %s %s\n" "$cls" "$name" "$file" "$line" "$cls" "$name"
       else printf "function\t%s\t%s:%s\trun wp-refs.sh %s\n" "$name" "$file" "$line" "$name"; fi
     fi
   done
