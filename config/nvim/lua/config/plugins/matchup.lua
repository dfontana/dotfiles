return {
  "andymass/vim-matchup",
  lazy = false,
  config = function()
    vim.g.matchup_matchparen_offscreen = { method = nil }
    vim.g.matchup_matchpref = { html = { nolists = 1 } }
  end
}
