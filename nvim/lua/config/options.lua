-- Global options
local opt = vim.opt

opt.number = true -- show line numbers
opt.relativenumber = true -- relative line numbers
opt.mouse = "a" -- enable mouse
opt.breakindent = true -- wrapped lines keep indentation
opt.undofile = true -- persistent undo between sessions
opt.autoread = true -- reload file-backed buffers whose file changed on disk (live ticker in autocmds.lua)
opt.ignorecase = true -- search case-insensitive...
opt.smartcase = true -- ...unless the search has capitals
opt.signcolumn = "yes" -- keep signcolumn visible to avoid shifts
opt.updatetime = 250 -- faster completion; also live-reload polling interval
opt.timeoutlen = 300 -- shorter key-combo timeout
opt.splitright = true -- split windows to the right
opt.splitbelow = true -- split windows below
opt.termguicolors = true -- 24-bit colors (modern colorschemes require this)

-- Indentation: 4 spaces instead of tabs
opt.expandtab = true -- use spaces instead of tab characters
opt.tabstop = 4 -- a <Tab> appears as 4 spaces wide
opt.shiftwidth = 4 -- >> / autoindent use 4 spaces per level
opt.softtabstop = 4 -- <Tab> / <BS> in insert mode edit by 4 spaces
opt.smartindent = true -- smart autoindent on new lines
opt.cursorline = true -- highlight cursor line
opt.scrolloff = 20 -- keep cursor ~20 lines from window edges (closer to center)
