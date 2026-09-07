#!/usr/bin/env bash
# Is this a WordPress repo? exit 0 yes, 1 no. Usage: detect-wp.sh [root]
cd "${1:-.}" || exit 1
grep -qlE "^\s*\*?\s*Plugin Name:|^\s*\*?\s*Theme Name:" ./*.php style.css 2>/dev/null && exit 0
grep -qE '"(johnpbloch|roots)/wordpress|wordpress-plugin|wordpress-theme|wordpress-muplugin' composer.json 2>/dev/null && exit 0
[ -d wp-content ] && exit 0
[ "$(git ls-files -- '*.php' 2>/dev/null | grep -vE '^(vendor|node_modules)/' | xargs grep -lE "add_action\(|add_filter\(" 2>/dev/null | wc -l)" -ge 3 ] && exit 0
exit 1
