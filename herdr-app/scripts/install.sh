#!/bin/sh
# Install herdr-tui-layout into the Herdr app (herdr-app).
#
#   ./scripts/install.sh                 install, or bring an earlier install up to date
#   ./scripts/install.sh --usage-hook    also set up the status line's Claude usage numbers
#   ./scripts/install.sh --no-switch     install without switching layouts
#
# Copies layouts/, themes/ and mods/ into the app's home (HERDR_APP_HOME, else
# ~/.config/herdr-app), adds the layout's keys to keys.json (backed up first
# when they change), checks every mod with `herdr-app check`, then switches to
# the layout (first install only; ctrl-shift-l switches back).
# Idempotent, so the repo's install.sh can run it every time: files already
# identical to the repo are left alone, changed ones are refreshed in place
# (files a mod wrote itself, like the worktree dialog's scripts.json, stay).
# On a first install, anything of yours in the way is moved to backups/ first.
# Without herdr-app or its home (open it once) there's nothing to install into:
# that is a warning, not a failure.
set -eu

here=$(cd "$(dirname "$0")/.." && pwd)
home="${HERDR_APP_HOME:-$HOME/.config/herdr-app}"
name=herdr-tui-layout
hook=0 switch=1
for a in "$@"; do
  case "$a" in
    --usage-hook) hook=1 ;;
    --no-switch) switch=0 ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) echo "unknown option: $a (see --help)"; exit 2 ;;
  esac
done

command -v herdr-app >/dev/null 2>&1 || { echo "warn: herdr-app isn't on PATH, so the layout isn't installed (https://herdr.dev); re-run this after installing it" >&2; exit 0; }
[ -d "$home" ] || { echo "warn: no Herdr app home at $home, so the layout isn't installed: open Herdr once, then re-run this" >&2; exit 0; }
stamp=$(date +%Y%m%d-%H%M%S)

# First install = the layout isn't in the app home yet.
fresh=0
[ -e "$home/layouts/$name.json" ] || fresh=1

if [ "$fresh" -eq 1 ]; then
  # What this would replace.
  taken=""
  for p in "layouts/$name.json" "themes/$name.json" "backgrounds/bg.png"; do
    if [ -e "$home/$p" ]; then taken="$taken $p"; fi
  done
  for m in "$here"/mods/*/; do
    m=$(basename "$m")
    if [ -e "$home/mods/$m" ]; then taken="$taken mods/$m"; fi
  done
  if [ -n "$taken" ]; then
    # Outside mods/, layouts/ and themes/: Herdr would load a copy left there.
    backup="$home/backups/$name-$stamp"
    for p in $taken; do
      mkdir -p "$backup/$(dirname "$p")"; mv "$home/$p" "$backup/$p"
    done
    echo "backed up what was in the way to $backup"
  fi
fi

mkdir -p "$home/layouts" "$home/themes" "$home/mods" "$home/backgrounds"
updated=""
put() { # $1 = repo file, $2 = destination dir: copy unless already identical
  if ! cmp -s "$1" "$2/$(basename "$1")"; then cp "$1" "$2/"; updated="$updated $(basename "$1")"; fi
}
put "$here/layouts/$name.json" "$home/layouts"
put "$here/layouts/$name.png" "$home/layouts"
put "$here/themes/$name.json" "$home/themes"
# The background lives outside this repo: the layout points at the app home's
# backgrounds/bg.png, so a picture changed in Herdr is never repo content.
# Seed it from the repo's wallpaper asset only when there isn't one.
bg_src="$here/../appearance/bg.png"
if [ ! -f "$bg_src" ]; then
  echo "warn: $bg_src missing; layout's background not seeded (is the repo intact?)" >&2
elif [ ! -e "$home/backgrounds/bg.png" ]; then
  cp "$bg_src" "$home/backgrounds/bg.png"
  echo "seeded $home/backgrounds/bg.png from the repo's appearance/bg.png"
fi
for m in "$here"/mods/*/; do
  mn=$(basename "$m")
  differs=0
  for f in $(cd "$m" && find . -type f); do
    cmp -s "$m/$f" "$home/mods/$mn/$f" || { differs=1; break; }
  done
  if [ "$differs" -eq 1 ]; then
    mkdir -p "$home/mods/$mn"; cp -R "$m/." "$home/mods/$mn/"; updated="$updated $mn"
  fi
done
if [ -n "$updated" ]; then echo "copied into $home:$updated"; else echo "layout, theme and mods already up to date in $home"; fi

# Keys: this layout's sections are the repo's; everything else stays as it is.
# keys.json is backed up before it changes.
python3 -I - "$home" "$here/keys.json" "$stamp" <<'PY'
import json, os, sys
home, src, stamp = sys.argv[1], sys.argv[2], sys.argv[3]
dest = os.path.join(home, "keys.json")
raw = open(dest).read() if os.path.exists(dest) else None
mine = json.loads(raw) if raw else {}
theirs = json.load(open(src))
changed = [s for s, k in theirs.items() if mine.get(s) != k]
if not changed:
    print("keys.json already has " + ", ".join(theirs))
    sys.exit(0)
if raw is not None:
    os.makedirs(os.path.join(home, "backups"), exist_ok=True)
    with open(os.path.join(home, "backups", "keys.json." + stamp), "w") as f:
        f.write(raw)
    print("backed up keys.json to backups/keys.json." + stamp)
for s in changed:
    mine[s] = theirs[s]
tmp = dest + ".tmp"
json.dump(mine, open(tmp, "w"), indent=2)
os.replace(tmp, dest)
print("updated " + ", ".join(changed) + " in keys.json")
PY

# Every mod must load before we switch to it.
bad=0
for m in "$here"/mods/*/; do
  m=$(basename "$m")
  if herdr-app check "$home/mods/$m" >/dev/null 2>&1; then echo "ok   $m"; else echo "FAIL $m:"; herdr-app check "$home/mods/$m" 2>&1 | tail -4; bad=1; fi
done
[ "$bad" -eq 0 ] || { echo "not switching: fix the mod above, or report it with its output"; exit 1; }

if [ "$hook" -eq 1 ]; then
  dir="${XDG_DATA_HOME:-$HOME/.local/share}/$name"
  mkdir -p "$dir" && cp "$here/extras/claude-usage-hook.sh" "$dir/" && chmod +x "$dir/claude-usage-hook.sh"
  settings="$HOME/.claude/settings.json"
  python3 -I - "$settings" "$dir/claude-usage-hook.sh" "$stamp" <<'PY'
import json, os, shutil, sys
path, hook, stamp = sys.argv[1], sys.argv[2], sys.argv[3]
data = json.load(open(path)) if os.path.exists(path) else {}
current = (data.get("statusLine") or {}).get("command")
if current and current != hook:
    print(f"note: Claude Code already has a statusLine ({current}); left it alone. "
          f"For the usage numbers, have it also run {hook} (it reads the same JSON on stdin).")
    sys.exit(0)
if os.path.exists(path):
    shutil.copy(path, f"{path}.bak-{stamp}")
data["statusLine"] = {"type": "command", "command": hook}
os.makedirs(os.path.dirname(path), exist_ok=True)
tmp = path + ".tmp"; json.dump(data, open(tmp, "w"), indent=2); os.replace(tmp, path)
print(f"Claude Code's statusLine now runs {hook} (prints nothing; Claude sessions started from now on report usage)")
PY
fi

if [ "$switch" -eq 1 ] && [ "$fresh" -eq 1 ]; then
  if herdr-app status >/dev/null 2>&1; then
    herdr-app do layout.switch --name "$name" >/dev/null && echo "switched to $name (ctrl-shift-l switches back)"
  else
    echo "Herdr isn't running: open it, then pick $name in Settings > Look"
  fi
fi
