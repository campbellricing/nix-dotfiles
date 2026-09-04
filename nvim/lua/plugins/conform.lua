local function has_biome_config(bufnr)
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  return vim.fs.find({ "biome.json", "biome.jsonc" }, {
    path = vim.fs.dirname(bufname),
    upward = true,
  })[1] ~= nil
end

-- Use biome when the project opts in via a biome.json(c), otherwise prettier.
-- "biome-check" (not plain "biome") so format + lint safe-fixes + assist
-- actions (e.g. organizeImports, useSortedClasses) all run on save, matching
-- what `biome check --write` would do per the project's biome.json.
local function js_formatter(bufnr)
  if has_biome_config(bufnr) then
    return { "biome-check" }
  end
  return { "prettier" }
end

return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      javascript = js_formatter,
      typescript = js_formatter,
      javascriptreact = js_formatter,
      typescriptreact = js_formatter,
      json = js_formatter,
    }
  },
}
