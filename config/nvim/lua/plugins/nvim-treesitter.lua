local treesitter = require("nvim-treesitter")

treesitter.setup({})
vim.filetype.add({
	extension = { rasi = "rasi" },
	pattern = {
		[".*/waybar/config.*"] = "jsonc",
		-- ['.*/mako/config'] = 'dosini',
		-- [".*/kitty/*.conf"] = "bash",
		[".*/hypr/.*%.conf"] = "hyprlang",
	},
})
require("nvim-ts-autotag").setup({
	opts = {
		enable_close = true,
		enable_rename = true,
		enable_close_on_slash = false,
	},
	per_filetype = {
		["html"] = {
			-- enable_close = false,
		},
	},
})

require("treesitter-context").setup({
	enable = true,
	multiwindow = false,
	max_lines = 4,
	min_window_height = 8,
	line_numbers = true,
	multiline_threshold = 20,
	trim_scope = "outer",
	mode = "cursor",
	separator = nil,
})
-- end)

local function enable_for_buffer(bufnr)
	if vim.bo[bufnr].buftype ~= "" then
		return
	end
	if not vim.treesitter.get_parser(bufnr, nil, { error = false }) then
		return
	end

	-- Parsers and queries are immutable Nix dependencies, so this only starts
	-- highlighting; it never invokes a compiler or writes into stdpath("data").
	vim.treesitter.start(bufnr)
	vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
	vim.wo.foldmethod = "expr"
	vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
end

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("treesitter_buffers", { clear = true }),
	callback = function(event)
		enable_for_buffer(event.buf)
	end,
})

-- This module itself is loaded by the first FileType event, so initialize the
-- buffer whose event caused the lazy load as well.
enable_for_buffer(vim.api.nvim_get_current_buf())

vim.keymap.set({ "n", "x", "o" }, "<C-space>", function()
	if vim.treesitter.get_parser(nil, nil, { error = false }) then
		require("vim.treesitter._select").select_parent(vim.v.count1)
	else
		vim.lsp.buf.selection_range(vim.v.count1)
	end
end, { desc = "Select parent treesitter node or outer incremental lsp selections" })

vim.keymap.set({ "n", "x", "o" }, "<C-BS>", function()
	if vim.treesitter.get_parser(nil, nil, { error = false }) then
		require("vim.treesitter._select").select_child(vim.v.count1)
	else
		vim.lsp.buf.selection_range(-vim.v.count1)
	end
end, { desc = "Select child treesitter node or inner incremental lsp selections" })
