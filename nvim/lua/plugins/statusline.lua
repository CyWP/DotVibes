-- Statusline: lualine (gruvbox-aware, reads mode/branch/diagnostics/filetype)
return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    globalstatus = true, -- one bar across all splits (IDE-style)
    sections = {
      lualine_a = { "mode" },
      lualine_b = { { "branch", icon = "" }, "diff" },
      lualine_c = { { "filename", path = 1 } }, -- show relative path
      lualine_x = { "diagnostics", "filetype" },
      lualine_y = { "progress" },
      lualine_z = { "location" }, -- line:col · total lines
    },
    inactive_sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = { { "filename", path = 1 } },
      lualine_x = {},
      lualine_y = {},
      lualine_z = {},
    },
  },
}
