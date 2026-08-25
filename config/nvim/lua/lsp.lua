local autocmd = Config.autocmd

autocmd("LspAttach", "lsp_core", function(event)
	local client = vim.lsp.get_client_by_id(event.data.client_id)
	if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
		autocmd({ "CursorHold", "CursorHoldI" }, "lsp_highlight", function()
			vim.lsp.buf.document_highlight()
		end, event.buf, "Highlight")

		autocmd({ "CursorMoved", "CursorMovedI" }, "lsp_highlight", vim.lsp.buf.clear_references, event.buf, "Clear")

		vim.lsp.inlay_hint.enable(true)
	end
end, "*", "Automatically highlights all references of the word under the cursor using LSP data")

autocmd("LspProgress", "lsp_core", function(args)
	if args.data.params.value.kind == "end" then
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client and client:supports_method("textDocument/foldingRange") then
			local win = vim.api.nvim_get_current_win()
			vim.wo[win].foldexpr = "v:lua.vim.lsp.foldexpr()"
			vim.wo[win].foldtext = ("v:lua.custom_foldtext('%s')"):format(client.config.name)
		end
	end
end, "*", "use LSP-based folding once the language server has finished indexing/loading")

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
