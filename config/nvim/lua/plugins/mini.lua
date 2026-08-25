require("mini.ai").setup({ n_lines = 500 })
require("mini.align").setup()
require("mini.move").setup()
require("mini.surround").setup()
require("mini.extra").setup()
require("plugins.mini.buf-remove")
require("plugins.mini.clue")
require("plugins.mini.operators")
require("mini.statusline").setup()
require("mini.bracketed").setup({
	git = { suffix = "" },
})
require("plugins.mini.hipatterns")
