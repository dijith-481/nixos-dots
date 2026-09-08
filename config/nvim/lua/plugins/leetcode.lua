local autocmd = Config.autocmd

autocmd({ "BufReadPost", "BufNewFile" }, "leetcode", function()
	Config.packadd_all({ "nui.nvim", "plenary.nvim", "leetcode.nvim" })
	require("leetcode").setup({
		lang = "rust",
		storage = {
			home = "~/Dev/leetcode/2026/nvim",
			cache = vim.fn.stdpath("cache") .. "/leetcode",
		},
	})
end, "leetcode.nvim", "leetcode")
