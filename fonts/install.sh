#!/usr/bin/env bash
# install.sh — put the DotVibes-managed fonts in place on this machine
# (one of several components; the top-level install.sh runs this for you):
#   1. check fontconfig tooling is present (missing = warning, not a failure)
#   2. back up any existing real font files (untouched otherwise)
#   3. symlink each font file -> ~/.local/share/fonts/<Family>/
#      (folders: Monaspace Argon, Areal, garamond — see fonts/*/SOURCE.md notes)
#   4. run the fontconfig refresh (fc-cache -f) so Ghostty etc. find them
# Symlinked per file so the target dir can still hold other styles of the
# same family installed alongside. Idempotent: safe to re-run.

# Source-safe (see the dispatcher note at the bottom): executing it is still
# the preferred way to run, but `. ./install.sh` is also honored — no state
# leaks and an internal `exit 1` returns to the shell instead of closing it.
_dv_install() { (
set -euo pipefail


# Resolve repo root even when invoked through the symlink target
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR=$(cd -P "$(dirname "$SOURCE")" && pwd)
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
ROOT=$(cd -P "$(dirname "$SOURCE")/.." && pwd)
FONTS_ROOT="$ROOT/fonts"

# --- sanity check / package warning ------------------------------------------
if ! command -v fc-cache > /dev/null; then
  echo "warn: fontconfig (fc-cache) not found on PATH — fonts installed anyway;" \
    "install fontconfig so applications can actually discover them" >&2
fi
if [ ! -d "$FONTS_ROOT" ]; then
  echo "error: $FONTS_ROOT missing — is the repo intact?" >&2
  exit 1
fi

FONT_TARGET_ROOT="$HOME/.local/share/fonts"
BACKUP_ROOT="$HOME/.local/share/fonts-backups"
TS=$(date +%Y%m%d-%H%M%S)

# --- back up + symlink each font file, per family folder -----------------------
installed=0
for family_dir in "$FONTS_ROOT"/*/; do
  [ -d "$family_dir" ] || continue
  family=$(basename "$family_dir")
  FONT_TARGET_DIR="$FONT_TARGET_ROOT/$family"
  BACKUP_DIR="$BACKUP_ROOT/$family"
  shopt -s nullglob
  files=("$family_dir"*.otf "$family_dir"*.ttf)
  shopt -u nullglob
  [ ${#files[@]} -gt 0 ] || continue
  mkdir -p "$FONT_TARGET_DIR" "$BACKUP_DIR"
  for src in "${files[@]}"; do
    name=$(basename "$src")
    target="$FONT_TARGET_DIR/$name"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      echo "-> existing $family/$name found; moving it to ${BACKUP_DIR}/${name}.${TS} (untouched, not deleted)"
      mv "$target" "$BACKUP_DIR/$name.$TS"
    fi
    ln -sfn "$src" "$target"
    echo "-> ${target} -> ${src}"
    installed=$((installed + 1))
  done
  # --- the fontconfig refresh ----------------------------------------------------
  if command -v fc-cache > /dev/null; then
    fc-cache -f "$FONT_TARGET_DIR" > /dev/null
  fi
done

if command -v fc-cache > /dev/null; then
  echo "-> fontconfig cache refreshed (fc-cache -f)"
fi

echo
echo "done — ${installed} font files installed; restart ghostty (or reload: ctrl+shift+,) to pick up the font"
)
}

# --- source-safe dispatcher ----------------------------------------------------
# Executed: run the install, exit with its status (unchanged behavior).
# Sourced: run it in the subshell above, then `return` the status so the
# interactive shell survives. Same pattern as check_deps.sh's _check_deps_run.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  _dv_install
  _dv_st=$?
  unset -f _dv_install
  exit "$_dv_st"
fi
_dv_install
_dv_st=$?
unset -f _dv_install
return "$_dv_st"
