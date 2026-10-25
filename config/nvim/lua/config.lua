_G.Config = {}

local loaded_plugins = {}
local home_manager_opt = vim.fn.stdpath("data") .. "/site/pack/hm/opt"

local function load_home_manager_plugin(name)
	local path = home_manager_opt .. "/" .. name
	if vim.fn.isdirectory(path) ~= 1 then
		return false
	end

	vim.opt.runtimepath:append(path)
	local after_path = path .. "/after"
	if vim.fn.isdirectory(after_path) == 1 then
		vim.opt.runtimepath:append(after_path)
	end

	for _, directory in ipairs({ "plugin", "after/plugin" }) do
		local scripts = {}
		for _, extension in ipairs({ "lua", "vim" }) do
			vim.list_extend(scripts, vim.fn.glob(path .. "/" .. directory .. "/**/*." .. extension, false, true))
		end
		table.sort(scripts)
		for _, script in ipairs(scripts) do
			local command = script:match("%.lua$") and "luafile" or "source"
			vim.cmd(command .. " " .. vim.fn.fnameescape(script))
		end
	end
	return true
end

-- Plugins live in the immutable Nix packpath. This only activates an opt
-- package; it never clones, updates or writes to Neovim's data directory.
-- Resolve Home Manager's copy directly so a stale manual `pack/core` copy of
-- the same plugin cannot be activated alongside the Nix-managed version.
Config.packadd = function(name)
	if loaded_plugins[name] then
		return true
	end

	local ok, loaded = pcall(load_home_manager_plugin, name)
	if ok and loaded then
		loaded_plugins[name] = true
		return true
	end

	local fallback_ok, err = pcall(vim.cmd.packadd, name)
	if not fallback_ok then
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
