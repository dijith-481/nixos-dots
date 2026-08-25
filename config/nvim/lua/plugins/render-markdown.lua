local autocmd = Config.autocmd
autocmd("FileType", "markdown", function()
	require("render-markdown").setup({
		completions = { blink = { enabled = true } },
	})
end, "*.md", "enable render-markdown")
