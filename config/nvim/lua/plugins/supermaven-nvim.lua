local binary = require("supermaven-nvim.binary.binary_handler")
local util = require("supermaven-nvim.util")
local original_on_update = binary.on_update
local original_get_text = util.get_text
local buffer_text = {}
local max_buffer_bytes = 1024 * 1024

-- Supermaven checks its 10 MB limit only after copying the complete buffer.
-- Cache text by changedtick so cursor-only updates can reuse it and large
-- buffers are rejected before the plugin allocates a full copy.
util.get_text = function(bufnr)
	local cached = buffer_text[bufnr]
	if cached and vim.api.nvim_buf_is_valid(bufnr) and cached.tick == vim.api.nvim_buf_get_changedtick(bufnr) then
		return cached.text or ""
	end
	return original_get_text(bufnr)
end

local function block_buffer(bufnr, tick)
	buffer_text[bufnr] = { tick = tick, blocked = true }
	if not vim.b[bufnr].supermaven_large_buffer then
		require("supermaven-nvim.completion_preview").dispose_inlay()
		vim.b[bufnr].supermaven_large_buffer = true
	end
end

binary.on_update = function(self, bufnr, file_name, event_type)
	if not vim.api.nvim_buf_is_loaded(bufnr) then
		return
	end

	local tick = vim.api.nvim_buf_get_changedtick(bufnr)
	local cached = buffer_text[bufnr]
	if cached and cached.tick == tick then
		if cached.blocked or event_type ~= "cursor" then
			return
		end
		return original_on_update(self, bufnr, file_name, event_type)
	end

	if vim.b[bufnr].bigfile then
		block_buffer(bufnr, tick)
		return
	end

	local byte_count = vim.api.nvim_buf_call(bufnr, function()
		return vim.fn.line2byte(vim.fn.line("$") + 1)
	end)
	if byte_count > max_buffer_bytes then
		block_buffer(bufnr, tick)
		return
	end

	vim.b[bufnr].supermaven_large_buffer = false
	buffer_text[bufnr] = { tick = tick, text = original_get_text(bufnr) }
	return original_on_update(self, bufnr, file_name, event_type)
end

vim.api.nvim_create_autocmd("BufWipeout", {
	group = vim.api.nvim_create_augroup("supermaven_buffer_text_cache", { clear = true }),
	callback = function(event)
		buffer_text[event.buf] = nil
	end,
})

require("supermaven-nvim").setup({
	ignore_filetypes = { "bigfile" },
	keymaps = {
		accept_suggestion = "<C-Tab>",
		clear_suggestion = "<C-]>",
		accept_word = "<Tab>",
	},
})
