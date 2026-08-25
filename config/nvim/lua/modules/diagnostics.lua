local function is_current_line(diag)
	return diag.lnum == vim.api.nvim_win_get_cursor(0)[1] - 1
end

function get_diagnostic_emoji(diagnostic)
	local s = vim.diagnostic.severity
	if diagnostic.severity == s.ERROR then
		return "🤤"
	end
	if diagnostic.severity == s.WARN then
		return "😔"
	end
	if diagnostic.severity == s.HINT then
		return "🥺"
	end
	return "😶‍🌫️"
end

vim.diagnostic.config({
	update_in_insert = false,
	underline = { severity = vim.diagnostic.severity.ERROR },
	signs = false,
	severity_sort = true,
	virtual_lines = {
		current_line = true,
		format = function(diagnostic)
			return get_diagnostic_emoji(diagnostic) .. " " .. diagnostic.message
		end,
	},
	virtual_text = {
		spacing = 2,
		prefix = function(diag)
			return is_current_line(diag) and "" or get_diagnostic_emoji(diag)
		end,
		format = function(diag)
			return is_current_line(diag) and "" or diag.message
		end,
	},
})
