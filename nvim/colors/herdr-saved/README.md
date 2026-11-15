# herdr colorscheme (saved 2026-11-14)

The custom nvim theme built from the herdr palette — saved here while
gruvbox is active again. To re-enable:

1. `cp herdr.lua ../` (so it sits at `colors/herdr.lua`)
2. `cp python-highlights.scm ../queries/python/highlights.scm`
   (`mkdir -p ../queries/python` first) — recolors `=`/`==`/`+=`… in the
   pastel blue and the other math symbols blue via `@operator.assign` /
   `@operator.math`
3. `cp statusline.lua ../../lua/plugins/statusline.lua` — lualine theme on
   the herdr surface (`#242320`), NOTE: its options must sit inside
   `options = {...}` (top-level keys are silently ignored by lualine)
4. `cp highlights.lua ../../lua/config/highlights.lua` — transparency
   autocmd + the beige diagnostic grey (`#a59b84`)

When it comes back, fix the diff view first: DiffAdd/DiffChange/DiffDelete
were fg-only (bg stripped by the transparency sweep), which made diffs
render as full red/green lines with no highlighted words. Give
DiffAdd/DiffChange/DiffDelete proper (low-contrast) backgrounds and let
DiffText paint on top of them.
