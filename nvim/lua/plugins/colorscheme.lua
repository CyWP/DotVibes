-- Colorscheme: herdr (colors/herdr.lua — the person's own palette), plus
-- rainbow-delimiters so nested brackets cycle the theme's palette.
--
-- The theme defines the Rainbow* groups; this only hands the names to
-- rainbow-delimiters, in nesting order. Strategy and query are the
-- plugin's defaults (global strategy, the rainbow-delimiters query).
return {
  "HiPhish/rainbow-delimiters.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require("rainbow-delimiters.setup").setup({
      highlight = {
        "RainbowSage",
        "RainbowYellow",
        "RainbowMint",
        "RainbowBlue",
        "RainbowLilac",
        "RainbowRed",
      },
    })
    vim.cmd.colorscheme("herdr")
  end,
}
