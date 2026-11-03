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
