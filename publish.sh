#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Build locally first so a broken export never gets pushed.
./build.sh

git add export site.json

if git diff --cached --quiet; then
  echo "publish.sh: nothing changed in export/ or site.json, skipping commit and push."
  exit 0
fi

git commit -m "Publish $(date '+%Y-%m-%d %H:%M')"
git push
