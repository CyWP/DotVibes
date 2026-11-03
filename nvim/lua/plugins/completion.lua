-- Completion: blink.cmp (pinned to stable v1; v2 is under active development)
return {
  "saghen/blink.cmp",
  version = "1.*",
  dependencies = { "rafamadriz/friendly-snippets" },
  event = "InsertEnter",
  config = function(_, opts)
    require("blink.cmp").setup(opts)

    -- Feed blink.cmp's capabilities into every LSP server so blink features
    -- (e.g. completion and snippets) work. `vim.lsp.config('*')` applies to all.
    vim.lsp.config("*", {
      capabilities = require("blink.cmp").get_lsp_capabilities(),
    })
  end,
  opts = {
    completion = {
      documentation = { auto_show = true },
    },
  },
}
