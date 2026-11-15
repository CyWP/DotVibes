-- Highlight tweaks that survive :colorscheme switching.

-- Transparent background: let the terminal's own surface (herdr's #242320)
-- show through. Strips the bg from the surface groups after every
-- colorscheme, so a switch (or a plugin) can't paint over it. Groups whose
-- bg carries meaning — Visual, Search, PmenuSel, CursorLine, MatchParen,
-- Diff* — are left alone.
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("transparent-background", { clear = true }),
  pattern = "*",
  callback = function()
    for _, name in ipairs({
      "Normal", "NormalNC", "SignColumn", "LineNr", "FoldColumn", "Folded",
      "EndOfBuffer", "WinSeparator", "VertSplit", "NormalFloat", "FloatBorder",
      "StatusLine", "StatusLineNC", "TabLine", "TabLineFill", "TabLineSel",
      "Pmenu", "PmenuSbar", "PmenuThumb", "MsgArea", "Terminal",
    }) do
      local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
      if ok and next(hl) ~= nil then
        hl.bg = nil
        vim.api.nvim_set_hl(0, name, hl)
      end
    end
  end,
  desc = "Transparent background: strip the bg from surface groups",
})

-- One neutral grey for ALL diagnostic decorations: underlines, the inline ●
-- message AND the gutter signs now all use gruvbox's fg4 grey — severity is
-- communicated only by the sign's letter (E/W/I/H) and the shape of the
-- squiggle, not by color anywhere. Underline groups use the `sp` (special)
-- color for the squiggle (plain `underline`, not undercurl); virtual text and
-- sign groups get the same grey as `fg` so every decoration reads identically.
local DIAGNOSTIC_GREY = "#a59b84"
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
