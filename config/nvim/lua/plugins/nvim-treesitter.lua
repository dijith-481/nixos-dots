local autocmd = Config.autocmd

autocmd("PackChanged", "treesitter", function()
	vim.cmd("TSUpdate")
end, "*", "install tree sitter")

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

vim.api.nvim_create_autocmd("FileType", {
	callback = function()
		-- Enable treesitter highlighting and disable regex syntax
		pcall(vim.treesitter.start)
		-- Enable treesitter-based indentation
		vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
	end,
})
local ensureInstalled = {

	"ninja",
	-- "rst",
	"angular",
	"python",
	"json",
	"javascript",
	"typescript",
	"tsx",
	"latex",
	"regex",
	"yaml",
	"html",
	"astro",
	"css",
	"dart",
	"java",
	-- "prisma",
	"markdown",
	"markdown_inline",
	"kdl",
	"toml",
	-- "svelte",
	-- "graphql",
	"bash",
	"lua",
	"vim",
	"dockerfile",
	"gitignore",
	"query",
	"fish",
	"rust",
	"vimdoc",
	"c",
	"cpp",
	"hyprlang",
	"zig",
}
local alreadyInstalled = require("nvim-treesitter.config").get_installed()
local parsersToInstall = vim.iter(ensureInstalled)
	:filter(function(parser)
		return not vim.tbl_contains(alreadyInstalled, parser)
	end)
	:totable()
require("nvim-treesitter").install(parsersToInstall)

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
