require("blink.cmp").setup({
	fuzzy = {
		sorts = { "exact", "score", "sort_text" },
		implementation = "rust",
	},
	completion = {
		documentation = {
			window = {},
			auto_show = true,
			auto_show_delay_ms = 300,
		},
		ghost_text = { enabled = false },
		list = {
			selection = { preselect = true, auto_insert = true },
		},
		menu = {
			border = "rounded",
			auto_show = true,
			draw = {
				align_to = "none",
				-- Blink's built-in components avoid per-item Treesitter and
				-- custom Lua formatting on every completion refresh.
				columns = { { "kind_icon", "label", gap = 1 }, { "source_name" } },
			},
		},
	},
	signature = { enabled = true },
	keymap = {
		preset = "default",
		-- Free Tab/S-Tab for Supermaven: unmap the preset's snippet jump.
		["<Tab>"] = false,
		["<S-Tab>"] = false,
		["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
		["<C-l>"] = { "snippet_forward", "fallback" },
		["<C-h>"] = { "snippet_backward", "fallback" },
		["<C-d>"] = { "scroll_documentation_down", "fallback" },
		["<C-f>"] = { "scroll_documentation_up", "fallback" },
		["<C-g>"] = {
			function(cmp)
				cmp.show({ providers = { "snippets" } })
			end,
		},
	},
	appearance = { nerd_font_variant = "mono" },
	snippets = { preset = "luasnip" },
	sources = {
		-- Keep the hot path focused on local, built-in sources. Specialized
		-- providers are only queried in the filetypes where they are useful.
		default = { "lsp", "path", "snippets", "buffer" },
		per_filetype = {
			markdown = { inherit_defaults = true, "markdown", "emoji" },
			bash = { inherit_defaults = true, "env" },
			sh = { inherit_defaults = true, "env" },
			zsh = { inherit_defaults = true, "env" },
			gitcommit = { inherit_defaults = false, "conventional_commits", "buffer", "snippets" },
		},
		providers = {
			env = {
				name = "Env",
				module = "blink-cmp-env",
				opts = {
					item_kind = require("blink.cmp.types").CompletionItemKind.Variable,
					show_braces = false,
					show_documentation_window = true,
				},
			},
			lsp = {
				name = "lsp",
				module = "blink.cmp.sources.lsp",
				score_offset = 90,
			},
			path = {
				fallbacks = { "snippets", "buffer" },
				score_offset = 53,
				opts = {
					trailing_slash = false,
					label_trailing_slash = true,
					show_hidden_files_by_default = true,
				},
			},
			snippets = { score_offset = 50 },
			buffer = {
				score_offset = 12,
				min_keyword_length = 3,
				max_items = 3,
				opts = {
					-- Avoid rescanning every loaded buffer, which can include
					-- large files and buffers from unrelated repositories.
					get_bufnrs = function()
						return { vim.api.nvim_get_current_buf() }
					end,
				},
			},
			markdown = {
				name = "RenderMarkdown",
				module = "render-markdown.integ.blink",
				score_offset = 200,
				fallbacks = { "lsp" },
			},
			conventional_commits = {
				name = "Conventional Commits",
				module = "blink-cmp-conventional-commits",
			},
			emoji = {
				max_items = 16,
				module = "blink-emoji",
				name = "Emoji",
				score_offset = 34,
				opts = { insert = true, max_items = 5 },
			},
		},
	},
})
