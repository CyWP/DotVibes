#!/usr/bin/env bash
# install.sh — put the DotVibes platform-agnostic skill/command set in place on
# this machine (one of several components; the top-level install.sh runs this).
#
#   skills   ~/.claude/skills/<name> — a single link serves both tools:
#            claude reads it natively and opencode reads it as a global
#            compatibility source (see opencode docs: skills discovery)
#   commands ~/.claude/commands/<name>.md (claude) AND
#            ~/.config/opencode/commands/<name>.md (opencode — it does not
#            read ~/.claude/commands, so this needs its own link)
#
#   1. check claude is on PATH (missing = warning, not a failure)
#   2. back up any existing real skill/commands (untouched otherwise)
#   3. symlink each skill dir + each command file into the config dirs
# Only repo paths get linked; anything else in those dirs stays local.
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
SKILLS_SRC="$ROOT/claude/skills"
COMMANDS_SRC="$ROOT/claude/commands"

# --- sanity check / package warning ------------------------------------------
if ! command -v claude > /dev/null; then
  echo "warn: claude not found on PATH — configs installed anyway;" \
    "(claude.ai/code / npm i -g @anthropic-ai/claude-code) needed to use them" >&2
fi

if [ ! -d "$SKILLS_SRC" ] || [ ! -d "$COMMANDS_SRC" ]; then
  echo "error: $SKILLS_SRC or $COMMANDS_SRC missing — is the repo intact?" >&2
  exit 1
fi

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
