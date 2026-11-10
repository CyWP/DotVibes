-- Autocommands
-- Live-reload: a 1s ticker that pulls changes from disk into open buffers
-- (e.g. an agent writing to a file you're viewing). `checktime` re-reads only
-- files whose mtime moved, so the tick is effectively free. Force-reload with
-- unsaved edits kept? - `<leader>ur` (`:e!`) discards local edits instead.
local live_reload_timer = vim.uv.new_timer()
live_reload_timer:start(1000, 1000, vim.schedule_wrap(function()
  if vim.o.autoread then
    vim.api.nvim_cmd({ cmd = "checktime" }, {})
  end
end))

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking text",
  group = vim.api.nvim_create_augroup("yank-highlight", { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Copy yanks (not deletes/changes) to the system clipboard, for pasting into
-- other applications with Ctrl+Shift+V. Local: xsel/xclip/wl-copy; over SSH:
-- OSC 52 (see options.lua).
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Copy yanks to the system clipboard",
  callback = function()
    if vim.v.event.operator == "y" and vim.v.event.regname == "" then
      pcall(vim.fn.setreg, "+", vim.fn.getreg('"'), vim.fn.getregtype('"'))
    end
  end,
})
