return {
  "kyazdani42/nvim-web-devicons",
  lazy = false,
  config = function()
    require("nvim-web-devicons").set_icon({
      sh = {
        icon = "",
        color = "#1DC123",
        cterm_color = "61",
        name = "Sy",
      },
      ["py"] = {
        icon = "",
        color = "#519BB7",
        cterm_color = "59",
        name = "Py",
      },
      [".gitattributes"] = {
        icon = "",
        color = "#e24329",
        cterm_color = "59",
        name = "GitAttributes",
      },
      [".gitconfig"] = {
        icon = "",
        color = "#e24329",
        cterm_color = "59",
        name = "GitConfig",
      },
      [".gitignore"] = {
        icon = "",
        color = "#e24329",
        cterm_color = "59",
        name = "GitIgnore",
      },
      [".gitlab-ci.yml"] = {
        icon = "",
        color = "#e24329",
        cterm_color = "166",
        name = "GitlabCI",
      },
      [".gitmodules"] = {
        icon = "",
        color = "#e24329",
        cterm_color = "59",
        name = "GitModules",
      },
      ["diff"] = {
        icon = "",
        color = "#e24329",
        cterm_color = "59",
        name = "Diff",
      },
    })
  end
}
