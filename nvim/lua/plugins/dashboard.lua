-- Start screen: dashboard-nvim with the "hyper" theme, but with the classic
-- doom-style "NEOVIM" block-letter logo as the header.
--
-- Opens when nvim is launched without a file argument — a VS Code
-- start-page: logo, action shortcuts and recent files/projects. Reopen
-- anytime with `:Dashboard` or <leader>h.
-- Shortcuts reuse telescope, which is already configured in telescope.lua.
--
-- Note: like the neo-tree auto-open in filetree.lua, this only triggers on
-- plain `nvim` (no file argument), so the two start together as a start
-- page + sidebar, and `nvim <file>` still skips straight to the file.
return {
  "nvimdev/dashboard-nvim",
  event = "VimEnter",
  dependencies = { "nvim-tree/nvim-web-devicons", "nvim-telescope/telescope.nvim" },
  keys = {
    { "<leader>h", "<cmd>Dashboard<cr>", desc = "Open dashboard" },
  },
  opts = {
    theme = "hyper",
    config = {
      -- The classic doom-style "NEOVIM" block-letter logo.
      header = vim.split([[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]], "\n"),
      -- week_header takes precedence over header in the plugin, so disable
      -- it or the weekday banner would still win over the logo above.
      week_header = {
        enable = false,
      },
      shortcut = {
        { desc = "New file",       key = "n", group = "@property", action = "ene | startinsert" },
        { desc = "Find file",      key = "f", group = "@property", action = "Telescope find_files" },
        { desc = "Recent files",   key = "r", group = "@property", action = "Telescope oldfiles" },
        { desc = "Live grep",      key = "g", group = "@property", action = "Telescope live_grep" },
        { desc = "Config",         key = "c", group = "@property", action = "edit $MYVIMRC" },
        { desc = "Quit",           key = "q", group = "@property", action = "qa" },
      },
      project = {
        enable = true,
        limit = 4,
        icon = " ",
        label = "Recent projects:",
        -- dashboard appends each recent directory to this command
        action = "Telescope find_files cwd=",
      },
      mru = { limit = 7, icon = " ", label = "Recent files:" },
      footer = {},
    },
  },
}
