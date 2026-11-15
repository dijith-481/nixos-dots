-- tsrs: Rust port of the TypeScript 7 language server.
-- Speaks the same protocol as `tsgo --lsp -stdio`; the binary comes from Nix.
local deno_markers = { "deno.json", "deno.jsonc", "deno.lock" }
local project_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" }

return {
	cmd = { "tsrs", "--lsp", "-stdio" },
	filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
	root_markers = project_markers,
	-- Deno projects are served by denols only; do not start tsrs there.
	root_dir = function(bufnr, on_dir)
		if vim.fs.root(bufnr, deno_markers) then
			return
		end
		local dir = vim.fs.root(bufnr, project_markers)
		if dir then
			on_dir(dir)
		end
	end,
}
