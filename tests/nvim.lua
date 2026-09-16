-- Offline checks; no init.lua, plugin downloads, or live Neovim state.
local root = assert(arg[1])
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path
for _, path in ipairs(vim.fn.glob(root .. "/**/*.lua", false, true)) do
  assert(loadfile(path))
end
assert(loadfile(root .. "/init.lua"))
require("config.options")
assert(vim.g.mapleader == " ")
assert(vim.o.expandtab and vim.o.shiftwidth == 2)
assert(vim.o.undofile and not vim.o.swapfile)

local formatter_options
package.preload.conform = function()
  return { setup = function(opts) formatter_options = opts end, format = function() end }
end
require("config.formatting")
assert(formatter_options.format_on_save == nil)
assert(formatter_options.formatters_by_ft.typescript.stop_after_first == true)

-- Exercise LSP selection without installing servers or loading lspconfig.
package.preload.cmp_nvim_lsp = function()
  return { default_capabilities = function() return {} end }
end
local enabled = {}
local configs = setmetatable({}, {
  __call = function(self, server, options)
    options.cmd = { server .. "-test-command" }
    rawset(self, server, options)
  end,
})
vim.lsp.config = configs
vim.lsp.enable = function(server) enabled[server] = true end
vim.fn.executable = function(cmd) return cmd == "lua_ls-test-command" and 1 or 0 end
require("config.lsp")
assert(enabled.lua_ls)
assert(not enabled.ts_ls and not enabled.bashls and not enabled.nil_ls)
assert(configs.lua_ls.settings.Lua.telemetry.enable == false)
assert(#vim.api.nvim_get_autocmds({ group = "DotfilesLsp" }) == 1)
print("Offline Neovim checks passed")
