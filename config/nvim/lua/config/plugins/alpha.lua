return {
  "goolord/alpha-nvim",
  lazy = false,
  config = function()
    local alpha = require("alpha")
    local dashboard = require "alpha.themes.dashboard"
    local icons = require "config.icons"

    local function button(sc, txt, keybind, keybind_opts)
      local b = dashboard.button(sc, txt, keybind, keybind_opts)
      b.opts.hl_shortcut = "Macro"
      return b
    end

    dashboard.section.header.val = {
      [[  ／l、     ]],
      [[（ﾟ､ ｡７    ]],
      [[  l、ﾞ~ヽ   ]],
      [[  じし(_,)ノ]],
    }
    dashboard.section.buttons.val = {
      button("f", icons.documents.Files .. " Find file", ":Telescope find_files <CR>"),
      button("e", icons.ui.NewFile .. " New file", ":ene <BAR> startinsert <CR>"),
      button("p", icons.git.Repo .. " Find project", ":lua require('telescope').extensions.projects.projects()<CR>"),
      button("r", icons.ui.History .. " Recent files", ":Telescope oldfiles <CR>"),
      button("t", icons.ui.List .. " Find text", ":Telescope live_grep <CR>"),
      button("c", icons.ui.Gear .. " Config", ":e ~/.config/nvim/init.lua <CR>"),
      button("u", icons.ui.CloudDownload .. " Update", ":PackerSync<CR>"),
      button("q", icons.ui.SignOut .. " Quit", ":qa<CR>"),
    }

    dashboard.section.header.opts.hl = "Include"
    dashboard.section.buttons.opts.hl = "Macro"
    dashboard.section.footer.opts.hl = "Type"

    dashboard.opts.opts.noautocmd = true
    alpha.setup(dashboard.opts)
  end
}

