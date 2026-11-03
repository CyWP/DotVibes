-- Bootstrap lazy.nvim
-- See `:h lazy.nvim.txt` or https://github.com/folke/lazy.nvim

-- Clone lazy.nvim if it isn't installed yet
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    error("Error cloning lazy.nvim:\n" .. out)
  end
end

-- Prepend lazy.nvim to the runtime path so `require("lazy")` works
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  install = { colorscheme = { "tokyonight-night", "habamax" } }, -- shown while plugins install
  checker = { enabled = true, notify = false }, -- check for plugin updates
})
