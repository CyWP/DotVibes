#!/usr/bin/env bash
# install.sh — install the herdr-app layout kept in this folder:
#
#   greasy-panes  the layout (scripts/install.sh): layout, theme and mods
#                     copied into the app home, keys.json merged (backed up
#                     first), every mod checked, then switch to the layout
#
#   ./install.sh              install it
#
# After the install, keys parity is applied to the person's keys.json:
# Herdr's stock bindings for commands the layout's ctrl-b keys provide are
# dropped (one way each), and stale key names are fixed. The table lives in
# scripts/keys-parity.json; uninstall.sh reverts it. Idempotent.
#
# Needs herdr-app on PATH and its home (HERDR_APP_HOME, else
# ~/.config/herdr-app) opened once; without them it warns and installs
# nothing. Re-running refreshes what changed in the repo.

# Source-safe (see the dispatcher note at the bottom): executing it is still
# the preferred way to run, but `. ./install.sh` is honored too — no state
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

layout=1
pass=()
for a in "$@"; do
  case "$a" in
    --no-layout) layout=0 ;;
    -h|--help)   sed -n '2,12p' "$0"; exit 0 ;;
    *) pass+=("$a") ;;
  esac
done

status=0
if [ "$layout" = 1 ]; then
  echo "==> greasy-panes"
  if ! "$ROOT/scripts/install.sh" "${pass[@]}"; then
    echo "warn: greasy-panes install reported an error (see above)" >&2
    status=1
  fi
fi

# --- keys parity ------------------------------------------------------------------
# Trim Herdr's duplicate defaults and fix stale key names (see the header
# and scripts/keys-parity.json). Runs against the person's keys.json even
# with --no-layout, but only touches what is actually installed.
app_home="${HERDR_APP_HOME:-$HOME/.config/herdr-app}"
keys="$app_home/keys.json"
echo
echo "==> keys parity"
if [ ! -f "$keys" ]; then
  echo "note: no keys.json in $app_home (the app hasn't run yet) — nothing to trim"
elif ! python3 -I - "$keys" "$ROOT/scripts/keys-parity.json" "$app_home" <<'PY'
import json, os, sys, time
keys_path, parity_path, app_home = sys.argv[1], sys.argv[2], sys.argv[3]
parity = json.load(open(parity_path))
raw = open(keys_path).read()
data = json.loads(raw)
changed = []

# a stale layout section may still carry the dead "ctrl-b minus" key name
lay = data.get('layout:greasy-panes')
if isinstance(lay, dict) and 'ctrl-b minus' in lay:
    v = lay.pop('ctrl-b minus'); lay['ctrl-b -'] = v
    changed.append('fixed ctrl-b minus -> ctrl-b -')

# drop Herdr's stock bindings the layout's ctrl-b keys already provide —
# only while those keys are actually merged in
if isinstance(lay, dict) and lay:
    for key, action in parity['remove_defaults'].items():
        if data.get('global', {}).get(key) == action:
            del data['global'][key]
            changed.append('removed ' + key)

if not changed:
    print("keys.json already at parity")
else:
    os.makedirs(os.path.join(app_home, 'backups'), exist_ok=True)
    stamp = time.strftime('%Y%m%d-%H%M%S')
    with open(os.path.join(app_home, 'backups', f'keys.json.{stamp}'), 'w') as f:
        f.write(raw)
    tmp = keys_path + '.tmp'
    with open(tmp, 'w') as f:
        json.dump(data, f, indent=2)
    os.replace(tmp, keys_path)
    print('-> ' + ', '.join(changed))
    print(f"-> backed up the earlier keys.json to backups/keys.json.{stamp}")
PY
then
  echo "warn: keys parity reported an error (see above)" >&2
  status=1
fi
exit $status
)
}

# --- source-safe dispatcher ----------------------------------------------------
# Executed: run the install, exit with its status (unchanged behavior).
# Sourced: run it in the subshell above, then `return` the status so the
# interactive shell survives; the set-flags and all script variables die with
# the subshell. Same pattern as check_deps.sh's _check_deps_run.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  _dv_install "$@"
  _dv_st=$?
  unset -f _dv_install
  exit "$_dv_st"
fi
_dv_install "$@"
_dv_st=$?
unset -f _dv_install
return "$_dv_st"
