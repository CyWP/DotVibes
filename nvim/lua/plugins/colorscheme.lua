-- Colorscheme: kanagawa (dragon variant — the dark, low-contrast one)
return {
  "rebelot/kanagawa.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    theme = "dragon",
    -- keep the terminal's background (incl. its background-opacity) visible
    -- instead of kanagawa's own opaque bg color
    transparent = true,
    -- a touch more contrast than stock dragon:
    -- main text: dragonWhite #c5c9c5 -> brighter, warmer cream (fujiWhite);
    -- comments: dragonAsh #737c73 -> lifted grey (statusline's fg matches)
    colors = {
      theme = {
        dragon = {
          ui = { fg = "#dcd7ba" },
          syn = { comment = "#8b948a" },
        },
      },
    },
    -- the bars' base groups paint opaque slabs over the translucent terminal
    -- background; lualine/bufferline are configured see-through separately,
    -- this clears what they don't draw over
    overrides = function()
      return {
        StatusLine = { bg = "none" },
        StatusLineNC = { bg = "none" },
        TabLine = { bg = "none" },
        TabLineFill = { bg = "none" },
      }
    end,
  },
  config = function(_, opts)
    require("kanagawa").setup(opts)
    -- :colorscheme kanagawa ignores `theme` when it matches `background`
    -- (defaults: dark = "wave", light = "lotus"), so load dragon explicitly
    vim.cmd.colorscheme("kanagawa-dragon")
  end,
}
