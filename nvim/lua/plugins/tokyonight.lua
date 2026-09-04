return {
  {
    "folke/tokyonight.nvim",
    opts = {
      style = "moon",
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
      on_highlights = function(hl, c)
        -- Line numbers in the same colour as the current line's number
        hl.LineNr = { fg = c.orange }
        hl.LineNrAbove = { fg = c.orange }
        hl.LineNrBelow = { fg = c.orange }
        -- Groups not covered by the transparent option
        hl.NeoTreeNormal = { bg = "NONE" }
        hl.NeoTreeNormalNC = { bg = "NONE" }
        hl.TelescopeNormal = { bg = "NONE" }
        hl.LazyNormal = { bg = "NONE" }
        -- Bufferline derives its colours from these at setup
        hl.TabLine = { bg = "NONE" }
        hl.TabLineFill = { bg = "NONE" }
        hl.BufferLineFill = { bg = "NONE" }
        hl.BufferLineBackground = { bg = "NONE" }
        -- Statusline fill (the strip lualine draws on)
        hl.StatusLine = { bg = "NONE" }
        hl.StatusLineNC = { bg = "NONE" }
        -- Which-key popup
        hl.WhichKeyNormal = { bg = "NONE" }
        hl.WhichKeyBorder = { bg = "NONE" }
      end,
    },
  },
  -- Make bufferline's own highlight config transparent too (it sets its
  -- groups itself at setup, so colourscheme overrides alone aren't enough)
  {
    "akinsho/bufferline.nvim",
    optional = true,
    opts = {
      highlights = {
        fill = { bg = "none" },
        background = { bg = "none" },
        tab = { bg = "none" },
        tab_selected = { bg = "none" },
        tab_separator = { bg = "none" },
        tab_separator_selected = { bg = "none" },
        buffer_selected = { bg = "none" },
        buffer_visible = { bg = "none" },
        separator = { bg = "none" },
        separator_selected = { bg = "none" },
        separator_visible = { bg = "none" },
        close_button = { bg = "none" },
        close_button_selected = { bg = "none" },
        close_button_visible = { bg = "none" },
        modified = { bg = "none" },
        modified_selected = { bg = "none" },
        modified_visible = { bg = "none" },
        duplicate = { bg = "none" },
        duplicate_selected = { bg = "none" },
        duplicate_visible = { bg = "none" },
        indicator_selected = { bg = "none" },
        indicator_visible = { bg = "none" },
        error = { bg = "none" },
        error_selected = { bg = "none" },
        error_visible = { bg = "none" },
        error_diagnostic = { bg = "none" },
        warning = { bg = "none" },
        warning_selected = { bg = "none" },
        warning_visible = { bg = "none" },
        warning_diagnostic = { bg = "none" },
        info = { bg = "none" },
        info_selected = { bg = "none" },
        info_visible = { bg = "none" },
        info_diagnostic = { bg = "none" },
        hint = { bg = "none" },
        hint_selected = { bg = "none" },
        hint_visible = { bg = "none" },
        hint_diagnostic = { bg = "none" },
        diagnostic = { bg = "none" },
        diagnostic_selected = { bg = "none" },
        diagnostic_visible = { bg = "none" },
        numbers = { bg = "none" },
        numbers_selected = { bg = "none" },
        numbers_visible = { bg = "none" },
        pick = { bg = "none" },
        pick_selected = { bg = "none" },
        pick_visible = { bg = "none" },
        offset_separator = { bg = "none" },
        trunc_marker = { bg = "none" },
      },
    },
  },
}
