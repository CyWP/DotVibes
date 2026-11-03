#!/usr/bin/env bash
# install.sh — put the DotVibes-managed fonts in place on this machine
# (one of several components; the top-level install.sh runs this for you):
#   1. check fontconfig tooling is present (missing = warning, not a failure)
#   2. back up any existing real font files (untouched otherwise)
#   3. symlink each font file -> ~/.local/share/fonts/Monaspace Argon/
#   4. run the fontconfig refresh (fc-cache -f) so Ghostty etc. find them
# Symlinked per file so the target dir can still hold other styles of the
# same family installed alongside. Idempotent: safe to re-run.

set -euo pipefail

# Resolve repo root even when invoked through the symlink target
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR=$(cd -P "$(dirname "$SOURCE")" && pwd)
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
ROOT=$(cd -P "$(dirname "$SOURCE")/.." && pwd)
FONT_SRC_DIR="$ROOT/fonts/Monaspace Argon"

# --- sanity check / package warning ------------------------------------------
if ! command -v fc-cache > /dev/null; then
  echo "warn: fontconfig (fc-cache) not found on PATH — fonts installed anyway;" \
    "install fontconfig so applications can actually discover them" >&2
fi
if [ ! -d "$FONT_SRC_DIR" ]; then
  echo "error: $FONT_SRC_DIR missing — is the repo intact?" >&2
  exit 1
fi

FONT_TARGET_DIR="$HOME/.local/share/fonts/Monaspace Argon"
# backups live outside the fontconfig scan tree, or fc-cache indexes them too
# and font pickers show the same font twice
BACKUP_DIR="$HOME/.local/share/fonts-backups/Monaspace Argon"
mkdir -p "$FONT_TARGET_DIR" "$BACKUP_DIR"

TS=$(date +%Y%m%d-%H%M%S)

# --- back up + symlink each font file -----------------------------------------
for src in "$FONT_SRC_DIR"/*.otf; do
  [ -e "$src" ] || continue
  name=$(basename "$src")
  target="$FONT_TARGET_DIR/$name"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "-> existing $name found; moving it to ${BACKUP_DIR}/${name}.${TS} (untouched, not deleted)"
    mv "$target" "$BACKUP_DIR/$name.$TS"
  fi
  ln -sfn "$src" "$target"
  echo "-> ${target} -> ${src}"
done

# --- the fontconfig refresh ----------------------------------------------------
if command -v fc-cache > /dev/null; then
  fc-cache -f "$FONT_TARGET_DIR" > /dev/null
  echo "-> fontconfig cache refreshed (fc-cache -f)"
fi

echo
echo "done — restart ghostty (or reload: ctrl+shift+,) to pick up the font"
