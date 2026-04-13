#!/bin/bash
# restore-secrets.sh - restore real secrets from .secrets into working files
# Run this after clone, or whenever working files show placeholders

cd "$(git rev-parse --show-toplevel)"

if [[ ! -f .secrets ]]; then
    echo "[!] .secrets not found!"
    exit 1
fi

while IFS='=' read -r real placeholder; do
    [[ -z "$real" || "$real" =~ ^# ]] && continue
    sed -i '' "s|$placeholder|$real|g" minigame/project.config.json minigame/game.json
    echo "  Restored: $placeholder → (real value)"
done < <(grep -v '^#' .secrets)

echo "[*] Done."
