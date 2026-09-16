local conform = require("conform")
local prettier = { "prettierd", "prettier", stop_after_first = true }
conform.setup({
  -- Only resolve existing executables. No downloads and no format-on-save.
  formatters_by_ft = {
    bash = { "shfmt" }, sh = { "shfmt" }, zsh = { "shfmt" }, lua = { "stylua" },
    nix = { "nixpkgs_fmt" },
    javascript = prettier, javascriptreact = prettier,
    typescript = prettier, typescriptreact = prettier,
    json = prettier, markdown = prettier, yaml = prettier,
  },
})
vim.keymap.set({ "n", "v" }, "<leader>lf", function()
  conform.format({ async = true, lsp_format = "fallback" })
end, { desc = "Format" })
