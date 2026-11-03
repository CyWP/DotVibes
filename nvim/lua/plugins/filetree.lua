-- File explorer: neo-tree (VS Code-style sidebar, toggleable)
return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  cmd = { "Neotree" },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  keys = {
    -- Toggle the sidebar like a typical IDE
    { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle file explorer" },
  },
  opts = {
    filesystem = {
      follow_current_file = { enabled = true },
      filtered_items = {
        -- gitignored/dotfiles stay *listed* (dimmed, "hidden" badge) but
        -- still navigable. `H` in the tree toggles them on/off.
        hide_dotfiles = false,
        visible = true,
      },
    },
  },
  config = function(_, opts)
    require("neo-tree").setup(opts)
    -- Open the sidebar on start-up (won't affect :Neotree git/toggle)
    vim.api.nvim_create_autocmd("VimEnter", {
      desc = "Open file explorer on start",
      callback = function()
        if vim.fn.argc() == 0 then -- only when plain `nvim` without a file argument
          vim.cmd("Neotree toggle")
        end
      end,
    })
  end,
}
