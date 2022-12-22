return {
  "f-person/git-blame.nvim",
  lazy = false,
  event = "BufReadPre",
  config = function()
    vim.g.gitblame_enabled = 0
    vim.g.gitblame_message_template = "<summary> • <date> • <author>"
    vim.g.gitblame_highlight_group = "LineNr"
  end
}
