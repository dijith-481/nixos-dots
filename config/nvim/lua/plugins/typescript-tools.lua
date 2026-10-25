local nmap_leader = Config.nmap_leader
local ts_utils = require("typescript-tools.utils")

require("typescript-tools").setup({
	-- Choose per buffer so Deno packages inside a monorepo do not also start
	-- tsserver, regardless of the directory Neovim was launched from.
	root_dir = function(bufnr, on_dir)
		if vim.fs.root(bufnr, { "deno.json", "deno.jsonc", "deno.lock" }) then
			return
		end
		on_dir(ts_utils.get_root_dir(bufnr))
	end,
	settings = {
		expose_as_code_action = "all",
		complete_function_calls = true,
		tsserver_file_preferences = {
			importModuleSpecifierPreference = "non-relative",
			importModuleSpecifierEnding = "minimal",
		},
	},
})
