# greasy-panes

herdr-tui's look and keys (the terminal herdr), inside herdr-app. A dark coffee-brown
window in Menlo 12.5: on the left, your spaces grouped by machine, each on one
line with its git branch and its worktrees on a little tree under it, and your
agents under them, with the focused agent's model and context, your Claude
5-hour and weekly use, and the machine and time on a line at the bottom. Over
the panes a 2px hairline in the border colour, divided once per tab of the
shown space, no text, the
shown tab's segment lit. Panes are rounded cards with a 1px border that turns
orange on the one you're typing in. `ctrl-b` drives it like herdr-tui does.
A community layout for herdr-app, not herdr-tui itself; not affiliated with Herdr.

![greasy-panes](layouts/greasy-panes.png)

## What you see

The theme is the person's own palette on warm grey surfaces
(`themes/Floracotta.json`): terminal `#242320` on `#e7e2d6`; bars and
sidebar `#1b1a17`; blocks, tabs and dialogs `#2d2b27`; hover `#3a3730`;
selected `#484439`; borders `#514d43`; accent `#afc8a6` (soft sage —
borders, tabs, branch names and cursor; mint `#35d6a4` stays the terminal
green); dim
text `#9a9484`. Status colours: working `#ffaf80` (light peach), needs you `#ff004c`,
done `#afc8a6`, idle `#9a9484`. Every font is Menlo at 12.5px, terminals and
panels alike; emphasis is bold or dim, never a bigger size.

Behind everything, the layout paints its background with `backgrounds/bg.png`
**in the app home** (`~/.config/herdr-app`, or `HERDR_APP_HOME`): a copy of
DotVibes' wallpaper (`appearance/bg.png`), seeded there by
`scripts/install.sh`. The image itself is not in this repo — changing the
picture in Herdr edits the app-home file, outside the repo; the installer
only seeds it when the file is missing. Every surface mutes it itself: the terminals paint their own surface
a touch more transparent than stock (`terminal_opacity: 0.68` on the
root — measured at ~78% coverage against the raw wallpaper), the
sidebar's two cards carry the same base (`bg(t.background + "c7")` in
the mod), and
the tab bar's segments are opaque. The pane frames paint nothing, so the
image sits directly under the terminals only through the pane gaps. The
thin margins around the cards have no muting — they show the raw washes
where the image has content. The file's transparent areas flatten onto
this theme's chrome, so it belongs to this theme only.

Top to bottom:

1. **Sidebar, top half: spaces.** One panel per machine, in machine order —
   each a rounded card with a 1px border painting the terminal surface at
   ~78%. Equal shares that always fill the block (no folding, no per-panel
   sizing). The boundary to the agents panel is the layout's own divider,
   given a strip of its own: dragging it drives the agents block's height,
   so only the agents panel expands or minimizes — the spaces panels just
   keep filling the rest.
   - The card's bottom label is the machine's name, lowercase, in the discreet
     12.5/muted lettering with a 6px link dot — green connected, yellow with
     `◐ reconnecting`, red unreachable.
   - One line per space: its name in its status colour (muted when no
     agent runs there), bold and on a `#484439` background when shown, cut
     at 150px — no status dots anywhere. The shown space's git branch
     lives in its own panel (below).
   - A worktree space sits under its repo's space on a drawn tree: a 1px
     trunk and a 10px twig in the border colour (fainter than the text),
     the trunk stopping halfway on the last one, then
     its branch, its name in its status colour like every row.
   - Which repo: git, asked in each space's live folder (its first
     terminal's `cwd`, else its folder) every 15s: a space is a worktree when
     `--git-common-dir` isn't its `--show-toplevel`'s `.git`, and it nests
     under the space holding that repo's main checkout.
2. **Tab bar, a 1px hairline under the panes**, in the border colour (the
   cards' edges) so it meshes with the border lines around it, aligned
   with the cards' side edges (6px in from the window edge, 3px above
   the window's bottom edge). Divided once per tab of the shown space, no
   gaps and no text: the shown tab's segment carries a 4px pill with
   rounded ends over the line, in the muted colour (the terminal
   scrollbar thumb's colour and thickness); a hovered segment's line
   lightens to the muted. Nothing shows when the space has no tabs. No
   `+`: new tabs come from `ctrl-b c` or the picker.
3. **Sidebar, bottom half: agents.** A draggable divider between the halves.
   - The rows sit directly on the card's base, their highlights touching
     the card's edges like in the machine panels.
   - One row per agent: its space name in its status colour (white when
     it reports none), bold only on the agent you're in; under it, what the
     agent's terminal
     is titled without the program's short name (`OC | …`), muted. The agent
     you're in is on
     `#484439` with its name orange; one that needs you is tinted red.
   - Each card carries its name at the bottom, in the agent description's
     lettering (12.5, muted) — `agents` on the bottom card, with a toggle (the buttons' hover,
     slightly larger arrows) that minimizes the panel to just that line
     and back — the agents block hands the exact difference to the spaces
     panels, so the bottom panels never move; when agents need you,
     `· 2 need you` in red follows it.
   - **A branch panel** between the agents card and the status panel, the
     cards' skin: the shown space's git branch (muted) with the git-branch
     icon at the right; `detached` when the checkout has no branch, `no
     repo` (dim) when the space isn't in one. Expanded state only.
   - **A status panel at the bottom:** its own small panel below the agents
     card, the cards' skin (rounded 6, 1px border, the same translucent
     base); the three panels sit 6px apart. Inside: the focused
     agent's model (`Opus 5.5`),
     `ctx 11%`, `5h 12%`, `week 13%` (each number green, yellow from 50%, red
     from 80%; hovering 5h or week shows when it resets); below them the
     window controls the system doesn't draw on Linux and the app's
     settings and keybinds, as lucide icons (Herdr's shipped
     workspace-chrome mod, plus this mod's own question mark), spread
     evenly across the panel's width: `×` closes (tinted red under
     the pointer), `–` minimizes, `□` maximizes (toggles), `⚙` opens
     Settings, `?` opens the keybinds panel, `🔍` the command palette,
     `«` folds the sidebar.
4. **Folded sidebar, 40px.** All three panels stay. Spaces as their number
   on their machine with a status mark (`1○ 2· 3●`), other machines opening
   with `▾2`, `▾3`; the shown space highlighted; agents below as their
   space's first letter with a mark; the status panel stacks its buttons
   inverted: `»` opens the sidebar again at its last width, then `⚙ □ – ×` —
   so `»` sits where `«` sits expanded.
5. **Panes:** cards with 6px corners and 6px gaps, no header line, terminal
   padding 6×10. The card paints no fill of its own — the background image
   sits directly under the terminal — and the terminal paints its `#242320`
   surface at ~78% over it (`terminal_opacity: 0.68` on the root,
   measured), so the wallpaper's washes show through. The tab bar
   hairline sits 4px above the window's bottom and 5px below the cards; 3px
   at the window's sides.
6. **Popups and dialogs** (right-click menus, rename, worktree, help,
   picker) draw their own translucent box — the popover colour at ~78%,
   like the panels — with the settings sheet's 7px corners and a 1px border; the menu's
   selected row is the selection colour at ~70% and follows the pointer.

## How it behaves

- **Agent status** comes from the agents themselves (Claude Code reports it):
  working is a light peach, done green, needs you red, idle a ring. Agents sort in
  `priority` order: needing you first, then done, working, idle.
  `ctrl-b alt-1..9` jumps to the
  agent in that row.
- **The New worktree dialog** (`ctrl-b shift-g`, or the space menu) asks
  the git branch, the base branch and a startup script. Tab / shift-tab
  always move between the fields (branch → base → the startup script →
  the custom command while it is shown, wrapping) and never pick a
  suggestion. In the base field, ↑↓ move through the suggestions and ↵
  picks the highlighted one (↵ again creates). On the startup script,
  ↵ or ↓ opens the dropdown, ↑↓ choose, ↵ picks. The dialog is drawn
  like the pane cards: 6px corners, the popover colour at the panels'
  translucency. The base defaults
  to where the repo is checked out now and suggests the repo's local and
  remote branches while the field is focused (↑↓ move, tab picks, the list
  follows what you type); a base that names a remote branch is fetched
  first. The startup script dropdown offers `No script`, the scripts saved
  in `mods/greasy-panes-worktree/scripts.json` and `Custom…` (type a
  command, save it on the spot; a repo with `artisan`/`composer.json`
  preselects a saved `composer install`, one with `package.json` a saved
  `yarn install`). Enter creates: the branch name is validated, a branch
  already checked out and an existing folder are caught, and the chosen
  script runs as the new space's first terminal's command.
- **Clicks:** a space switches to it; dragging a space onto another of the
  same machine moves it (it fades; an orange line shows where it lands);
  right-click a space for Rename, New / Open / Remove worktree, Close. A
  segment of the tab bar selects its tab; the bar is also the window's drag
  handle (the layout draws no title bar), so dragging it moves the window
  and a double-click maximizes. An agent row goes to that agent. Right-click
  a terminal for split, zoom, close. The sidebar's blocks drag the window
  too; its rows and buttons stop their presses, while the gaps, the machine
  rows and the status line still drag it.
- **Keys** (`keys.json`, only while this layout shows; prefix `ctrl-b`):
  `c` new tab, `n` / `p` next / previous, `shift-x` close tab,
  `shift-t` rename tab; `shift-1..9` space N, `up` / `down` previous /
  next space and `alt-j` / `alt-k` the same without the prefix — both walk
  the sidebar's order (worktrees right after their repo), wrapping at the
  ends — and `alt-h` / `alt-l` previous / next tab. `left` / `right` back
  / forward through your recent spaces (wrapping at the ends; a new jump
  drops the forward ones; closed spaces are skipped), `alt-left` /
  `alt-right` focus the pane to the left / right,
  `shift-n` new space, `r` or `shift-w` rename space, `shift-d` close
  space, `w` space picker (one row
  per space: name and agent status, worktrees nested under their repo's
  space; Enter or a click goes there),
  `shift-g` new
  worktree; `shift-h` / `shift-j` / `shift-k` / `shift-l` split left /
  down / up / right (left and up split right or down and swap, since
  pane.split only makes right/down), `x` close pane, `z` or `m` zoom,
  `h j k l` move between panes; `b` hide the sidebar, `shift-b` fold it
  to its strip and back; `shift-/` (or `?`) the keybinds panel; `s` settings;
  `alt-g` lazygit, `alt-b` btop, `alt-f` yazi, each in a floating terminal
  (80% / 90% of the window) that closes when the program exits.
- Install also merges a `terminal` section into the person's keys.json
  (plain `ctrl-shift-c` / `ctrl-shift-v` copy and paste, `ctrl-insert` /
  `shift-insert` the same, `ctrl-shift-f` find, `ctrl-v` paste-image,
  `ctrl-left` / `ctrl-right` / `ctrl-backspace` word-wise line editing,
  and `shift-pgup` / `shift-pgdn` one page of terminal scrollback).
- The status line's numbers refresh every 15s; machine states and hostnames
  every 10s and 60s; the clock every 15s.

## Built from

- **Layout** (`layouts/greasy-panes.json`): a row (`titlebar: "none"`,
  `traffic_lights` `[14, 14]`, `terminal_menu: "greasy-panes-menu"`,
  `background` the wallpaper image `backgrounds/bg.png` in the app home
  (a copy of DotVibes' `appearance/bg.png`, seeded by the installer; see
  above) (`fit: "cover"`), `terminal_opacity: 0.68`):
  `sidebar` (column, 280px,
  40–480, gap 5, no padding — the mod draws the cards so the margins can
  differ per side: 4 at the top and bottom, 3 at the sides) holding
  `side-spaces` and `side-agents`
  (blocks, weight 1, min 80, both `window_drag`; both `greasy-panes-side` with `props.part`
   `"spaces"` / `"agents"`), and `work` (column, resizable false so the
   hairline can't be stretched, padding `[3, 6]`, gap 3) holding
   `tabsbar` (block, 2px, `window_drag`, `greasy-panes-tabs`) and
  `main` (block, no padding, `{ tab: "active" }` with pane frames: gap
  6, radius 6, no fill (the background paint shows through), border
  `border`, focus `accent`, `lone: true`, no header).
- **greasy-panes-side:** `spaces()`, `agents()`, `machines()`, `panes()`,
  `setAgentOrder`, `space.select`, `space.move`, `space.new`, `pane.focus`,
  `layout.resize` (fold to 40, unfold to the width it had, kept in
  `localStorage`), `openOverlay`; polls `hc machine ls --json` for connection
  states, and its git probe is shared as `side.git` for the picker's
  worktree nesting; listens on `nextCommand()` for `agent-N`, `recent-back`,
   `recent-forward`, `space-next`, `space-prev`, `split-left`, `split-up`, `fold-toggle`, `rename-space`, `new-worktree` (spaces copy; the
   recents pair walk a back/forward list of spaces the mod tracks in
   `render()`, and the space pair walk `displayOrder` — each top space
   followed by its worktrees, per machine, rebuilt every render) and
   `picker`, `help`, `rename-tab`,
   `popup-lazygit|btop|yazi` (agents copy). The agents copy also runs the
   status chores: `hostname -s`, `hc machine ls --json` for hostnames, and
   a `sh` loop reading `~/.local/state/greasy-panes/claude/*.json`;
   starts
  popups with `hc run --bg --rm` and shows them as dialog overlays holding
  the terminal, sized as shares of the window.
- **greasy-panes-tabs:** `spaces()`, `tab.select`; one full-height
  segment per tab of the shown space, the active one `accent`, the rest
  `border`; its presses pass through, so the 2px hairline drags the window.
- **Copies of Herdr's mods** (Apache-2.0, see NOTICE), each opened with
  `frame: "none"` and drawing its own rounded box: `greasy-panes-menu`
  (`menu`), `greasy-panes-prompt` (`prompt`),
  `greasy-panes-worktree` (`worktree`), `greasy-panes-picker`
  (`picker`), `greasy-panes-help` (`help`). The worktree copy's New
  dialog also carries the base branch field (suggestions from
  `git for-each-ref`, a remote base fetched first) and the startup script
  picker (`scripts.json` next to the mod, custom commands saved there),
  ported from the herdrtw layout (see NOTICE).
- **extras/claude-usage-hook.sh**, optional: a Claude Code `statusLine`
  command that saves each session's status JSON to
  `~/.local/state/greasy-panes/claude/<session_id>.json` and prints nothing.
  Install it with `"statusLine": {"type": "command", "command":
  "<path>/claude-usage-hook.sh"}` in `~/.claude/settings.json`.

## Watch out

- **What it runs and reads:** `hostname`, `hc machine ls`, `git rev-parse` in each space's folder every 15s (to nest worktrees) and `git` in the worktree dialog (creating a worktree validates the branch, probes the checkout for a package manifest and fetches a remote base), `sh -c` (the chosen startup script, as the new space's first terminal), `sh`/`ls`/`stat` over `~/.local/state/greasy-panes/claude/`,
  and lazygit/btop/yazi on their keys. No HTTP requests; the dialog's
  `git fetch` talks to the repo's remote, only when the base branch names
  one. The dialog reads and writes `mods/greasy-panes-worktree/scripts.json`
  (saved startup scripts).
- **Without the usage hook** the agents half's status line just leaves
  model, ctx, 5h and week out. The hook applies to every Claude Code session
  on the machine.
- **Two copies, one listener.** The side mod runs twice (`props.part`
  `"spaces"` / `"agents"`), and every `<mod>.<command>` key reaches both, so
  the loop checks its part before acting: the picker, help, rename-tab and
  popup keys only act on the agents copy, rename-space and new-worktree only
  on the spaces copy.
- **Square-in-rounded corners:** Herdr's own dialogs paint a square
  background inside the app's slightly rounded frame, and the corners show a
  notch. That's why five mods are copies opened with `frame: "none"`. The
  terminal right-click menu and the close-confirm dialog are opened by the
  app itself, which ignores that, so they keep Herdr's small corners;
  `popover` in the theme matches the frame so they stay clean.
- **Background images are JPGs, live on the root, and reload on a layout
  switch.** The same image as a PNG drew flat chrome; as a JPG it renders.
  Pane frames won't paint an image at all — given one, the frame falls
  back to the terminal background colour — which is why the file sits on
  the root and `terminal_opacity` does the muting. And replacing the file
  under the same name doesn't redraw — switch layouts away and back (or
  restart) before judging a new blend.
- **`herdr-app check` alone isn't enough:** it renders once without agents,
  so a bad style call in an agent row passes it. Type-check against the
  mod's `gpui-kit.d.ts` too (`line_clamp` doesn't exist; `flex_shrink()`
  needs a number), and look at the window: `line_height(15)` is fifteen
  times the text size, not 15px.
- **Saved drags beat the file:** a dragged boundary is kept in
  `layouts/.state/` and overrides `layouts/greasy-panes.json`. A state
  saved by an older install may still carry a removed block's size; it's
  harmless when no block has that id.
- **Worktree nesting** asks git, never names: a space's `folder` can be
  stale (where it was made) and its name can be anything. An earlier build
  matched folder names and put one repo's worktree under another repo.
- **`ctrl-b`** is taken from programs while this layout shows (shells lose
  ctrl-b for back-a-character).
- Untested on screen so far: the `ctrl-b` keys, the popups, help and the
  reconnecting state; each loads and type-checks.

## Done when

- With the layout shown, the window has no title bar: the sidebar runs to
  the top, and over the panes sits the 6px tab bar, one segment per tab with
  the shown tab's lit.
- Spaces show grouped by machine on `#2d2b27` blocks, one line each, with
  worktrees on a drawn tree under their repo; clicking `▾ Local` folds it.
- Clicking a segment of the tab bar switches tabs; dragging the bar moves
  the window.
- Dragging a space onto another moves it.
- `«` folds the sidebar to a 40px strip of numbers and letters; `»` restores
  its width. Dragging the sidebar's empty space moves the window.
- `ctrl-b c` opens a tab; `ctrl-b alt-g` opens lazygit floating over the
  tab, gone when it quits.
- Right-click a space → Rename opens a dialog with 7px corners and no notch.
- With the usage hook installed and a Claude session running, the agents
  half's bottom line shows its model and ctx, and 5h and week turn yellow
  past 50%.
- Every mod passes `herdr-app check`, and a TypeScript check against its
  `gpui-kit.d.ts` shows no errors the mod's Herdr original doesn't have.
