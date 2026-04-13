#!/bin/bash
# setup-secret-filter.sh
# Run once after cloning to set up secret filter hooks
# Usage: bash setup-secret-filter.sh

set -e

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

echo "=== Secret Filter Setup ==="

# Check/create .secrets
if [[ ! -f .secrets ]]; then
    echo "[!] .secrets not found. Creating template..."
    cat > .secrets << 'TEMPLATE'
# Secrets mapping: REAL_VALUE=PLACEHOLDER
# Fill in your real values below (one per line)
# Example: wxdfe72aa8c7017a1c=YOUR_WECHAT_APPID
TEMPLATE
    echo "[!] Please edit .secrets with your real values, then re-run this script."
    exit 1
fi

# Install pre-commit hook
echo "[*] Installing pre-commit hook..."
cp .git秘密过滤.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
echo "[*] pre-commit hook installed."

# Restore real values in working directory
echo "[*] Restoring real secrets in working directory..."
python3 __secret_replace.py --restore << 'PYEOF'
import sys, os

secrets_path = os.path.join(os.path.dirname(__file__), '.secrets')
if len(sys.argv) > 1 and sys.argv[1] == '--restore':
    pass  # Use working dir replacement

replacements = {}
with open('.secrets') as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        if '=' in line:
            real, placeholder = line.split('=', 1)
            replacements[placeholder.strip()] = real.strip()

for fname in ['minigame/project.config.json', 'minigame/game.json']:
    if os.path.exists(fname):
        with open(fname) as f:
            content = f.read()
        for placeholder, real in replacements.items():
            content = content.replace(placeholder, real)
        with open(fname, 'w') as f:
            f.write(content)
        print(f"  Restored: {fname}")
print("[*] Done! Real secrets restored in working directory.")
PYEOF

# If python restore fails, use sed fallback
python3 __secret_replace.py --restore 2>/dev/null || {
    echo "[*] Using sed fallback for restore..."
    while IFS='=' read -r real placeholder; do
        [[ -z "$real" || "$real" =~ ^# ]] && continue
        sed -i '' "s|$placeholder|$real|g" minigame/project.config.json minigame/game.json 2>/dev/null || true
    done < <(grep -v '^#' .secrets)
    echo "[*] Done!"
}

echo ""
echo "=== Setup Complete ==="
echo "Pre-commit hook will now replace real secrets with placeholders before each commit."
echo "Your local .secrets file contains the real values and is NOT committed."
