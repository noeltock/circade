# Shared by every script. Source it: . "$(dirname "$0")/lib.sh"
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"
# git output must be parseable: signature lines, pagers and colour all break --format parsing.
export GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=log.showSignature GIT_CONFIG_VALUE_0=false GIT_CONFIG_KEY_1=color.ui GIT_CONFIG_VALUE_1=false GIT_PAGER=cat
# Stacks with a section in references/tools.md (dead code, duplication, dependency lenses).
TOOLED_EXTS="php ts tsx js jsx mjs cjs py rs go"
# Stacks the history and shape scripts count but tools.md has no lens for yet.
COUNTED_EXTS="java kt kts swift rb cs c cc cpp h hpp m mm scala ex exs dart vue svelte astro"
SRC_EXTS="$TOOLED_EXTS $COUNTED_EXTS"
SRC_RE='\.(php|ts|tsx|js|jsx|mjs|cjs|py|rs|go|java|kt|kts|swift|rb|cs|c|cc|cpp|h|hpp|m|mm|scala|ex|exs|dart|vue|svelte|astro)$'
RG_SRC_GLOB='*.{php,ts,tsx,js,jsx,mjs,cjs,py,rs,go,java,kt,kts,swift,rb,cs,c,cc,cpp,h,hpp,m,mm,scala,ex,exs,dart,vue,svelte,astro}'
# Test files by path or name: tests/ spec/ __tests__/, *.test.*, *.spec.*, *_test.go, test_*.py, *_test.py, *Test.java, *_spec.rb, *Tests.swift
TEST_RE='(^|/)(tests?|__tests__|spec|specs|testing)/|\.(test|spec)\.|_test\.(go|py|rs|rb|ts|js)$|(^|/)test_[^/]*\.py$|Tests?\.(java|kt|swift|cs|scala)$|_spec\.rb$|Spec\.(scala|kt)$'
FN_RE='^\s*(export\s+)?(pub(\([^)]*\))?\s+)?(async\s+)?(public|protected|private|internal|static|abstract|final|unsafe|const|override|open)?\s*(function\s+\w+|fn\s+\w+|func\s+(\([^)]*\)\s*)?\w+|def\s+\w+|fun\s+\w+|const\s+\w+\s*=\s*(async\s*)?\(.*\)\s*=>)'
IMPORT_RE='^\s*(import\s|use\s+[A-Za-z]|from\s+\S+\s+import|require\s*\(|extern\s+crate|#include\s|using\s+[A-Z]|alias\s+[A-Z])'
EXPORT_RE='^\s*(export\s|module\.exports\s*=|exports\.\w+\s*=|pub\s+(fn|struct|enum|trait|mod|const|static|type|use)\s|func\s+[A-Z]\w*\s*\(|public\s+(static\s+)?(class|interface|fun|func|def|[A-Za-z<>\[\]]+\s+\w+\s*\())'
# Shallow clones make every history lens lie about age and churn.
shallow_guard() { if [ "$(git rev-parse --is-shallow-repository 2>/dev/null)" = "true" ]; then echo "# SHALLOW CLONE: history lenses see only the fetched depth; run 'git fetch --unshallow' before trusting churn, age or trend" >&2; fi; }
