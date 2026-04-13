#!/usr/bin/env python3
"""Replace real secrets with placeholders using a single regex pass.
Avoids cascading replacements that occur with sequential string replace."""
import sys, re

if len(sys.argv) < 3:
    print("Usage: __secret_replace.py <in_file> <out_file> <secrets_file>", file=sys.stderr)
    sys.exit(1)

in_path, out_path, secrets_path = sys.argv[1:]

# Build a single regex that matches any of the real secrets
secrets = []
with open(secrets_path) as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        if '=' in line:
            real, placeholder = line.split('=', 1)
            secrets.append((real.strip(), placeholder.strip()))

if not secrets:
    # No secrets, just copy
    with open(in_path) as f:
        content = f.read()
    with open(out_path, 'w') as f:
        f.write(content)
    sys.exit(0)

# Sort by length descending so longer matches are tried first
secrets.sort(key=lambda x: len(x[0]), reverse=True)

# Build alternation regex: (real1|real2|real3)
pattern = '|'.join(re.escape(real) for real, _ in secrets)

def replacer(match):
    matched = match.group(0)
    for real, placeholder in secrets:
        if matched == real:
            return placeholder
    return matched  # Shouldn't happen

regex = re.compile(pattern)

if in_path == '-':
    import sys
    content = sys.stdin.read()
else:
    with open(in_path) as f:
        content = f.read()

new_content = regex.sub(replacer, content)

if out_path == '-':
    import sys
    sys.stdout.write(new_content)
else:
    with open(out_path, 'w') as f:
        f.write(new_content)
