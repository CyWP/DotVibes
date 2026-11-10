# AGENTS.md

## Secrets / env vars
- Never put real credentials, tokens, API keys, IPs or usernames into any tracked file in this repo — the real values live only in `~/.config/bash/.env_usr` (perm 600, outside the repo). `bash/env_usr.example` documents its shape with commented-out examples only; keep it that way (see `bash/install.sh`: it seeds the local file once, never overwrites). If a new script needs a secret, wire it through `.env_usr` instead of hardcoding.
- Shared NON-sensitive variables (paths reused by several installers/scripts/skills) live in the tracked `bash/env_vars` (linked to `~/.config/bash/.env_vars`). Both files are sourced by `~/.bashrc`, `.env_vars` first, then `.env_usr` (which can override). Installers load `bash/env_vars` straight from the repo (`. "$ROOT/bash/env_vars"`); bin scripts rely on the inherited env, with a guarded source of `~/.config/bash/.env_vars` where they run outside a shell (`appinstall`, `update-desktop`, `update-config`). Add a new shared path there instead of repeating a literal like `$HOME/.local/bin`.

## Installer-owned blocks in ~/.bashrc
- The micromamba init block, the nvim PATH line and the opencode PATH line are appended to `~/.bashrc` by their own installers — they are tool-managed, NOT DotVibes content. Never move them into repo files (`bash/paths`, `bash/mamba` already proved to be a wrong turn; was reverted). `bash/install.sh` guarantees they exist after its bashrc reset via existence-checked, idempotent re-add steps; extend those steps if a new tool behaves the same way.

## install.sh conventions
- Every `install.sh` (top-level and each component) is source-safe: the body runs inside `_dv_install() { ( ... ) }` (a subshell) and a dispatcher at the bottom does `exit` when executed, `return` when sourced. The user is known to dot-source these; any new script must follow the same pattern (and check_deps.sh does). Don't add top-level `exit` outside the subshell body.
