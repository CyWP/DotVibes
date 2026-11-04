-- Keymaps
local map = vim.keymap.set

-- Survive accidental modifier-mode: exit terminal mode
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Better window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Handle search highlighting
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Hide search highlighting" })

-- PageUp/PageDown scroll half a page (like <C-u>/<C-d>) instead of a full page
map({ "n", "v" }, "<PageUp>", "<C-u>", { desc = "Scroll half page up" })
map({ "n", "v" }, "<PageDown>", "<C-d>", { desc = "Scroll half page down" })
map("i", "<PageUp>", "<C-o><C-u>", { desc = "Scroll half page up" })
map("i", "<PageDown>", "<C-o><C-d>", { desc = "Scroll half page down" })
