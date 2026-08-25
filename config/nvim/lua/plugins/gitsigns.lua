require("gitsigns").setup({
	signcolumn = false,
	numhl = true,
	current_line_blame = true,
	current_line_blame_opts = {
		ignore_whitespace = true,
	},
	watch_gitdir = {
		follow_files = true,
	},

	on_attach = function(bufnr)
		local gitsigns = require("gitsigns")

		local function map(mode, l, r, opts)
			opts = opts or {}
			opts.buffer = bufnr
			vim.keymap.set(mode, l, r, opts)
		end

		map("n", "]h", function()
			gitsigns.nav_hunk("next")
		end, { desc = "[H]unk Next" })
		map("n", "[h", function()
			gitsigns.nav_hunk("prev")
		end, { desc = "[H]unk Prev" })
		map("n", "<leader>hs", gitsigns.stage_hunk, { desc = "[S]tage Hunk" })
		map("n", "<leader>hr", gitsigns.reset_hunk, { desc = "[R]eset Hunk" })
		map("v", "<leader>hs", function()
			gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }, { desc = "[S]tage Hunk" })
		end)
		map("v", "<leader>hr", function()
			gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }, { desc = "[R]eset Hunk" })
		end)

		map("n", "<leader>hS", gitsigns.stage_buffer, { desc = "[S]tage Buffer" })
		map("n", "<leader>hR", gitsigns.reset_buffer, { desc = "[R]eset Buffer" })
		map("n", "<leader>hp", gitsigns.preview_hunk, { desc = "[P]review Hunk" })
		map("n", "<leader>hi", gitsigns.preview_hunk_inline, { desc = "Preview [I]nline Hunk" })
		map("n", "<leader>hh", function()
			gitsigns.setqflist(0) -- 0 represents the current buffer/file
		end, { desc = "Hunks [H]ere (Current File)" })

		map("n", "<leader>hH", function()
			gitsigns.setqflist("all") -- "all" represents the whole repository
		end, { desc = "Hunks [H]all (Full Repo)" })

		map("n", "<leader>hb", function()
			gitsigns.blame_line({ full = true })
		end, { desc = "[B]lame Line" })

		map("n", "<leader>hd", gitsigns.diffthis, { desc = "[D]iff" })

		map("n", "<leader>hD", function()
			gitsigns.diffthis("~")
		end, { desc = "[D]iff ~" })

		map("n", "<leader>hQ", function()
			gitsigns.setqflist("all")
		end)
		map("n", "<leader>hq", gitsigns.setqflist)

		-- Toggles
		map("n", "<leader>tb", gitsigns.toggle_current_line_blame, { desc = "Line [B]lame" })
		map("n", "<leader>tw", gitsigns.toggle_word_diff, { desc = "[W]ord Diff" })
		map("n", "<leader>tl", gitsigns.toggle_linehl, { desc = "[L]ine Highlight" })

		-- Text object
		map({ "o", "x" }, "ih", gitsigns.select_hunk)
	end,
})
