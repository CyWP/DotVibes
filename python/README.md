# python/ — python project templates

Canonical python project files, applied into a project by `bin/pyproj`
(which copies everything in this folder except `README.md` and `install.sh`
into the target root — drop new templates here and `pyproj` picks them up
automatically).

## Why copy, not link

The files are copied so the style is committed *with* each project: cloned
checkouts and machines without DotVibes lint/format identically, and a
project can deviate by editing its copy. Consequence: updating
`python/ruff.toml` here does **not** touch existing projects — re-apply the
new baseline per project with `pyproj --force` (it overwrites the template
files it owns; without `--force` existing files are never touched).

## Discovery notes (ruff)

- Per-file config resolution walks up from the file; the closest config
  wins, same-directory precedence is `.ruff.toml` > `ruff.toml` >
  `pyproject.toml` `[tool.ruff]`.
- No merging across files: a project config replaces, unless it starts
  with `extend = "~/.config/ruff/ruff.toml"`.
- If no config is found at all, ruff falls back to `~/.config/ruff/`
  (a machine-local escape hatch; this folder is the tracked source of
  truth).
- `target-version` is deliberately not set here — ruff infers it from the
  project's `pyproject.toml` `requires-python`.
