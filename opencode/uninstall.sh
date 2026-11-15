#!/usr/bin/env bash
# uninstall.sh — undo opencode/install.sh on this machine:
#   remove the ~/.config/opencode/cli.json symlink if it points into this
#   repo (anything else there is left untouched) and restore the most recent
#   cli.json.bak-* backup. The top-level uninstall.sh undoes this component
#   the same way; this script exists so the component is self-contained.
# Deliberately NOT touched: opencode.jsonc, tui.jsonc, plugins/, commands/,
# herdr-* — none of them are this component's links.
# Idempotent: safe to re-run.

# Source-safe (see the dispatcher at the bottom): executing it is still
# the preferred way to run, but `. ./uninstall.sh` is now honored too.
_dv_uninstall() { (
set -uo pipefail

# Resolve repo root even when invoked through the symlink target
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR=$(cd -P "$(dirname "$SOURCE")" && pwd)
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
ROOT=$(cd -P "$(dirname "$SOURCE")/.." && pwd)

TARGET="$HOME/.config/opencode/cli.json"

# --- drop our link -------------------------------------------------------------
if [ -L "$TARGET" ]; then
  case "$(readlink "$TARGET")" in
    "$ROOT"/*)
      rm "$TARGET"
      echo "-> removed $TARGET"
      ;;
    *)
      echo "warn: $TARGET is not a DotVibes symlink — left untouched" >&2
      ;;
  esac
elif [ -e "$TARGET" ]; then
  echo "warn: $TARGET is not a DotVibes symlink — left untouched" >&2
fi

# --- restore the newest backup, if any -----------------------------------------
NEWEST=$(ls -1 -- "$TARGET".bak-* 2>/dev/null | LC_ALL=C sort | tail -1)
if [ -n "$NEWEST" ]; then
  if [ ! -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
    mv "$NEWEST" "$TARGET"
    echo "-> restored $TARGET (from $(basename "$NEWEST"))"
  else
    echo "warn: cli.json backup exists beside $TARGET but something else is now" \
      "installed there — left for manual review" >&2
  fi
fi

echo
echo "uninstall finished. re-run opencode/install.sh to restore it."
)
}

# --- source-safe dispatcher ----------------------------------------------------
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  _dv_uninstall
  _dv_st=$?
  unset -f _dv_uninstall
  exit "$_dv_st"
fi
_dv_uninstall
_dv_st=$?
unset -f _dv_uninstall
return "$_dv_st"
