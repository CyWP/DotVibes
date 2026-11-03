#!/usr/bin/env bash
# install.sh — set up every NVibe-managed tool on this machine:
#   nvim, ghostty, herdr, claude — each has its own <component>/install.sh
#   (self-contained; you can also run any of them directly).
# One component failing or a missing binary never blocks the others;
# warnings are logged so nothing goes silently missing.
# Idempotent: safe to re-run.

set -uo pipefail

# Resolve repo root even when invoked through the symlink target
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR=$(cd -P "$(dirname "$SOURCE")" && pwd)
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
ROOT=$(cd -P "$(dirname "$SOURCE")" && pwd)

COMPONENTS=(nvim ghostty herdr claude)

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

echo
if [ "${#problems[@]}" -gt 0 ]; then
  echo "finished, with problems in: ${problems[*]} — see the warnings above"
  exit 1
fi
echo "all done: ${COMPONENTS[*]}"
