return {
  "junegunn/vim-slash",
  lazy = false,
  config = function()
    vim.cmd [[noremap <plug>(slash-after) zz]]
  end
}
