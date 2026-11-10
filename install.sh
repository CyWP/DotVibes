#!/usr/bin/env bash
# install.sh — set up every DotVibes-managed tool on this machine:
#   nvim, ghostty, herdr, agents, tmux, appearance, fonts, bash, bin — each
#   has its own <component>/install.sh (self-contained; you can also run any
#   of them directly).
# One component failing or a missing binary never blocks the others;
# warnings are logged so nothing goes silently missing.
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
ROOT=$(cd -P "$(dirname "$SOURCE")" && pwd)

COMPONENTS=(nvim ghostty herdr agents tmux appearance fonts bash bin)

declare -a problems=()
for comp in "${COMPONENTS[@]}"; do
  echo
  echo "==> ${comp}"
  SCRIPT="$ROOT/$comp/install.sh"
  if [ ! -x "$SCRIPT" ]; then
    echo "warn: $SCRIPT missing or not executable — skipped (is the repo intact?)" >&2
    problems+=("$comp")
    continue
  fi
  if "$SCRIPT"; then
    echo "<== ${comp} ok"
  else
    echo "warn: ${comp} install reported an error (see above); continuing with the rest" >&2
    problems+=("$comp")
  fi
done

# --- record the repo path, for bin scripts that need to find it again -------------
# bin/update-config sources this file and re-runs install.sh to re-apply the
# configs after you've pulled changes. Written fresh on every install run, so
# moving/re-cloning the repo fixes the path automatically: run ./install.sh
# once from the new location.
# shared variables (DOTVIBES_CONFIG_DIR, ...), loaded straight from the repo
# shellcheck disable=SC1091
. "$ROOT/bash/env_vars"
BASH_DIR="$DOTVIBES_CONFIG_DIR"
mkdir -p "$BASH_DIR"
REPO_FILE="$BASH_DIR/.dotvibes_repo"
cat > "$REPO_FILE" <<EOF
# Path to the DotVibes repo — written by install.sh, read by bin/update-config.
# Local-only (not a repo symlink); re-running ./install.sh rewrites it.
export DOTVIBES_REPO="$ROOT"
EOF
echo "<-> repo path recorded in ${REPO_FILE}"

# --- dependency report -----------------------------------------------------------
# check_deps.sh reports binary/version gaps per component (installs nothing).
# Missing tools are warnings here — the component installers already handled
# their own outcomes; this is the "what will degrade" summary.
echo
echo "==> dependency check"
if [ -x "$ROOT/check_deps.sh" ]; then
  if ! "$ROOT/check_deps.sh"; then
    echo "warn: see the [missing — required] items above; the affected features will degrade" >&2
  fi
else
  echo "warn: $ROOT/check_deps.sh missing — skipped (is the repo intact?)" >&2
fi

echo
if [ "${#problems[@]}" -gt 0 ]; then
  echo "finished, with problems in: ${problems[*]} — see the warnings above"
  exit 1
fi
echo "all done: ${COMPONENTS[*]}"
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
