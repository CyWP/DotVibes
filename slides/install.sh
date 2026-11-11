#!/usr/bin/env bash
# install.sh — put the DotVibes Marp slide tooling in place on this machine
# (one of several components; the top-level install.sh runs this for you):
#   commands/marp-slides.md -> ~/.claude/commands + ~/.config/opencode/commands
#   marp.css           -> ~/.config/marp/marp.css      (theme "dotvibes")
#   marp-dark.css      -> ~/.config/marp/marp-dark.css (theme "dotvibes-dark")
#   (marp-build lives in bin/ so cmdlist shows it; bin/install.sh links it)
# Links only; an existing real file at a target is moved aside to *.bak-<ts>.
# Needs marp-cli (marp or npx) at use time, not install time — see check_deps.sh.
# Idempotent: safe to re-run.

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
SRC="$ROOT/slides"

for f in marp.css marp-dark.css commands/marp-slides.md; do
  if [ ! -e "$SRC/$f" ]; then
    echo "error: $SRC/$f missing — is the repo intact?" >&2
    exit 1
  fi
done

TS=$(date +%Y%m%d-%H%M%S)
link() { # $1 = link path, $2 = source
  mkdir -p "$(dirname "$1")"
  if [ -e "$1" ] && [ ! -L "$1" ]; then
    echo "-> existing $1 found; moving it to $1.bak-$TS (untouched, not deleted)"
    mv "$1" "$1.bak-$TS"
  fi
  ln -sfn "$2" "$1"
  echo "-> $1 -> $2"
}

link "$HOME/.claude/commands/marp-slides.md" "$SRC/commands/marp-slides.md"
link "$HOME/.config/opencode/commands/marp-slides.md" "$SRC/commands/marp-slides.md"
link "$HOME/.config/marp/marp.css" "$SRC/marp.css"
link "$HOME/.config/marp/marp-dark.css" "$SRC/marp-dark.css"

if ! command -v marp > /dev/null && ! command -v npx > /dev/null; then
  echo "warn: neither marp nor npx found — marp-build won't work until" \
    "marp-cli is installed (npm i -g @marp-team/marp-cli)" >&2
fi

echo
echo "done — /marp-slides loads on the next claude session"
)
}

# --- source-safe dispatcher ----------------------------------------------------
# Executed: run the install, exit with its status (unchanged behavior).
# Sourced: run it in the subshell above, then `return` the status so the
# interactive shell survives.
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
