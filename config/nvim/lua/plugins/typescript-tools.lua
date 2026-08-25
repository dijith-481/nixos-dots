local nmap_leader = Config.nmap_leader
local function has_deno_json()
	local deno_json_path = vim.fn.findfile("deno.json", vim.fn.getcwd() .. ";")

	return deno_json_path ~= ""
end

if not has_deno_json() then
	require("typescript-tools").setup({
		expose_as_code_action = "all",
		settings = {
			tsserver_file_preferences = {
				importModuleSpecifierPreference = "non-relative",
				importModuleSpecifierEnding = "minimal",
			},
		},
		complete_function_calls = true,
	})
end
