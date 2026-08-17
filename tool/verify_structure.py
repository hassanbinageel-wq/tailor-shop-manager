import re, pathlib, sys, collections

root = pathlib.Path('lib')
files = sorted(root.rglob('*.dart'))
errors, warns = [], []

def strip_code(s):
    """remove strings and comments for brace counting"""
    out=[]; i=0; n=len(s)
    while i<n:
        c=s[i]
        if c=='/' and i+1<n and s[i+1]=='/':
            while i<n and s[i]!='\n': i+=1
        elif c=='/' and i+1<n and s[i+1]=='*':
            i+=2
            while i+1<n and not (s[i]=='*' and s[i+1]=='/'): i+=1
            i+=2
        elif s[i:i+3] in ("'''",'"""'):
            q=s[i:i+3]; i+=3
            while i<n and s[i:i+3]!=q:
                if s[i]=='\\': i+=1
                i+=1
            i+=3
        elif c in "'\"":
            q=c; i+=1; depth=0
            while i<n:
                if s[i]=='\\': i+=2; continue
                if s[i]=='$' and i+1<n and s[i+1]=='{':
                    depth+=1; out.append('${'); i+=2; continue
                if depth>0 and s[i]=='}':
                    depth-=1; out.append('}'); i+=1; continue
                if depth>0:
                    out.append(s[i]); i+=1; continue
                if s[i]==q: i+=1; break
                i+=1
        else:
            out.append(c); i+=1
    return ''.join(out)

# map of declared top-level symbols per file
declared = collections.defaultdict(set)
decl_re = re.compile(r'^(?:abstract\s+|sealed\s+|final\s+|base\s+)*(?:class|mixin|enum|extension|typedef)\s+([A-Za-z_]\w*)', re.M)
func_re = re.compile(r'^(?:[A-Za-z_][\w<>,\s\?\.\(\)\[\]]*?\s+)([A-Za-z_]\w*)\s*(?:<[^>]*>)?\s*\([^;{]*\)\s*(?:async\s*)?\{', re.M)
var_re  = re.compile(r'^(?:const|final)\s+(?:[\w<>,\s\?\.]+\s+)?([A-Za-z_]\w*)\s*=', re.M)

for f in files:
    src = f.read_text()
    code = strip_code(src)
    if code.count('{') != code.count('}'):
        errors.append(f"{f}: unbalanced braces {code.count('{')} vs {code.count('}')}")
    if code.count('(') != code.count(')'):
        errors.append(f"{f}: unbalanced parens {code.count('(')} vs {code.count(')')}")
    if code.count('[') != code.count(']'):
        errors.append(f"{f}: unbalanced brackets")
    for m in decl_re.finditer(code): declared[str(f)].add(m.group(1))
    for m in func_re.finditer(code): declared[str(f)].add(m.group(1))
    for m in var_re.finditer(code): declared[str(f)].add(m.group(1))

# check relative imports resolve
for f in files:
    src = f.read_text()
    for m in re.finditer(r"import\s+'([^']+)'", src):
        imp = m.group(1)
        if imp.startswith('package:') or imp.startswith('dart:'): continue
        target = (f.parent / imp).resolve()
        if not target.exists():
            errors.append(f"{f}: unresolved import '{imp}'")

# detect used-but-not-imported classes from our own models/providers
all_syms = {}
for fp, syms in declared.items():
    for s in syms:
        all_syms.setdefault(s, []).append(fp)

for f in files:
    src = f.read_text()
    code = strip_code(src)
    imported = set()
    for m in re.finditer(r"import\s+'([^']+)'", src):
        imp = m.group(1)
        if imp.startswith('package:') or imp.startswith('dart:'): continue
        imported.add(str((f.parent / imp).resolve().relative_to(pathlib.Path.cwd())))
    imported.add(str(f))
    # our own PascalCase symbols referenced
    for sym in set(re.findall(r'\b([A-Z][A-Za-z0-9]{2,})\b', code)):
        if sym in all_syms:
            owners = set(all_syms[sym])
            if not (owners & imported):
                warns.append(f"{f}: uses '{sym}' declared in {sorted(owners)[0]} but not imported")

print(f"scanned {len(files)} dart files")
print(f"\n=== ERRORS ({len(errors)}) ===")
for e in errors: print(" ", e)
print(f"\n=== POSSIBLE MISSING IMPORTS ({len(warns)}) ===")
for w in sorted(set(warns)): print(" ", w)
