local opt = vim.opt
local g = vim.g
-- Experimental Features
require("vim._core.ui2").enable({}) -- New UI architecture

-- Enable loader for performance
if vim.loader then
	vim.loader.enable()
end

-- Global / Provider Settings
g.have_nerd_font = true -- Icons support
g.mapleader = " " -- Space as leader
g.maplocalleader = " " -- Local leader space

-- UI
opt.number = true -- Show line numbers
-- opt.colorcolumn = "+1" -- Draw column on the right of maximum width
opt.linebreak = true -- Wrap lines at 'breakat' (if 'wrap' is set)
-- opt.relativenumber = false -- Relative line jumps
opt.cursorline = true -- Highlight current line
opt.termguicolors = true -- True color support
opt.laststatus = 3 -- Global statusline
opt.signcolumn = "yes" -- Constant sign column
opt.list = true -- Show helpful text indicators
opt.pumborder = "single" -- Use border in popup menu
opt.pumheight = 10 -- Make popup menu smaller
opt.pummaxwidth = 100 -- Make popup menu not too wide
opt.ruler = false -- Don't show cursor coordinates
opt.shortmess = "CFOSWaco" -- Disable some built-in completion messages
opt.showmode = false -- Don't show mode in command line
opt.splitkeep = "screen" -- Reduce scroll during window split
opt.winborder = "single" -- Use border in floating windows

-- Search Behavior
opt.hlsearch = true -- Highlight search results
opt.incsearch = true -- Show search matches
opt.ignorecase = true -- Case insensitive search
opt.smartcase = true -- Smart case search
opt.inccommand = "split" -- Live substitution preview
opt.cursorlineopt = "screenline,number"

-- Indentation & Formatting
opt.expandtab = true -- Convert tabs to spaces
opt.formatoptions = "rqnl1j" -- Improve comment editing
opt.virtualedit = "block" -- Allow going past end of line in blockwise mode
opt.iskeyword = "@,48-57,_,192-255,-" -- Treat dash as `word` textobject part

-- Pattern for a start of numbered list (used in `gw`). This reads as
-- "Start of list item is: at least one special character (digit, -, +, *)
-- possibly followed by punctuation (. or `)`) followed by at least one space".
opt.formatlistpat = [[^\s*[0-9\-\+\*]\+[\.\)]*\s\+]]
opt.shiftwidth = 2 -- Indent size (2)
opt.tabstop = 2 -- Tab size (2)
opt.smartindent = true -- Auto-indent logic
opt.breakindent = true -- Wrapped line indent
opt.copyindent = true -- Maintain indent style
opt.spelloptions = "camel" -- Treat camelCase word parts as separate words

-- Performance & System
opt.updatetime = 250 -- Faster UI updates
opt.timeoutlen = 300 -- Keybind timeout delay
opt.undofile = true -- Persistent undo history
opt.swapfile = false -- Disable swap files
opt.shada = "'100,<50,s10,:1000,/100,@100,h" -- Optimized history storage

-- Navigation & Splits
opt.scrolloff = 7 -- Context lines visible
opt.smoothscroll = true -- Pixel-level scrolling
opt.splitbelow = true -- New split bottom
opt.splitright = true -- New split right
opt.mouse = "a" -- Enable mouse support

-- Code Folding
opt.foldcolumn = "1" -- Fold indicator column
opt.foldlevel = 99 -- Default unfolded view
opt.foldlevelstart = 99 -- Start fully unfolded
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldtext = "v:lua.custom_foldtext()"
opt.foldopen:remove({ "search" })
opt.fillchars = {
	fold = " ",
	foldopen = "",
	foldsep = " ",
	foldclose = "",
}

-- Enable all filetype plugins and syntax (if not enabled, for better startup)
vim.cmd("filetype plugin indent on")
if vim.fn.exists("syntax_on") ~= 1 then
	vim.cmd("syntax enable")
end

opt.conceallevel = 2
