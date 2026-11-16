-- Surround mappings: nvim-surround by kylechui, with short prefix-style keys
-- instead of the defaults:
--   sa{motion}{char}  add a surrounding around a textobject, e.g. saiw(
--   s{char}           add a surrounding around the visual selection
--   sd{char}          delete a surrounding, e.g. sd(
--   sr{old}{new}      change a surrounding, e.g. sr([  (was cs)
-- S / gS still surround the selection (line-wise) in visual mode, and the
-- insert-mode defaults (<C-g>s / <C-g>S) are untouched.
-- Note: since v4 keymaps are bound by hand to the plugin's <Plug> mappings
-- (see :h nvim-surround.migrating.v3_to_v4); the ys/cs/ds defaults are
-- disabled, so the line-wise variants (yss, yS, cS, dst, ...) are gone too.
return {
  "kylechui/nvim-surround",
  event = "VeryLazy",
  opts = {},
  init = function()
    -- read at plugin load time: drop the ys/cs/ds family, we bind our own
    vim.g.nvim_surround_no_normal_mappings = true
  end,
  config = function(_, opts)
    require("nvim-surround").setup(opts)
    local map = vim.keymap.set
    map("n", "sa", "<Plug>(nvim-surround-normal)", { desc = "Surround: add around motion" })
    map("n", "sd", "<Plug>(nvim-surround-delete)", { desc = "Surround: delete" })
    map("n", "sr", "<Plug>(nvim-surround-change)", { desc = "Surround: change" })
    map("x", "s", "<Plug>(nvim-surround-visual)", { desc = "Surround: add around selection" })
    map("x", "gS", "<Plug>(nvim-surround-visual-line)", { desc = "Surround: add around selection (line-wise)" })
  end,
}
