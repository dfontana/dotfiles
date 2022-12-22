return {
  "mg979/vim-visual-multi",
  lazy = false,
  init = function()
    vim.cmd("let g:VM_quit_after_leaving_insert_mode = 1")
    vim.cmd("let g:VM_skip_empty_lines = 1")
    vim.cmd("let g:VM_default_mappings = 0")
    vim.cmd("let g:VM_mouse_mappings = 1")
    vim.cmd("let g:VM_theme = 'sand'")

    -- (More here: https://github.com/mg979/vim-visual-multi/wiki/Mappings)
    vim.cmd("let g:VM_maps = {}")
    vim.cmd("let g:VM_maps['Add Cursor Down'] = '<S-Down>'")
    vim.cmd("let g:VM_maps['Add Cursor Up'] = '<S-Up>'")
    vim.cmd("let g:VM_maps['Visual Cursors'] = '<Space-S-c>'")
  end
}
