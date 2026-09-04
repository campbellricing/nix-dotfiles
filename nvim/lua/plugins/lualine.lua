return {
  "nvim-lualine/lualine.nvim",
  opts = {
    sections = {
      lualine_a = { { "mode", separator = { left = '', right = '' }, right_padding = 2 } },
      lualine_c = { { "filename", separator = { right = '' }, right_padding = 2 } },
      lualine_x = {},
      lualine_y = {},
      lualine_z = { { "location", separator = { left = '', right = '' } } },
    },
  },
}
