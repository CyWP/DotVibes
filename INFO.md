# INFO: DotVibes

## THEME: environment variables / secrets are local-only
**Claim:** Real env vars are not in the repo; they live in a moved/seeded local file.
**Verdict:** Correct for secrets. The repo tracks only `bash/env_usr.example`,
comments-only (shape doc only). Real values live in `~/.config/bash/.env_usr`
(perms 600, outside the repo). `bash/install.sh` (# seed step) copies the example
into place **only when the real file doesn't exist yet** and never overwrites it
on re-runs; a legacy local `.env_vars` is moved to `.env_usr` first. Shared,
non-sensitive variables (paths) are tracked in `bash/env_vars`, linked to
`~/.config/bash/.env_vars`; `~/.bashrc` sources `.env_vars`, then `.env_usr`.
Caveat: local-only means no repo backup for `.env_usr` — by design
(README: "keeps secrets out of the repo").

## THEME: installer-owned blocks live directly in ~/.bashrc
**Q:** Isn't `bash/mamba` (and the nvim/opencode PATH lines in `bash/paths`)
user-written config?
**A:** No — those are auto-generated/appended by their own installers
(`micromamba shell init` writes the `# >>> mamba initialize >>>` block; the
nvim tarball and opencode installers each append their own PATH line). They
are tool-managed and deliberately NOT repo files; they live directly in
`~/.bashrc`. `bash/install.sh` only *guarantees* them after its bashrc reset
(it re-adds what the machine actually has, existence-checked and idempotent —
see `ensure_tool_path` and the mamba-block step). Don't recreate them as repo
files; that mistake already happened once and had to be reversed.

## THEME: provenance of the agent skills/commands
**Claim:** learn.md and agent-correct are defaults shipped by opencode/claude.
**Verdict (corrected after user input):** learn.md and rmslop.md ARE default
opencode commands — the repo's copies were redundant and were removed (the
commands/ dir is gone; agents/install.sh pruned the repo symlinks from
~/.claude/commands and ~/.config/opencode/commands, leaving opencode's
built-ins to provide them). agent-correct, however, is NOT a default of either
tool: it arrived via the user's own commit `ca7e3f4 "claude: port skills +
commands from opencode-configs"` and stays as a DotVibes skill.
