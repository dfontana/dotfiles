return {
  settings = {
    Lua = {
      hint = {
        enable = true,
        arrayIndex = "Disable", -- "Enable", "Auto", "Disable"
        await = true,
        paramName = "Disable", -- "All", "Literal", "Disable"
        paramType = false,
        semicolon = "Disable", -- "All", "SameLine", "Disable"
        setType = true,
      },
      runtime = {
        version = "LuaJIT",
        special = {
          reload = "require",
        },
      },
      diagnostics = {
        globals = { "vim" },
      },
      workspace = {
        library = {
          library = vim.api.nvim_get_runtime_file("", true),
          -- [vim.fn.expand "$VIMRUNTIME/lua"] = true,
          -- [vim.fn.stdpath "config" .. "/lua"] = true,
        },
      },
      telemetry = {
        enable = false,
      },
    },
  },
}
