-- Code formatting: conform.nvim. Formatter binaries resolve from PATH.
return {
  "stevearc/conform.nvim",
  event = "BufWritePre", -- format on save
  cmd = { "ConformInfo" },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      c = { "clang_format" },
      cpp = { "clang_format" },
      python = { "ruff_organize_imports", "ruff_format" },
    },
    default_format_opts = { lsp_format = "fallback" },
    format_on_save = {
      timeout_ms = 500,
      lsp_format = "fallback",
    },
  },
  keys = {
    {
      "<leader>lf",
      function() require("conform").format({ lsp_format = "fallback" }) end,
      desc = "Format buffer",
      mode = { "n", "v" },
    },
  },
}
