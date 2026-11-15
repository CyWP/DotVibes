-- Scrollbar: satellite.nvim (thin bar on the right edge showing where you are
-- in the file, with ticks for diagnostics, git hunks (gitsigns) and search matches)
return {
  "lewis6991/satellite.nvim",
  event = "VeryLazy",
  keys = {
    { "<leader>us", "<cmd>SatelliteToggle<cr>", desc = "Toggle scrollbar" },
  },
  opts = {
    current_only = true, -- bar only in the focused window
    winblend = 30, -- slightly transparent
    width = 2,
    excluded_filetypes = { "neo-tree", "TelescopePrompt", "lazy", "mason" },
    handlers = {
      cursor = { enable = true },
      search = { enable = true },
      diagnostic = { enable = true },
      gitsigns = { enable = true },
      marks = { enable = false }, -- noisy
      quickfix = { enable = false },
    },
  },
}
