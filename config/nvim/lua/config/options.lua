vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
local options = {
  termguicolors = true, number = true, relativenumber = true,
  signcolumn = "yes", cursorline = true, wrap = false,
  scrolloff = 8, sidescrolloff = 8, updatetime = 250, timeoutlen = 300,
  completeopt = "menu,menuone,noselect",
  expandtab = true, tabstop = 2, shiftwidth = 2, smartindent = true,
  ignorecase = true, smartcase = true, hlsearch = false, incsearch = true,
  splitright = true, splitbelow = true, swapfile = false, backup = false,
  undofile = true, clipboard = "unnamedplus",
}
for name, value in pairs(options) do
  vim.opt[name] = value
end

local map = vim.keymap.set
for _, direction in ipairs({ "h", "j", "k", "l" }) do
  map("n", "<C-" .. direction .. ">", "<C-w>" .. direction)
end
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")
map("n", "<Esc>", "<cmd>nohlsearch<CR>")
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Write file" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit window" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })
map("n", "<leader>dp", function() vim.diagnostic.jump({ count = -1, float = true }) end,
  { desc = "Previous diagnostic" })
map("n", "<leader>dn", function() vim.diagnostic.jump({ count = 1, float = true }) end,
  { desc = "Next diagnostic" })
map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end)
map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end)
map("n", "<leader>ld", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "<leader>lq", vim.diagnostic.setloclist, { desc = "Diagnostics list" })
-- Restart Neovim to reload plugin configuration; re-sourcing init duplicates hooks.
map("n", "<leader>sv", "<cmd>edit $MYVIMRC<CR>", { desc = "Edit config" })
vim.diagnostic.config({
  severity_sort = true, float = { border = "rounded", source = "if_many" },
  underline = true, signs = true,
  virtual_text = { spacing = 2, source = "if_many", prefix = "●" },
})
