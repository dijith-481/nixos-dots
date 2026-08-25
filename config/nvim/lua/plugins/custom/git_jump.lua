local M = {}

M.jump = function(dir)
	local unstaged = vim.fn.systemlist("git diff --name-only")
	local untracked = vim.fn.systemlist("git ls-files --others --exclude-standard")
	local files = {}
	local seen = {}

	local function add_files(list)
		for _, f in ipairs(list) do
			if f ~= "" and not seen[f] then
				table.insert(files, f)
				seen[f] = true
			end
		end
	end

	add_files(unstaged)
	add_files(untracked)
	if #files == 0 then
		return vim.notify("No unstaged changes")
	end

	local ok, root = pcall(function()
		return vim.fn.systemlist("git rev-parse --show-toplevel")[1]
	end)
	if not ok or not root then
		return
	end

	for i, f in ipairs(files) do
		files[i] = root .. "/" .. f
	end

	local current = vim.api.nvim_buf_get_name(0)
	local idx = nil
	for i, f in ipairs(files) do
		if f == current then
			idx = i
			break
		end
	end

	local target_idx
	if not idx then
		target_idx = (dir == "next") and 1 or #files
	else
		target_idx = (dir == "next") and (idx % #files + 1) or ((idx - 2 + #files) % #files + 1)
	end

	vim.cmd("edit " .. files[target_idx])
end

return M
