#!/usr/bin/env bash
# Installs (or reinstalls) the watcher that publishes automatically whenever a
# new Logseq export lands in export/. Safe to re-run.
set -euo pipefail

WATCH_DIR="$(cd "$(dirname "$0")" && pwd)"
LABEL="net.oxus.logseq-faq-publish"
PLIST="$WATCH_DIR/$LABEL.plist"
AGENT="$HOME/Library/LaunchAgents/$LABEL.plist"
DOMAIN="gui/$(id -u)"

mkdir -p "$WATCH_DIR/bin"
clang -O2 -Wall -Wextra -Werror -o "$WATCH_DIR/bin/logseq-faq-publish" "$WATCH_DIR/launcher.c"
echo "built $WATCH_DIR/bin/logseq-faq-publish"

launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true

# Remove and recreate the link rather than editing in place: macOS keeps the
# job's old display name otherwise.
rm -f "$AGENT"
ln -s "$PLIST" "$AGENT"

launchctl bootstrap "$DOMAIN" "$AGENT"
echo "loaded $LABEL"
