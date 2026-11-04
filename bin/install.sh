#!/usr/bin/env bash
# install.sh — put the DotVibes hand-written scripts in place on this machine
# (one of several components; the top-level install.sh runs this for you):
#   back up + symlink every repo bin/* into ~/.local/bin
# Only versioned scripts land there; tool-managed binaries that already live
# in ~/.local/bin (pip/uv entry points, micromamba, clangd, tree-sitter, ...)
# are deliberately NOT part of this component and stay untouched.
# The scripts are on PATH via bash/.paths (they need ~/.local/bin).
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
SRC_DIR="$ROOT/bin"

# --- sanity check ----------------------------------------------------------------
if [ ! -d "$SRC_DIR" ]; then
  echo "error: $SRC_DIR missing — is the repo intact?" >&2
  exit 1
fi
ls -A "$SRC_DIR" > /dev/null 2>&1 || true

TARGET="$HOME/.local/bin"
BACKUP_DIR="$HOME/.local/bin-backups"
TS=$(date +%Y%m%d-%H%M%S)
mkdir -p "$TARGET" "$BACKUP_DIR"

# --- back up + symlink each script ------------------------------------------------
count=0
for src in "$SRC_DIR"/*; do
  [ -f "$src" ] || continue
  name=$(basename "$src")
  # the installer itself is not a user script — keep it out of PATH
  [ "$name" = "install.sh" ] && continue
  target="$TARGET/$name"
  if [ -e "$target" ] || [ -L "$target" ]; then
    if [ ! -L "$target" ]; then
      echo "-> existing $name found; moving it to ${BACKUP_DIR}/$name.$TS (untouched, not deleted)"
      mv "$target" "$BACKUP_DIR/$name.$TS"
    fi
  fi
  ln -sfn "$src" "$target"
  echo "-> ${target} -> ${src}"
  count=$((count + 1))
done

if [ "$count" -eq 0 ]; then
  echo "warn: no scripts found in $SRC_DIR — nothing installed" >&2
fi

echo
echo "done — ${count} scripts on PATH via ~/.local/bin (see bash/.paths)"
