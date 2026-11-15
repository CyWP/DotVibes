-- Top strip of open buffers (VS Code-style "tabs") + cycling bindings
--
-- Every highlight group gets bg = "none" so the terminal's translucent
-- background shows through the strip instead of an opaque slab (bufferline
-- otherwise derives solid backgrounds from the colorscheme's Normal bg).
-- Foreground colors are left to bufferline's own derivation.
-- (Keys must be valid bufferline highlight names or it errors on setup.)
local bar_groups = {
  "fill", "trunc_marker", "group_separator", "group_label",
  "background", "buffer", "buffer_visible", "buffer_selected",
  "tab", "tab_close", "tab_selected", "tab_separator", "tab_separator_selected",
  "numbers", "numbers_visible", "numbers_selected",
  "diagnostic", "diagnostic_visible", "diagnostic_selected",
  "hint", "hint_visible", "hint_selected",
  "info", "info_visible", "info_selected",
  "warning", "warning_visible", "warning_selected",
  "error", "error_visible", "error_selected",
  "modified", "modified_visible", "modified_selected",
  "duplicate", "duplicate_visible", "duplicate_selected",
  "separator", "separator_visible", "separator_selected",
  "close_button", "close_button_visible", "close_button_selected",
  "pick", "pick_visible", "pick_selected",
  "indicator_visible", "indicator_selected",
  "offset_separator",
}
local transparent = {}
for _, group in ipairs(bar_groups) do
  transparent[group] = { bg = "none" }
end

return {
  "akinsho/bufferline.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev buffer (tab)" },
    { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer (tab)" },
    { "<leader>bd", "<cmd>bd<cr>", desc = "Close current buffer" },
    { "<leader>bp", "<cmd>BufferLinePick<cr>", desc = "Pick buffer" },
    { "<leader>ur", "<cmd>edit!<cr>", desc = "Reload buffer from disk (discard unsaved edits)" },
  },
  opts = {
    options = {
      diagnostics = "nvim_lsp", -- error/warning icons right on the tabs
      offsets = {
        -- don't overlay the file explorer
        { filetype = "neo-tree", text = "Explorer", highlight = "Directory", separator = true },
      },
    },
    highlights = transparent,
  },
}
