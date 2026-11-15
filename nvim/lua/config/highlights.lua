-- Highlight tweaks that survive :colorscheme switching.

-- One neutral grey for ALL diagnostic decorations: underlines, the inline ●
-- message AND the gutter signs now all use gruvbox's fg4 grey — severity is
-- communicated only by the sign's letter (E/W/I/H) and the shape of the
-- squiggle, not by color anywhere. Underline groups use the `sp` (special)
-- color for the squiggle (plain `underline`, not undercurl); virtual text and
-- sign groups get the same grey as `fg` so every decoration reads identically.
-- (herdr's terminal cannot colour underlines, so the line renders in the
-- text's colour — the sp still applies anywhere that supports it.)
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
-- it is: the sweep walks all defined highlight groups and forces a grey
-- special (sp) colour on the ones with underline/undercurl — even where the
-- theme set its own sp (spell undercurls, for one). Runs on every
-- colourscheme and every FileType (plugins attach highlights per buffer
-- type), plus a few late passes so groups registered after start are caught.
local UNDERLINE_AUGROUP = vim.api.nvim_create_augroup("grey-all-underlines", { clear = true })
local function sweep_underlines()
  for name, def in pairs(vim.api.nvim_get_hl(0, {})) do
    if type(def) == "table" and not def.link and (def.underline or def.undercurl) then
      vim.api.nvim_set_hl(0, name, vim.tbl_extend("force", def, { sp = DIAGNOSTIC_GREY }))
    end
  end
end
vim.api.nvim_create_autocmd({ "ColorScheme", "FileType" }, {
  group = UNDERLINE_AUGROUP,
  pattern = "*",
  callback = sweep_underlines,
  desc = "All underlines and undercurls drawn in the same grey, not the text colour",
})
for _, ms in ipairs({ 300, 1000, 3000 }) do
  vim.defer_fn(sweep_underlines, ms)
end
