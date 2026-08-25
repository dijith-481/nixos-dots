local scooter_term = nil

-- Called by scooter to open the selected file at the correct line from the scooter search list
_G.EditLineFromScooter = function(file_path, line)
	if scooter_term and scooter_term:buf_valid() then
		scooter_term:hide()
	end

	local current_path = vim.fn.expand("%:p")
	local target_path = vim.fn.fnamemodify(file_path, ":p")

	if current_path ~= target_path then
		vim.cmd.edit(vim.fn.fnameescape(file_path))
	end

	vim.api.nvim_win_set_cursor(0, { line, 0 })
end

local function is_terminal_running(term)
	if not term or not term:buf_valid() then
		return false
	end
	local channel = vim.fn.getbufvar(term.buf, "terminal_job_id")
	return channel and vim.fn.jobwait({ channel }, 0)[1] == -1
end

local function open_scooter()
	if scooter_term and scooter_term.toggle and is_terminal_running(scooter_term) then
		scooter_term:toggle()
	else
		scooter_term = require("snacks").terminal.open("scooter", {
			win = { position = "float" },
		})
	end
end

local function open_scooter_with_text(search_text)
	if scooter_term and scooter_term:buf_valid() then
		scooter_term:close()
	end

	local escaped_text = vim.fn.shellescape(search_text:gsub("\r?\n", " "))
	scooter_term = require("snacks").terminal.open("scooter --fixed-strings --search-text " .. escaped_text, {
		win = { position = "float" },
	})
end

require("snacks").setup({

	animate = {},
	bigfile = {},
	dim = {},
	gitbrowse = {},
	input = {},
	picker = {
		sources = {
			files = {
				hidden = true,
				ignored = true,
			},
		},
		win = {
			input = {
				keys = {
					["<c-q>"] = { "qflist", mode = { "i", "n" } },
				},
			},
			list = {
				keys = {
					["<c-q>"] = "qflist",
				},
			},
		},
	},
	zen = {},
	scratch = {},
	lazygit = {},
	notifier = {},
	quickfile = {},
	scope = {},
	--BUG janky scroll in jk
	-- scroll = {},
	-- statuscolumn = {},
	words = {},
})

vim.keymap.set(
	"n",
	",cc",
	"<cmd> lua Snacks.picker.pick({source='files',cwd=vim.fn.stdpath('config'),...})<CR>",
	{ desc = "Find Nvim [C]onfig " }
)
vim.keymap.set(
	"n",
	",cn",
	"<cmd> lua Snacks.picker.pick({source='files',cwd=vim.fn.expand('$HOME/.config/niri'),...})<CR>",
	{ desc = "Find Niri Config " }
)

vim.keymap.set("n", "<leader>R", open_scooter, { desc = "Open scooter" })
vim.keymap.set("v", "<leader>r", function()
	local selection = vim.fn.getreg('"')
	vim.cmd('normal! "ay')
	open_scooter_with_text(vim.fn.getreg("a"))
	vim.fn.setreg('"', selection)
end, { desc = "Search selected text in scooter" })

vim.keymap.set("n", "<leader>a", vim.lsp.buf.code_action, { noremap = true, silent = true, desc = "[A]ction" })
vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, { noremap = true, silent = true, desc = "[R]ename" })
local function keymap(kb, fn, desc, args)
	return vim.keymap.set("n", kb, function()
		local parts = vim.split(fn, "%.")
		local obj = Snacks
		for _, part in ipairs(parts) do
			obj = obj[part]
		end
		obj(args)
	end, { desc = desc })
end
Config.nmap_leader("h/", function()
	local items = {}
	-- Get diff with 0 context lines against HEAD
	local diff = vim.fn.systemlist("git diff HEAD --unified=0")
	local current_file = nil
	local current_line = 0
	local diff_hunks = {} -- Track all hunk changes to generate the inline diff view

	for _, line in ipairs(diff) do
		if line:match("^diff %-%-git") then
			current_file = line:match(" b/(.*)$")
			if current_file then
				diff_hunks[current_file] = diff_hunks[current_file] or {}
			end
		elseif line:match("^@@") then
			local lnum = line:match("%+(%d+)")
			current_line = tonumber(lnum) or 0
		-- Parse DELETED lines (-)
		elseif line:match("^%-") and not line:match("^%-%-%-") then
			local content = line:sub(2)
			if current_file then
				table.insert(diff_hunks[current_file], {
					line = current_line,
					type = "delete",
					text = content,
				})
				table.insert(items, {
					text = content,
					file = current_file,
					pos = { current_line == 0 and 1 or current_line, 1 },
					is_deleted = true,
				})
			end
		-- Parse ADDED lines (+)
		elseif line:match("^%+") and not line:match("^%+%+%+") then
			local content = line:sub(2)
			if current_file then
				table.insert(diff_hunks[current_file], {
					line = current_line,
					type = "add",
					text = content,
				})
				table.insert(items, {
					text = content,
					file = current_file,
					pos = { current_line, 1 },
					is_deleted = false,
				})
			end
			current_line = current_line + 1
		elseif not line:match("^%-") then
			current_line = current_line + 1
		end
	end

	if #items == 0 then
		vim.notify("No changed hunk contents found", vim.log.levels.INFO)
		return
	end

	Snacks.picker.pick({
		title = "Grep Git Changes",
		icon = "🍿 ",
		items = items,
		jump = { match = true },

		-- Formatting the picker list: Adds colored +/- indicators alongside treesitter code
		format = function(item, _)
			local ret = {}
			local filename = vim.fs.basename(item.file or "")
			local line_num = item.pos[1]

			table.insert(ret, { string.format("%s:%d ", filename, line_num), "SnacksPickerFile" })

			if item.is_deleted then
				table.insert(ret, { "- ", "DiffDelete" })
			else
				table.insert(ret, { "+ ", "DiffAdd" })
			end

			Snacks.picker.highlight.format(item, item.text, ret)
			return ret
		end,

		-- Previewer: Highlights all changed ranges, overriding the active match with CurSearch
		preview = function(ctx)
			require("snacks.picker.preview").file(ctx)

			vim.schedule(function()
				if not vim.api.nvim_buf_is_valid(ctx.buf) then
					return
				end

				local file = ctx.item.file
				if not file or not diff_hunks[file] then
					return
				end

				local ns = vim.api.nvim_create_namespace("snacks_git_hunk_preview_comprehensive")
				vim.api.nvim_buf_clear_namespace(ctx.buf, ns, 0, -1)

				local total_lines = vim.api.nvim_buf_line_count(ctx.buf)
				if total_lines == 0 then
					return
				end

				-- Extract details of the currently focused item in the picker list
				local active_row = ctx.item.pos[1]
				local active_is_deleted = ctx.item.is_deleted
				local active_text = ctx.item.text

				for _, change in ipairs(diff_hunks[file]) do
					local idx = change.line - 1
					if idx < 0 then
						idx = 0
					end

					-- Normalize line matching for zero-index edge cases at the top of files
					local change_line_normalized = change.line == 0 and 1 or change.line

					if change.type == "add" and idx < total_lines then
						-- Check if this specific added line is the active match
						local is_current_match = (
							not active_is_deleted
							and change_line_normalized == active_row
							and change.text == active_text
						)

						vim.api.nvim_buf_set_extmark(ctx.buf, ns, idx, 0, {
							line_hl_group = is_current_match and "CurSearch" or "DiffAdd",
						})
					elseif change.type == "delete" then
						-- Check if this specific virtual deleted line is the active match
						local is_current_match = (
							active_is_deleted
							and change_line_normalized == active_row
							and change.text == active_text
						)
						local target_row = math.min(idx, total_lines - 1)

						vim.api.nvim_buf_set_extmark(ctx.buf, ns, target_row, 0, {
							virt_lines = {
								{ { "- " .. change.text, is_current_match and "CurSearch" or "DiffDelete" } },
							},
							virt_lines_above = true,
						})
					end
				end
			end)
		end,
		win = {
			input = {
				keys = {
					["<CR>"] = { "confirm", mode = { "n", "i" } },
				},
			},
		},
	})
end, "Grep changed git content with true inline diff background colors")

return {
	vim.keymap.set("n", "<leader>td", function()
		local ok, Snacks = pcall(require, "snacks")
		if not ok then
			return
		end

		if Snacks.dim.enabled then
			Snacks.dim.disable()
		else
			Snacks.dim()
		end
	end, {
		noremap = true,
		silent = true,
		desc = "[T]oggle [D]iM",
	}),
	keymap("<leader>tr", "terminal", "Toggle Terminal"),
	keymap("<leader>.", "scratch", "Toggle Scratch Buffer"),
	keymap("<leader>S", "scratch.select", "Select Scratch Buffer"),
	keymap("<leader>z", "zen", "Toggle [Z]en mode"),
	keymap("<leader>lg", "lazygit", "lazy git"),
	keymap("<leader>e", "explorer", "File [E]xplorer"),

	keymap("<leader><leader>", "picker.resume", "resume"),
	keymap("<leader>d", "picker.diagnostics", "[D]iagnostics"),
	keymap("<leader>D", "picker.diagnostics_buffer", "Buffer [D]iagnostics"),
	keymap("<leader>g", "picker.git_status", "Git [S]tatus"),
	keymap("<leader>s", "picker.lsp_symbols", "LSP [S]ymbols"),
	keymap("<leader>S", "picker.lsp_workspace_symbols", "LSP Workspace [S]ymbols"),

	keymap(",b", "picker.buffers", " Find [B]uffers"),
	keymap(",i", "picker.icons", "picker [I]cons"),
	keymap(",j", "picker.jumps", "[J]umps"),
	keymap(",k", "picker.keymaps", "picker Keymaps"),
	keymap(",n", "picker.notifications", "Notification History"),
	keymap(",p", "picker.projects", "Find [P]rojects"),
	keymap(",r", "picker.recent", "Find [R]ecent"),
	keymap(",s", "picker.smart", "Smart picker"),
	keymap(",u", "picker.undo", "picker undo"),
	keymap(",z", "picker.zoxide", "[Z]oxide"),
	keymap(",?", "picker.command_history", "Command History"),

	keymap(",f", "picker.files", "files"),
	keymap(",gb", "picker.git_branches", "Git [B]ranches"),
	keymap(",gd", "picker.git_diff", "Git [D]iff (Hunks)"),
	keymap(",gf", "picker.git_log_file", "Git Log [F]ile"),
	keymap(",gl", "picker.git_log", "Git [L]og"),
	keymap(",gL", "picker.git_log_line", "Git Log [L]ine"),
	keymap(",gs", "picker.git_stash", "Git [S]tash"),

	keymap(",L", "picker.lsp_config", "Search [L]SP [C]onfig"),
	keymap(",C", "picker.colorschemes", "[C]olorschemes"),

	keymap("gq", "picker.qflist", "[Q]uickfix List"),
	keymap("gd", "picker.lsp_definitions", "Goto [D]efinition"),
	keymap("gD", "picker.lsp_declarations", "Goto [D]eclaration"),
	keymap("gr", "picker.lsp_references", "[R]eferences"),
	keymap("gi", "picker.lsp_implementations", "Goto [I]mplementation"),
	keymap("gy", "picker.lsp_type_definitions", "Goto T[y]pe Definition"),
	keymap("gai", "picker.lsp_incoming_calls", "Goto [I]ncoming Calls"),
	keymap("gao", "picker.lsp_outgoing_calls", "Goto [O]utgoing Calls"),

	keymap("gB", "gitbrowse", "Git [B]rowse"),
}

-- 🍿 Grep through the actual git diff content
