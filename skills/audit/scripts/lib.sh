# Shared by every script. Source it: . "$(dirname "$0")/lib.sh"
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"
# git output must be parseable: signature lines, pagers and colour all break --format parsing.
export GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=log.showSignature GIT_CONFIG_VALUE_0=false GIT_CONFIG_KEY_1=color.ui GIT_CONFIG_VALUE_1=false GIT_PAGER=cat
# Source languages, one list. Add here, not in individual scripts.
SRC_EXTS="php ts tsx js jsx mjs cjs py rs go java kt swift rb"
SRC_RE='\.(php|ts|tsx|js|jsx|mjs|cjs|py|rs|go|java|kt|swift|rb)$'
RG_SRC_GLOB='*.{php,ts,tsx,js,jsx,mjs,cjs,py,rs,go,java,kt,swift,rb}'
# function/method declarations across those languages (one line each)
FN_RE='^\s*(export\s+)?(pub(\([^)]*\))?\s+)?(async\s+)?(public|protected|private|static|abstract|final|unsafe|const)?\s*(function\s+\w+|fn\s+\w+|func\s+(\([^)]*\)\s*)?\w+|def\s+\w+|fun\s+\w+|const\s+\w+\s*=\s*(async\s*)?\(.*\)\s*=>)'
IMPORT_RE='^\s*(import\s|use\s+[A-Za-z]|from\s+\S+\s+import|require\s*\(|extern\s+crate|#include\s)'
EXPORT_RE='^\s*(export\s|module\.exports\s*=|exports\.\w+\s*=|pub\s+(fn|struct|enum|trait|mod|const|static|type|use)\s|func\s+[A-Z]\w*\s*\()'
