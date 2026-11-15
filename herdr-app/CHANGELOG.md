# Changelog

## Unreleased

- **Changed:** `ctrl-b w` opens the picker as a space picker now: one row
  per space — its color chip, name and agent status — and Enter or a
  click goes there (it was the tab picker, grouping each space's tabs).
  The picker mod keeps its tab mode; only what `ctrl-b w` opens changed.

- **New:** space keys on the arrows. `ctrl-b up`/`down` go to the
  previous/next space, and `ctrl-b left`/`right` walk back and forward
  through the spaces you've been on, browser-style: jumping somewhere new
  drops the forward entries, and closed spaces are skipped. The side mod
  keeps the list, since Herdr has no command for it.

- **Changed:** the bright peach got brighter. The peach pair in slot 4 is
  now pastel `#ffc7a2` / bright `#ffaf80` (was `#f5a878` — the bright half
  was duller than the person's hand-picked peach `#ffaf80`, so the theme
  now carries that exact hex). The DotVibes prompt's user@host and
  `nvim/colors/herdr.lua`'s `d_peach` follow.

- **New:** the wallpaper shows through the terminals. The layout's
  background is `backgrounds/herdr-tui-layout-bg.jpg` — DotVibes'
  `appearance/bg.png` **unmuted** (only format-converted, since Herdr
  doesn't draw a PNG background) and pre-scaled 150% so the window maps to
  the image's centre — painted on the root. Every surface mutes it itself:
  the side mod paints a 70%-chrome veil, the pane frames paint no fill so
  the image sits directly under the terminals, and `terminal_opacity: 0.7`
  draws the terminal background at 30% over it — the washes reach the
  terminal text. The thin margins around the cards are the one place with
  no muting and show the raw washes. Panels, blocks, cards and the
  sidebar's rows still cover their own areas. The installer copies
  `backgrounds/` into the app home; the file's transparent areas flatten
  onto this theme's chrome, so it belongs to this theme only. Two quirks
  found on the way: the same image as a PNG drew flat chrome (it ships as
  a JPG), pane frames fall back to the terminal background colour when
  given an image (which is why the file sits on the root), and replacing
  the image file needs a layout switch before it shows.
- **Changed:** the tabs moved out of the way. A 2px hairline sits over the
  panes, in the border colour so it meshes with the border lines around it
  (6px in from the sidebar's divider, 3px below the window's top edge),
  divided once per tab of the shown space with no gaps and no text — the
  shown tab's segment is solid accent, the
  rest `border`, a hovered one lightens, and nothing shows when the space
  has no tabs. Clicking a segment selects its tab; the bar also drags the
  window (the layout draws no title bar) and a double-click on it
  maximizes. The hairline can't be stretched by dragging (the panes
  column is resizable false). There is no `+` any more: new tabs come from `ctrl-b c` or the
  picker (`ctrl-b w`), so the `herdr-tui-layout-new-menu` mod is gone. The
  26px top line is gone too — panes get the whole height. The status the
  top line carried (the focused agent's model and context, the Claude
  5-hour and weekly use, the machine and the time) sits on a line at the
  bottom of the agents half, next to the fold `«`. The sidebar's blocks
  drag the window as well (its rows and buttons stop their presses; the
  gaps, machine rows and the status line still drag). `herdr-tui-layout-bar`
  is gone; its keys (`shift-t`, `w`, `shift-/`, `alt-g/b/f`) point at
  `herdr-tui-layout-side`, which now runs what the bar ran. The picker and
  popups size themselves as shares of the window, so they no longer assume
  a 16:9 shape.

- **Changed:** the palette, per the person's taste, to their own hand-picked
  colours on warm grey surfaces (chrome `#1b1a17`, terminal `#242320`,
  blocks `#2d2b27`, borders `#514d43` — no blue-dominant backgrounds):
  soft sage `#afc8a6` main accent going around the panels (was orange, then
  pink, then coral, then mint), mint `#00ffb3` kept as the terminal green,
  working `#ffca5f` (warm yellow), needs you `#ff004c` (crimson),
  done `#afc8a6`, idle `#9a9484`. Terminal ANSI palette follows the same
  colours, with the pastel versions as the normals (what programs use by
  default) and their deeper, more saturated homologues as the brights, and
  peach and blue swapped (slot 4 peach `#ffc7a2` / `#f5a878`, slot 6
  blue, lighter and less gray, `#8ac0ff` / `#5b93e3` — the yellow pair
  `#ffdb66` / `#eea63b` sits in slot 3):
  a true pastel red `#fa8383` / red `#ea4b62` (the earlier salmon
  `#fb879d` read yellow), pastel mint `#7fe9c8` / mint `#35d6a4`, lilac
  `#dfaee6` / violet `#8f55e0`. Blues in two pairs only. One white slot
  only — normal white `#ffffff` (the terminal's default text colour is
  white too), the bright-white slot instead carries the sage accent
  `#afc8a6`.
- **Removed:** herdr-nvim (the nvim extension) at the person's request — the
  files panel and the `herdr-nvim-sync` controller are out of the layout
  again, its mods, keys (`cmd-e` / `cmd-o` / `cmd-shift-e` and the Linux
  `alt-` twins) and its state are gone. The `ctrl-b` keymap, the pastel
  indigo palette
  theme and the keys parity are unchanged. The parity table keeps the
  `alt-` twins for herdr-nvim dormant: they only apply if that mod is
  installed again.
- **New:** `ctrl-b m` zooms the focused pane (alongside `ctrl-b z`).
- **New:** herdr-tui-layout now carries herdr-nvim's wiring: a hidden files
  panel (the tree) at the right edge and the `herdr-nvim-sync` controller, so
  `alt-e` toggles the tree with the tab's own nvim pane beside your panes (no
  new tab), and `alt-o` / `alt-shift-e` reach the controller. Without
  herdr-nvim installed nothing shows. No pane header, so Preview/Source
  buttons don't show in this layout.
- **Changed:** the toplevel `install.sh` now trims `keys.json` to parity after
  installing: Herdr's stock bindings for commands the layout's `ctrl-b` keys
  provide are removed (tab/space/pane keys, split, zoom, sidebar, settings,
  help), an old install's dead `ctrl-b minus` is fixed to `ctrl-b -` (Herdr
  spells the hyphen `-`, not `minus`), and herdr-nvim's `cmd-` keys get `alt-`
  twins on Linux (`alt-e`, `alt-o`, `alt-shift-e`) — the `cmd-` ones never
  reach the app there. The table is `scripts/keys-parity.json`; the global
  uninstall reverts all of it. Keys a person already uses are never taken.
  On this machine the twins are swapped from herdr-nvim's habit:
  `alt-shift-e` toggles the tree + nvim (herdr-nvim's `cmd-e`), `alt-e`
  hands the keyboard to the tree (its `cmd-shift-e`).
- **Fixed:** a worktree could sit under the wrong repo, and move when spaces
  were reordered: nesting matched folder names. It now asks git which repo
  each space's live folder belongs to.
- **New:** `▾` / `▸` at the right of a repo's row folds its worktrees.
- **Removed:** `ctrl-b 1`…`9` for tabs; click a tab, or use Herdr's own
  tab keys.

## v0.1.0 — 2026-11-03

First release. Built and tested with herdr-app 0.1.12 and hc 0.1.17 on macOS.

- **Sidebar:** spaces grouped by machine on rounded blocks, one line each with
  branch and tab count; worktrees drawn as a tree under their repo; fold a
  machine; drag spaces to reorder; right-click for rename, worktrees and close;
  connection state per machine (connected, reconnecting, unreachable).
- **Agents:** below the spaces, behind a draggable divider; status mark, space
  and tab, and the agent's task; `priority` / `spaces` order.
- **Top line:** numbered tabs (drag to reorder, double-click to rename), the
  focused agent's model and context, Claude 5-hour and weekly use, the shown
  space's machine and the time.
- **Fold strip:** `«` / `»` fold the sidebar to a 40px rail of space numbers
  and agent letters.
- **Keys:** herdr-tui's `ctrl-b` prefix for tabs, spaces, panes, worktrees,
  the picker, help and lazygit / btop / yazi popups.
- **Look:** Melange colours, Menlo 12.5 everywhere, rounded panes; menus and
  dialogs that draw their own rounded boxes.
- **Install:** `scripts/install.sh`, with `--force` (backs up first) and
  `--usage-hook` (sets up the usage numbers).
- **Checks:** `scripts/check.sh` runs `herdr-app check` and a TypeScript check
  on every mod.

Not yet tried on screen: the `ctrl-b` keys, the popups, the picker, help,
the `+` menu and the reconnecting state.
