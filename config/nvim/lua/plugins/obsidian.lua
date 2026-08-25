require("obsidian").setup({
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

Config.autocmd({ "BufReadPost", "BufNewFile" }, "obsidian", function()
	require("obsidian").setup({
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
	vim.cmd("ObsidianToday")
	-- end, 100)
end, "mdToday", "obsidian")
