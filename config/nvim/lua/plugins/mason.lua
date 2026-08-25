local ensure_installed = {
	"angular-language-server",
	"bash-language-server",
	"clangd",
	"hyprls",
	"lua-language-server",
	"ruff",
	"typescript-language-server",
	"marksman",
	"tailwindcss-language-server",
	"shellcheck",
	"deno",
	"biome",
	"oxlint",
	"css-lsp",
	"astro-language-server",
	"fish-lsp",
	"ty",
	"jdtls",
	"zls",
}
require("mason").setup()
require("mason-tool-installer").setup({
	ensure_installed = ensure_installed,
})
