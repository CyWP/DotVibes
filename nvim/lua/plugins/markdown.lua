-- Inline markdown viewer/editor: render-markdown
-- Renders markdown in the buffer (headings, checkboxes, tables, code blocks,
-- callouts) while remaining fully editable. `:RenderMarkdown toggle` off.
return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown" },
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  keys = {
    { "<leader>md", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle markdown render" },
  },
  opts = {
    render_modes = true, -- keep rendering while in insert/normal/edit modes

    -- "Obsidian-like" spacing: chunky headings, inset paragraphs, roomy lists
    heading = {
      border = true, -- ▄ above / ▀ below: visual gap around headings
      width = "full", -- full-width band like a big Obsidian title
      right_pad = 1,
      -- one quiet left tick for every level (the list cycles per level),
      -- instead of the default per-level nerd-font glyphs
      icons = { "▍" },
    },
    paragraph = {
      left_margin = 2, -- small inset for body text
    },
    bullet = {
      -- plain prose bullets instead of the default dots-and-diamonds
      icons = { "•", "◦", "▪" },
    },
    code = {
      width = "full", -- code blocks span the window (with their own band)
      left_pad = 2,
    },
    checkbox = {
      left_pad = 3, -- checkbox lists breathe
      right_pad = 1,
      -- Obsidian's in-progress state: '- [/]' renders as a half-filled circle
      custom = {
        in_progress = { raw = "[/]", rendered = "◐", highlight = "RenderMarkdownTodo" },
      },
    },
    dash = {
      width = "full", -- '---' spans the whole window like a divider
    },
  },
}
