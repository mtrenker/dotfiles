return {
  { "folke/lazy.nvim", branch = "main", commit = "85c7ff3711b730b4030d03144f6db6375044ae82", pin = true },
  { "folke/tokyonight.nvim", lazy = false, priority = 1000,
    config = function() vim.cmd.colorscheme("tokyonight-night") end },
  { "nvim-tree/nvim-web-devicons", lazy = false },
  { "nvim-lualine/lualine.nvim", opts = { options = { theme = "tokyonight" } } },
  { "nvim-tree/nvim-tree.lua", opts = {},
    keys = { { "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "Toggle file tree" } } },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup({})
      local telescope = require("telescope.builtin")
      local mappings = {
        ff = { "find_files", "Find files" }, fg = { "live_grep", "Live grep" },
        fb = { "buffers", "Buffers" }, fh = { "help_tags", "Help tags" },
        fr = { "oldfiles", "Recent files" }, fd = { "diagnostics", "Diagnostics" },
      }
      for key, spec in pairs(mappings) do
        vim.keymap.set("n", "<leader>" .. key, telescope[spec[1]], { desc = spec[2] })
      end
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter", branch = "main", lazy = false,
    config = function()
      require("nvim-treesitter").setup({})
      -- Use available parsers only. Never download parsers or a compiler on open.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("DotfilesTreesitter", { clear = true }),
        callback = function(event)
          pcall(vim.treesitter.start, event.buf)
        end,
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "hrsh7th/cmp-nvim-lsp" },
    config = function() require("config.lsp") end,
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path",
      "saadparwaiz1/cmp_luasnip",
      { "L3MON4D3/LuaSnip", dependencies = { "rafamadriz/friendly-snippets" },
        config = function() require("luasnip.loaders.from_vscode").lazy_load() end },
    },
    config = function() require("config.completion") end,
  },
  { "stevearc/conform.nvim", config = function() require("config.formatting") end },
  { "windwp/nvim-autopairs", opts = {} },
  { "numToStr/Comment.nvim", opts = {} },
  { "lewis6991/gitsigns.nvim", opts = {} },
  {
    "folke/which-key.nvim", opts = {},
    config = function(_, opts)
      local wk = require("which-key")
      wk.setup(opts)
      wk.add({
        { "<leader>b", group = "buffer" }, { "<leader>d", group = "document" },
        { "<leader>f", group = "find" }, { "<leader>g", group = "git" },
        { "<leader>l", group = "language / diagnostics" }, { "<leader>s", group = "settings" },
        -- <leader>w already writes the file; don't assign it a group as well.
      })
    end,
  },
}
