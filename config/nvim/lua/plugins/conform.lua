local nmap_leader = Config.nmap_leader
local conform = require("conform")
conform.setup({
	formatters_by_ft = {
		c = { "clang-format" },
		cpp = { "clang-format" },
		fish = { "fish_indent" },
		bash = { "shfmt" },
		javascript = { "prettier" },
		tailwind = { "rustywind" },
		typescript = { "prettier" },
		javascriptreact = { "prettier" },
		typescriptreact = { "prettier" },
		svelte = { "prettier" },
		css = { "prettier" },
		html = { "prettier" },
		json = { "prettier" },
		jsonc = { "prettier" },
		yaml = { "prettier" },
		markdown = { "prettier" },
		lua = { "stylua" },
		dart = { "dart_format" },
		python = { "ruff_format" },
		java = { "google_java_format" },
		nix = { "nixpkgs-fmt" },
		-- rust = { "dx_fmt", "rustfmt", lsp_format = "first" },
		kdl = { "kdlfmt" },
	},
	formatters = {
		biome = {
			command = "biome",
			args = { "check", "--write", "$FILENAME" },
			stdin = false,
		},
		oxlint = {
			command = "oxlint",
			args = { "--fix", "$FILENAME" },
			stdin = false,
		},
	},

	format_on_save = function(bufnr)
		if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat or vim.b[bufnr].bigfile then
			return
		end

		local filetype = vim.bo[bufnr].filetype
		local project_formatters
		if vim.tbl_contains({ "javascript", "javascriptreact", "typescript", "typescriptreact", "css", "json", "jsonc" }, filetype) then
			if vim.fs.root(bufnr, { "biome.json", "biome.jsonc" }) then
				project_formatters = { "biome" }
			elseif vim.fs.root(bufnr, { ".oxlintrc.json" }) then
				project_formatters = { "oxlint" }
			end
		end

		return { timeout_ms = 500, lsp_fallback = true, formatters = project_formatters }
	end,
})

vim.api.nvim_create_user_command("FormatDisable", function(args)
	if args.bang then
		vim.b.disable_autoformat = true
	else
		vim.g.disable_autoformat = true
	end
end, {
	desc = "Disable autoformat-on-save",
	bang = true,
})

Config.nvmap("<leader>Bf", function()
	require("conform").format({ async = true, lsp_fallback = true })
end, "[F]ormat")

vim.api.nvim_create_user_command("FormatEnable", function()
	vim.b.disable_autoformat = false
	vim.g.disable_autoformat = false
end, {
	desc = "[B]uffer [F]ormat",
})

nmap_leader("tf", function()
	if vim.b.disable_autoformat or vim.g.disable_autoformat then
		vim.cmd("FormatEnable")
	else
		vim.cmd("FormatDisable")
	end
end, "[T]oggle [F]ormat")
