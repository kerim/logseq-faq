#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
git submodule update --init --recursive 2>/dev/null || true
builder/build-static.sh --source "$PWD/export" --output "$PWD/dist" --config "$PWD/site.json"
touch dist/.nojekyll
