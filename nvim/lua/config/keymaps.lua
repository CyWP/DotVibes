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

-- PageUp/PageDown: skip a quarter of the window's height per press (half of
-- what <C-u>/<C-d> skip) instead of a full page. Uses cursor moves (j/k) with
-- a count that adapts to the window — with a large `scrolloff`, view-scroll
-- commands (<C-d>/<C-e>...) stutter against the margin, while cursor moves
-- stay smooth and keep the scrolloff context. Works from insert mode via
-- <C-o>, and extends/a shrinks the selection in visual mode.
do
	local ctrl_o = vim.api.nvim_replace_termcodes("<C-o>", true, false, true)
	-- `down` is a real boolean bearing in mind two traps when changing these
	-- v:lua calls: Lua treats ALL numbers (incl. 0) as truthy, and the v:lua
	-- call ARGS are parsed with vimscript syntax — plain `false` there raised
	-- E121, so they must be v:false / v:true (which arrive here as Lua bools).
	function _G.page_quarter(down, insert)
		local n = math.max(1, math.floor(vim.api.nvim_win_get_height(0) / 4))
		if insert then
			return ctrl_o .. n .. (down and "j" or "k")
		end
		return n .. (down and "j" or "k")
	end
end
map({ "n", "v" }, "<PageUp>", "v:lua.page_quarter(v:false)", { expr = true, desc = "Skip a quarter page up" })
map({ "n", "v" }, "<PageDown>", "v:lua.page_quarter(v:true)", { expr = true, desc = "Skip a quarter page down" })
map("i", "<PageUp>", "v:lua.page_quarter(v:false, v:true)", { expr = true, desc = "Skip a quarter page up" })
map("i", "<PageDown>", "v:lua.page_quarter(v:true, v:true)", { expr = true, desc = "Skip a quarter page down" })
