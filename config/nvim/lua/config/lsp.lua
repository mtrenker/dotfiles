local servers = {
  bashls = {}, jsonls = {}, marksman = {}, nil_ls = {}, ts_ls = {}, yamlls = {},
  lua_ls = { settings = { Lua = {
    diagnostics = { globals = { "vim" } }, workspace = { checkThirdParty = false },
    telemetry = { enable = false },
  } } },
}
local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- Launch from the project with `mise exec -- nvim`. No implicit mise trust,
-- installation, or cross-project PATH switching inside an existing editor.
for server, options in pairs(servers) do
  options.capabilities = capabilities
  vim.lsp.config(server, options)
  local cmd = vim.lsp.config[server].cmd
  if type(cmd) == "table" and vim.fn.executable(cmd[1]) == 1 then
    vim.lsp.enable(server)
  end
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("DotfilesLsp", { clear = true }),
  callback = function(event)
    local telescope = require("telescope.builtin")
    local function map(mode, key, action, desc)
      vim.keymap.set(mode, key, action, { buffer = event.buf, desc = desc })
    end
    map("n", "gd", telescope.lsp_definitions, "Goto definition")
    map("n", "gr", telescope.lsp_references, "References")
    map("n", "gI", telescope.lsp_implementations, "Implementations")
    map("n", "<leader>ds", telescope.lsp_document_symbols, "Document symbols")
    -- Avoid colliding with <leader>w (write file).
    map("n", "<leader>ls", telescope.lsp_dynamic_workspace_symbols, "Workspace symbols")
    map("n", "K", vim.lsp.buf.hover, "Hover")
    map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
    map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
  end,
})
