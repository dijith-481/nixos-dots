local autocmd = Config.autocmd
local function build_preview(params)
	vim.notify("Building markdown preview", vim.log.levels.INFO)
	local obj = vim.system({ "npm", "install" }, { cwd = params.path .. "/app" }):wait()
	if obj.code == 0 then
		vim.notify("Building markdown preview done", vim.log.levels.INFO)
	else
		vim.notify("Building markdown preview failed", vim.log.levels.ERROR)
	end
end

Config.build_hook("markdown-preview", "build", build_preview)

autocmd({ "BufReadPost", "BufNewFile" }, "markdown", function()
	vim.g.mkdp_filetypes = { "markdown" }
	-- delay  to load the command
	vim.defer_fn(function()
		vim.cmd("MarkdownPreviewToggle")
	end, 100)
end, "*.md", "Markdown Preview")
