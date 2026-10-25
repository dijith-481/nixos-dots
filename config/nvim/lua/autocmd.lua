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
local dioxus_formatting = {}
autocmd("BufWritePost", "rust_tools", function(event)
	local root = vim.fs.root(event.buf, { "Dioxus.toml" })
	local path = vim.api.nvim_buf_get_name(event.buf)
	if not root or path == "" or dioxus_formatting[event.buf] then
		return
	end

	dioxus_formatting[event.buf] = true
	local changedtick = vim.api.nvim_buf_get_changedtick(event.buf)
	vim.system({ "dx", "fmt", "--file", path }, { cwd = root, text = true }, function(result)
		vim.schedule(function()
			dioxus_formatting[event.buf] = nil
			if result.code ~= 0 then
				local detail = vim.trim(result.stderr or result.stdout or "")
				vim.notify(("dx fmt failed (exit %d)%s"):format(result.code, detail ~= "" and (": " .. detail) or ""), vim.log.levels.ERROR)
				return
			end

			if
				vim.api.nvim_buf_is_valid(event.buf)
				and vim.api.nvim_buf_get_name(event.buf) == path
				and vim.api.nvim_buf_get_changedtick(event.buf) == changedtick
				and not vim.bo[event.buf].modified
			then
				vim.api.nvim_buf_call(event.buf, function()
					vim.cmd.checktime()
				end)
			end
		end)
	end)
end, "*.rs", "Dioxus auto-format (async)")

-- Personal Workflow TODO move to personal config
autocmd("BufEnter", "todo_list", function()
	vim.defer_fn(function()
		vim.cmd("edit ~/syncthing/notes/todolist.md")
		vim.cmd("normal! G")
	end, 100)
end, "todolist.nvim", "Open todo file")

autocmd({ "TextChanged", "InsertLeave" }, "todo_list", function()
	if vim.api.nvim_buf_get_name(0):match("todolist.md") or vim.api.nvim_buf_get_name(0):match("dsa.md") then
		vim.cmd("silent! write")
	end
end, "*", "Autosave todo list")
