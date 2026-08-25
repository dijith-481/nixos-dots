local nmap_leader = Config.nmap_leader
local autocmd = Config.autocmd
local build_hook = Config.build_hook
require("fff").setup({
	git = {
		status_text_color = true,
	},
})

local function build_fff(ev)
	local name, kind = ev.data.spec.name, ev.data.kind
	if name == "fff.nvim" and (kind == "install" or kind == "update") then
		if not ev.data.active then
			vim.cmd.packadd("fff.nvim")
		end
		require("fff.download").download_or_build_binary()
	end
end

nmap_leader("f", function()
	require("fff").find_files()
end, "Find files")
nmap_leader("/", function()
	require("fff").live_grep()
end, "Live grep")

autocmd("PackChanged", "after installing plugin", function()
	build_hook("fff", { "install", "update" }, build_fff)
end, "*", "build fff")
