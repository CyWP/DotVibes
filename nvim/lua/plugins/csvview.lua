-- CSV files as aligned tables: csvview (column alignment + field navigation)
--
-- Instead of raw comma soup, renders each line as aligned columns
-- (VS Code-style table view) and adds field text-objects + jumps:
--   if/af  inner/around field text-object
--   <Tab>  next field start    <S-Tab>  previous field start
--   <C-j>  next field end      <C-k>    previous field end
-- Toggle with :Csv (also auto-enables when a csv/tsv file is opened).
return {
  "hat0uma/csvview.nvim",
  ft = { "csv", "tsv" },
  cmd = { "Csv", "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
  opts = {
    parser = {
      -- per-filetype delimiters: commas for .csv, tabs for .tsv
      delimiter = { ft = { csv = ",", tsv = "\t" } },
    },
    view = {
      -- "align" pads every column to its widest cell (true table look);
      -- the default "highlight" only colors columns without aligning
      display_mode = "align",
    },
  },
  config = function(_, opts)
    require("csvview").setup(opts)
    -- Turn the table view on automatically (no built-in autostart option)
    vim.api.nvim_create_autocmd("FileType", {
      desc = "Enable csvview on csv/tsv files",
      pattern = { "csv", "tsv" },
      callback = function(args)
        require("csvview").enable(args.buf)
      end,
    })
    -- Short alias for toggling the table view
    vim.api.nvim_create_user_command("Csv", function()
      require("csvview").toggle(0)
    end, { desc = "Toggle csvview table view (current buffer)" })
  end,
}
