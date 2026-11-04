#!/usr/bin/env bash
# install.sh — set the wallpaper this repo ships (appearance/bg.png)
# (one of several components; the top-level install.sh runs this for you):
#   copy the image into ~/.local/share/backgrounds/ (stable location, survives
#   repo moves/deletions) and point GNOME's background keys at the copy for
#   both light and dark mode.
# Needs a gsettings/GNOME session; without one it warns and leaves the
# wallpaper alone instead of guessing.
# Idempotent: safe to re-run (skips when the URI already matches).

# Source-safe (see the dispatcher at the bottom): executing it is still
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
ROOT=$(cd -P "$(dirname "$SOURCE")/.." && pwd)
IMG_SRC="$ROOT/appearance/bg.png"

# --- sanity check -------------------------------------------------------------
if [ ! -f "$IMG_SRC" ]; then
  echo "error: $IMG_SRC missing — is the repo intact?" >&2
  exit 1
fi
if ! command -v gsettings > /dev/null; then
  echo "warn: gsettings not found (no GNOME?) — wallpaper not changed" >&2
  exit 0
fi

DEST="$HOME/.local/share/backgrounds"
URI="file://$DEST/DotVibes-bg.png"
mkdir -p "$DEST"

# --- the copy (mtime preserved) -----------------------------------------------
if ! cmp -s "$IMG_SRC" "$DEST/DotVibes-bg.png"; then
  install -p -m 644 "$IMG_SRC" "$DEST/DotVibes-bg.png"
  echo "-> wallpaper image copied to ${DEST}/DotVibes-bg.png"
fi

# --- set it (light + dark variants) --------------------------------------------
if [ "$(gsettings get org.gnome.desktop.background picture-uri)" = "'$URI'" ] \
   && [ "$(gsettings get org.gnome.desktop.background picture-uri-dark)" = "'$URI'" ]; then
  echo "-> wallpaper already points at DotVibes-bg.png"
  exit 0
fi
if ! gsettings set org.gnome.desktop.background picture-uri "$URI" \
  || ! gsettings set org.gnome.desktop.background picture-uri-dark "$URI" \
  || ! gsettings set org.gnome.desktop.background picture-options 'zoom'; then
  echo "warn: gsettings write failed (no DBus session? run it inside a desktop session)" >&2
  exit 1
fi
echo "-> wallpaper set: light + dark mode, zoom fill"

exit 0
)
}

# --- source-safe dispatcher ----------------------------------------------------
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
