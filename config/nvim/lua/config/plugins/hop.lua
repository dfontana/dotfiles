return {
	{
		"phaazon/hop.nvim",
		lazy = false,
		config = function()
			local hop = require("hop")
			local directions = require("hop.hint").HintDirection

			-- Jump forward on the line
			vim.keymap.set("", "f", function()
				hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true })
			end, { remap = true })

			-- Jump to a word on the doc
			vim.keymap.set("", "w", function()
				hop.hint_words({})
			end, { remap = true })

			hop.setup()
		end,
	},
}
