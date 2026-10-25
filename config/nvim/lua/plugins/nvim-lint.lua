local lint = require("lint")
local autocmd = Config.autocmd
local nmap_leader = Config.nmap_leader

local linters_by_ft = {
	angular = { "eslint_d" },
	javascript = true,
	javascriptreact = true,
	typescript = true,
	typescriptreact = true,
	bash = { "shellcheck" },
	fish = { "fish" },
	python = { "ruff" },
}

local function get_linters(bufnr)
	if vim.b[bufnr].bigfile then
		return {}
	end

	local configured = linters_by_ft[vim.bo[bufnr].filetype]
	if configured == true then
		if vim.fs.root(bufnr, { "biome.json", "biome.jsonc" }) then
			return {}
		end
		if vim.fs.root(bufnr, { ".oxlintrc.json" }) then
			return { "oxlint" }
		end
		return { "eslint_d" }
	end
	return configured or {}
end

local function lint_buffer(bufnr)
	local linters = get_linters(bufnr)
	if #linters > 0 then
		lint.try_lint(linters)
	end
end

-- Lint after edits or writes, not on every buffer switch. Resolve the linter
-- from this buffer's repository so switching projects cannot retain a choice
-- made from the Neovim launch directory.
autocmd({ "BufWritePost", "InsertLeave" }, "lint_file", function(args)
	lint_buffer(args.buf)
end, "*", "lint file")

nmap_leader("ll", function()
	lint_buffer(vim.api.nvim_get_current_buf())
end, "[L]int  current file")
