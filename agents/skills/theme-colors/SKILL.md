---
name: theme-colors
description: The person's colour preferences for creating or adjusting any theme, colorscheme or terminal palette (dark themes only). Use whenever building, tweaking or reviewing a colour theme for any tool or app.
---

# Theme colours

The person uses **dark themes only** — never build or suggest a light
theme. Backgrounds must be **warm, slightly warm greys**: no blue-dominant
surfaces, and not brown either (gruvbox's greys read brown to them). A
ladder that works: chrome `#1b1a17`, surface `#242320`, raised `#2d2b27`,
hover `#3a3730`, selected `#484439`, borders `#514d43`, foreground
`#e7e2d6`, beige blacks `#332e27` / `#b3a88f`.

## Accent family they like

Pastel, bright "in-between" colours — pinkish-red, greenish-blues (teal,
mint), indigo/violet, orangeish yellows. Their hand-picked hexes:

- crimson `#ff004c`
- mint `#00ffb3`
- violet `#7a00ff`
- beigish yellow `#ffca5f`
- peach `#ffaf80`
- blue `#489dff`
- soft sage `#afc8a6`
- lilac `#dfaee6`

## Rules that came out of iterating on the herdr theme

- **Pastel versions are the defaults** (the normal slots / base colours);
  the deeper, more saturated versions are the brights.
- **Sage `#afc8a6` is the main accent** going around panels (borders, tabs,
  focus rings); mint `#00ffb3` is the punch colour.
- **Keep hues honest at pastel lightness**: raise lightness too far and red
  turns salmon (reads yellow), blue turns gray. Pastel ≠ washed out — keep
  the hue unmistakable (`#f87171` is a pastel red; `#fb879d` is not).
- **Blues: at most two blue-ish pairs** in a 16-colour terminal palette.
- **One white slot only** (full white `#ffffff`); spare bright-white slots
  can carry the accent instead.
- **Keep semantics conventional**: red in the red slot, yellow in the
  yellow slot, unless the person explicitly asks for a swap — they notice
  and mind when colours drift into the wrong columns.
- **Terminal default text: white**, not tinted.
- **Editor syntax (nvim): warm/green dominant, minimal blue/purple.** In
  syntax colours they want the warm colours and greens to dominate —
  current mapping: keywords in sage, numbers in pastel red,
  methods/functions in yellow,
  strings in mint, operators in deep mint (equal signs in
  pastel blue), types in deep peach. Blues and
  purples read as "too much blue/purple" when they cover frequent
  roles. Blue only for rare/UI roles.
- **opencode stays on its built-in `"system"` theme.** A custom opencode
  theme mapped onto the terminal's ANSI slots was tried and rejected —
  it looked bad. Do not build one again unless asked.

A working reference that follows all of this:
`herdr-app/themes/Floracotta.json` in the DotVibes repo (live in
`~/.config/herdr-app/themes/`).
