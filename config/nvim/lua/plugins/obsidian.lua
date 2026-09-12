Config.autocmd({ "BufReadPost", "BufNewFile" }, "obsidian", function()
	Config.packadd("obsidian.nvim")
	require("obsidian").setup({
		legacy_commands = false,
		ui = { enable = false },
		workspaces = {
			{
				name = "personal",
				path = "~/syncthing/notes",
			},
		},
		daily_notes = {
			folder = "daily",
			date_format = "%Y-%m-%d",
		},
	})
	vim.opt.conceallevel = 2
	-- vim.defer_fn(function()
	vim.cmd("Obsidian today")
	-- end, 100)
end, "mdToday", "obsidian")
