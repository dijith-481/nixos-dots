local nordic = require("nordic")
nordic.setup({

	vim.api.nvim_set_hl(0, "YankHighlight", {}),
	vim.api.nvim_set_hl(0, "DiagnosticLineNrError", {}),
	vim.api.nvim_set_hl(0, "DiagnosticLineNrWarn", {}),
	vim.api.nvim_set_hl(0, "DiagnosticLineNrInfo", {}),
	vim.api.nvim_set_hl(0, "DiagnosticLineNrHint", {}),
	vim.api.nvim_set_hl(0, "DiagnosticLineNrErrorRev", {}),
	vim.api.nvim_set_hl(0, "DiagnosticLineNrWarnRev", {}),
	vim.api.nvim_set_hl(0, "DiagnosticLineNrInfoRev", {}),
	vim.api.nvim_set_hl(0, "DiagnosticLineNrHintRev", {}),
	vim.api.nvim_set_hl(0, "CursorLineNrRev", {}),
	vim.api.nvim_set_hl(0, "CursorLineNrBg", {}),
	vim.api.nvim_set_hl(0, "Bars_glow__1", {}),
	vim.api.nvim_set_hl(0, "Bars_glow_0", {}),
	vim.api.nvim_set_hl(0, "Bars_glow_1", {}),
	vim.api.nvim_set_hl(0, "Bars_glow_2", {}),
	vim.api.nvim_set_hl(0, "Bars_glow_3", {}),
	vim.api.nvim_set_hl(0, "Bars_glow_4", {}),
	vim.api.nvim_set_hl(0, "Bars_glow_5", {}),
	vim.api.nvim_set_hl(0, "Bars_glow_6", {}),
	vim.api.nvim_set_hl(0, "Bars_glow_7", {}),
	on_highlight = function(highlights, palette)
		local U = require("nordic.utils")
		highlights.CursorLine = {
			bg = U.blend(palette.blue0, palette.bg, 0.10),
		}

		highlights.FloatBorder = {
			fg = palette.white0,
			bg = palette.bg,
		}

		highlights.Bars_glow__1 = {
			bg = palette.bg,
			fg = palette.gray2,
		}
		highlights.CursorColumn = {
			bg = U.blend(palette.blue0, palette.bg, 0.04),
		}
		highlights.MiniStatusLineModeNormal = {
			bg = palette.blue1,
			fg = palette.black0,
		}

		highlights.CursorLineNr = {
			bg = U.blend(palette.blue1, palette.bg, 0.20),
			fg = palette.blue1,
			bold = true,
		}
		highlights.CursorLineNrBg = {
			bg = U.blend(palette.blue1, palette.bg, 0.20),
			bold = true,
		}
		highlights.CursorLineNrRev = {
			fg = U.blend(palette.blue1, palette.bg, 0.20),
			bg = palette.bg,
		}
		highlights.LspReferenceText = {
			bg = U.blend(palette.blue0, palette.bg, 0.10),
		}
		highlights.LspReferenceRead = {
			bg = U.blend(palette.cyan.base, palette.bg, 0.20),
		}
		highlights.LspReferenceWrite = {
			bg = U.blend(palette.green.base, palette.bg, 0.10),
		}
		highlights.DiagnosticLineNrError = {
			bg = U.blend(palette.red.base, palette.bg, 0.30),
			fg = palette.red.base,
		}
		highlights.DiagnosticLineNrErrorRev = {
			fg = U.blend(palette.red.base, palette.bg, 0.30),
			bg = palette.bg,
		}

		highlights.DiagnosticLineNrWarn = {
			bg = U.blend(palette.yellow.base, palette.bg, 0.30),
			fg = palette.yellow.base,
		}

		highlights.DiagnosticLineNrWarnRev = {
			fg = U.blend(palette.yellow.base, palette.bg, 0.30),
			bg = palette.bg,
		}

		highlights.DiagnosticLineNrInfo = {
			bg = U.blend(palette.cyan.base, palette.bg, 0.30),
			fg = palette.cyan.base,
		}

		highlights.DiagnosticLineNrInfoRev = {
			fg = U.blend(palette.cyan.base, palette.bg, 0.30),
			bg = palette.bg,
		}

		highlights.DiagnosticLineNrHint = {
			bg = U.blend(palette.green.base, palette.bg, 0.30),
			fg = palette.green.base,
		}

		highlights.DiagnosticLineNrHintRev = {
			fg = U.blend(palette.green.base, palette.bg, 0.30),
			bg = palette.bg,
		}

		highlights.Folded = {
			bg = U.blend(palette.blue0, palette.bg, 0.06),
		}
		highlights.GitSignsChange = {
			fg = palette.blue1,
		}

		highlights.GitSignsStagedChangeNr = {
			fg = U.blend(palette.blue1, palette.bg, 0.70),
			italic = true,
		}

		highlights.GitSignsStagedDeleteNr = {
			fg = U.blend(palette.red.base, palette.bg, 0.50),
			italic = true,
		}
		highlights.GitSignsStagedAddNr = {
			fg = U.blend(palette.green.base, palette.bg, 0.50),
			italic = true,
		}

		highlights.MiniStatuslineTreesitter = {
			fg = palette.fg,
		}
		highlights.MiniStatuslineFilename = {
			bg = palette.gray1,
			fg = palette.fg,
		}
		highlights.MiniStatuslineDevinfo = {
			bg = palette.gray2,
			fg = palette.fg,
		}

		highlights.GitSignsCurrentLineBlame = {
			fg = U.blend(palette.white0, palette.bg, 0.27),
		}
		highlights.YankHighlight = {
			bg = palette.bg_selected,
		}
		highlights.Bars_glow_4 = {
			bg = palette.bg,
			fg = palette.red.base,
		}
		highlights.Bars_glow_3 = {
			bg = palette.bg,
			fg = palette.orange.base,
		}
		highlights.Bars_glow_2 = {
			bg = palette.bg,
			fg = palette.yellow.base,
		}
		highlights.Bars_glow_1 = {
			bg = palette.bg,
			fg = palette.green.base,
		}
		highlights.Bars_glow_0 = {
			bg = palette.bg,
			fg = palette.blue1,
		}
	end,
	after_palette = function(palette)
		local U = require("nordic.utils")
		palette.bg_visual = U.blend(palette.blue0, palette.bg, 0.18)
		palette.bg_selected = U.blend(palette.blue0, palette.bg, 0.50)
	end,
})
nordic.load()
