#!/usr/bin/env bash
# Serves dist/ under the /logseq-faq/ base path so local preview matches
# GitHub Pages, where the site lives at https://kerim.github.io/logseq-faq/.
set -euo pipefail
cd "$(dirname "$0")"

PORT="${1:-8002}"
PREVIEW_ROOT="$(mktemp -d)"
trap 'rm -rf "$PREVIEW_ROOT"' EXIT

ln -s "$PWD/dist" "$PREVIEW_ROOT/logseq-faq"

echo "Serving http://localhost:${PORT}/logseq-faq/ (Ctrl+C to stop)"
python3 -m http.server "$PORT" --directory "$PREVIEW_ROOT"
