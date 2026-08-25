vim.g.rustaceanvim = {

	tools = {},
	server = {
		status_notify_level = false,
		---@diagnostic disable-next-line: unused-local
		on_attach = function(client, bufnr) end,
		default_settings = {
			["rust-analyzer"] = {
				cargo = { features = "all", buildScripts = {
					enable = true,
				} },
			},
		},
	},
	dap = {},
}
