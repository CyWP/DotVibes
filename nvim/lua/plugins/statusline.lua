-- Statusline: lualine (reads mode/branch/diagnostics/filetype)
--
-- lualine has no `kanagawa-dragon` theme, so instead of its `auto` theme
-- (which would sample dragon's wave-blue popup colors) use a warm theme
-- built from dragon's own dragon* palette colors. Every section gets
-- bg = "none" so the terminal's translucent background shows through the
-- bar instead of an opaque strip. (theme + globalstatus must live inside
-- `options`; top-level keys are silently ignored.)
local black = "#181616"  -- dragonBlack3
local fg    = "#dcd7ba"  -- matches the colorscheme's ui.fg override
local grey  = "#625e5a"  -- dragonBlack6
local modes = {
  normal  = "#c4b28a", -- dragonYellow
  insert  = "#87a987", -- dragonGreen
  visual  = "#a292a3", -- dragonPink
  replace = "#c4746e", -- dragonRed
  command = "#8ba4b0", -- dragonBlue2
}
-- mode color is the foreground instead of a filled box: no opaque strip
local function theme(color)
  return {
    a = { bg = "none", fg = color, gui = "bold" },
    b = { bg = "none", fg = color },
    c = { bg = "none", fg = fg },
  }
end
local lualine_theme = {
  normal   = theme(modes.normal),
  insert   = theme(modes.insert),
  visual   = theme(modes.visual),
  replace  = theme(modes.replace),
  command  = theme(modes.command),
  terminal = theme(modes.command),
  inactive = { a = {}, b = {}, c = { bg = "none", fg = grey } },
}

return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      globalstatus = true, -- one bar across all splits (IDE-style)
      theme = lualine_theme,
    },
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
