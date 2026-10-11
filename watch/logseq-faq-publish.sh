#!/usr/bin/env bash
# Watches logseq-faq/export/ for changes (via launchd WatchPaths) and
# publishes once the export has settled. Logseq's export writes many files
# over several seconds, so this debounces rather than firing on every write.
set -uo pipefail

REPO_DIR="/Users/niyaro/Code/logseq-faq"
LOG_FILE="$HOME/Library/Logs/logseq-faq-publish.log"
INDEX_FILE="$REPO_DIR/export/index.html"
LOCK_DIR="$REPO_DIR/.publish.lock"

log() {
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE"
}

log "triggered"

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  log "another run is already in progress (lock held), exiting"
  exit 0
fi
trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT

sleep 20

if [[ ! -f "$INDEX_FILE" ]]; then
  log "no export/index.html yet, exiting (next trigger will retry)"
  exit 0
fi

# Wait for the export to settle instead of exiting and counting on another
# trigger: launchd does not fire again for changes made while this is running.
while :; do
  now=$(date +%s)
  mtime=$(stat -f %m "$INDEX_FILE")
  age=$(( now - mtime ))
  (( age >= 15 )) && break
  log "export still being written (index.html age ${age}s < 15s), waiting"
  sleep 10
done

log "export looks settled (index.html age ${age}s), publishing"

cd "$REPO_DIR"
if ./publish.sh >> "$LOG_FILE" 2>&1; then
  log "publish.sh succeeded"
else
  log "publish.sh FAILED (see output above)"
fi
