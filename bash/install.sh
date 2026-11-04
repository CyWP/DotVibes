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
#   .aliases    shell aliases (replaces the old ~/.bash_aliases hook)
#   .prompt     the two-line prompt (git + python env detection)
#   .extra      misc bash code snippets (interactive only — e.g. readline
#               settings like case-insensitive autocompletion)
#
# The micromamba init block and the nvim/opencode PATH lines are TOOL-MANAGED
# (their own installers append them) and live directly in ~/.bashrc — they are
# deliberately NOT repo files. Steps 5–6 below only guarantee what exists on
# this machine still ends up wired after the bashrc reset; see the warnings
# they print on machines missing the tools.
# ~/.bashrc gets exactly two tiny blocks that source those files:
#   top —    before the interactive check, so env vars/PATH/mamba also work
#            in non-interactive shells (script hooks, ssh, ...)
#   bottom — after the interactive check, so aliases/prompt/extra win over the
#            skeleton's own choices
# Everything else (backups, symlinks) never clobbers: idempotent, safe to
# re-run.

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
for f in paths prompt aliases extra env_vars.example; do
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
# >>> DotVibes (non-interactive: env vars, PATH) >>>
_dv_dir="$HOME/.config/bash"
for _dv_file in .env_vars .paths; do
    [ -r "$_dv_dir/$_dv_file" ] && . "$_dv_dir/$_dv_file"
done
unset _dv_dir _dv_file
# <<< DotVibes <<<
EOF

cat > "$WORK/bottom" <<'EOF'
# >>> DotVibes (interactive: aliases, prompt, extra) >>>
_dv_dir="$HOME/.config/bash"
for _dv_file in .aliases .prompt .extra; do
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
for name in paths prompt aliases extra; do
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

# --- 4. migrate older wirings (mamba used to be a DotVibes-sourced file) -----------
# The micromamba init block is tool-managed in ~/.bashrc (see step 5); older
# runs sourced it as ~/.config/bash/.mamba. Clean up the leftovers.
if [ -L "$TARGET/.mamba" ]; then
  rm "$TARGET/.mamba"
  echo "-> removed the stale $TARGET/.mamba symlink (mamba init lives directly in ~/.bashrc now)"
elif [ -e "$TARGET/.mamba" ]; then
  echo "warn: $TARGET/.mamba is a real file, not a repo symlink — left untouched; keep whatever you still need, then delete it" >&2
fi
if grep -q '\.env_vars \.paths \.mamba' "$BASHRC" 2> /dev/null; then
  cp -p "$BASHRC" "$BASHRC.bak-$TS"
  sed -i \
    -e 's/for _dv_file in \.env_vars \.paths \.mamba/for _dv_file in .env_vars .paths/' \
    -e 's/(non-interactive: env vars, PATH, mamba)/(non-interactive: env vars, PATH)/' \
    "$BASHRC"
  bash -n "$BASHRC"
  echo "-> dropped the .mamba source from the DotVibes block in ${BASHRC} (backup at ${BASHRC}.bak-$TS)"
fi
# older wirings didn't source .extra — add it to the interactive block
if grep -q '>>> DotVibes (interactive' "$BASHRC" 2>/dev/null \
   && ! grep -q '\.extra' "$BASHRC" 2>/dev/null; then
  cp -p "$BASHRC" "$BASHRC.bak-$TS"
  sed -i \
    -e 's/for _dv_file in \.aliases \.prompt;/for _dv_file in .aliases .prompt .extra;/' \
    -e 's/(interactive: aliases, prompt)/(interactive: aliases, prompt, extra)/' \
    "$BASHRC"
  bash -n "$BASHRC"
  echo "-> wired .extra into the DotVibes block in ${BASHRC} (backup at ${BASHRC}.bak-$TS)"
fi

# --- 5. guarantee the tool-managed mamba init block exists in ~/.bashrc -----------
# Never carried in the repo: `micromamba shell init` owns this block. Re-runs
# see it and leave it alone; to recreate it, run `micromamba shell init
# --shell bash` yourself instead.
if grep -q '>>> mamba initialize' "$BASHRC" 2> /dev/null; then
  echo "-> mamba init block already in ${BASHRC} (managed by micromamba)"
elif command -v micromamba > /dev/null; then
  cat >> "$BASHRC" <<EOF

# >>> mamba initialize >>>
# !! Contents within this block are managed by 'micromamba shell init' !!
export MAMBA_EXE="$(command -v micromamba)";
export MAMBA_ROOT_PREFIX="$HOME/.micromamba";
__mamba_setup="\$("\$MAMBA_EXE" shell hook --shell bash --root-prefix "\$MAMBA_ROOT_PREFIX" 2> /dev/null)"
if [ \$? -eq 0 ]; then
    eval "\$__mamba_setup"
else
    alias micromamba="\$MAMBA_EXE"  # Fallback on help from micromamba activate
fi
unset __mamba_setup
# <<< mamba initialize <<<
EOF
  bash -n "$BASHRC"
  echo "-> appended the mamba init block to ${BASHRC}"
else
  echo "warn: no micromamba on PATH and no mamba init block in ${BASHRC} — run 'micromamba shell init --shell bash' after installing micromamba" >&2
fi

# --- 6. guarantee tool-installer PATH lines (nvim, opencode) ----------------------
# Their installers append these exports to ~/.bashrc directly. This component
# must stay free of tool-owned lines (bin/, env vars etc.), but the bashrc
# reset below would silently strip an installer's lines, so after wiring we
# re-add what the machine actually has. Idempotent: skipped when the line is
# already present; a missing tool prints a warning instead of a fake line.
ensure_tool_path() { # $1 = binary name, $2 = "append\|prepend"
  local bin dir
  bin=$(command -v "$1" 2>/dev/null) || return 0
  dir=$(dirname "$bin")
  case "$dir" in
    /usr/bin|/bin|/usr/local/bin|/usr/sbin|/sbin) return 0 ;; # no non-standard PATH entry needed
  esac
  if grep -qF -- "$dir" "$BASHRC"; then
    return 0
  fi
  if [ "$2" = prepend ]; then
    printf 'export PATH="%s:$PATH"\n' "$dir" >> "$BASHRC"
  else
    printf 'export PATH="$PATH:%s"\n' "$dir" >> "$BASHRC"
  fi
  echo "-> added the tool-owned PATH line for $1 ($dir) to ${BASHRC}"
}
ensure_tool_path nvim append
ensure_tool_path opencode prepend

# --- 7. deprecation notices -------------------------------------------------------
if [ -e "$HOME/.bash_aliases" ]; then
  echo "warn: $HOME/.bash_aliases still exists but is no longer sourced by ~/.bashrc — merge anything you need into ${TARGET}/.aliases" >&2
fi

echo
echo "done — restart your shell (exec bash) or . ${BASHRC} to pick everything up"
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
