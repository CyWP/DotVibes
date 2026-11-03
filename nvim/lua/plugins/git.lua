-- Git: gitsigns (gutter indicators) + diffview (side-by-side merge tool)
return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local map = function(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = "Git: " .. desc })
        end
        map("]h", function()
          if vim.wo.diff then vim.schedule(gs.next_hunk) return end
          gs.next_hunk()
        end, "Next hunk")
        map("[h", function()
          if vim.wo.diff then vim.schedule(gs.prev_hunk) return end
          gs.prev_hunk()
        end, "Prev hunk")
        map("<leader>hp", gs.preview_hunk, "Preview hunk")
        map("<leader>hs", gs.stage_hunk, "Stage hunk")
        map("<leader>hr", gs.reset_hunk, "Reset hunk")
        map("<leader>tb", function() gs.toggle_current_line_blame() end, "Toggle inline blame")
        map("<leader>td", function() gs.toggle_deleted() end, "Toggle deleted")
      end,
    },
  },
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    dependencies = {
      "nvim-tree/nvim-web-devicons", -- file type icons in the diff panel
    },
    keys = {
      { "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "Diff: open" },
      { "<leader>gc", "<cmd>DiffviewClose<cr>", desc = "Diff: close" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Diff: file history" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Diff: repo history" },
    },
  },
}
