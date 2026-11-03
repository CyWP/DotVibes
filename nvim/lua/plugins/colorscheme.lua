-- Colorscheme: gruvbox (alternative: morhetz/gruvbox is the original vim variant)
return {
  "ellisonleao/gruvbox.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    -- keep the terminal's background (incl. its background-opacity) visible
    -- instead of gruvbox's own opaque bg color
    -- (newer gruvbox versions renamed this option to transparent_background)
    transparent_mode = true,
  },
  config = function(_, opts)
    require("gruvbox").setup(opts)
    vim.cmd.colorscheme("gruvbox")
  end,
}
