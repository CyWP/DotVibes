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
