local autocmd = Config.autocmd
local highlight_groups = {}

local function has_client_method(bufnr, method)
	for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
		if client:supports_method(method, bufnr) then
			return true
		end
	end
	return false
end

autocmd("LspAttach", "lsp_core", function(event)
	local client = vim.lsp.get_client_by_id(event.data.client_id)
	if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
		if not highlight_groups[event.buf] then
			local group = vim.api.nvim_create_augroup("lsp_highlight_" .. event.buf, { clear = true })
			highlight_groups[event.buf] = group
			vim.api.nvim_create_autocmd("CursorHold", {
				group = group,
				buffer = event.buf,
				callback = vim.lsp.buf.document_highlight,
			})
			vim.api.nvim_create_autocmd("CursorMoved", {
				group = group,
				buffer = event.buf,
				callback = vim.lsp.buf.clear_references,
			})
		end
	end

	if client and client:supports_method("textDocument/inlayHint", event.buf) then
		vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
	end
end, "*", "Automatically highlights all references of the word under the cursor using LSP data")

autocmd("LspDetach", "lsp_core", function(event)
	vim.schedule(function()
		if highlight_groups[event.buf] and not has_client_method(event.buf, "textDocument/documentHighlight") then
			pcall(vim.api.nvim_del_augroup_by_id, highlight_groups[event.buf])
			highlight_groups[event.buf] = nil
			if vim.api.nvim_buf_is_valid(event.buf) then
				vim.api.nvim_buf_call(event.buf, vim.lsp.buf.clear_references)
			end
		end
	end)
end, "*", "Remove buffer-scoped LSP highlight hooks after the final supporting client detaches")

autocmd("BufWipeout", "lsp_core", function(event)
	local group = highlight_groups[event.buf]
	if group then
		pcall(vim.api.nvim_del_augroup_by_id, group)
		highlight_groups[event.buf] = nil
	end
end, "*", "Clean up LSP highlight hooks with their buffer")

autocmd("LspProgress", "lsp_core", function(args)
	local value = args.data and args.data.params and args.data.params.value
	if value and value.kind == "end" then
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client then
			for bufnr in pairs(client.attached_buffers or {}) do
				if client:supports_method("textDocument/foldingRange", bufnr) then
					for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
						vim.api.nvim_set_option_value("foldexpr", "v:lua.vim.lsp.foldexpr()", { win = win })
						vim.api.nvim_set_option_value(
							"foldtext",
							("v:lua.custom_foldtext('%s')"):format(client.config.name),
							{ win = win }
						)
					end
				end
			end
		end
	end
end, "*", "use LSP-based folding once the language server has finished indexing/loading")

-- Advertise completion support before any server attaches, and batch rapid
-- didChange notifications so large language servers do not process every
-- single keystroke independently.
vim.lsp.config("*", {
	capabilities = require("blink.cmp").get_lsp_capabilities(),
	flags = {
		debounce_text_changes = 150,
	},
})

vim.lsp.enable({
	"angularls",
	"bashls",
	"biome",
	"cssls",
	"denols",
	"fish_lsp",
	"hyprls",
	"lua_ls",
	"marksman",
	"ruff",
	"ty", -- python
	"tailwindcss",
	"jdtls",
	"clangd",
	"astro",
	"zls",
})
