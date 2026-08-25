autocmd = Config.autocmd
-- UI & Aesthetics
autocmd("TextYankPost", "ui_effects", function()
	vim.highlight.on_yank({ higroup = "IncSearch", timeout = 120 })
end, "*", "Highlight on yank")

autocmd("VimResized", "ui_effects", function()
	local current_tab = vim.api.nvim_get_current_tabpage()
	vim.cmd("tabdo wincmd =")
	vim.api.nvim_set_current_tabpage(current_tab)
end, "*", "Equalize split sizes")

-- Filetype Specific Behavior
autocmd("BufEnter", "clean_options", function()
	vim.opt.formatoptions:remove({ "c", "r", "o" })
end, "*", "Disable auto-commenting")

autocmd("TermOpen", "ui_effects", function()
	vim.opt_local.number = false
	vim.opt_local.relativenumber = false
end, "*", "Disable term numbers")

-- Buffer Management (Helix-like / NoFile)
autocmd("FileType", "buffer_rules", function()
	vim.keymap.set("n", "q", "<cmd>close!<CR>", { silent = true, buffer = true })
	vim.api.nvim_set_option_value("buflisted", false, { buf = 0 })
end, { "qf", "help", "man" }, "Close with q")

autocmd("BufEnter", "buffer_rules", function()
	if vim.bo.buftype == "nofile" then
		vim.keymap.set("n", "<Esc>", ":q<CR>", { buffer = true, silent = true })
	end
end, "*", "Esc quits nofile")

-- Plugin Compatibility
autocmd("FileType", "plugin_fixes", function()
	vim.b.miniindentscope_disable = true
end, { "dashboard", "mason", "notify", "trouble", "help" }, "Disable indent scope")

-- Development Workflow (Rust/Dioxus)  TODO: move to dioxus config
autocmd("BufWritePost", "rust_tools", function()
	if vim.fn.filereadable(vim.fn.getcwd() .. "/Dioxus.toml") == 1 then
		vim.cmd("silent !dx fmt --file %")
	end
end, "*.rs", "Dioxus auto-format")

-- Personal Workflow TODO move to personal config
autocmd("BufEnter", "todo_list", function()
	vim.defer_fn(function()
		vim.cmd("edit ~/syncthing/notes/todolist.md")
		vim.cmd("normal! G")
	end, 100)
end, "todolist.nvim", "Open todo file")

autocmd({ "TextChanged", "InsertLeave" }, "todo_list", function()
	if vim.api.nvim_buf_get_name(0):match("todolist.md") then
		vim.cmd("silent! write")
	end
end, "*", "Autosave todo list")
