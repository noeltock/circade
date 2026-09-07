#!/usr/bin/env bash
# Scope preflight. Run before any scanner.
# Usage: scope.sh [repo-root] [--format text|shell]
#   text  (default): human summary + exclude list + secret-shaped files; exit 3 on scope trap
#   shell: prints RG_X=(...) JSCPD_IGNORE=... X=... assignments to eval
set -u; export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"
root="."; fmt="text"
while [ $# -gt 0 ]; do case "$1" in --format) fmt="$2"; shift 2;; *) root="$1"; shift;; esac; done
cd "$root" || exit 2
# 5. not a git worktree? look for the real checkout
if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  base=$(basename "$(pwd)"); cands=$(find "$HOME/dev" -maxdepth 3 -type d -name "$base" -not -path "$(pwd)" 2>/dev/null | while read -r c; do [ -d "$c/.git" ] || git -C "$c" rev-parse --show-toplevel >/dev/null 2>&1 && echo "$c"; done)
  echo "NOT A GIT WORKTREE: $(pwd) (runtime shell or uploads dir?)"
  n=$(echo "$cands" | grep -c . || true)
  if [ "$n" -eq 1 ]; then echo "resolved checkout: $cands  (report this resolution prominently; rerun scope.sh there)"; exit 4
  elif [ "$n" -gt 1 ]; then echo "candidates:"; echo "$cands" | sed 's/^/  /'; echo "multiple matches: stop and ask which"; exit 5
  else echo "no matching checkout under ~/dev; stop and ask"; exit 5; fi
fi
tracked=$(git ls-files | wc -l | tr -d ' ')
ondisk=$(rg --files --no-ignore -g '!.git' -g '!node_modules' -g '!vendor' | wc -l | tr -d ' ')
ign=$(git status --ignored --porcelain 2>/dev/null | awk '$1=="!!"{print $2}' | sed 's#/$##' | grep -vE '^(node_modules|vendor)$|\.DS_Store$|(^|/)\._' | awk -F/ '{print (NF>2 ? $1"/"$2 : $0)}' | sort -u | while read -r i; do [ -z "$(git ls-files -- "$i" | head -1)" ] && echo "$i"; done | head -40)
srcdirs=$(git ls-files | grep -E '\.(php|ts|tsx|js|jsx|py)$' | grep -vE '^(vendor|node_modules)/' | awk -F/ 'NF>1{print $1} NF==1{print $0}' | sort | uniq -c | sort -rn | awk '$1>=3{print $2}' | tr '\n' ' ')
X=$(echo "$ign" | grep -v '^$' | tr '\n' ',' | sed 's/,$//')
RGX=(); JS=("**/node_modules/**" "**/vendor/**"); while IFS= read -r i; do [ -n "$i" ] && RGX+=("-g" "!$i") && JS+=("**/$i/**"); done <<< "$ign"
if [ "$fmt" = "shell" ]; then
  printf 'X=%q\n' "$X"; printf 'RG_X=('; printf '%q ' "${RGX[@]}"; printf ')\n'; printf 'JSCPD_IGNORE=%q\n' "$(IFS=,; echo "${JS[*]}")"
  printf 'SRC_PATHS=%q\n' "$srcdirs"
  exit 0
fi
echo "tracked files: $tracked   on disk (excl. node_modules/vendor/.git): $ondisk"
echo "tracked by top dir:"; git ls-files | awk -F/ 'NF>1{print $1} NF==1{print "(root)"}' | sort | uniq -c | sort -rn | head -12
echo "ignored dirs present on disk (exclude from every scan):"; echo "$ign" | sed 's/^/  /'
echo "exclude list: $X"
echo "source paths (tracked dirs with ≥3 source files; pass these positionally to ripwire and every scanner): $srcdirs"
echo "shell form: eval \"\$(scope.sh --format shell)\"  → \$SRC_PATHS (positional), \${RG_X[@]} (rg), \$JSCPD_IGNORE (jscpd --ignore)"
# 3. library mode needs real evidence
if [ -f package.json ]; then node -e '
const fs=require("fs"),p=require("./package.json");
const m=p.main&&fs.existsSync(p.main), pub=p.private!==true&&(p.exports||p.bin||p.types||m||p.publishConfig);
if(pub) console.log("library mode: yes (public exports; single-consumer/unused-export findings default CAREFUL, say \"external consumers unknown\")");
else if(p.main&&!m) console.log("library mode: no · stale package metadata: main="+p.main+" does not exist (report as SAFE candidate)");
else console.log("library mode: no");' 2>/dev/null || echo "library mode: n/a (package.json unreadable)"; else echo "library mode: n/a"; fi
# 10. tracked secret-shaped artefacts: paths and key names only, never values. Repo hygiene, not a secret scan.
sf=$(git ls-files | grep -E '(^|/)(auth\.json|\.npmrc|\.env(\.[a-z]+)?|.*\.pem|.*\.p12|.*\.pfx|id_(rsa|ed25519)[^/]*|.*credentials.*\.json|service-account.*\.json|.*\.key)$' | grep -vE '\.(example|sample|dist|template)$|\.pub$')
echo "tracked secret-shaped files: $(echo "${sf:-none}" | tr "\n" " ")"
for f in $sf; do case "$f" in *.json) echo "  $f keys: $(jq -r 'paths(scalars) | map(tostring) | join(".")' "$f" 2>/dev/null | grep -iE 'pass|token|secret|key|auth' | head -6 | tr '\n' ' ')";; esac; done
kv=$(git grep -IlE '(AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|sk-[A-Za-z0-9]{20,}|xox[bp]-[0-9A-Za-z-]{10,}|-----BEGIN (RSA|EC|OPENSSH) PRIVATE KEY-----)' -- ':!*.lock' ':!*.min.*' ':!*.map' 2>/dev/null | head -5 | tr '\n' ' ')
echo "key-shaped values in tracked files: ${kv:-none}"
awk -v t="$tracked" -v d="$ondisk" 'BEGIN{ if (d > 1.5*t) { print "SCOPE TRAP: on-disk files exceed 1.5x tracked; use the shell form for every scanner"; exit 3 } }'
