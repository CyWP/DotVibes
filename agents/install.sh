#!/usr/bin/env bash
# install.sh — put the DotVibes skill set in place on this machine
# (one of several components; the top-level install.sh runs this for you).
#
#   skills   ~/.claude/skills/<name> — a single link serves both tools:
#            claude reads it natively and opencode reads it as a global
#            compatibility source (see opencode docs: skills discovery)
#
# NOTE on commands: the repo no longer carries any command files. learn/rmslop
# (and similar) are default opencode commands and live inside the tool; if own
# commands are added again, drop the .md files back into agents/commands/ and
# they get linked into ~/.claude/commands AND ~/.config/opencode/commands
# (opencode does not read ~/.claude/commands, so it needs its own link).
#
#   1. check claude is on PATH (missing = warning, not a failure)
#   2. back up any existing real skill/commands (untouched otherwise)
#   3. symlink each skill dir (and optional command file) into the config dirs
#   4. prune stale repo links (skills/commands that vanished from the repo)
# Only repo paths get linked; anything else in those dirs stays local.
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
SKILLS_SRC="$ROOT/agents/skills"
COMMANDS_SRC="$ROOT/agents/commands"

# --- sanity check / package warning ------------------------------------------
if ! command -v claude > /dev/null; then
  echo "warn: claude not found on PATH — configs installed anyway;" \
    "(claude.ai/code / npm i -g @anthropic-ai/claude-code) needed to use them" >&2
fi

if [ ! -d "$SKILLS_SRC" ]; then
  echo "error: $SKILLS_SRC missing — is the repo intact?" >&2
  exit 1
fi
# commands are optional (see header note); the empty/missing dir is fine

SKILLS_TARGET_DIR="$HOME/.claude/skills"
COMMANDS_TARGET_DIRS=("$HOME/.claude/commands" "$HOME/.config/opencode/commands")

TS=$(date +%Y%m%d-%H%M%S)

# back up an existing real file/dir that a symlink is about to replace
backup_and_link() { # $1 = path to link as, $2 = source
  local target="$1" src="$2"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    BACKUP="${target}.bak-${TS}"
    echo "-> existing $(basename "$target") found; moving it to ${BACKUP} (untouched, not deleted)"
    mv "$target" "$BACKUP"
  fi
  ln -sfn "$src" "$target"
  echo "-> ${target} -> ${src}"
}

if [ -n "$(ls -A "$SKILLS_SRC" 2> /dev/null)" ]; then
  mkdir -p "$SKILLS_TARGET_DIR"
  for src in "$SKILLS_SRC"/*/; do
    backup_and_link "$SKILLS_TARGET_DIR/$(basename "$src")" "${src%/}"
  done
fi

# prune symlinks that point into this repo but whose skill/command no longer
# exists (e.g. skills merged or renamed — python-fmt etc. fold into `python`)
prune_stale() { # $1 = target dir, $2 = source dir pattern prefix
  local dst tgt
  for dst in "$1"/*; do
    [ -L "$dst" ] || continue
    tgt=$(readlink "$dst")
    case "$tgt" in
      "$2"/*)
        if [ ! -e "$tgt" ]; then
          rm "$dst"
          echo "-> removed stale link $dst (no longer in the repo)"
        fi
        ;;
    esac
  done
}
for target_dir in "$SKILLS_TARGET_DIR" "${COMMANDS_TARGET_DIRS[@]}"; do
  prune_stale "$target_dir" "$ROOT"
done

if [ -n "$(ls -A "$COMMANDS_SRC" 2> /dev/null)" ]; then
  for target_dir in "${COMMANDS_TARGET_DIRS[@]}"; do
    mkdir -p "$target_dir"
    for src in "$COMMANDS_SRC"/*.md; do
      [ -e "$src" ] || continue
      backup_and_link "$target_dir/$(basename "$src")" "$src"
    done
  done
fi

echo
echo "done — skills/commands load on the next claude (and opencode) session"
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
