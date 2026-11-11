#!/usr/bin/env bash
# uninstall.sh — undo the DotVibes config on this machine:
#   remove every symlink the component installers created (only links that
#   point into this repo — anything else in those directories stays), restore
#   the most recent backup of whatever they replaced, clear the wallpaper and
#   the repo-path pointer, and strip the DotVibes blocks back out of
#   ~/.bashrc when no pre-DotVibes snapshot exists.
# Deliberately NOT touched:
#   ~/.config/bash/.env_vars        — your local-only secrets
#   tool-owned lines in ~/.bashrc   — the micromamba init block and the
#   nvim/opencode PATH lines belong to their installers, not this repo
#   plugin/tool data dirs           — neovim data, local tool binaries, ...
# Everything is reversible: re-run install.sh to put it all back.
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
ROOT=$(cd -P "$(dirname "$SOURCE")" && pwd)

COMPONENTS=(nvim ghostty herdr agents tmux appearance fonts bash bin slides)

# --- helpers ---------------------------------------------------------------------
is_ours() { # $1 = path: true iff a symlink pointing into this repo
  [ -L "$1" ] || return 1
  case "$(readlink "$1")" in
    "$ROOT"/*) return 0 ;;
    *) return 1 ;;
  esac
}

remove_link() { # $1 = installed path
  if is_ours "$1"; then
    rm "$1"
    echo "-> removed $1"
  elif [ -e "$1" ] || [ -L "$1" ]; then
    echo "warn: $1 is not a DotVibes symlink — left untouched" >&2
  fi
}

# newest "<target>.bak-*" beside the target (nvim/ghostty/herdr/tmux/agents)
restore_sideways() { # $1 = installed path (already link-removed)
  local tgt="$1" newest
  newest=$(ls -1 -- "$tgt".bak-* 2>/dev/null | LC_ALL=C sort | tail -1)
  [ -n "$newest" ] || return 0
  if [ ! -e "$tgt" ] && [ ! -L "$tgt" ]; then
    mv "$newest" "$tgt"
    echo "-> restored $tgt (from $(basename "$newest"))"
  else
    echo "warn: backup exists beside $tgt but something else is now installed there — left for manual review" >&2
  fi
}

# default config file/dir: remove our link, then bring the newest backup back
undo_default() { # $1 = installed path
  remove_link "$1"
  restore_sideways "$1"
}

# backups moved into a dedicated dir as "<name>.<TS>" (bin/fonts/bash topics)
restore_from_dir() { # $1 = name, $2 = backup dir, $3 = destination path
  local name="$1" bdir="$2" dst="$3" newest
  newest=$(ls -1 -- "$bdir/$name."* 2>/dev/null | LC_ALL=C sort | tail -1)
  [ -n "$newest" ] || return 0
  if [ ! -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$newest" "$dst"
    echo "-> restored $dst (from $(basename "$newest"))"
  elif is_ours "$dst"; then
    rm "$dst"; mv "$newest" "$dst"
    echo "-> replaced the DotVibes link at $dst with $(basename "$newest")"
  else
    echo "warn: backup for $name exists in $bdir but '$dst' is not DotVibes-owned — left for manual review" >&2
  fi
}

undo_component() {
  echo
  echo "==> $1"
  case "$1" in
    nvim)     undo_default "$HOME/.config/nvim" ;;
    ghostty)  undo_default "$HOME/.config/ghostty/config.ghostty" ;;
    herdr)    undo_default "$HOME/.config/herdr/config.toml" ;;
    tmux)     undo_default "$HOME/.tmux.conf" ;;
    agents)
      local d f
      for d in "$HOME/.claude/skills"; do
        for f in "$d"/*; do [ -e "$f" ] || [ -L "$f" ] || continue; undo_default "$f"; done
      done
      for d in "$HOME/.claude/commands" "$HOME/.config/opencode/commands"; do
        for f in "$d"/*; do [ -e "$f" ] || [ -L "$f" ] || continue; undo_default "$f"; done
      done
      ;;
    appearance)
      IMG="$HOME/.local/share/backgrounds/DotVibes-bg.png"
      if command -v gsettings > /dev/null 2>&1; then
        ours=0
        for key in picture-uri picture-uri-dark; do
          if [ "$(gsettings get org.gnome.desktop.background "$key" 2>/dev/null)" = "'file://$IMG'" ]; then
            gsettings reset "org.gnome.desktop.background" "$key" \
              && { echo "-> reset org.gnome.desktop.background/$key"; ours=1; }
          fi
        done
        [ "$ours" = 1 ] && gsettings reset "org.gnome.desktop.background" "picture-options" \
          && echo "-> reset org.gnome.desktop.background/picture-options"
      else
        echo "warn: gsettings missing — wallpaper keys not reset" >&2
      fi
      if [ -f "$IMG" ]; then rm "$IMG"; echo "-> removed $IMG"; fi
      ;;
    fonts)
      local d f b name fam_dir fam
      for fam_dir in "$ROOT/fonts"/*/; do
        [ -d "$fam_dir" ] || continue
        fam=$(basename "$fam_dir")
        d="$HOME/.local/share/fonts/$fam"
        for f in "$d"/*; do [ -e "$f" ] || [ -L "$f" ] || continue; remove_link "$f"; done
        for b in "$HOME/.local/share/fonts-backups/$fam"/*; do
          [ -e "$b" ] || continue
          name="${b##*/}"; name="${name%.*}"
          restore_from_dir "$name" "$HOME/.local/share/fonts-backups/$fam" "$d/$name"
        done
      done
      if command -v fc-cache > /dev/null 2>&1; then fc-cache -f > /dev/null 2>&1; echo "-> fontconfig cache refreshed"; fi
      ;;
    bash)
      local BASHRC="$HOME/.bashrc" T="$HOME/.config/bash" name f pristine
      # 1. per-topic files: drop our symlinks, restore the newest backup
      for name in paths prompt aliases extra; do
        f="$T/.$name"
        remove_link "$f"
        restore_from_dir "$name" "$T/backups" "$f"
      done
      # 2. .env_vars is LOCAL-ONLY content (secrets) — never removed
      [ -f "$T/.env_vars" ] && echo "-> kept $T/.env_vars (local-only secrets — remove manually if desired)"
      # 3. the repo-path pointer
      if [ -f "$T/.dotvibes_repo" ]; then rm "$T/.dotvibes_repo"; echo "-> removed $T/.dotvibes_repo"; fi
      # 4. ~/.bashrc: restore a pre-DotVibes snapshot if one exists; else strip
      if [ -f "$BASHRC" ]; then
        pristine=""
        for b in $(ls -1 -- "$BASHRC".bak-* 2>/dev/null | LC_ALL=C sort -r); do
          if ! grep -q '>>> DotVibes' "$b" 2>/dev/null; then pristine="$b"; break; fi
        done
        if [ -n "$pristine" ]; then
          if cmp -s "$pristine" "$BASHRC"; then
            echo "-> ${BASHRC} already matches the pristine snapshot"
          else
            cp -p "$pristine" "$BASHRC"
            echo "-> restored ${BASHRC} from $(basename "$pristine")"
          fi
        elif grep -q '>>> DotVibes' "$BASHRC"; then
          cp -p "$BASHRC" "$BASHRC.bak-uninstall-$(date +%Y%m%d-%H%M%S)"
          sed -i '/^# >>> DotVibes /,/^# <<< DotVibes <<</d' "$BASHRC"
          bash -n "$BASHRC" \
            && echo "-> stripped the DotVibes blocks from ${BASHRC} (snapshot saved next to it)" \
            || echo "warn: ${BASHRC} failed bash -n after stripping — restore from the saved snapshot" >&2
        else
          echo "-> ${BASHRC} has no DotVibes wiring — untouched"
        fi
        echo "-> kept tool-owned lines (micromamba init, nvim/opencode PATH) — they belong to their installers"
      fi
      ;;
    bin)
      local f b name
      for f in "$HOME/.local/bin"/*; do [ -e "$f" ] || [ -L "$f" ] || continue; remove_link "$f"; done
      for b in "$HOME/.local/bin-backups"/*; do
        [ -e "$b" ] || continue
        name="${b##*/}"; name="${name%.*}"
        restore_from_dir "$name" "$HOME/.local/bin-backups" "$HOME/.local/bin/$name"
      done
      ;;
    slides)
      # the marp-slides command and marp-build links are already swept by the
      # agents / bin topics; only the theme CSS is slides-specific
      undo_default "$HOME/.config/marp/marp.css"
      undo_default "$HOME/.config/marp/marp-dark.css"
      ;;
  esac
}

for comp in "${COMPONENTS[@]}"; do
  undo_component "$comp"
done

echo
echo "uninstall finished. re-run ./install.sh (or update-config) to restore everything."
exit 0
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
