M = {}
local status_ok, jaq_nvim = pcall(require, "jaq-nvim")
if not status_ok then
  return
end

-- Note these are defaults. You can supply a .jaq.json to the local directory of a project
-- with the "external" and "internal"
jaq_nvim.setup {
  cmds = {
    default = "terminal",
    external = {
      typescript = "deno run %",
      javascript = "node %",
      -- markdown = "glow %",
      python = "python %",
      rust = "cargo run",
      go = "go run %",
      sh = "sh %",
    },

    -- Uses internal commands such as 'source' and 'luafile'
    internal = {
      -- lua = "luafile %",
      -- vim = "source %",
    },
  },

  behavior = {
    default = "terminal",
    startinsert = false,
    wincmd = false,
    autosave = false,
  },
  ui = {
    float = {
      border = "rounded",
      height = 0.8,
      width = 0.8,
      x = 0.5,
      y = 0.5,
      border_hl = "FloatBorder",
      float_hl = "Normal",
      blend = 0,
    },

    terminal = {
      position = "vert",
      line_no = false,
      size = 60,
    },
  },
}

return M
