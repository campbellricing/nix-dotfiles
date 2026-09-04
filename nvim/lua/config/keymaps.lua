-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set
local opts = { noremap = true, silent = true }
local function extend_opts(extra)
  return setmetatable(extra or {}, { __index = opts })
end

-- Normal mode tab switching
map("n", "<Tab>", "<cmd>bnext<cr>", extend_opts({ desc = "Next tab" }))
map("n", "<S-Tab>", "<cmd>bprevious<cr>", extend_opts({ desc = "Previous tab" }))
-- Split window
map("n", "ss", ":split<Return>", extend_opts({ desc = "Horizontal split" }))
map("n", "sv", ":vsplit<Return>", extend_opts({ desc = "Vertical split" }))
