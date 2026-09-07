#!/usr/bin/env bash
# Walk a PHP class's extends/implements/trait chain through the repo AND vendor/ and
# report any ancestor declaring <method>. Any "declares" line = override, never SAFE.
# "unresolved" = parent lives in WP core or outside the tree; check core for the method.
# Usage: php-parent-chain.sh <Class> <method> [root]
set -u; . "$(dirname "$0")/lib.sh"
command -v rg >/dev/null || { echo "rg required" >&2; exit 2; }
exec python3 - "$@" <<'PY'
import re, subprocess, sys
cls, method = sys.argv[1], sys.argv[2]; root = sys.argv[3] if len(sys.argv) > 3 else "."
RG = ["rg", "--no-ignore", "-g", "*.php", "-g", "!node_modules", "-g", "!tests", "-l"]
seen = set(); order = []
def find(c):
    r = subprocess.run(RG + ["-e", rf"^\s*(abstract\s+|final\s+)?(class|interface|trait)\s+{re.escape(c)}\b", root], capture_output=True, text=True)
    return r.stdout.split("\n")[0] if r.stdout else None
def walk(c):
    c = c.split("\\")[-1]
    if c in seen: return
    seen.add(c); order.append(c)
    f = find(c)
    if not f:
        hint = subprocess.run(["rg","-n","--no-ignore","-g","*.php","-g","!vendor","-g","!node_modules","-m","1","-e",rf"^\s*use\s+[A-Za-z0-9_\\]*\b{re.escape(c)}\s*;",root],capture_output=True,text=True).stdout.strip().split("\n")[0]
        where = "composer package not in vendor/ or WP core" if hint else "WP core or global (no `use` import found)"
        print(f"unresolved: {c} ({where}; check for function {method}){'  via '+hint if hint else ''}"); return
    src = open(f, encoding="utf-8", errors="ignore").read()
    for m in re.finditer(rf"^[^\S\n]*(abstract\s+)?(public|protected|private)?\s*(static\s+)?function\s+{re.escape(method)}\s*\(", src, re.M):
        line = src.count("\n", 0, m.start()) + 1
        print(f"declares: {c} {f}:{line}: {m.group(0).strip()}")
    hdr = re.search(rf"(class|interface|trait)\s+{re.escape(c)}\b([^{{]*)", src)
    parents = []
    if hdr:
        for kw in ("extends", "implements"):
            mm = re.search(rf"{kw}\s+([A-Za-z0-9_\\,\s]+?)(?=\s+(extends|implements)\b|$)", hdr.group(2).strip())
            if mm: parents += [p.strip() for p in mm.group(1).split(",") if p.strip()]
    body = src[hdr.end():] if hdr else ""
    parents += re.findall(r"^[ \t]+use\s+([A-Za-z0-9_\\]+(?:\s*,\s*[A-Za-z0-9_\\]+)*)\s*[;{]", body, re.M)
    for p in parents:
        for q in p.split(","): walk(q.strip())
walk(cls)
print("chain: " + " > ".join(order))
PY
