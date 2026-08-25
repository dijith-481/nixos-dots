local nmap = Config.nmap

nmap("<C-;>", function()
	require("blink.chartoggle").toggle_char_eol(";")
end, "Toggle eol for ;")
nmap("<C-,>", function()
	require("blink.chartoggle").toggle_char_eol(",")
end, "Toggle eol for ,")
