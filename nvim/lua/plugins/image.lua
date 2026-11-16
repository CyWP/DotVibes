-- snacks.nvim: image viewer + start screen (dashboard) --
-- Image: kitty graphics protocol. Ghostty renders these natively; PNG needs
-- no extra tools on the system. Other formats (jpg, avif, webp, mp4
-- previews...) additionally require ImageMagick on PATH.
-- Note: on Neovim >= 0.13 the native `vim.ui.img` API covers this; revisit then.
--
-- Dashboard: replaces the dashboard-nvim plugin (removed). Same content as
-- before: doom-style NEOVIM logo, quick links, recent projects, recent files.
-- Reopen anytime with <leader>h.
local dashboard_header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]]

return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  keys = {
    { "<leader>h", function() Snacks.dashboard() end, desc = "Open dashboard" },
  },
  opts = {
    -- everything else stays off (snacks modules are opt-in)
    dashboard = {
      enabled = true,
      preset = {
        header = dashboard_header,
        -- Same quick links as the old dashboard-nvim setup.
        keys = {
          { icon = " ", key = "n", desc = "New file",     action = ":ene | startinsert" },
          { icon = " ", key = "f", desc = "Find file",    action = ":lua Snacks.dashboard.pick('files')" },
          { icon = " ", key = "r", desc = "Recent files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
          { icon = " ", key = "g", desc = "Live grep",    action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = " ", key = "c", desc = "Config",       action = ":edit $MYVIMRC" },
          { icon = " ", key = "q", desc = "Quit",         action = ":qa" },
        },
      },
      sections = {
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },
        -- Like before: open the picker in the project dir, without cd-ing.
        {
          icon = " ",
          title = "Recent projects:",
          section = "projects",
          limit = 4,
          indent = 2,
          padding = 1,
          action = function(dir) Snacks.dashboard.pick("files", { cwd = dir }) end,
        },
        {
          icon = " ",
          title = "Recent files:",
          section = "recent_files",
          limit = 7,
          indent = 2,
          padding = 1,
        },
        { section = "startup" },
      },
    },
    image = {
      enabled = true,
      doc = {
        inline = true, -- render image links inside the buffer (Obsidian-like)
        float = true, -- fallback: floating window on hover
      },
    },
  },
}
