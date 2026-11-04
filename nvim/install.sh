#!/usr/bin/env bash
# install.sh — put the DotVibes Neovim config in place on this machine
# (one of several components; the top-level install.sh runs this for you):
#   1. back up any existing ~/.config/nvim (leaves it untouched otherwise)
#   1. back up any existing ~/.config/nvim (leaves it untouched otherwise)
#   2. symlink ~/.config/nvim -> <repo>/nvim
#   3. install all plugins headlessly (first launch is ready to use)
#   4. run the tool checklist (scripts/bootstrap.sh, warnings only)
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
NVIM_SRC="$ROOT/nvim"

# --- sanity checks -----------------------------------------------------------
if ! command -v nvim > /dev/null; then
  echo "error: nvim not found on PATH (needs >= 0.12 — see README)" >&2
  exit 1
fi
if [ ! -d "$NVIM_SRC" ]; then
  echo "error: $NVIM_SRC missing — is the repo intact?" >&2
  exit 1
fi

TARGET="$HOME/.config/nvim"

# --- 1. back up an existing real config directory ----------------------------
if [ -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
  TS=$(date +%Y%m%d-%H%M%S)
  BACKUP="${TARGET}.bak-${TS}"
  echo "-> existing config found; moving it to ${BACKUP} (untouched, not deleted)"
  mv "$TARGET" "$BACKUP"
fi

# --- 2. the symlink ----------------------------------------------------------
mkdir -p "$(dirname "$TARGET")"
ln -sfn "$NVIM_SRC" "$TARGET"
echo "-> ${TARGET} -> ${NVIM_SRC}"

# --- 3. headless plugin install ----------------------------------------------
# First run clones lazy.nvim + every plugin + treesitter parsers, so the very
# first interactive launch is already set up. Errors are non-fatal here:
# `:Lazy` inside nvim can always finish the job.
echo "-> installing plugins (first run: clones lazy.nvim, plugins, parsers...)"
if ! nvim --headless "+Lazy! sync" +qa; then
  echo "warn: plugin sync reported errors; you can finish with :Lazy sync later"
fi

# --- 4. tool checklist -------------------------------------------------------
echo
echo "-> tool checklist:"
"$TARGET/scripts/bootstrap.sh" || true

echo
echo "done — run: nvim"
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
