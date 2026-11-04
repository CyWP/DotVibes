#!/usr/bin/env bash
# install.sh — put the DotVibes Ghostty config in place on this machine
# (one of several components; the top-level install.sh runs this for you):
#   1. check ghostty is on PATH (missing = warning, not a failure)
#   2. back up an existing ~/.config/ghostty/config.ghostty (untouched otherwise)
#   3. symlink it -> <repo>/ghostty/config.ghostty
# Only the config file is linked; everything else in that dir stays local.
# Idempotent: safe to re-run.

# Source-safe (see the dispatcher note at the bottom): executing it is still
# the preferred way to run, but `. ./install.sh` is now honored too — no state
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
SRC="$ROOT/ghostty/config.ghostty"

# --- sanity check / package warning ------------------------------------------
if ! command -v ghostty > /dev/null; then
  echo "warn: ghostty not found on PATH — config installed anyway;" \
    "get it from https://ghostty.org (or your package manager) to use it" >&2
fi
if [ ! -f "$SRC" ]; then
  echo "error: $SRC missing — is the repo intact?" >&2
  exit 1
fi

TARGET_DIR="$HOME/.config/ghostty"
TARGET="$TARGET_DIR/config.ghostty"

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
echo "done — reload ghostty (ctrl+shift+,) or restart it to pick up changes"
)
}

# --- source-safe dispatcher ----------------------------------------------------
# Executed: run the install, exit with its status (unchanged behavior).
# Sourced: run it in the subshell above, then `return` the status so the
# interactive shell survives; the set-flags and all script variables die with
# the subshell. Same pattern as check_deps.sh's _check_deps_run.
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
