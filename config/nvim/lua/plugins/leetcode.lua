local build_hook = Config.build_hook
local autocmd = Config.autocmd

build_hook("leetcode", { "install", "update" }, function()
	vim.cmd(":TSUpdate html")
end)

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
	-- vim.api.nvim_create_autocmd({ "FileType" }, {
	group = vim.api.nvim_create_augroup("leetcode", { clear = true }),
	pattern = { "leetcode.nvim" },
	callback = function()
		require("leetcode").setup({
			lang = "rust",

			storage = {
				home = "~/Dev/leetcode/2025/nvim",
				cache = vim.fn.stdpath("cache") .. "/leetcode",
			},
		})
	end,
})

autocmd({ "BufReadPost", "BufNewFile" }, "leetcode", function()
	require("leetcode").setup({
		lang = "rust",
		storage = {
			home = "~/Dev/leetcode/2026/nvim",
			cache = vim.fn.stdpath("cache") .. "/leetcode",
		},
	})
end, "leetcode.nvim", "leetcode")
