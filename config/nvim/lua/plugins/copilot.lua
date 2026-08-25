-- vim.api.nvim_cConfig.autocmd("User", "BlinkCmpMenuOpen", function()
-- 	vim.b.copilot_suggestion_hidden = true
-- end, "*", "Hide Copilot suggestions when the Blink completion menu is open")
-- Config.autocmd("User", "CopilotSuggestionHidden", function()
-- 	vim.b.copilot_suggestion_hidden = true
-- end, "*", "Hide Copilot suggestions when the Blink completion menu is open")

Config.autocmd("InsertEnter", "CopilotLazyLoad", function()
	require("copilot").setup({
		suggestion = { enabled = true },
	})
end, "*", "Lazy load and setup Copilot on entering Insert mode")
