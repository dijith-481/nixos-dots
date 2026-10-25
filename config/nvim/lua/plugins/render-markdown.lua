local autocmd = Config.autocmd
autocmd("FileType", "markdown", function()
	Config.packadd("render-markdown.nvim")
	Config.packadd("blink-emoji.nvim")
	require("render-markdown").setup({
		completions = { blink = { enabled = true } },
	})
end, "markdown", "enable render-markdown")
