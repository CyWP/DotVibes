-- Code outline window: aerial (skimmable symbol tree, VS Code-style)
--
-- Uses treesitter when available and falls back to LSP for symbols.
-- <leader>a toggles the outline; inside it, {/} jump to the previous/next
-- symbol while the source window scrolls along (README-prescribed setup).
return {
  "stevearc/aerial.nvim",
  cmd = { "AerialToggle", "AerialOpen", "AerialClose", "AerialNavToggle" },
  keys = {
    { "<leader>a", "<cmd>AerialToggle!<cr>", desc = "Toggle outline window" },
  },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    -- README's on_attach example: jump forwards/backwards with { and }
    -- (buffer-local, so these keys are untouched everywhere else)
    on_attach = function(bufnr)
      vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr, desc = "Previous symbol" })
      vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr, desc = "Next symbol" })
    end,
  },
}
