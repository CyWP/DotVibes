#!/usr/bin/env bash
# install.sh — put the DotVibes tmux config in place on this machine
# (one of several components; the top-level install.sh runs this for you):
#   back up any existing real ~/.tmux.conf (leaves it untouched otherwise)
#   symlink ~/.tmux.conf -> <repo>/tmux/tmux.conf
# `xsel` is needed at runtime for the clipboard bindings (checked by the
# top-level check_deps.sh; missing = copies stay inside tmux, nothing breaks).
# Idempotent: safe to re-run.

# Source-safe (see the dispatcher note at the bottom): executing it is still
# the preferred way to run, but `. ./install.sh` is now honored too — no state
# leaks and an internal `exit 1` returns to the shell instead of closing it.
_dv_install() { (
set -uo pipefail


# Resolve repo root even when invoked through the symlink target
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR=$(cd -P "$(dirname "$SOURCE")" && pwd)
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
ROOT=$(cd -P "$(dirname "$SOURCE")/.." && pwd)
CONF_SRC="$ROOT/tmux/tmux.conf"

# --- sanity check / package warning ------------------------------------------
if ! command -v tmux > /dev/null; then
  echo "warn: tmux not found on PATH — config installed anyway;" \
    "(apt install tmux / your package manager) needed to use it" >&2
fi
if [ ! -f "$CONF_SRC" ]; then
  echo "error: $CONF_SRC missing — is the repo intact?" >&2
  exit 1
fi

TARGET="$HOME/.tmux.conf"

# --- back up an existing real config file ------------------------------------
if [ -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
  TS=$(date +%Y%m%d-%H%M%S)
  BACKUP="${TARGET}.bak-${TS}"
  echo "-> existing config found; moving it to ${BACKUP} (untouched, not deleted)"
  mv "$TARGET" "$BACKUP"
fi

# --- the symlink -------------------------------------------------------------
ln -sfn "$CONF_SRC" "$TARGET"
echo "-> ${TARGET} -> ${CONF_SRC}"

# --- reload into running sessions (best effort) --------------------------------
if command -v tmux > /dev/null; then
  if tmux info > /dev/null 2>&1 || [ -S "${TMPDIR:-/tmp}/tmux-$(id -u)/default" ]; then
    tmux source-file "$TARGET" && echo "-> running tmux session(s) reloaded"
  else
    echo "-> no running tmux server — the config loads on next tmux start"
  fi
fi

echo
echo "done — tmux picks the config up on its next start (or after the reload above)"
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
