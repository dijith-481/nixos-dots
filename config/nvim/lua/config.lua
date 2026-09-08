_G.Config = {}

local loaded_plugins = {}

-- Plugins live in the immutable Nix packpath. This only activates an opt
-- package; it never clones, updates or writes to Neovim's data directory.
Config.packadd = function(name)
	if loaded_plugins[name] then
		return true
	end

	local ok, err = pcall(vim.cmd.packadd, name)
	if not ok then
		vim.schedule(function()
			vim.notify(("Failed to load Nix plugin %s: %s"):format(name, err), vim.log.levels.ERROR)
		end)
		return false
	end

	loaded_plugins[name] = true
	return true
end

Config.packadd_all = function(names)
	for _, name in ipairs(names) do
		Config.packadd(name)
	end
end

Config.key_map = function(mode, lhs, rhs, desc, opts)
	local final_opts = vim.tbl_extend("force", opts or {}, { desc = desc })
	vim.keymap.set(mode, lhs, rhs, final_opts)
end

Config.nmap = function(lhs, rhs, desc, opts)
	Config.key_map("n", lhs, rhs, desc, opts)
end
Config.nmap_leader = function(suffix, rhs, desc, opts)
	Config.nmap("<Leader>" .. suffix, rhs, desc, opts)
end
Config.nvmap = function(lhs, rhs, desc, opts)
	Config.key_map({ "n", "v" }, lhs, rhs, desc, opts)
end
Config.imap = function(lhs, rhs, desc, opts)
	Config.key_map("i", lhs, rhs, desc, opts)
end
Config.vmap = function(lhs, rhs, desc, opts)
	Config.key_map("v", lhs, rhs, desc, opts)
end
Config.xmap = function(lhs, rhs, desc, opts)
	Config.key_map("x", lhs, rhs, desc, opts)
end
Config.xmap_leader = function(suffix, rhs, desc, opts)
	Config.xmap("<Leader>" .. suffix, rhs, desc, opts)
end
Config.omap = function(lhs, rhs, desc, opts)
	Config.key_map("o", lhs, rhs, desc, opts)
end
Config.omap_leader = function(suffix, rhs, desc, opts)
	Config.omap("<Leader>" .. suffix, rhs, desc, opts)
end

Config.autocmd = function(event, group, cb, pattern, desc)
	local autocmd_group
	if type(group) == "string" then
		autocmd_group = vim.api.nvim_create_augroup(group, { clear = false })
	else
		autocmd_group = group
	end

	local is_buf = type(pattern) == "number"
	vim.api.nvim_create_autocmd(event, {
		desc = desc,
		pattern = not is_buf and pattern or nil,
		buffer = is_buf and pattern or nil,
		group = autocmd_group,
		callback = cb,
	})
end
