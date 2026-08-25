-- TODO:  refactor autocmd
-- ── cache tables ──────────────────────────────────────────────────
local diag_cache = {} -- [bufnr] = { [lnum] = severity }
local git_cache = {} -- [bufnr] = { [lnum] = diff_status_string }

-- ── per-render caches (invalidated by changedtick each render) ────
-- Stores fold info per lnum so foldfn + lineNrFn share one lookup.
local fold_info_cache = {} -- [lnum] = { level, closed_at }
local ctx_cache = {} -- [lnum] = context table
local render_tick = -1 -- vim.b[bufnr].changedtick snapshot

local function reset_render_cache(tick)
	if tick ~= render_tick then
		fold_info_cache = {}
		ctx_cache = {}
		render_tick = tick
	end
end

-- ── autocmd invalidation ──────────────────────────────────────────
local group = vim.api.nvim_create_augroup("StatusColCache", { clear = true })
vim.api.nvim_create_autocmd({ "DiagnosticChanged", "BufEnter" }, {
	group = group,
	callback = function(args)
		diag_cache[args.buf] = nil
	end,
})
vim.api.nvim_create_autocmd("User", {
	pattern = "GitSignsUpdate",
	group = group,
	callback = function(args)
		git_cache[args.buf or vim.api.nvim_get_current_buf()] = nil
	end,
})

-- ── fold-info helpers ─────────────────────────────────────────────
-- Returns { level, closed_at } for lnum, using the per-render cache.
-- Reduces repeated foldlevel()/foldclosed() Vimscript FFI calls.
local function get_fold_info(lnum)
	local cached = fold_info_cache[lnum]
	if cached then
		return cached
	end
	local info = {
		level = vim.fn.foldlevel(lnum),
		closed_at = vim.fn.foldclosed(lnum), -- -1 if open, else fold-start lnum
	}
	fold_info_cache[lnum] = info
	return info
end

-- Fold-range cache (one entry; keyed by buf+lnum+tick+level).
-- Using a flat struct is slightly faster than nested tables.
local last_fold_args = {}

local function get_current_fold_range(cursor_lnum, fold_level)
	local bufnr = vim.api.nvim_get_current_buf()
	local tick = vim.b[bufnr].changedtick

	if
		last_fold_args.bufnr == bufnr
		and last_fold_args.lnum == cursor_lnum
		and last_fold_args.tick == tick
		and last_fold_args.level == fold_level
	then
		return last_fold_args.start, last_fold_args.end_
	end

	local fi = get_fold_info(cursor_lnum)
	local closed_start = fi.closed_at
	local calc_lnum = cursor_lnum
	local calc_level = fold_level

	if closed_start ~= -1 then
		local closed_fi = get_fold_info(closed_start)
		calc_lnum = closed_start
		calc_level = closed_fi.level - 1
	end

	if calc_level <= 0 then
		last_fold_args = { bufnr = bufnr, lnum = cursor_lnum, tick = tick, level = fold_level, start = nil, end_ = nil }
		return nil, nil
	end

	-- Walk upward until the fold level drops below calc_level.
	-- Each get_fold_info call is cached, so repeated lines in the same
	-- render cycle are essentially free.
	local start_lnum = calc_lnum
	while get_fold_info(start_lnum - 1).level >= calc_level do
		start_lnum = start_lnum - 1
	end

	local end_lnum = calc_lnum
	local last_line = vim.fn.line("$")
	while end_lnum < last_line and get_fold_info(end_lnum + 1).level >= calc_level do
		end_lnum = end_lnum + 1
	end

	last_fold_args = {
		bufnr = bufnr,
		lnum = cursor_lnum,
		tick = tick,
		level = fold_level,
		start = start_lnum,
		end_ = end_lnum,
	}
	return start_lnum, end_lnum
end

-- ── misc helpers ──────────────────────────────────────────────────
local function get_by_level(property, level)
	if not property or not level then
		return
	end
	if not vim.islist(property) then
		return property
	end
	return property[level] or property[(#property % level)]
end

-- ── git diff ──────────────────────────────────────────────────────
local function get_line_diff_status(lnum, bufnr)
	if git_cache[bufnr] then
		return git_cache[bufnr][lnum]
	end
	if not package.loaded.gitsigns then
		return nil
	end

	local hunks = require("gitsigns").get_hunks(bufnr)
	local cache = {}
	if hunks then
		for _, hunk in ipairs(hunks) do
			local added = hunk.added
			if added then
				local val = hunk.type
				-- Show deleted-line count as a subscript numeral instead of "delete".
				if hunk.type == "delete" and hunk.removed.count > 1 then
					val = tostring(hunk.removed.count)
				end
				if added.count > 0 then
					for i = added.start, added.start + added.count - 1 do
						cache[i] = val
					end
				else
					cache[added.start] = val
				end
			end
		end
	end
	git_cache[bufnr] = cache
	return cache[lnum]
end

-- ── line context (shared between foldfn + lineNrFn) ───────────────
-- Called once per lnum per render cycle; result is cached in ctx_cache.
local function get_line_context(bufnr, lnum, tick)
	reset_render_cache(tick)

	local cached = ctx_cache[lnum]
	if cached then
		return cached
	end

	-- Ensure diag cache is populated.
	if not diag_cache[bufnr] then
		local dc = {}
		for _, d in ipairs(vim.diagnostic.get(bufnr)) do
			local ln = d.lnum + 1
			if not dc[ln] or d.severity < dc[ln] then
				dc[ln] = d.severity
			end
		end
		diag_cache[bufnr] = dc
	end

	local ctx = {
		bufnr = bufnr,
		diff_status = get_line_diff_status(lnum, bufnr),
		diagnostic_severity = diag_cache[bufnr][lnum],
	}
	ctx_cache[lnum] = ctx
	return ctx
end

-- ── diff_icon: pre-built lookup table ────────────────────────────
-- Avoids string concatenation on the hot path.
-- Built once; keys are the diff_status strings used by get_line_diff_status.
local diff_icon_cache = {}

local _diff_icons = { add = "₊", change = "ₒ", delete = "˯" }
local _diff_hls = { add = "GitSignsAdd", change = "GitSignsChange", delete = "GitSignsDelete" }
local _nums = { "₁", "₂", "₃", "₄", "₅", "₆", "₇", "₈", "₉", "ₓ" }

function _G.diff_icon(diff_status)
	if not diff_status then
		return " "
	end

	local hit = diff_icon_cache[diff_status]
	if hit then
		return hit
	end

	local result
	local num = tonumber(diff_status)
	if num then
		-- Numeric delete count: no highlight group (matches original).
		result = "%##" .. _nums[math.min(num, #_nums)]
	else
		result = ("%#" .. _diff_hls[diff_status] .. "#") .. _diff_icons[diff_status]
	end
	diff_icon_cache[diff_status] = result
	return result
end

-- ── highlight-string cache (lineNrFn) ────────────────────────────
-- Each unique hl group pair is built once, never again.
local hl_str_cache = {}
local function hl_str(group)
	local hit = hl_str_cache[group]
	if not hit then
		hit = "%#" .. group .. "#"
		hl_str_cache[group] = hit
	end
	return hit
end

-- ── foldfn ────────────────────────────────────────────────────────
local foldfn = function(args)
	if not args.rnu and not args.nu then
		return ""
	end
	if args.virtnum ~= 0 then
		return "%="
	end

	local bufnr = vim.api.nvim_get_current_buf()
	local tick = vim.b[bufnr].changedtick
	local lnum = args.lnum
	local context = get_line_context(bufnr, lnum, tick)

	local cursor_lnum = vim.fn.line(".")
	local cursor_fi = get_fold_info(cursor_lnum)
	local cursor_fold_level = cursor_fi.level
	local cursor_scope_start, cursor_scope_end = get_current_fold_range(cursor_lnum, cursor_fold_level)

	local fi = get_fold_info(lnum)
	local line_fold_level = fi.level
	local fold_part = hl_str("Bars_glow__1") .. "  "

	if line_fold_level > 0 then
		local is_in_cursor_scope = cursor_scope_start and lnum >= cursor_scope_start and lnum <= cursor_scope_end

		local active_scope_hl_group = is_in_cursor_scope and ("Bars_glow_" .. (cursor_fold_level - 1) % 5)
			or "Bars_glow__1"
		local self_level_hl_group = is_in_cursor_scope and ("Bars_glow_" .. (line_fold_level - 1) % 5) or "Bars_glow__1"

		local active_scope_hl = hl_str(active_scope_hl_group)
		local self_level_hl = hl_str(self_level_hl_group)

		local closed_at = fi.closed_at

		if closed_at == lnum then
			-- Closed fold
			local icons = { "● ", "┿❭", "╪❭" }
			fold_part = self_level_hl .. get_by_level(icons, line_fold_level)
		elseif closed_at == -1 then
			-- Open fold — cache neighbor levels
			local prev_fi = get_fold_info(lnum - 1)
			local next_fi = get_fold_info(lnum + 1)

			local text = {
				opened_first = { first = "╭", second = "•" },
				opened_special = { first = "╭", second = "•" },
				opened_normal = { first = "├", second = "•" },
				edge_first = { first = "╰", second = "›" },
				edge_special = { first = "╰", second = "›" },
				edge_normal = { first = "│", second = " " },
				scope = { "│", "┆", "┊" },
			}

			if line_fold_level > prev_fi.level then
				-- Fold start
				local icon_set
				if line_fold_level == 1 then
					icon_set = text.opened_first
				elseif lnum == cursor_scope_start then
					icon_set = text.opened_special
				else
					icon_set = text.opened_normal
				end
				fold_part = self_level_hl .. icon_set.first .. self_level_hl .. icon_set.second
			elseif line_fold_level > next_fi.level then
				-- Fold end
				local is_active_scope_end = cursor_scope_end and (lnum == cursor_scope_end)
				local icon_set
				if next_fi.level == 0 then
					icon_set = text.edge_first
					fold_part = active_scope_hl .. icon_set.first .. active_scope_hl .. icon_set.second
				elseif is_active_scope_end then
					icon_set = text.edge_special
					fold_part = active_scope_hl .. icon_set.first .. self_level_hl .. icon_set.second
				else
					icon_set = text.edge_normal
					fold_part = active_scope_hl .. icon_set.first .. _G.diff_icon(context.diff_status)
				end
			else
				-- Interior of fold
				local base_icon
				if cursor_fi.closed_at ~= -1 then
					local hl_group = is_in_cursor_scope and ("Bars_glow_" .. (cursor_fold_level - 2) % 5)
						or "Bars_glow__1"
					base_icon = hl_str(hl_group) .. get_by_level(text.scope, line_fold_level)
				else
					base_icon = active_scope_hl .. get_by_level(text.scope, line_fold_level)
				end
				fold_part = base_icon .. _G.diff_icon(context.diff_status)
			end
		end
	else
		fold_part = " " .. _G.diff_icon(context.diff_status)
	end

	return fold_part
end

-- ── lineNrFn ──────────────────────────────────────────────────────
-- Pre-built highlight-string table for diagnostic severity levels.
local diag_hls = {
	[vim.diagnostic.severity.ERROR] = "DiagnosticLineNrError",
	[vim.diagnostic.severity.WARN] = "DiagnosticLineNrWarn",
	[vim.diagnostic.severity.INFO] = "DiagnosticLineNrInfo",
	[vim.diagnostic.severity.HINT] = "DiagnosticLineNrHint",
}

local lineNrFn = function(args, segment)
	if args.sclnu and segment.sign and segment.sign.wins[args.win].signs[args.lnum] then
		return "%=" .. M.signfunc(args, segment)
	end
	if not args.rnu and not args.nu then
		return ""
	end
	if args.virtnum ~= 0 then
		return "%="
	end

	local lnum_str = args.rnu and (args.relnum > 0 and tostring(args.relnum) or tostring(args.nu and args.lnum or 0))
		or tostring(args.lnum)

	local pad = (" "):rep(args.nuw - #lnum_str)
	local bufnr = vim.api.nvim_get_current_buf()
	local tick = vim.b[bufnr].changedtick
	-- Re-use context already built by foldfn (or build it now if foldfn
	-- was skipped, e.g. when fold column is absent).
	local context = get_line_context(bufnr, args.lnum, tick)

	if context.diagnostic_severity and diag_hls[context.diagnostic_severity] then
		local hl_group = diag_hls[context.diagnostic_severity]
		local rev_hl_group = hl_group .. "Rev"
		return hl_str(hl_group) .. "%=" .. lnum_str .. hl_str(rev_hl_group)
	end

	if args.relnum == 0 then
		local prefix = context.diff_status and hl_str("CursorLineNrBg") or ""
		return prefix .. "%=" .. pad .. lnum_str .. hl_str("CursorLineNrRev#")
	end

	return "%=" .. pad .. lnum_str .. " "
end

local builtin = require("statuscol.builtin")
require("statuscol").setup({
	relculright = true,
	clickhandlers = { Lnum = builtin.gitsigns_click },
	segments = {
		{
			text = { lineNrFn },
			colwidth = 1,
			click = "v:lua.ScLa",
		},
		{
			sign = {
				namespace = { ".*" },
				maxwidth = 1,
				colwidth = 1,
				auto = true,
				wrap = true,
			},
			click = "v:lua.ScSa",
		},
		{
			text = { foldfn },
			wrap = true,
			colwidth = 2,
			click = "v:lua.ScFa",
		},
	},
})
