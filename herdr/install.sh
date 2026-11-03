#!/usr/bin/env bash
# install.sh — put the DotVibes herdr config in place on this machine
# (one of several components; the top-level install.sh runs this for you):
#   1. check herdr is on PATH (missing = warning, not a failure)
#   2. back up an existing ~/.config/herdr/config.toml (untouched otherwise)
#   3. symlink it -> <repo>/herdr/config.toml
# Only the config file is linked; herdr's runtime state in that dir
# (logs, sockets, session.json, ...) is left completely alone.
# Idempotent: safe to re-run.

set -euo pipefail

# Resolve repo root even when invoked through the symlink target
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR=$(cd -P "$(dirname "$SOURCE")" && pwd)
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
ROOT=$(cd -P "$(dirname "$SOURCE")/.." && pwd)
SRC="$ROOT/herdr/config.toml"

# --- sanity check / package warning ------------------------------------------
if ! command -v herdr > /dev/null; then
  echo "warn: herdr not found on PATH — config installed anyway;" \
    "(usually ~/.local/bin/herdr) install it to use the config" >&2
fi
if [ ! -f "$SRC" ]; then
  echo "error: $SRC missing — is the repo intact?" >&2
  exit 1
fi

TARGET_DIR="$HOME/.config/herdr"
TARGET="$TARGET_DIR/config.toml"

# --- back up an existing real config file -------------------------------------
if [ -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
  TS=$(date +%Y%m%d-%H%M%S)
  BACKUP="${TARGET}.bak-${TS}"
  echo "-> existing config found; moving it to ${BACKUP} (untouched, not deleted)"
  mv "$TARGET" "$BACKUP"
fi

# --- the symlink ---------------------------------------------------------------
mkdir -p "$TARGET_DIR"
ln -sfn "$SRC" "$TARGET"
echo "-> ${TARGET} -> ${SRC}"

echo
echo "done — restart herdr to pick up changes"
