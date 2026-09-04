local function backend()
  local term = vim.env.TERM or ""
  if vim.env.KITTY_WINDOW_ID or vim.env.GHOSTTY_RESOURCES_DIR or term:find("kitty") or term:find("ghostty") then
    return "kitty"
  end
  return "ueberzug"
end

return {
  {
    "3rd/image.nvim",
    build = false,
    init = function()
      -- Claim image files before snacks.nvim's catch-all bigfile pattern
      -- (priority 0) can mark them as "bigfile" and warn about it.
      vim.filetype.add({
        pattern = {
          [".*%.png"] = { "image_nvim", { priority = 10 } },
          [".*%.jpe?g"] = { "image_nvim", { priority = 10 } },
          [".*%.gif"] = { "image_nvim", { priority = 10 } },
          [".*%.webp"] = { "image_nvim", { priority = 10 } },
          [".*%.avif"] = { "image_nvim", { priority = 10 } },
        },
      })
    end,
    opts = {
      backend = backend(),
      processor = "magick_cli",
    },
  },
}
