-- Colourscheme: gruvbox (ellisonleao/gruvbox.nvim — the warm classic),
-- plus rainbow-delimiters for nested brackets.
--
-- transparent_mode keeps the terminal's background (incl. its opacity)
-- visible. The Rainbow* groups ride in through gruvbox's overrides, in its
-- bright palette (no red, no yellow in the cycle). Order = nesting depth,
-- cycling.
return {
  {
    "HiPhish/rainbow-delimiters.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("rainbow-delimiters.setup").setup({
        highlight = {
          "RainbowFg",
          "RainbowGreen",
          "RainbowAqua",
          "RainbowBlue",
          "RainbowPurple",
        },
      })
    end,
  },
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1001,
    opts = {
      transparent_mode = true,
      palette_overrides = {
        -- the yellow (types, line numbers), a touch lighter than stock
        bright_yellow = "#ffca5f",
        -- the blue (identifiers, attribute names, signs), a touch lighter
        bright_blue = "#a2bbb2",
        -- the green (strings, functions, signs), a touch pastel
        bright_green = "#cdcf67",
        -- the purple (constants, numbers, booleans): lilac, not rose
        bright_purple = "#dfaee6",
        -- the orange (operators, special): a punchier peach (the light
        -- peach for imports/decorators stays softer)
        bright_orange = "#ff9547",
        -- the aqua (imports, decorators, special marks): light peach
        bright_aqua = "#ffc7a2",
        -- the red: pinkish (crimson), not orange-red
        bright_red = "#ff4d7f",
      },
      overrides = {
        -- docstrings read as comments (python and the generic capture)
        ["@string.documentation"] = { link = "Comment" },
        ["@string.documentation.python"] = { link = "Comment" },
        RainbowFg     = { fg = "#ebdbb2" }, -- the regular-text colour
        RainbowGreen  = { fg = "#b8bb26" },
        RainbowAqua   = { fg = "#ffc7a2" },
        RainbowBlue   = { fg = "#83a598" },
        RainbowPurple = { fg = "#dfaee6" },
      },
    },
    config = function(_, opts)
      vim.o.background = "dark"
      require("gruvbox").setup(opts)
      vim.cmd.colorscheme("gruvbox")
    end,
  },
}
