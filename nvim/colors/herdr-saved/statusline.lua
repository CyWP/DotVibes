-- Statusline: lualine (reads mode/branch/diagnostics/filetype).
-- Every section paints the herdr terminal surface (#242320) — the exact
-- background the pane shows — so the bar merges into the pane and the
-- card padding below it is invisible. Modes get a small chip in the
-- palette's accent colours (sage normal, mint insert, peach visual,
-- red replace, yellow command, blue terminal).
-- NOTE: lualine's own options (theme, globalstatus, separators) must sit
-- inside `options = {...}` — at the top level they are silently ignored.

local surface = "#242320" -- the herdr theme's terminal background
local ink      = "#1b1a17" -- dark text on the accent chips
local fg       = "#e7e2d6"
local dim      = "#a59b84"

local function section(fg_)
  return { fg = fg_, bg = surface }
end

local function chip(bg_)
  return { fg = ink, bg = bg_, gui = "bold" }
end

return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      globalstatus = true, -- one bar across all splits (IDE-style)
      theme = {
        normal   = { a = chip("#afc8a6"), b = section(dim), c = section(fg) },
        insert   = { a = chip("#7fe9c8"), b = section(dim), c = section(fg) },
        visual   = { a = chip("#ffc7a2"), b = section(dim), c = section(fg) },
        replace  = { a = chip("#f091a2"), b = section(dim), c = section(fg) },
        command  = { a = chip("#ffdb66"), b = section(dim), c = section(fg) },
        terminal = { a = chip("#8ac0ff"), b = section(dim), c = section(fg) },
        inactive = { a = section(dim), b = section(dim), c = section(dim) },
      },
      section_separators = { left = "", right = "" },
      component_separators = { left = "", right = "" },
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
