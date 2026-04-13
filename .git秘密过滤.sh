#!/bin/bash
# .git秘密过滤.sh pre-commit
# Replace real secrets with placeholders ONLY in git staging area.
# Working directory remains unchanged (keeps real values for local dev).
#
# .secrets file format (gitignored): REAL_VALUE=PLACEHOLDER

SECRETS_FILE=".secrets"
REPO_ROOT=$(git rev-parse --show-toplevel)
PYTHON_SCRIPT="$REPO_ROOT/__secret_replace.py"
TARGET_FILES=("minigame/project.config.json" "minigame/game.json")

if [[ ! -f "$SECRETS_FILE" ]]; then
    echo "[secret-filter] Warning: $SECRETS_FILE not found, skipping"
    exit 0
fi

STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)
REPLACED=0

for file in "${TARGET_FILES[@]}"; do
    if echo "$STAGED_FILES" | grep -qF "$file"; then
        tmp_in=$(mktemp)
        tmp_out=$(mktemp)
        trap "rm -f $tmp_in $tmp_out" EXIT

        # Read staged blob content
        git show ":$file" > "$tmp_in" 2>/dev/null
        [[ ! -s "$tmp_in" ]] && continue

        # Replace secrets
        python3 "$PYTHON_SCRIPT" "$tmp_in" "$tmp_out" "$SECRETS_FILE"

        # Write new blob and update index
        new_blob=$(git hash-object -w --stdin < "$tmp_out")
        git update-index --add --cacheinfo 100644 "$new_blob" "$file"

        echo "[secret-filter] Replaced secrets in: $file"
        REPLACED=1
        rm -f "$tmp_in" "$tmp_out"
        trap - EXIT
    fi
done

[[ "$REPLACED" -eq 0 ]] && echo "[secret-filter] No target files staged"
exit 0
