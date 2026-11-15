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
local faint   = "#a49e91"  -- a bit closer to white than before
local red     = "#c77b88"
local d_red   = "#cd6578"
local yellow  = "#dcc37a"
local d_yellow= "#c68c36"
local mint    = "#6dc1a6"
local d_mint  = "#32b28a"
local peach   = "#ffc7a2"
local d_peach = "#ffaf80"
local lilac   = "#dfaee6"
local blue    = "#91b4db"
local d_blue  = "#507dbc"
local pale_teal = "#a9d0c4"
local pale_pink = "#d0aca4"
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
-- syntax — a 1:1 mapping of kanagawa-dragon's colours onto this palette,
-- same distribution, each colour a touch lighter than its dragon original:
-- dragonAsh→faint, dragonGreen2→sage, dragonPink→pale_pink,
-- dragonOrange→d_peach, dragonYellow→yellow, dragonGray/Gray2→dim,
-- dragonBlue2→blue, dragonViolet→lilac, dragonRed→d_red, dragonAqua→pale_teal,
-- dragonTeal→mint.
hi(0, "Comment",        { fg = faint, italic = true })
hi(0, "Constant",       { fg = d_peach })
hi(0, "String",         { fg = sage })
hi(0, "Character",      { fg = sage })
hi(0, "Number", { fg = fg })  -- numeric literals read as plain text
hi(0, "Float", { fg = fg })
hi(0, "Boolean",        { fg = fg })
hi(0, "Identifier",     { fg = yellow })
hi(0, "Function",       { fg = pale_pink })
hi(0, "Statement",      { fg = lilac })
hi(0, "Keyword",        { fg = lilac })
hi(0, "Conditional",    { fg = lilac })
hi(0, "Repeat",         { fg = lilac })
hi(0, "Label",          { fg = lilac })
hi(0, "Operator",       { fg = peach })
hi(0, "Exception",      { fg = peach })
hi(0, "PreProc",        { fg = peach })
hi(0, "Include",        { fg = peach })
hi(0, "Define",         { fg = peach })
hi(0, "Macro",          { fg = peach })
hi(0, "Type",           { fg = pale_teal })
hi(0, "StorageClass",   { fg = pale_teal })
hi(0, "Structure",      { fg = pale_teal })
hi(0, "Typedef",        { fg = pale_teal })
hi(0, "Special",        { fg = mint })
hi(0, "SpecialChar",    { fg = mint })
hi(0, "Tag",            { fg = mint })
hi(0, "Delimiter",      { fg = dim })
hi(0, "SpecialComment", { fg = mint })
hi(0, "Debug",          { fg = mint })
hi(0, "Underlined",     { fg = mint, underline = true })
hi(0, "Ignore",         { fg = faint })
hi(0, "Error",          { fg = d_red })
hi(0, "Todo",           { fg = dark, bg = sage, bold = true })

-- treesitter captures — kanagawa's mapping (unset ones fall through)
hi(0, "@variable",          { fg = fg })
hi(0, "@variable.builtin",  { fg = peach, italic = true })  -- self/this
hi(0, "@variable.parameter",{ fg = dim })
hi(0, "@variable.member",   { fg = fg })  -- instance attributes read as plain text
hi(0, "@parameter",         { fg = dim })
hi(0, "@field",             { fg = fg })
hi(0, "@property",          { fg = fg })
hi(0, "@constant.builtin",  { fg = d_peach })
hi(0, "@attribute",         { fg = d_peach })
hi(0, "@function.builtin",  { fg = pale_pink })
hi(0, "@string.regexp",     { fg = peach })
hi(0, "@string.escape",     { fg = peach, bold = true })
hi(0, "@string.special.symbol", { fg = yellow })
hi(0, "@string.documentation",  { fg = faint, italic = true })  -- docstrings read as comments
hi(0, "@string.special.url",    { fg = mint, underline = true })
hi(0, "@type",              { fg = pale_teal })
hi(0, "@type.builtin",      { fg = pale_teal })
hi(0, "@type.definition",   { fg = pale_teal })
hi(0, "@module",            { fg = pale_teal })  -- dragon leaves modules to Structure/Type
hi(0, "@module.builtin",    { fg = pale_teal })
hi(0, "@constructor",       { fg = mint })
hi(0, "@operator",          { fg = d_red })
hi(0, "@punctuation",       { fg = dim })

-- nested brackets (rainbow-delimiters): outermost level blue, then cycling
-- yellow → mint → rose → lilac → peach deeper in (no red in the cycle)
hi(0, "RainbowBlue",   { fg = blue })
hi(0, "RainbowYellow", { fg = yellow })
hi(0, "RainbowMint",   { fg = mint })
hi(0, "RainbowRose",   { fg = pale_pink })
hi(0, "RainbowLilac",  { fg = lilac })
hi(0, "RainbowPeach",  { fg = d_peach })

-- diff washes behind the lines, the text colour itself unchanged (no fg on
-- the Diff groups) — dragon's winter washes, a touch lighter: add green,
-- delete red, change blue-grey, text amber. gitsigns links its gutter marks
-- to these, so GitSigns* carry their own colours.
hi(0, "DiffAdd",    { bg = "#2e4034" })  -- dark mint wash (winterGreen)
hi(0, "DiffChange", { bg = "#2c3140" })  -- dark blue-grey wash (winterBlue)
hi(0, "DiffText",   { bg = "#4a4437" })  -- dark amber wash (winterYellow)
hi(0, "DiffDelete", { bg = "#402e31" })  -- dark red wash (winterRed)
hi(0, "GitSignsAdd",    { fg = d_mint })
hi(0, "GitSignsChange", { fg = d_yellow })
hi(0, "GitSignsDelete", { fg = d_red })

-- diagnostics (base colours; lua/config/highlights.lua restyles the
-- underline/virtual-text/sign shapes uniformly)
hi(0, "DiagnosticError", { fg = d_red })
hi(0, "DiagnosticWarn",  { fg = d_yellow })
hi(0, "DiagnosticInfo",  { fg = pale_pink })
hi(0, "DiagnosticHint",  { fg = mint })
hi(0, "DiagnosticOk",    { fg = d_mint })
