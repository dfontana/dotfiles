-- TODO: Fix default indent from 4 to rustfmt or 2
return function(lsp_server)
  local mason_registry = require("mason-registry")

  local codelldb_root = mason_registry.get_package("codelldb"):get_install_path() .. "/extension/"
  local codelldb_path = codelldb_root .. "adapter/codelldb"
  local liblldb_path = codelldb_root .. "lldb/lib/liblldb.dylib" -- changes to .so on linux
  local dap = {
    type = "server",
    port = "13000",
    host = "127.0.0.1",
    executable = {
      command = codelldb_path,
      args = { "--liblldb", liblldb_path, "--port", "13000" },
    },
  }

	return {
		tools = {
			-- autoSetHints = false,
			on_initialized = function()
				vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter", "CursorHold", "InsertLeave" }, {
					pattern = { "*.rs" },
					callback = function()
						vim.lsp.codelens.refresh()
					end,
				})
			end,

			auto = false,
			inlay_hints = {
				-- Only show inlay hints for the current line
				only_current_line = false,
				auto = false,

				-- Event which triggers a refersh of the inlay hints.
				-- You can make this "CursorMoved" or "CursorMoved,CursorMovedI" but
				-- not that this may cause higher CPU usage.
				-- This option is only respected when only_current_line and
				-- autoSetHints both are true.
				only_current_line_autocmd = "CursorHold",

				-- whether to show parameter hints with the inlay hints or not
				-- default: true
				show_parameter_hints = false,

				-- whether to show variable name before type hints with the inlay hints or not
				-- default: false
				show_variable_name = false,

				-- prefix for parameter hints
				-- default: "<-"
				-- parameter_hints_prefix = "<- ",
				parameter_hints_prefix = " ",

				-- prefix for all the other hints (type, chaining)
				-- default: "=>"
				-- other_hints_prefix = "=> ",
				other_hints_prefix = " ",

				-- whether to align to the lenght of the longest line in the file
				max_len_align = false,

				-- padding from the left if max_len_align is true
				max_len_align_padding = 1,

				-- whether to align to the extreme right or not
				right_align = false,

				-- padding from the right if right_align is true
				right_align_padding = 7,

				-- The color of the hints
				highlight = "Comment",
			},
			hover_actions = {
				auto_focus = true,
				border = "rounded",
				width = 60,
				-- height = 30,
			},
		},
		dap = {
			adapter = dap,
		},
    server = lsp_server
		-- server = {
		-- 	settings = {
		-- 		["rust-analyzer"] = {
		-- 			lens = {
		-- 				enable = true,
		-- 			},
		-- 			checkOnSave = {
		-- 				command = "clippy",
		-- 			},
		-- 		},
		-- 	},
		-- },
	}
end
