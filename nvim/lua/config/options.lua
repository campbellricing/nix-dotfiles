-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.clipboard = 'unnamedplus'
vim.opt.scrolloff = 10       -- scroll offset
vim.opt.inccommand = "split" -- previews changes before replace
vim.opt.wrap = true
vim.opt.breakindent = true   -- indents wrapped lines
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.wildignore:append({ "*/node_modules/*" }) -- ignores node_modules folder
vim.opt.fillchars = { fold = " " }
vim.opt.foldlevel = 99
vim.g.snacks_animate = false
