return {
  "kyazdani42/nvim-tree.lua",
  lazy = false,
  config = function()
    local nvim_tree = require("nvim-tree")
    local nvim_tree_config = require("nvim-tree.config")
    local icons = require "config.icons"
    local tree_cb = nvim_tree_config.nvim_tree_callback
    nvim_tree.setup {
      hijack_directories = {
        enable = false,
      },
      ignore_ft_on_setup = {
        "startify",
        "dashboard",
        "alpha",
      },
      update_cwd = true,
      renderer = {
        add_trailing = false,
        group_empty = false,
        highlight_git = false,
        highlight_opened_files = "name",
        root_folder_modifier = ":t",
        indent_markers = {
          enable = true,
          icons = {
            corner = "└ ",
            edge = "│ ",
            none = "  ",
          },
        },
        icons = {
          webdev_colors = true,
          git_placement = "before",
          padding = " ",
          symlink_arrow = " ➛ ",
          show = {
            file = true,
            folder = true,
            folder_arrow = true,
            git = true,
          },
          glyphs = {
            default = "",
            symlink = "",
            folder = {
              arrow_open = icons.ui.ArrowOpen,
              arrow_closed = icons.ui.ArrowClosed,
              default = "",
              open = "",
              empty = "",
              empty_open = "",
              symlink = "",
              symlink_open = "",
            },
            git = {
              unstaged = "",
              staged = "S",
              unmerged = "",
              renamed = "➜",
              untracked = "U",
              deleted = "",
              ignored = "◌",
            },
          },
        },
      },
      diagnostics = {
        enable = true,
        icons = {
          hint = icons.diagnostics.Hint,
          info = icons.diagnostics.Information,
          warning = icons.diagnostics.Warning,
          error = icons.diagnostics.Error,
        },
      },
      update_focused_file = {
        enable = true,
        update_cwd = true,
        ignore_list = {},
      },
      actions = {
        open_file = {
          resize_window = true,
        }
      },
      git = {
        enable = true,
        ignore = false,
        timeout = 500,
      },
      view = {
        width = 30, 
        hide_root_folder = false,
        side = "left",
        adaptive_size = true,
        mappings = {
          custom_only = false,
          list = {
            { key = { "l", "<CR>", "o" }, cb = tree_cb "edit" },
            { key = "h", cb = tree_cb "close_node" },
            { key = "v", cb = tree_cb "vsplit" },
          },
        },
        number = false,
        relativenumber = false,
      },
    }
  end
}
