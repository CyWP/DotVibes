-- Highlight tweaks that survive :colorscheme switching.

-- One neutral grey for ALL diagnostic decorations: underlines, the inline ●
-- message AND the gutter signs now all use gruvbox's fg4 grey — severity is
-- communicated only by the sign's letter (E/W/I/H) and the shape of the
-- squiggle, not by color anywhere. Underline groups use the `sp` (special)
-- color for the squiggle (plain `underline`, not undercurl); virtual text and
-- sign groups get the same grey as `fg` so every decoration reads identically.
local DIAGNOSTIC_GREY = "#928374"
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("uniform-diagnostic-underline", { clear = true }),
  pattern = "*",
  callback = function()
    for _, sev in ipairs({ "Error", "Warn", "Info", "Hint" }) do
      vim.api.nvim_set_hl(0, "DiagnosticUnderline" .. sev, { underline = true, sp = DIAGNOSTIC_GREY })
      vim.api.nvim_set_hl(0, "DiagnosticVirtualText" .. sev, { fg = DIAGNOSTIC_GREY })
      vim.api.nvim_set_hl(0, "DiagnosticSign" .. sev, { fg = DIAGNOSTIC_GREY })
    end
  end,
  desc = "Uniform light-grey diagnostics across severities: underline, virtual text and gutter signs",
})

-- Every underline is drawn in the same grey, whatever colour the text above
-- it is: the sweep walks all defined highlight groups and gives the ones
-- with underline/undercurl a grey special (sp) colour, leaving groups that
-- already set one (the diagnostic underlines above) untouched. Runs on
-- every colourscheme and again once late, so plugin groups (treesitter
-- captures, telescope, …) registered after start are caught too.
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("grey-all-underlines", { clear = true }),
  pattern = "*",
  callback = function()
    local function sweep()
      for name, def in pairs(vim.api.nvim_get_hl(0, {})) do
        if type(def) == "table" and not def.link and (def.underline or def.undercurl) and not def.sp then
          vim.api.nvim_set_hl(0, name, vim.tbl_extend("force", def, { sp = DIAGNOSTIC_GREY }))
        end
      end
    end
    sweep()
    vim.defer_fn(sweep, 800)
  end,
  desc = "All underlines and undercurls drawn in the same grey, not the text colour",
})
