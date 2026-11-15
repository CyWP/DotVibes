-- Inline image viewer: snacks.nvim image module (kitty graphics protocol --
-- Ghostty renders these natively; PNG needs no extra tools on the system)
-- Other formats (jpg, avif, webp, mp4 previews...) additionally require
-- ImageMagick on PATH.
-- Note: on Neovim >= 0.13 the native `vim.ui.img` API covers this; revisit then.
return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    -- everything else stays off (snacks modules are opt-in)
    dashboard = {
      -- snacks has its own start screen ("NVIM DASH BOARD" banner) that
      -- otherwise hijacks startup; dashboard-nvim (plugins/dashboard.lua)
      -- owns the start page instead.
      enabled = false,
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
