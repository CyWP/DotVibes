-- Sticky scope: nvim-treesitter-context pins the enclosing class/function
-- signature at the top of the window once it has scrolled off screen
return {
  "nvim-treesitter/nvim-treesitter-context",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  keys = {
    { "<leader>uc", "<cmd>TSContext toggle<cr>", desc = "Toggle sticky scope context" },
  },
  opts = {
    max_lines = 3, -- never eat more than 3 rows in deeply nested code
    multiline_threshold = 1, -- collapse long multi-line signatures to one row
    mode = "cursor", -- scope the cursor is inside (not the topmost visible line)
  },
}
