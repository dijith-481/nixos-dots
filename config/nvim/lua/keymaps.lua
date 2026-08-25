local git = require("plugins.custom.git_jump")
local nmap = Config.nmap
local nvmap = Config.nvmap
local xmap = Config.xmap
local imap = Config.imap
local vmap = Config.vmap
local nmap_leader = Config.nmap_leader
local xmap_leader = Config.xmap_leader
local omap_leader = Config.omap_leader
local unmap = vim.keymap.del

-- General
nmap("<Esc>", "<cmd>nohlsearch<CR>", "Clear search highlight")
nmap("<C-s>", "<C-a>", "Increment number") -- <C-a> is used by zellij

-- Diagnostics
nmap_leader("q", vim.diagnostic.setloclist, "Open Quickfix list")
nmap_leader("k", function()
	vim.diagnostic.open_float()
end, "Diagnostic float")

-- Navigation (Focus)
nmap("<C-h>", "<C-w><C-h>", "Move focus left")
nmap("<C-l>", "<C-w><C-l>", "Move focus right")
nmap("<C-j>", "<C-w><C-j>", "Move focus down")
nmap("<C-k>", "<C-w><C-k>", "Move focus up")

-- Tabs
nmap("<C-q>", "<cmd>tabnew<CR>", "New Tab")
nmap("<C-w>", "<cmd>tabclose<CR>", "Close Tab")
nmap("<C-S-q>", "<cmd>tabnew %<CR>", "Current buffer to new tab")

-- System Clipboard (Helix Style)
nvmap("<leader>y", '"+y', "Copy to system clipboard")
nvmap("<leader>p", '"+p', "Paste from system clipboard")
nvmap("<leader>P", '"+P', "Paste before from system clipboard")

-- Helix Window Management (Leader w prefix)
nmap_leader("ww", "<C-w>w", "Next window")
nmap_leader("ws", "<C-w>s", "Horizontal split")
nmap_leader("wv", "<C-w>v", "Vertical split")
nmap_leader("wt", "<C-w>r", "Transpose (Rotate) splits")
nmap_leader("wq", "<C-w>q", "Close window")
nmap_leader("wo", "<C-w>o", "Close other windows")
nmap_leader("wn", "<cmd>new<CR>", "New scratch split")

-- Window Jumps
nmap_leader("wh", "<C-w>h", "Jump to left split")
nmap_leader("wj", "<C-w>j", "Jump to split below")
nmap_leader("wk", "<C-w>k", "Jump to split above")
nmap_leader("wl", "<C-w>l", "Jump to right split")

-- Window Swaps
nmap_leader("wH", "<C-w>H", "Swap with left split")
nmap_leader("wJ", "<C-w>J", "Swap with split below")
nmap_leader("wK", "<C-w>K", "Swap with split above")
nmap_leader("wL", "<C-w>L", "Swap with right split")

-- Insert Mode
imap("jk", "<Esc>", "Exit insert mode")
imap("kj", "<Esc>", "Exit insert mode")
imap("<C-h>", "<Left>", "Move left")
imap("<C-j>", "<Down>", "Move down")
imap("<C-k>", "<Up>", "Move up")
imap("<C-l>", "<Right>", "Move right")

-- Git Navigation
nmap("]g", function()
	git.jump("next")
end, "Next modified git file")
nmap("[g", function()
	git.jump("prev")
end, "Prev modified git file")

-- Selection / Indentation
vmap("<", "<gv", "Indent left and keep selection")
vmap(">", ">gv", "Indent right and keep selection")
xmap("/", [[<Esc>/\%V]], "Search within selection")

-- Smart Folds (Assumes your nmap wrapper handles expr = true internally)
nmap("h", function()
	return vim.fn.col(".") ~= 1 and "h" or vim.fn.foldlevel(vim.fn.line(".")) == 0 and "h" or "zc"
end, "Smart fold/left", { expr = true, noremap = true })

nmap("l", function()
	return vim.fn.foldclosed(".") > -1 and "zo" or "l"
end, "Smart unfold/right", { expr = true, noremap = true })

-- LSP & Paste Logic
nmap("gt", vim.lsp.buf.type_definition, "[T]ype Definition")
nmap_leader("ti", function()
	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, "[T]oggle [I]nlay Hint")

nmap("[p", '<Cmd>exe "iput! " . v:register<CR>', "Paste Above")
nmap("]p", '<Cmd>exe "iput "  . v:register<CR>', "Paste Below")

-- Unmaps
unmap("n", "gra")
unmap("n", "gri")
unmap("n", "grn")
unmap("n", "grr")
unmap("n", "grt")
unmap("n", "grx")

nmap_leader("C", "gc", "Comment Operator", { remap = true })
nmap_leader("c", "gcc", "Comment Line", { remap = true })
xmap_leader("c", "gc", "Comment Selection", { remap = true })
xmap_leader("c", "gc", "Comment object", { remap = true })

local edit_plugin_file = function(filename)
	return string.format("<Cmd>edit %s/plugin/%s<CR>", vim.fn.stdpath("config"), filename)
end
nmap_leader("ei", "<Cmd>edit $MYVIMRC<CR>", "init.lua")
nmap_leader("ek", edit_plugin_file("keymaps.lua"), "Keymaps config")
nmap_leader("eo", edit_plugin_file("options.lua"), "Options config")
nmap_leader("ep", edit_plugin_file("plugins.lua"), "Plugins config")
