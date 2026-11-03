-- Leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Core configuration
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- Plugin manager
require("config.lazy")
