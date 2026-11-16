-- Smooth scrolling: neoscroll (karb94) — animated versions of the standard
-- vim scroll keys. <C-b> is deliberately left out: herdr's tmux-style prefix
-- (ctrl-b chords) swallows it before it can ever reach nvim.
-- <PageUp>/<PageDown> stay quarter-page cursor jumps (config/keymaps.lua).
return {
  "karb94/neoscroll.nvim",
  event = "VeryLazy",
  opts = {
    mappings = { "<C-u>", "<C-d>", "<C-f>", "<C-e>", "<C-y>", "zt", "zz", "zb" },
  },
}
