local lint = require("lint")
local autocmd = Config.autocmd
local nmap_leader = Config.nmap_leader

local function get_lint()
	if vim.fs.root(0, { "biome.json", "biome.jsonc" }) then
		return {}
	end
	if vim.fs.root(0, { ".oxlintrc.json" }) then
		return { "oxlint" }
	end
	return { "eslint_d" }
end

lint.linters_by_ft = {
	angular = { "eslint_d" },
	javascript = get_lint(),
	-- css = { "stylelint" },
	bash = { "shellcheck" },
	fish = { "fish" },
	-- markdown = { "markdownlint" },
	typescript = get_lint(),
	python = { "ruff" },
	javascriptreact = get_lint(),
	typescriptreact = get_lint(),
	-- svelte = { "eslint_d" },
}

autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, "lint file", function()
	lint.try_lint()
end, "*", "lint file")

nmap_leader("ll", function()
	lint.try_lint()
end, "[L]int  current file")
