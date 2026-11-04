#!/usr/bin/env bash
# install.sh — put the DotVibes hand-written scripts in place on this machine
# (one of several components; the top-level install.sh runs this for you):
#   back up + symlink every repo bin/* into ~/.local/bin
# Only versioned scripts land there; tool-managed binaries that already live
# in ~/.local/bin (pip/uv entry points, micromamba, clangd, tree-sitter, ...)
# are deliberately NOT part of this component and stay untouched.
# The scripts are on PATH via bash/.paths (they need ~/.local/bin).
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

# --- 2. remove stale symlinks pointing into this repo -----------------------------
# Handles renames/deletions in bin/ (e.g. updatedesktop -> update-desktop):
# without this, an old link sits broken in ~/.local/bin forever. Only links
# INTO the repo are touched — this dir is intentionally shared with
# tool-managed binaries (pip entry points, micromamba, clangd, ...).
for dst in "$TARGET"/*; do
  [ -L "$dst" ] || continue
  tgt=$(readlink "$dst")
  case "$tgt" in
    "$SRC_DIR"/*)
      if [ ! -e "$tgt" ]; then
        rm "$dst"
        echo "-> removed stale symlink $dst (script no longer exists in the repo)"
      fi
      ;;
  esac
done

if [ "$count" -eq 0 ]; then
  echo "warn: no scripts found in $SRC_DIR — nothing installed" >&2
fi

echo
echo "done — ${count} scripts on PATH via ~/.local/bin (see bash/.paths)"
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
