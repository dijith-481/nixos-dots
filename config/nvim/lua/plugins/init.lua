local packadd = Config.packadd
local packadd_all = Config.packadd_all

local function load_config(plugin, module)
	if packadd(plugin) then
		local ok, err = pcall(require, module)
		if not ok then
			vim.schedule(function()
				vim.notify(("Failed to configure %s: %s"):format(plugin, err), vim.log.levels.ERROR)
			end)
		end
	end
end

local function once(event, group, callback, opts)
	opts = opts or {}
	opts.group = vim.api.nvim_create_augroup(group, { clear = true })
	opts.once = true
	opts.callback = callback
	vim.api.nvim_create_autocmd(event, opts)
end

-- Core UI is ready during the first frame. Everything here affects the
-- initial layout, so deferring it would cause visible flicker.
load_config("nordic.nvim", "plugins.nordic")
load_config("mini.nvim", "plugins.mini")
load_config("statuscol.nvim", "plugins.statuscol")

-- Register native LSP definitions before lsp.lua enables servers. Lazydev and
-- fidget are small and need to observe the first Lua/LSP events.
packadd("nvim-lspconfig")
packadd("blink.cmp")
load_config("lazydev.nvim", "plugins.lazydev")
load_config("fidget.nvim", "plugins.fidget")

-- Commands provided directly by plugin/ scripts stay available without
-- loading their larger Lua modules.
packadd_all({ "dressing.nvim", "nui.nvim", "codediff.nvim" })

-- These files only register lightweight event/key stubs. Their actual plugins
-- remain outside runtimepath until the feature is used.
require("plugins.fff")
require("plugins.oil")
require("plugins.markdown-preview")
require("plugins.render-markdown")
require("plugins.obsidian")
require("plugins.leetcode")
require("plugins.rustaceanvim")

once({ "BufReadPre", "BufNewFile" }, "lazy_gitsigns", function()
	load_config("gitsigns.nvim", "plugins.gitsigns")
end)

once({ "BufReadPost", "BufNewFile" }, "lazy_editor_services", function()
	load_config("conform.nvim", "plugins.conform")
	load_config("nvim-lint", "plugins.nvim-lint")
end)

once("FileType", "lazy_treesitter", function()
	packadd_all({
		"nvim-treesitter",
		"nvim-ts-autotag",
		"nvim-treesitter-context",
		"nvim-ts-context-commentstring",
	})
	require("plugins.nvim-treesitter")
	require("plugins.nvim-ts-context-commentstring")
end)

-- Completion and pairs are initialized together on the first insert. Their
-- Rust libraries are already present in the Nix store, so this does no I/O or
-- compilation. All existing insert-mode mappings are defined by blink setup.
once("InsertEnter", "lazy_completion", function()
	packadd_all({
		"luasnip",
		"friendly-snippets",
		"colorful-menu.nvim",
		"render-markdown.nvim",
		"fff.nvim",
		"blink-cmp-env",
		"blink-emoji.nvim",
		"blink-nerdfont.nvim",
		"blink-cmp-conventional-commits",
		"blink.cmp",
		"blink.pairs",
		"blink.indent",
		"blink.chartoggle",
	})
	require("plugins.luasnip")
	require("plugins.blink")
end)

-- Language-specific integrations are loaded before FileType, so their own
-- FileType hooks can attach to the buffer currently being opened.
once("BufReadPre", "lazy_typescript_tools", function()
	load_config("typescript-tools.nvim", "plugins.typescript-tools")
end, { pattern = { "*.js", "*.jsx", "*.mjs", "*.cjs", "*.ts", "*.tsx", "*.mts", "*.cts" } })

once("BufReadPre", "lazy_flutter_tools", function()
	load_config("flutter-tools.nvim", "plugins.flutter-tools")
end, { pattern = "*.dart" })

once("BufReadPre", "lazy_roslyn", function()
	load_config("roslyn.nvim", "plugins.roslyn")
end, { pattern = "*.cs" })

once("BufReadPre", "lazy_rustaceanvim", function()
	packadd("rustaceanvim")
end, { pattern = "*.rs" })

-- Snacks supplies commands and keymaps used across the config. Set it up once
-- the first UI frame exists, keeping startup responsive without changing keys.
once("UIEnter", "deferred_ui_plugins", function()
	vim.schedule(function()
		load_config("snacks.nvim", "plugins.snacks")
		load_config("supermaven-nvim", "plugins.supermaven-nvim")
	end)
end)
