return {
  "kevinhwang91/nvim-ufo",
  dependencies = { "kevinhwang91/promise-async" },
  event = "BufReadPost",
  init = function()
    vim.o.foldcolumn = "1"
    vim.o.foldlevel = 99
    vim.o.foldlevelstart = 99
    vim.o.foldenable = true
  end,
  keys = {
    { "zR", function() require("ufo").openAllFolds() end, desc = "Open all folds" },
    { "zM", function() require("ufo").closeAllFolds() end, desc = "Close all folds" },
    { "zr", function() require("ufo").openFoldsExceptKinds() end, desc = "Open folds except kinds" },
    { "zm", function() require("ufo").closeFoldsWith() end, desc = "Close folds with" },
    { "zk", function() require("ufo").peekFoldedLinesUnderCursor() end, desc = "Peek folded lines under cursor" },
  },
  opts = {
    open_fold_hl_timeout = 150,
    -- auto-close these fold kinds when a buffer is displayed;
    -- "imports" comes from the LSP's foldingRange response
    close_fold_kinds_for_ft = {
      default = { "imports", "comment" },
    },
    -- show the folded line count instead of a raw "..." placeholder
    fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
      local newVirtText = {}
      local suffix = ("  %d lines"):format(endLnum - lnum)
      local sufWidth = vim.fn.strdisplaywidth(suffix)
      local targetWidth = width - sufWidth
      local curWidth = 0
      for _, chunk in ipairs(virtText) do
        local chunkText = chunk[1]
        local chunkWidth = vim.fn.strdisplaywidth(chunkText)
        if targetWidth > curWidth + chunkWidth then
          table.insert(newVirtText, chunk)
        else
          chunkText = truncate(chunkText, targetWidth - curWidth)
          table.insert(newVirtText, { chunkText, chunk[2] })
          chunkWidth = vim.fn.strdisplaywidth(chunkText)
          if curWidth + chunkWidth < targetWidth then
            suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
          end
          break
        end
        curWidth = curWidth + chunkWidth
      end
      table.insert(newVirtText, { suffix, "MoreMsg" })
      return newVirtText
    end,
    -- prefer LSP-provided fold ranges (has "imports" kind) for JS/TS,
    -- fall back to treesitter/indent everywhere else
    provider_selector = function(_, filetype, _)
      local ftMap = {
        javascript = { "lsp", "treesitter" },
        javascriptreact = { "lsp", "treesitter" },
        typescript = { "lsp", "treesitter" },
        typescriptreact = { "lsp", "treesitter" },
      }
      return ftMap[filetype] or { "treesitter", "indent" }
    end,
  },
}
