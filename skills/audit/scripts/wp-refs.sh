#!/usr/bin/env bash
# String references to a PHP/JS symbol that static tools miss (hooks, REST callbacks,
# cron, shortcodes, wp.hooks). Any output = still referenced. Requires rg (honours
# .gitignore; grep walks tmp/ and build output and takes minutes).
# Usage: wp-refs.sh <symbol> [path ...]   default paths: tracked files from repo root
set -u; export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"
command -v rg >/dev/null || { echo "rg required (brew install ripgrep)" >&2; exit 2; }
sym="${1:?symbol required}"; shift; paths=("${@:-.}")
G=(-g '*.php' -g '*.js' -g '*.jsx' -g '*.ts' -g '*.tsx' -g '*.twig' -g '*.json'
   -g '!node_modules' -g '!vendor' -g '!dist' -g '!build' -g '!storybook-static' -g '!tmp' -g '!*.min.js')
files=$(rg --files "${G[@]}" "${paths[@]}" | wc -l | tr -d ' '); bare=$(rg -c "${G[@]}" -e "\\b${sym}\\b" "${paths[@]}" | awk -F: '{s+=$NF}END{print s+0}')
echo "# searched $files files under ${paths[*]} · bare-name occurrences (incl. definition): $bare · quoted/string refs below:"
rg -n --no-heading "${G[@]}" \
   -e "['\"]${sym}['\"]" -e "['\"][A-Za-z0-9_\\\\]*::${sym}['\"]" -e "\\[[^]]*['\"]${sym}['\"]\\]" "${paths[@]}"
rg -n --no-heading -g '*.php' -g '!vendor' \
   -e "(do_action|apply_filters|do_action_ref_array|apply_filters_ref_array)\\(\\s*['\"]${sym}['\"]" "${paths[@]}"
