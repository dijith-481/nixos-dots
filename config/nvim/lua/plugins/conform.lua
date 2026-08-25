local nmap_leader = Config.nmap_leader
local conform = require("conform")
local function get_formatter(fallback)
	if vim.fs.root(0, { "biome.json", "biome.jsonc" }) then
		return { "biome" }
	end
	if vim.fs.root(0, { ".oxlintrc.json" }) then
		return { "oxlint" }
	end
	return fallback or { "prettier" }
end

conform.setup({
	formatters_by_ft = {
		c = { "clang-format" },
		cpp = { "clang-format" },
		fish = { "fish_indent" },
		bash = { "shfmt" },
		javascript = get_formatter(),
		tailwind = get_formatter({ "rustywind" }),
		typescript = get_formatter(),
		javascriptreact = get_formatter(),
		typescriptreact = get_formatter(),
		svelte = { "prettier" },
		css = get_formatter(),
		html = { "prettier" },
		json = get_formatter(),
		jsonc = get_formatter(),
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
		if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
			return
		end
		return { timeout_ms = 500, lsp_fallback = true }
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
