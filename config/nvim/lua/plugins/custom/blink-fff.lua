---@class FffSourceOpts
---@field min_query_len?  number   (default 3)
---@field page_size?      number   (default 40)
---@field time_budget_ms? number   (default 30)
---@field smart_case?     boolean  (default true)

---@class FffGrepHit
---@field line_content string|nil
---@field col          number|nil
---@field name         string|nil

---@class FffGrepResult
---@field items FffGrepHit[]

---@class FffGrep
---@field search fun(query: string, offset: number, page_size: number, config: table, mode: string): FffGrepResult

---@class BlinkContext
---@field cursor  number[]   {row, col}
---@field line    string

---@class FffSource
---@field opts       FffSourceOpts
---@field _request_id number
---@field _grep      FffGrep|nil
local FffSource = {}
FffSource.__index = FffSource

---@param opts? FffSourceOpts
---@return FffSource
function FffSource.new(opts)
	local ok, grep = pcall(require, "fff.grep")
	if not ok then
		vim.notify("[blink-fff] fff.grep unavailable: " .. tostring(grep), vim.log.levels.WARN)
	end
	return setmetatable({
		opts = opts or {},
		_request_id = 0,
		_grep = ok and grep or nil,
	}, FffSource)
end

---@param context  BlinkContext
---@param callback fun(response: table|nil)
---@return fun()
function FffSource:get_completions(context, callback)
	if not self._grep then
		callback(nil)
		return function() end
	end

	local opts = self.opts
	local min_len = opts.min_query_len or 3
	local col = context.cursor[2]
	local query = context.line:sub(1, col):match("[%w_%-]+$") or ""

	if #query < min_len then
		callback({ is_incomplete_forward = true, is_incomplete_backward = false, items = {} })
		return function() end
	end

	self._request_id = self._request_id + 1
	local my_id = self._request_id
	local cancelled = false

	vim.schedule(function()
		if cancelled or my_id ~= self._request_id then
			return
		end

		---@type FffGrepResult
		local result = self._grep.search(query, 0, opts.page_size or 40, {
			time_budget_ms = opts.time_budget_ms or 30,
			smart_case = opts.smart_case ~= false,
		}, "fuzzy")

		if cancelled or my_id ~= self._request_id then
			return
		end
		if not (result and result.items) then
			callback({ is_incomplete_forward = true, is_incomplete_backward = true, items = {} })
			return
		end

		local seen = {}
		local items = {}
		local kinds = require("blink.cmp.types").CompletionItemKind

		for _, hit in ipairs(result.items) do
			local content = tostring(hit.line_content or "")
			local m_col = (hit.col or 0) + 1

			local word = content:sub(1, m_col):match("[%w_%-]+$") or ""
			word = word .. (content:sub(m_col + 1):match("^[%w_%-]*") or "")

			if #word > #query and not seen[word] then
				seen[word] = true
				items[#items + 1] = {
					label = word,
					insertText = word,
					kind = kinds.Text,
					labelDetails = { description = content },
				}
			end
		end

		callback({
			is_incomplete_forward = true,
			is_incomplete_backward = true,
			items = items,
		})
	end)

	return function()
		cancelled = true
	end
end

function FffSource:resolve(item, callback)
	item = vim.deepcopy(item)
	item.documentation = {
		kind = "markdown",
		value = item.labelDetails.description,
	}

	callback(item)
end

return FffSource
