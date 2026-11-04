#!/usr/bin/env bash
# install.sh — rewire ~/.bashrc to the DotVibes decoupled shell files
# (one of several components; the top-level install.sh runs this for you).
#
# Design: ~/.bashrc returns to (nearly) the pristine Debian skeleton; all
# DotVibes logic lives in per-topic files under ~/.config/bash/:
#
#   .env_vars   environment variables — LOCAL-ONLY, never in the repo
#               (created from bash/env_vars.example if missing)
#   .paths      every PATH addition in one place
#   .mamba      micromamba initialization
#   .aliases    shell aliases (replaces the old ~/.bash_aliases hook)
#   .prompt     the two-line prompt (git + python env detection)
#
# ~/.bashrc gets exactly two tiny blocks that source those files:
#   top —    before the interactive check, so env vars/PATH/mamba also work
#            in non-interactive shells (script hooks, ssh, ...)
#   bottom — after the interactive check, so aliases/prompt win over the
#            skeleton's own choices
# Everything else (backups, symlinks) never clobbers: idempotent, safe to
# re-run.

set -euo pipefail

# Resolve repo root even when invoked through the symlink target
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR=$(cd -P "$(dirname "$SOURCE")" && pwd)
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
ROOT=$(cd -P "$(dirname "$SOURCE")/.." && pwd)
REPO_SHELL="$ROOT/bash"

TARGET="$HOME/.config/bash"
BASHRC="$HOME/.bashrc"
SKEL="/etc/skel/.bashrc"
TS=$(date +%Y%m%d-%H%M%S)

# --- sanity checks --------------------------------------------------------------
if [ ! -d "$REPO_SHELL" ]; then
  echo "error: $REPO_SHELL missing — is the repo intact?" >&2
  exit 1
fi
for f in paths prompt aliases mamba env_vars.example; do
  if [ ! -f "$REPO_SHELL/$f" ]; then
    echo "error: $REPO_SHELL/$f missing — is the repo intact?" >&2
    exit 1
  fi
done

mkdir -p "$TARGET/backups"

# --- 1. wire ~/.bashrc (only if not already wired) -------------------------------
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/top" <<'EOF'
# >>> DotVibes (non-interactive: env vars, PATH, mamba) >>>
_dv_dir="$HOME/.config/bash"
for _dv_file in .env_vars .paths .mamba; do
    [ -r "$_dv_dir/$_dv_file" ] && . "$_dv_dir/$_dv_file"
done
unset _dv_dir _dv_file
# <<< DotVibes <<<
EOF

cat > "$WORK/bottom" <<'EOF'
# >>> DotVibes (interactive: aliases, prompt) >>>
_dv_dir="$HOME/.config/bash"
for _dv_file in .aliases .prompt; do
    [ -r "$_dv_dir/$_dv_file" ] && . "$_dv_dir/$_dv_file"
done
unset _dv_dir _dv_file
# <<< DotVibes <<<
EOF

if [ -f "$BASHRC" ] && grep -q '>>> DotVibes' "$BASHRC"; then
  echo "-> ${BASHRC} already wires the DotVibes files; leaving it as is"
elif [ -r "$SKEL" ] && head -n 1 "$SKEL" | grep -q 'bashrc'; then
  if [ -e "$BASHRC" ]; then
    BACKUP="$HOME/.bashrc.bak-$TS"
    echo "-> existing bashrc found; backed up to ${BACKUP} (untouched, not deleted)"
    cp -p "$BASHRC" "$BACKUP"
  fi
  { head -n 3 "$SKEL"; echo; cat "$WORK/top"; tail -n +4 "$SKEL"; echo; echo; cat "$WORK/bottom"; } > "$WORK/new"
  bash -n "$WORK/new"
  mv "$WORK/new" "$BASHRC"
  echo "-> ${BASHRC} reset to the stock skeleton + the two DotVibes source blocks"
else
  echo "warn: /etc/skel/.bashrc not readable — appending the DotVibes blocks to the existing ${BASHRC} instead of resetting it" >&2
  if [ -e "$BASHRC" ]; then
    BACKUP="$HOME/.bashrc.bak-$TS"
    cp -p "$BASHRC" "$BACKUP"
    echo "-> backed up to ${BACKUP}" >&2
  else
    touch "$BASHRC"
  fi
  cat "$WORK/top" "$WORK/bottom" >> "$BASHRC"
  bash -n "$BASHRC"
fi

# --- 2. symlink the per-topic files ----------------------------------------------
for name in paths prompt aliases mamba; do
  src="$REPO_SHELL/$name"
  dst="$TARGET/.$name"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    echo "-> existing .$(basename "$name") found; moving it to ${TARGET}/backups/$name.$TS (untouched, not deleted)"
    mv "$dst" "$TARGET/backups/$name.$TS"
  fi
  ln -sfn "$src" "$dst"
  echo "-> ${dst} -> ${src}"
done

# --- 3. seed ~/.env_vars if it does not exist (never overwrite!) ------------------
if [ ! -e "$TARGET/.env_vars" ]; then
  cp "$REPO_SHELL/env_vars.example" "$TARGET/.env_vars"
  echo "-> seeded ${TARGET}/.env_vars from the repo template (comments only)"
  echo "warn: no real values in it yet — moved your machine's secrets there manually if intended; missing exports referenced by scripts/apps will be unset" >&2
fi

# --- 4. deprecation notices -------------------------------------------------------
if [ -e "$HOME/.bash_aliases" ]; then
  echo "warn: $HOME/.bash_aliases still exists but is no longer sourced by ~/.bashrc — merge anything you need into ${TARGET}/.aliases" >&2
fi

echo
echo "done — restart your shell (exec bash) or . ${BASHRC} to pick everything up"
