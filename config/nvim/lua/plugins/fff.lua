local nmap_leader = Config.nmap_leader
local configured = false

local function fff()
	Config.packadd("fff.nvim")
	if not configured then
		require("fff").setup({
			git = {
				status_text_color = true,
			},
		})
		configured = true
	end
	return require("fff")
end

nmap_leader("f", function()
	fff().find_files()
end, "Find files")
nmap_leader("/", function()
	fff().live_grep()
end, "Live grep")
