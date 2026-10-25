vim.g.rustaceanvim = {

	tools = {},
	server = {
		status_notify_level = false,
		---@diagnostic disable-next-line: unused-local
		on_attach = function(client, bufnr) end,
		default_settings = {
			["rust-analyzer"] = {
				-- Use the workspace's default features. `all` can force very
				-- large dependency graphs and duplicate build-script work.
				cargo = { buildScripts = {
					enable = true,
				} },
			},
		},
	},
	dap = {},
}
