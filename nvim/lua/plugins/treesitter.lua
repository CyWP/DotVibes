-- Treesitter parsers + syntax highlighting
-- Uses the rewritten plugin (`main` branch), requires Nvim 0.12+ and
-- `tree-sitter` cli (0.26.1+), curl/tar and a C compiler.
return {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    -- Install parsers for the languages used (async; no-op if present)
    require("nvim-treesitter").install({
      "lua",
      "vim",
      "vimdoc",
      "python",
      "c",
      "cpp",
      "markdown",
      "markdown_inline",
      "html", -- inline-styled blocks inside markdown
      "bash",
    })

    -- nvim-treesitter provides queries; Neovim core implements the features.
    vim.api.nvim_create_autocmd("FileType", {
      desc = "Enable treesitter highlighting",
      pattern = { "lua", "vim", "vimdoc", "python", "c", "cpp", "markdown", "bash" },
      callback = function()
        -- do not error for filetypes without a parser on disk
        pcall(vim.treesitter.start)
      end,
    })
  end,
}
