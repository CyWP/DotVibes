-- herdr — the person's own palette (see DotVibes agents/skills/theme-colors).
-- Dark, transparent background: the herdr terminal surface (#242320) shows
-- through, like gruvbox's transparent_mode did before it.

if vim.g.colors_name then vim.cmd("hi clear") end
if vim.fn.exists("syntax_on") then vim.cmd("syntax reset") end
vim.o.termguicolors = true
vim.g.colors_name = "herdr"

local hi = vim.api.nvim_set_hl

local fg      = "#e7e2d6"
local white   = "#ffffff"
local dim     = "#a59b84"  -- beige: comments, secondary text
local faint   = "#8e897a"
local red     = "#c77b88"
local d_red   = "#cd6578"
local yellow  = "#dcc37a"
local d_yellow= "#c68c36"
local mint    = "#6dc1a6"
local d_mint  = "#32b28a"
local peach   = "#ffc7a2"
local d_peach = "#ffaf80"
local light_peach = "#ffc7a2"  -- lighter peach: math symbols
local lilac   = "#dfaee6"
local blue    = "#91b4db"
local d_blue  = "#507dbc"
local pale_teal = "#a9d0c4"
local pale_pink = "#d0aca4"
local pink   = "#ffb0d0"  -- light pastel pink: module names
local sage    = "#afc8a6"
local dark    = "#332e27"
local select  = "#3e3a31"
local line    = "#2b2925"  -- barely above the surface, for cursor line
local border  = "#514d43"

-- base: transparent — the terminal's own surface shows through
hi(0, "Normal",   { fg = fg })
hi(0, "NormalNC", { fg = fg })
hi(0, "EndOfBuffer", { fg = dark })

-- UI chrome
hi(0, "Cursor",       { fg = dark, bg = sage })
hi(0, "lCursor",      { fg = dark, bg = sage })
hi(0, "Visual",       { bg = select })
hi(0, "CursorLine",   { bg = line })
hi(0, "CursorColumn", { bg = line })
hi(0, "LineNr",       { fg = faint })
hi(0, "CursorLineNr", { fg = sage, bold = true })
hi(0, "SignColumn",   { fg = faint })
hi(0, "FoldColumn",   { fg = faint })
hi(0, "Folded",       { fg = dim })
hi(0, "WinSeparator", { fg = border })
hi(0, "VertSplit",    { fg = border })
hi(0, "StatusLine",   { fg = fg })
hi(0, "StatusLineNC", { fg = dim })
hi(0, "TabLine",      { fg = dim })
hi(0, "TabLineSel",   { fg = white })
hi(0, "TabLineFill",  { fg = dim })
hi(0, "NormalFloat",  { fg = fg })
hi(0, "FloatBorder",  { fg = sage })
hi(0, "FloatTitle",   { fg = sage, bold = true })
hi(0, "Pmenu",        { fg = fg })
hi(0, "PmenuSel",     { bg = select, fg = white })
hi(0, "PmenuMatch",   { fg = sage })
hi(0, "PmenuSbar",    { bg = dark })
hi(0, "PmenuThumb",   { bg = border })
hi(0, "Search",       { bg = select, fg = white })
hi(0, "IncSearch",    { fg = dark, bg = d_yellow })
hi(0, "CurSearch",    { fg = dark, bg = d_yellow })
hi(0, "Substitute",   { fg = dark, bg = d_mint })
hi(0, "QuickFixLine", { bg = select })
hi(0, "MsgArea",      { fg = fg })
hi(0, "MoreMsg",      { fg = mint })
hi(0, "ModeMsg",      { fg = fg })
hi(0, "ErrorMsg",     { fg = d_red })
hi(0, "WarningMsg",   { fg = d_yellow })
hi(0, "Directory",    { fg = blue })
hi(0, "Title",        { fg = sage, bold = true })
hi(0, "SpecialKey",   { fg = faint })
hi(0, "NonText",      { fg = faint })
hi(0, "Whitespace",   { fg = dark })
hi(0, "Conceal",      { fg = dim })
hi(0, "MatchParen",   { fg = white, bg = select, bold = true })
hi(0, "WildMenu",     { fg = dark, bg = sage })

-- syntax
hi(0, "Comment",        { fg = dim, italic = true })
hi(0, "Constant",       { fg = sage })
hi(0, "String",         { fg = sage })
hi(0, "Character",      { fg = sage })
hi(0, "Number", { fg = sage })  -- numeric literals read like strings
hi(0, "Float", { fg = sage })
hi(0, "Boolean",        { fg = lilac })
hi(0, "Identifier",     { fg = fg })
hi(0, "Function",       { fg = yellow })
hi(0, "Statement",      { fg = pale_teal })
hi(0, "Keyword",        { fg = pale_teal })
hi(0, "Conditional",    { fg = pale_teal })
hi(0, "Repeat",         { fg = pale_teal })
hi(0, "Label",          { fg = pale_teal })
hi(0, "Operator",       { fg = d_mint })
hi(0, "Exception",      { fg = red })
hi(0, "PreProc",        { fg = d_peach })
hi(0, "Include",        { fg = d_peach })
hi(0, "Define",         { fg = d_peach })
hi(0, "Macro",          { fg = d_peach })
hi(0, "Type",           { fg = d_peach })
hi(0, "StorageClass",   { fg = d_peach })
hi(0, "Structure",      { fg = d_peach })
hi(0, "Typedef",        { fg = d_peach })
hi(0, "Special",        { fg = red })
hi(0, "SpecialChar",    { fg = red })
hi(0, "Tag",            { fg = yellow })
hi(0, "Delimiter",      { fg = dim })
hi(0, "SpecialComment", { fg = dim })
hi(0, "Debug",          { fg = red })
hi(0, "Underlined",     { fg = d_blue, underline = true })
hi(0, "Ignore",         { fg = faint })
hi(0, "Error",          { fg = d_red, bold = true })
hi(0, "Todo",           { fg = dark, bg = sage, bold = true })

-- treesitter captures the built-in links don't cover
hi(0, "@variable",          { fg = fg })
hi(0, "@variable.builtin",  { fg = sage })
hi(0, "@constant.builtin",  { fg = d_peach })
hi(0, "@function.builtin",  { fg = yellow })
hi(0, "@type",              { fg = d_peach })
hi(0, "@type.builtin",      { fg = d_peach })
hi(0, "@type.definition",   { fg = d_peach })
hi(0, "@module",            { fg = pink })   -- module names, imports
hi(0, "@module.builtin",    { fg = pink })
hi(0, "@property",          { fg = fg })
hi(0, "@parameter",         { fg = fg })
hi(0, "@field",             { fg = fg })
hi(0, "@operator",          { fg = d_mint })
hi(0, "@operator.assign",   { fg = blue })   -- equal signs, per the python query
hi(0, "@operator.math",     { fg = light_peach })  -- + - * /, lighter peach
hi(0, "@punctuation",       { fg = dim })
-- docstrings read like comments (strings themselves stay sage)
hi(0, "@string.documentation", { fg = dim, italic = true })

-- nested brackets (rainbow-delimiters): outermost level sage (the numeric
-- literal colour), then cycling yellow → mint → blue → lilac → red deeper in
hi(0, "RainbowSage",   { fg = sage })
hi(0, "RainbowYellow", { fg = yellow })
hi(0, "RainbowMint",   { fg = mint })
hi(0, "RainbowBlue",   { fg = blue })
hi(0, "RainbowLilac",  { fg = lilac })
hi(0, "RainbowRed",    { fg = red })

-- diff: green/red washes behind the lines, the text colour itself unchanged
-- (no fg on the Diff groups). gitsigns links its gutter marks to these, so
-- GitSigns* get explicit colours here to keep them green/red in the gutter.
hi(0, "DiffAdd",    { bg = "#2e4034" })  -- dark mint wash
hi(0, "DiffChange", { bg = "#413625" })  -- dark amber wash
hi(0, "DiffText",   { bg = "#3d5a4f" })  -- the changed words, stronger green
hi(0, "DiffDelete", { bg = "#402e31" })  -- dark red wash
hi(0, "GitSignsAdd",    { fg = d_mint })
hi(0, "GitSignsChange", { fg = d_yellow })
hi(0, "GitSignsDelete", { fg = d_red })

-- diagnostics (base colours; lua/config/highlights.lua restyles the
-- underline/virtual-text/sign shapes uniformly)
hi(0, "DiagnosticError", { fg = d_red })
hi(0, "DiagnosticWarn",  { fg = d_yellow })
hi(0, "DiagnosticInfo",  { fg = d_mint })
hi(0, "DiagnosticHint",  { fg = mint })
hi(0, "DiagnosticOk",    { fg = d_mint })
