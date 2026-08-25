local nmap = Config.nmap
local autocmd = Config.autocmd
require("oil").setup({
	view_options = {
		show_hidden = true,

		---@diagnostic disable-next-line: unused-local
		is_always_hidden = function(name, bufnr)
			local m = name:match("^%..$")
			return m ~= nil
		end,
	},
	win_options = {
		signcolumn = "yes",
	},
	watch_for_changes = true,
	keymaps = {
		["<CR>"] = "actions.select",
		["<leader>v"] = { "actions.select", opts = { vertical = true } },
		["<leader>h"] = { "actions.select", opts = { horizontal = true } },
		["<C-q>"] = { "actions.select", opts = { tab = true } },
	},
})
nmap("-", function()
	require("oil").toggle_float()
end, "Oil toggle float")

autocmd("User", "oil", function(event)
	if event.data.actions.type == "move" then
		Snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
	end
end, "OilActionsPost", "rename files on oil")

require("oil-git-status").setup()
