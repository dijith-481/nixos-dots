require("blink.pairs").setup({
	mappings = {
		enabled = true,
		pairs = {},
		wrap = {
			["<C-b>"] = "treesitter",
			["<C-S-b>"] = "treesitter_reverse",
		},
	},
	highlights = {
		enabled = true,
		groups = {
			"Bars_glow_0",
			"Bars_glow_1",
			"Bars_glow_2",
			"Bars_glow_3",
			"Bars_glow_4",
		},
		matchparen = {
			enabled = true,
			group = "MatchParen",
		},
	},
})
