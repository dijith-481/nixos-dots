_G.Config = {}

Config.pack_add = function(items)
	local specs = {}
	local names = {}

	for _, item in ipairs(items) do
		local repo = type(item) == "table" and (item.src or item[1]) or item
		local url = repo:find("://") and repo or ("https://github.com/" .. repo)
		local raw_name = url:match(".+/(.+)$") or repo
		-- 2. Capture everything before the first dot
		local name = string.lower(raw_name:match("^([^%.]+)"))
		local spec
		if type(item) == "table" then
			spec = vim.tbl_extend("force", item, { src = url })
			spec[1] = nil
		else
			spec = { src = url }
		end

		table.insert(names, spec.name or name)
		table.insert(specs, spec)
	end

	vim.pack.add(specs)

	for _, name in ipairs(names) do
		pcall(require, "plugins." .. name)
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
Config.build_hook = function(name, kind, cb)
	local kinds = type(kind) == "table" and kind or { kind }

	return function(ev)
		if name == ev.data.spec.name and vim.list_contains(kinds, ev.data.kind) then
			cb(ev.data)
		end
	end
end
