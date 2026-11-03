-- Fuzzy finder
return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
    "nvim-telescope/telescope-ui-select.nvim",
  },
  -- Load telescope and let it handle the keymaps which also trigger an install.
  keys = {
    { "<leader>ff", function() require("telescope.builtin").find_files() end, desc = "Find files" },
    { "<leader>fg", function() require("telescope.builtin").live_grep() end, desc = "Live grep" },
    { "<leader>fb", function() require("telescope.builtin").buffers() end, desc = "Buffers" },
    { "<leader>fh", function() require("telescope.builtin").help_tags() end, desc = "Help tags" },
    { "<leader>fk", function() require("telescope.builtin").keymaps() end, desc = "Search keymaps" },
    { "<leader>fr", function() require("telescope.builtin").oldfiles() end, desc = "Recent files" },
    { "<leader>ld", function() require("telescope.builtin").diagnostics() end, desc = "Diagnostics" },
  },
  config = function()
    require("telescope").setup({
      pickers = {
        find_files = { hidden = true },
      },
    })
    require("telescope").load_extension("fzf")
    require("telescope").load_extension("ui-select")
  end,
}
