#!/usr/bin/env bash
# install.sh — put the DotVibes opencode CLI settings in place on this machine
# (one of several components; the top-level install.sh runs this for you):
#   back up any existing real ~/.config/opencode/cli.json (untouched otherwise)
#   symlink ~/.config/opencode/cli.json -> <repo>/opencode/cli.json
#
# Scope note: cli.json holds the terminal-client preferences (theme, tabs,
# input, keybinds, ...). Deliberately NOT managed here:
#   opencode.jsonc / tui.jsonc — server/project config + TUI plugin wiring,
#     currently trivial/herdr-owned; promote into this component if they grow
#   commands/  — linked by the agents component
#   plugins/, herdr-opencode/, herdr-tui-session.js — herdr setup, not DotVibes
# The `plugins: ["./herdr-opencode"]` entry stays in the tracked cli.json: the
# path is resolved relative to the config dir, so the symlink keeps it working.
# The TUI watches cli.json — changes reload live, no restart needed.
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
CONF_SRC="$ROOT/opencode/cli.json"

# --- sanity check / package warning ------------------------------------------
if ! command -v opencode > /dev/null; then
  echo "warn: opencode not found on PATH — config installed anyway;" \
    "(see https://opencode.ai/docs) needed to use it" >&2
fi
if [ ! -f "$CONF_SRC" ]; then
  echo "error: $CONF_SRC missing — is the repo intact?" >&2
  exit 1
fi

TARGET="$HOME/.config/opencode/cli.json"
mkdir -p "$HOME/.config/opencode"

# --- back up an existing real config file ------------------------------------
if [ -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
  TS=$(date +%Y%m%d-%H%M%S)
  BACKUP="${TARGET}.bak-${TS}"
  echo "-> existing cli.json found; moving it to ${BACKUP} (untouched, not deleted)"
  mv "$TARGET" "$BACKUP"
fi

# --- the symlink -------------------------------------------------------------
ln -sfn "$CONF_SRC" "$TARGET"
echo "-> ${TARGET} -> ${CONF_SRC}"

echo
echo "done — a running TUI reloads cli.json live; no restart needed"
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
