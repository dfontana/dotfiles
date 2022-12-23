return {
  "akinsho/bufferline.nvim",
  lazy = false,
  dependencies = {
    "catppuccin/nvim",
  },
  config = function()
    local bufferline = require("bufferline")

    bufferline.setup {
      options = {
        numbers = "none",

        close_command = "Bdelete! %d",
        right_mouse_command = "Bdelete! %d",
        left_mouse_command = "buffer %d",
        middle_mouse_command = nil,
        indicator = {
          style = "underline",
        },
        buffer_close_icon = "",
        modified_icon = "●",
        close_icon = "",
        left_trunc_marker = "",
        right_trunc_marker = "",
        show_buffer_icons = true,
        show_buffer_close_icons = true,
        show_close_icon = true,
        show_tab_indicators = true,

        max_name_length = 30,
        max_prefix_length = 30, -- prefix used when a buffer is de-duplicated
        tab_size = 21,

        diagnostics = false,
        diagnostics_update_in_insert = false,

        offsets = { { filetype = "NvimTree", text = "", padding = 0 } },
        persist_buffer_sort = true, -- whether or not custom sorted buffers should persist
        separator_style = "thin",
        enforce_regular_tabs = true,
        always_show_bufferline = true,
      },
      highlights = require("catppuccin.groups.integrations.bufferline").get(),
    }
  end
}
