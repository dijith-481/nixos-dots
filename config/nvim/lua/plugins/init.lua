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

local function once_for_code_buffer(event, group, callback, opts)
	opts = opts or {}
	local group_id = vim.api.nvim_create_augroup(group, { clear = true })
	opts.group = group_id
	opts.callback = function(args)
		if vim.b[args.buf].bigfile then
			return
		end
		vim.api.nvim_del_augroup_by_id(group_id)
		callback(args)
	end
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

once_for_code_buffer({ "BufReadPre", "BufNewFile" }, "lazy_gitsigns", function()
	load_config("gitsigns.nvim", "plugins.gitsigns")
end)

once_for_code_buffer({ "BufReadPost", "BufNewFile" }, "lazy_editor_services", function()
	load_config("conform.nvim", "plugins.conform")
	load_config("nvim-lint", "plugins.nvim-lint")
end)

local treesitter_group = vim.api.nvim_create_augroup("lazy_treesitter", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
	group = treesitter_group,
	callback = function(event)
		if vim.b[event.buf].bigfile then
			return
		end
		vim.api.nvim_del_augroup_by_id(treesitter_group)
		packadd_all({
			"nvim-treesitter",
			"nvim-ts-autotag",
			"nvim-treesitter-context",
			"nvim-ts-context-commentstring",
		})
		require("plugins.nvim-treesitter")
		require("plugins.nvim-ts-context-commentstring")
	end,
})

local function is_large_file(bufnr)
	if vim.b[bufnr].bigfile then
		return true
	end
	local path = vim.api.nvim_buf_get_name(bufnr)
	return path ~= "" and vim.fn.getfsize(path) > 1.5 * 1024 * 1024
end

-- Optional completion sources only need to be present for their matching
-- filetypes, so Rust/TypeScript InsertEnter does not activate them.
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("lazy_blink_sources", { clear = true }),
	pattern = { "bash", "sh", "zsh", "gitcommit" },
	callback = function(event)
		if event.match == "gitcommit" then
			packadd("blink-cmp-conventional-commits")
		else
			packadd("blink-cmp-env")
		end
	end,
})


local completion_loaded = false
local function setup_completion()
	if completion_loaded or vim.b.bigfile then
		return
	end
	completion_loaded = true
	packadd_all({
		"luasnip",
		"friendly-snippets",
		"blink.cmp",
		"blink.pairs",
		"blink.indent",
		"blink.chartoggle",
	})
	require("plugins.luasnip")
	require("plugins.blink")
end

-- Initialize Blink shortly after the first frame so the first typed character
-- does not pay for LuaSnip, its mappings, and the completion renderer.
vim.api.nvim_create_autocmd("InsertEnter", {
	group = vim.api.nvim_create_augroup("lazy_completion", { clear = true }),
	callback = setup_completion,
})

-- Language-specific integrations are loaded before FileType, so their own
-- FileType hooks can attach to the buffer currently being opened.
vim.api.nvim_create_autocmd("BufReadPre", {
	group = vim.api.nvim_create_augroup("lazy_typescript_tools", { clear = true }),
	pattern = { "*.js", "*.jsx", "*.mjs", "*.cjs", "*.ts", "*.tsx", "*.mts", "*.cts" },
	callback = function(event)
		if is_large_file(event.buf) then
			return
		end
		-- typescript-tools' ftplugin requires plenary.async as soon as a
		-- TypeScript buffer's filetype is set, so plenary must already be on
		-- the runtimepath before load_config activates the plugin.
		packadd("plenary.nvim")
		load_config("typescript-tools.nvim", "plugins.typescript-tools")
	end,
})

once_for_code_buffer("BufReadPre", "lazy_flutter_tools", function()
	packadd("plenary.nvim")
	load_config("flutter-tools.nvim", "plugins.flutter-tools")
end, { pattern = "*.dart" })

once_for_code_buffer("BufReadPre", "lazy_roslyn", function()
	load_config("roslyn.nvim", "plugins.roslyn")
end, { pattern = "*.cs" })

once_for_code_buffer("BufReadPre", "lazy_rustaceanvim", function()
	packadd("rustaceanvim")
end, { pattern = "*.rs" })

local ui_ready = false
local supermaven_loaded = false
local function load_supermaven_for_buffer(bufnr)
	if supermaven_loaded or vim.b[bufnr].bigfile then
		return
	end
	supermaven_loaded = true
	vim.schedule(function()
		load_config("supermaven-nvim", "plugins.supermaven-nvim")
	end)
end

vim.api.nvim_create_autocmd("BufEnter", {
	group = vim.api.nvim_create_augroup("lazy_supermaven", { clear = true }),
	callback = function(event)
		if ui_ready then
			load_supermaven_for_buffer(event.buf)
		end
	end,
})

-- Snacks supplies commands and keymaps used across the config. Set it up once
-- the first UI frame exists, keeping startup responsive without changing keys.
once("UIEnter", "deferred_ui_plugins", function()
	ui_ready = true
	vim.schedule(function()
		load_config("snacks.nvim", "plugins.snacks")
		load_supermaven_for_buffer(vim.api.nvim_get_current_buf())
		vim.defer_fn(setup_completion, 100)
	end)
end)
