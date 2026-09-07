#!/usr/bin/env bash
# ripwire --clones emits one XML line. Print every group as a table so none is skipped.
# Usage: ripwire-clones.sh scan/ripwire-clones.txt
python3 - "$1" <<'PY'
import re,sys
x=open(sys.argv[1],encoding='utf-8',errors='ignore').read()
hdr=re.search(r'<clones ([^>]*)>',x); print("clones:",hdr.group(1) if hdr else "?")
groups=re.findall(r'<group ([^>]*)>(.*?)</group>',x,re.S)
print(f"groups: {len(groups)}\n#\ttype\ttokens\tsim\tmembers")
for i,(attrs,body) in enumerate(groups,1):
    a=dict(re.findall(r'(\w+)="([^"]*)"',attrs))
    mem=[f"{p}:{n}" for n,p in re.findall(r'<f n="([^"]*)" p="([^"]*)"/>',body)]
    print(f"{i:02d}\t{a.get('type','?')}\t{a.get('tokens','?')}\t{a.get('similarity','1.00')}\t"+" | ".join(mem))
PY
