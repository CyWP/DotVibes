-- Top strip of open buffers (VS Code-style "tabs") + cycling bindings
return {
  "akinsho/bufferline.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev buffer (tab)" },
    { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer (tab)" },
    { "<leader>bd", "<cmd>bd<cr>", desc = "Close current buffer" },
    { "<leader>bp", "<cmd>BufferLinePick<cr>", desc = "Pick buffer" },
    { "<leader>ur", "<cmd>edit!<cr>", desc = "Reload buffer from disk (discard unsaved edits)" },
  },
  opts = {
    options = {
      diagnostics = "nvim_lsp", -- error/warning icons right on the tabs
      offsets = {
        -- don't overlay the file explorer
        { filetype = "neo-tree", text = "Explorer", highlight = "Directory", separator = true },
      },
    },
  },
}
