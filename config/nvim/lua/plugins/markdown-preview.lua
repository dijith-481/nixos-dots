local autocmd = Config.autocmd

autocmd({ "BufReadPost", "BufNewFile" }, "markdown", function()
	Config.packadd("markdown-preview.nvim")
	vim.g.mkdp_filetypes = { "markdown" }
	-- delay  to load the command
	vim.defer_fn(function()
		vim.cmd("MarkdownPreviewToggle")
	end, 100)
end, "*.md", "Markdown Preview")
