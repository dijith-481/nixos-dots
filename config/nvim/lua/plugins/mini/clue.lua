local miniclue = require("mini.clue")
miniclue.setup({
	window = {
		config = {},
		delay = 200,
	},
	triggers = {
		-- Leader triggers
		{ mode = "n", keys = "<Leader>" },
		{ mode = "x", keys = "<Leader>" },

		-- Built-in completion
		{ mode = "i", keys = "<C-x>" },

		-- `g` key
		{ mode = "n", keys = "g" },
		{ mode = "n", keys = "v" },
		{ mode = "n", keys = "," },
		{ mode = "x", keys = "g" },

		{ mode = "n", keys = "]" },
		{ mode = "x", keys = "]" },
		{ mode = "n", keys = "[" },
		{ mode = "x", keys = "[" },

		-- Marks
		{ mode = "n", keys = "'" },
		{ mode = "n", keys = "`" },
		{ mode = "x", keys = "'" },
		{ mode = "x", keys = "`" },

		-- Registers
		{ mode = "n", keys = '"' },
		{ mode = "x", keys = '"' },
		{ mode = "i", keys = "<C-r>" },
		{ mode = "c", keys = "<C-r>" },

		-- Window commands
		{ mode = "n", keys = "<C-w>" },

		-- `z` key
		{ mode = "n", keys = "z" },
		{ mode = "x", keys = "z" },
	},

	clues = {
		{ mode = "n", keys = "<leader>w", desc = "[W]indow" },
		{ mode = "n", keys = "<leader>h", desc = "[H]unk" },
		{ mode = "n", keys = "<leader>g", desc = "[G]it" },
		{ mode = "n", keys = "<leader>t", desc = "[T]oggle" },
		{ mode = "n", keys = ",g", desc = "Find Git" },

		miniclue.gen_clues.builtin_completion(),
		miniclue.gen_clues.g(),
		miniclue.gen_clues.marks(),
		miniclue.gen_clues.registers({ show_contents = true }),
		miniclue.gen_clues.windows(),
		miniclue.gen_clues.z(),
	},
})
