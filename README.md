# DotVibes

**A complete, portable Neovim configuration** — Lua-first, plugin-manager-managed
(lazy.nvim), with LSPs (Python: ruff + basedpyright, C/C++: clangd), formatting
(conform, format-on-save), completion (blink.cmp), treesitter highlighting,
inline markdown rendering (incl. images via the Ghostty/kitty graphics
protocol), git tooling (gitsigns, diffview), telescope, neo-tree, gruvbox, and
which-key discoverability. See the key reference below for daily usage.

## Install

```sh
git clone https://github.com/CyWP/DotVibes.git  # anywhere you like, e.g. ~/DotVibes
cd DotVibes && ./install.sh
```

The repo manages four tools, each in its own subfolder with a
self-contained `install.sh` (you can also run any of them on its own):

| Component | Versioned source | Linked as |
|---|---|---|
| `nvim/` | Neovim config (Lua, lazy.nvim) | `~/.config/nvim` |
| `ghostty/` | `ghostty/config.ghostty` | `~/.config/ghostty/config.ghostty` |
| `herdr/` | `herdr/config.toml` | `~/.config/herdr/config.toml` |
| `agents/` | `agents/skills/*` | skills: `~/.claude/skills/*` (commands come from the tools' own defaults) |
| `tmux/` | `tmux/tmux.conf` | `~/.tmux.conf` |
| `appearance/` | `appearance/bg.png` | wallpaper: copied to `~/.local/share/backgrounds/`, GNOME keys set via gsettings |
| `fonts/` | `fonts/Monaspace Argon/*.otf` (core 4 styles) | `~/.local/share/fonts/Monaspace Argon/*.otf` |
| `bash/` | shell files: `paths`, `prompt`, `aliases`, `extra` | `~/.config/bash/.{paths,prompt,aliases,extra}` (micromamba's init block + the tool-installer nvim/opencode PATH lines live directly in `~/.bashrc`, tool-managed) |
| `bin/` | 16 hand-written scripts | `~/.local/bin/*` |

The agents component is intentionally linked into the Claude config dirs —
opencode natively reads `~/.claude/skills` as a global compatibility source,
so one skills link serves both tools. Commands are not carried in the repo:
`learn` and `rmslop` are default opencode commands; if own ones are added
later, `agents/commands/*.md` gets linked into `~/.claude/commands` **and**
`~/.config/opencode/commands` (opencode does not read the former, so it needs
its own link).

The `bash/` component resets `~/.bashrc` to the stock Debian skeleton plus
two tiny source blocks that load the per-topic files from
`~/.config/bash/` — `.env_vars` (local-only, keeps secrets out of the repo;
seeded from `bash/env_vars.example`), `.paths`, `.aliases` and
`.prompt` (two-line prompt with git info and python-env detection for
venv/conda/mamba/pyenv). The micromamba init block is NOT a repo file — it is
tool-managed and lives directly in `~/.bashrc` (`micromamba shell init` owns
it). Your originals are always backed up
(`~/.bashrc.bak-<timestamp>`). The `bin/` component symlinks the
hand-written scripts into `~/.local/bin` — originals to
`~/.local/bin-backups/` — replacing hand-rolled `gitfix`/`tm*` shells still
kept where it was.

The top-level `./install.sh` runs all of them; one component failing or a
binary not being installed never blocks the others — missing packages are
logged as warnings. Only the config files of ghostty/herdr are linked;
their runtime state (logs, sockets, session data) stays local.
`install.sh` is idempotent:

1. backs up any existing real config files/dirs (never deletes them)
2. symlinks each config → the matching subfolder in this repo
3. (nvim) installs every plugin headlessly (first `nvim` launch is ready to use)
4. (nvim) runs the tool checklist (`nvim/scripts/bootstrap.sh`, warnings only)

Because the configs are symlinks, edits inside the clone are live — and the
clone (rather than `~/.config`) is the thing you version. Any location works:
`install.sh` resolves its own path, so the repo can live wherever your
projects do.


## What the machine still needs beyond the config

The config bootstraps plugins itself; tool binaries come from the OS:

| Requirement | Why | Typical install |
|---|---|---|
| Neovim ≥ 0.12 | treesitter rewrite + `vim.lsp.enable` | package manager or GitHub release |
| tree-sitter CLI ≥ 0.26 | parser builds | binary into `~/.local/bin` (or brew, etc.) |
| tar + curl + C compiler | parser build step | usually preinstalled |
| git | lazy.nvim + plugin cloning | usually preinstalled |
| make | telescope build step | usually preinstalled |
| LSP/formatter binaries on `$PATH` (optional, per-language) | see list below | `pip install --user ruff basedpyright clang-format` (+`--break-system-packages` on Debian), `apt install clangd`/`brew install llvm`, `cargo install stylua` |
| ImageMagick (optional) | renders jpg/avif/webp/svg/pdf inline images (png works without it) | `apt install imagemagick` |
| ripgrep (optional) | `<Space>fg` telescope `live_grep` | `apt install ripgrep` |
| Nerd Font (cosmetic) | icons | JetBrainsMono Nerd Font in the terminal |

Missing tools are warnings, not failures — the related language simply loses
its LSP/formatter, and png-only images still render. Run
`./nvim/scripts/bootstrap.sh` any time for the current machine's status.

Decoupled by design: the editor never installs tools itself, so this config
doesn't fight pip, PEP 668, or conda/mamba environments — whatever is on
`$PATH` is used, and which env you launch neovim from doesn't change LSP
behavior.

# Neovim Key Reference

Quick reference for this config's most important keys.
Leader key is **`<Space>`** (press it, pause a beat, and which-key.nvim will
show every available option).

## File navigation

| Key | Action |
|---|---|
| `<Space>ff` | Find files by name (telescope) |
| `<Space>fg` | Grep text across files (telescope) |
| `<Space>fb` | List open buffers |
| `<Space>fr` | Recently opened files |
| `<Space>fh` | Search Neovim help |
| `<Space>fk` | Search all keymaps by name (shortcut discovery) |
| `<Space>ld` | All diagnostics telescope window |
| `<Space>e` | Toggle neo-tree sidebar |
| `:Ex` | Netrw fallback (built-in) |

Inside telescope: type to filter · `<C-n>/<C-p>` or arrows move · `<Enter>`
open · `<Esc>` close.

## Explorer (neo-tree)

| Key | Action |
|---|---|
| `<Enter>` | Open selected |
| `a` / `d` / `r` | Add / delete / rename |
| `m` / `c` / `x` / `y` | Move / copy / cut / copy-to |
| `H` | Show/hide hidden + git-ignored files (listed dimmed) |
| `/` | Fuzzy-find within the tree |
| `i` | Show file details (size, mtime) |
| `P` | Preview file without leaving the tree |
| `q` | Close tree |

## Completion (blink.cmp — automatic as you type)

| Key | Action |
|---|---|
| `<C-space>` | Force-show / open in menu / close documentation |
| `<C-y>` | Select + accept completion |
| `<C-e>` | Dismiss popup |
| `<C-n>/<C-p>`, `<Up>/<Down>` | Next / prev item |
| `<C-f>/<C-b>` | Scroll completion docs |
| `<Tab>/<S-Tab>` | Jump through snippet placeholders |

Also active: signature help `<C-k>`, plus LSP-attached motions below.

## LSP & diagnostics

| Key | Action |
|---|---|
| `gd` / `gD` / `gI` | Definition / declaration / implementation |
| `gl` | Floating window with diagnostic message for line |
| `]d` / `[d` | Next / previous diagnostic |
| `gra` | Code actions (built-in; try on type errors) |
| `grn` | Rename symbol (built-in) |
| `K` | Hover docs (built-in) |

Servers: `ruff` + `basedpyright` (Python), `clangd` (C/C++).

### Python environments

basedpyright resolves imports (`reportMissingImports`) against an interpreter.
Point it anywhere:

| Key | Action |
|---|---|
| `:PythonEnv` | Fuzzy-pick an interpreter (both micromamba/conda envs, project `.venv`, system python) |
| `:PythonEnv 3dml` | Env by name |
| `:PythonEnv /path/to/bin/python` | Explicit path |

Change applies live (workspace/didChangeConfiguration) — diagnostics re-resolve
against the chosen env's packages. Note: `ruff` is env-agnostic (it doesn't
resolve imports), so only basedpyright's judgments shift.

**Persisting a choice:** the `:PythonEnv` switch lasts for the session; for a
per-project default commit `pyrightconfig.json` in the repo root:

```json
{ "pythonPath": "/home/user/.micromamba/envs/3dml/bin/python" }
```

## Formatting (conform)

| Key | Action |
|---|---|
| `<Space>lf` | Format buffer (visual mode formats selection) |
| *on save* | Buffer auto-formats when written |
| `:ConformInfo` | Show configured formatters |

## Git

| Key | Action |
|---|---|
| `]h` / `[h` | Next / previous change (git hunk) |
| `<Space>hp` | Preview hunk |
| `<Space>hs` / `<Space>hr` | Stage / reset hunk |
| `<Space>tb` | Toggle inline git blame |
| `<Space>gv` | Open DiffView (diffs/merge) |
| `<Space>gc` | Close DiffView |
| `<Space>gh` / `<Space>gH` | File history / whole-repo history |

gitsigns shows +/-/~ marks in the gutter next to changed lines.

## Editing & windows

| Key | Action |
|---|---|
| `<Esc>` | Clear search highlighting |
| `<C-h/j/k/l>` | Move between split windows |
| `<S-h>` / `<S-l>` | Cycle previous/next buffer (tabs at top) |
| `<leader>bd` | Close current buffer |
| `<leader>ur` | Force-reload buffer from disk `:e!` — discards unsaved edits |
| *(automatic)* | Unmodified buffers re-read from disk ~1s after the file changes (live-reload ticker; e.g. agents writing to files) |
| `<leader>bp` | Pick buffer by letter |
| `gcc` | Toggle comment on line (Comment.nvim) |
| `gc{motion}` e.g. `gcap` | Comment region covered by motion |
| `gc` in Visual mode | Comment selection |
| `<C-o>` / `<C-i>` | Jump back / forward in position list |
| `%` | Jump between matching brackets |
| `zz` | Center view on cursor |
| `q` + letter (e.g. `qa`) then `q` | Record macro; play back with `@a` |

## Plugin manager

| Command | Purpose |
|---|---|
| `:Lazy` | Status/management UI |
| `:Lazy update` | Update plugins |
| `:Lazy sync` | Install missing + update |
| `:checkhealth` | Diagnose environment |

## Layout map of the config (edit these files to customize)

Config lives in `nvim/` inside this repo; `~/.config/nvim` is a symlink to it.

```
DotVibes/nvim/
├── init.lua
├── lua/
│   ├── config/
│   │   ├── lazy.lua (spec rules)
│   │   ├── options.lua (vim settings)
│   │   ├── keymaps.lua (mappings)
│   │   └── autocmds.lua (event hooks)
│   └── plugins/
│       ├── colorscheme.lua — gruvbox
│       ├── telescope.lua
│       ├── filetree.lua — neo-tree (auto-opens w/o args)
│       ├── lsp.lua — languages servers + diagnostics UI
│       ├── completion.lua — blink.cmp
│       ├── formatting.lua — conform (format-on-save)
│       ├── statusline.lua — lualine (bottom bar)
│       ├── tabs.lua — bufferline (top bar)
│       ├── treesitter.lua — syntax highlighting
│       ├── git.lua — gitsigns + diffview
│       ├── markdown.lua — render-markdown (inline .md viewer)
│       ├── image.lua — snacks.image (inline images via kitty protocol)
│       ├── comment.lua — Comment.nvim
│       └── whichkey.lua
└── README.md — this file
```

## Installing on another machine

Just follow the `Install` section at the top: clone the repo anywhere,
run `./install.sh`, then run `nvim/scripts/bootstrap.sh` to see which tool
binaries (nvim/tree-sitter CLI per above table, LSPs, Nerd Font) that
particular machine already has vs. needs. Missing tools are warnings —
the related language simply gets no LSP/formatter until installed, so the
config never hard-fails on a fresh box.

# Neovim Key Reference

Quick reference for this config's most important keys.
Leader key is **`<Space>`** (press it, pause a beat, and which-key.nvim will
show every available option).

## File navigation

| Key | Action |
|---|---|
| `<Space>ff` | Find files by name (telescope) |
| `<Space>fg` | Grep text across files (telescope) |
| `<Space>fb` | List open buffers |
| `<Space>fr` | Recently opened files |
| `<Space>fh` | Search Neovim help |
| `<Space>fk` | Search all keymaps by name (shortcut discovery) |
| `<Space>ld` | All diagnostics telescope window |
| `<Space>e` | Toggle neo-tree sidebar |
| `:Ex` | Netrw fallback (built-in) |

Inside telescope: type to filter · `<C-n>/<C-p>` or arrows move · `<Enter>`
open · `<Esc>` close.

## Explorer (neo-tree)

| Key | Action |
|---|---|
| `<Enter>` | Open selected |
| `a` / `d` / `r` | Add / delete / rename |
| `m` / `c` / `x` / `y` | Move / copy / cut / copy-to |
| `H` | Show/hide hidden + git-ignored files (listed dimmed) |
| `/` | Fuzzy-find within the tree |
| `i` | Show file details (size, mtime) |
| `P` | Preview file without leaving the tree |
| `q` | Close tree |

## Completion (blink.cmp — automatic as you type)

| Key | Action |
|---|---|
| `<C-space>` | Force-show / open in menu / close documentation |
| `<C-y>` | Select + accept completion |
| `<C-e>` | Dismiss popup |
| `<C-n>/<C-p>`, `<Up>/<Down>` | Next / prev item |
| `<C-f>/<C-b>` | Scroll completion docs |
| `<Tab>/<S-Tab>` | Jump through snippet placeholders |

Also active: signature help `<C-k>`, plus LSP-attached motions below.

## LSP & diagnostics

| Key | Action |
|---|---|
| `gd` / `gD` / `gI` | Definition / declaration / implementation |
| `gl` | Floating window with diagnostic message for line |
| `]d` / `[d` | Next / previous diagnostic |
| `gra` | Code actions (built-in; try on type errors) |
| `grn` | Rename symbol (built-in) |
| `K` | Hover docs (built-in) |

Servers: `ruff` + `basedpyright` (Python), `clangd` (C/C++).

### Python environments

basedpyright resolves imports (`reportMissingImports`) against an interpreter.
Point it anywhere:

| Key | Action |
|---|---|
| `:PythonEnv` | Fuzzy-pick an interpreter (both micromamba/conda envs, project `.venv`, system python) |
| `:PythonEnv 3dml` | Env by name |
| `:PythonEnv /path/to/bin/python` | Explicit path |

Change applies live (workspace/didChangeConfiguration) — diagnostics re-resolve
against the chosen env's packages. Note: `ruff` is env-agnostic (it doesn't
resolve imports), so only basedpyright's judgments shift.

**Persisting a choice:** the `:PythonEnv` switch lasts for the session; for a
per-project default commit `pyrightconfig.json` in the repo root:

```json
{ "pythonPath": "/home/user/.micromamba/envs/3dml/bin/python" }
```

## Formatting (conform)

| Key | Action |
|---|---|
| `<Space>lf` | Format buffer (visual mode formats selection) |
| *on save* | Buffer auto-formats when written |
| `:ConformInfo` | Show configured formatters |

## Git

| Key | Action |
|---|---|
| `]h` / `[h` | Next / previous change (git hunk) |
| `<Space>hp` | Preview hunk |
| `<Space>hs` / `<Space>hr` | Stage / reset hunk |
| `<Space>tb` | Toggle inline git blame |
| `<Space>gv` | Open DiffView (diffs/merge) |
| `<Space>gc` | Close DiffView |
| `<Space>gh` / `<Space>gH` | File history / whole-repo history |

gitsigns shows +/-/~ marks in the gutter next to changed lines.

## Editing & windows

| Key | Action |
|---|---|
| `<Esc>` | Clear search highlighting |
| `<C-h/j/k/l>` | Move between split windows |
| `<S-h>` / `<S-l>` | Cycle previous/next buffer (tabs at top) |
| `<leader>bd` | Close current buffer |
| `<leader>ur` | Force-reload buffer from disk `:e!` — discards unsaved edits |
| *(automatic)* | Unmodified buffers re-read from disk ~1s after the file changes (live-reload ticker; e.g. agents writing to files) |
| `<leader>bp` | Pick buffer by letter |
| `gcc` | Toggle comment on line (Comment.nvim) |
| `gc{motion}` e.g. `gcap` | Comment region covered by motion |
| `gc` in Visual mode | Comment selection |
| `<C-o>` / `<C-i>` | Jump back / forward in position list |
| `%` | Jump between matching brackets |
| `zz` | Center view on cursor |
| `q` + letter (e.g. `qa`) then `q` | Record macro; play back with `@a` |

## Plugin manager

| Command | Purpose |
|---|---|
| `:Lazy` | Status/management UI |
| `:Lazy update` | Update plugins |
| `:Lazy sync` | Install missing + update |
| `:checkhealth` | Diagnose environment |

## Layout map of the config (edit these files to customize)

Config lives in `nvim/` inside this repo; `~/.config/nvim` is a symlink to it.

```
DotVibes/nvim/
├── init.lua
├── lua/
│   ├── config/
│   │   ├── lazy.lua (spec rules)
│   │   ├── options.lua (vim settings)
│   │   ├── keymaps.lua (mappings)
│   │   └── autocmds.lua (event hooks)
│   └── plugins/
│       ├── colorscheme.lua — gruvbox
│       ├── telescope.lua
│       ├── filetree.lua — neo-tree (auto-opens w/o args)
│       ├── lsp.lua — languages servers + diagnostics UI
│       ├── completion.lua — blink.cmp
│       ├── formatting.lua — conform (format-on-save)
│       ├── statusline.lua — lualine (bottom bar)
│       ├── tabs.lua — bufferline (top bar)
│       ├── treesitter.lua — syntax highlighting
│       ├── git.lua — gitsigns + diffview
│       ├── markdown.lua — render-markdown (inline .md viewer)
│       ├── image.lua — snacks.image (inline images via kitty protocol)
│       ├── comment.lua — Comment.nvim
│       └── whichkey.lua
└── README.md — this file
```

## Installing on another machine

The config is portable: plugin installation bootstraps itself on first launch.
What the new box needs outside the config:

**1. Copy the directory to `~/.config/nvim`, then run `scripts/bootstrap.sh`.**
It checks nothing installs itself: Neovim version, git/make/tar/curl, a C
compiler, tree-sitter CLI, the optional LSP tool binaries, and a Nerd Font.
Missing LSP tools are warnings on purpose — the related language simply gets
no LSP until you install it. Then run `nvim`: the first launch clones
lazy.nvim (see `lua/config/lazy.lua`) and installs every plugin, including
treesitter parsers — nothing manual.

**2. System requirements:**

| Requirement | Why | Typical install |
|---|---|---|
| Neovim ≥ 0.12 | treesitter rewrite + `vim.lsp.enable` | package manager or GitHub release |
| tree-sitter CLI ≥ 0.26 | parser builds | binary into `~/.local/bin` (or brew, etc.) |
| tar + curl + C compiler | parser build step | usually preinstalled |
| git | lazy.nvim + plugin cloning | usually preinstalled |
| make | telescope-fzf-native build | usually preinstalled |

**3. LSP/formatter binaries (just need to be on `$PATH`):**

```sh
pip install --user ruff basedpyright clang-format   # Debian/Ubuntu: add --break-system-packages
# macOS: plain pip (or pipx) works
brew install llvm    # or: apt install clangd            → clangd
brew install stylua  # or: cargo install stylua          → stylua
```

Missing binaries are not errors — the related language simply gets no LSP/formatter.

**4. Nerd Font for icons:**
install JetBrainsMono Nerd Font and select it in your terminal. Without it the
config still works; icons just degrade to boxes/letters.

Decoupled by design: the editor never installs these tools itself, so this
config doesn't fight pip, PEP 668, or conda/mamba environments — whatever is
on `$PATH` is used, and which mamba env (or python) you launch neovim from
doesn't affect LSP behavior.

**Images in the terminal (optional):** Ghostty already supports the kitty
graphics protocol — no extra tooling (no `kitten icat` needed). `snacks.image`
renders PNG images inline in markdown buffers with zero extra installs; for
other formats (jpg, avif, webp, video/pdf previews) additionally install
ImageMagick on that machine.
