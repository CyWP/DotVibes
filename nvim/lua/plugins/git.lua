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
    opts = {
      -- the file list docks on the right edge, like neo-tree (top level:
      -- the panel reads config.file_panel, not view.file_panel)
      file_panel = { win_config = { position = "right" } },
    },
    keys = (function()
      local keys = {
        { "<leader>gv0", "<cmd>DiffviewOpen<cr>", desc = "Diff: working changes" },
        { "<leader>gc", "<cmd>DiffviewClose<cr>", desc = "Diff: close" },
        { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Diff: file history" },
        { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Diff: repo history" },
      }
      -- <leader>gv1..9: the last N commits combined (gv1 = the last commit);
      -- committed changes only, uncommitted work is gv0
      for n = 1, 9 do
        keys[#keys + 1] = {
          "<leader>gv" .. n,
          "<cmd>DiffviewOpen HEAD~" .. n .. "..HEAD<cr>",
          desc = "Diff: last " .. n .. (n == 1 and " commit" or " commits"),
        }
      end
      return keys
    end)(),
  },
}
