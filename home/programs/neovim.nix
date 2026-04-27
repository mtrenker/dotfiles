{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;

    extraPackages = with pkgs; [
      # Language servers
      lua-language-server
      nil
      bash-language-server
      typescript-language-server
      typescript
      vscode-langservers-extracted
      yaml-language-server
      marksman

      # Formatters
      stylua
      shfmt
      prettierd
      nixpkgs-fmt
    ];

    # Core options written as Lua (loaded as init.lua)
    initLua = ''
      -- ── Options ────────────────────────────────────────────────────────
      vim.opt.termguicolors   = true
      vim.opt.number          = true
      vim.opt.relativenumber  = true
      vim.opt.signcolumn      = "yes"
      vim.opt.cursorline      = true
      vim.opt.wrap            = false
      vim.opt.scrolloff       = 8
      vim.opt.sidescrolloff   = 8
      vim.opt.updatetime      = 250
      vim.opt.timeoutlen      = 300
      vim.opt.completeopt     = "menu,menuone,noselect"

      -- Indentation
      vim.opt.expandtab   = true
      vim.opt.tabstop     = 2
      vim.opt.shiftwidth  = 2
      vim.opt.smartindent = true

      -- Search
      vim.opt.ignorecase = true
      vim.opt.smartcase  = true
      vim.opt.hlsearch   = false
      vim.opt.incsearch  = true

      -- Splits
      vim.opt.splitright = true
      vim.opt.splitbelow = true

      -- Files
      vim.opt.swapfile = false
      vim.opt.backup   = false
      vim.opt.undofile = true

      -- Clipboard
      vim.opt.clipboard = "unnamedplus"

      -- ── Key mappings ───────────────────────────────────────────────────
      vim.g.mapleader      = " "
      vim.g.maplocalleader = "\\"

      local map = vim.keymap.set

      -- Easier window navigation
      map("n", "<C-h>", "<C-w>h")
      map("n", "<C-j>", "<C-w>j")
      map("n", "<C-k>", "<C-w>k")
      map("n", "<C-l>", "<C-w>l")

      -- Keep cursor centred when jumping
      map("n", "<C-d>", "<C-d>zz")
      map("n", "<C-u>", "<C-u>zz")
      map("n", "n",     "nzzzv")
      map("n", "N",     "Nzzzv")

      -- Move selected lines up/down
      map("v", "J", ":m '>+1<CR>gv=gv")
      map("v", "K", ":m '<-2<CR>gv=gv")

      -- Quality of life
      map("n", "<Esc>", "<cmd>nohlsearch<CR>")
      map("n", "<leader>w", "<cmd>write<CR>", { desc = "Write file" })
      map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit window" })
      map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })
      map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
      map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
      map("n", "<leader>dp", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
      map("n", "<leader>dn", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
      map("n", "<leader>ld", vim.diagnostic.open_float, { desc = "Line diagnostics" })
      map("n", "<leader>lq", vim.diagnostic.setloclist, { desc = "Diagnostics list" })
      map({ "n", "v" }, "<leader>lf", function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end, { desc = "Format" })

      -- Quick config reload
      map("n", "<leader>sv", "<cmd>source $MYVIMRC<CR>", { desc = "Reload config" })

      -- Diagnostics UI
      vim.diagnostic.config({
        severity_sort = true,
        float = { border = "rounded", source = "if_many" },
        underline = true,
        signs = true,
        virtual_text = {
          spacing = 2,
          source = "if_many",
          prefix = "●",
        },
      })

    '';

    plugins = with pkgs.vimPlugins; [
      # Colour scheme
      {
        plugin = tokyonight-nvim;
        type = "lua";
        config = ''vim.cmd.colorscheme("tokyonight-night")'';
      }

      # Status line
      {
        plugin = lualine-nvim;
        type = "lua";
        config = ''require("lualine").setup({ options = { theme = "tokyonight" } })'';
      }

      # File tree
      {
        plugin = nvim-tree-lua;
        type = "lua";
        config = ''
          require("nvim-tree").setup()
          vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file tree" })
        '';
      }

      # Fuzzy finder
      telescope-nvim
      plenary-nvim
      {
        plugin = telescope-fzf-native-nvim;
        type = "lua";
        config = ''
          local t = require("telescope.builtin")
          vim.keymap.set("n", "<leader>ff", t.find_files,  { desc = "Find files" })
          vim.keymap.set("n", "<leader>fg", t.live_grep,   { desc = "Live grep" })
          vim.keymap.set("n", "<leader>fb", t.buffers,     { desc = "Buffers" })
          vim.keymap.set("n", "<leader>fh", t.help_tags,   { desc = "Help tags" })
          vim.keymap.set("n", "<leader>fr", t.oldfiles,    { desc = "Recent files" })
          vim.keymap.set("n", "<leader>fd", t.diagnostics, { desc = "Diagnostics" })
          require("telescope").load_extension("fzf")
        '';
      }

      # Syntax highlighting
      nvim-treesitter.withAllGrammars

      # LSP
      {
        plugin = nvim-lspconfig;
        type = "lua";
        config = ''
          local map = vim.keymap.set
          local capabilities = vim.lsp.protocol.make_client_capabilities()
          local ok_cmp_lsp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
          if ok_cmp_lsp then
            capabilities = cmp_lsp.default_capabilities(capabilities)
          end
          local telescope = require("telescope.builtin")

          vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(event)
              local opts = { buffer = event.buf }

              map("n", "gd", telescope.lsp_definitions, vim.tbl_extend("force", opts, { desc = "Goto definition" }))
              map("n", "gr", telescope.lsp_references, vim.tbl_extend("force", opts, { desc = "Goto references" }))
              map("n", "gI", telescope.lsp_implementations, vim.tbl_extend("force", opts, { desc = "Goto implementation" }))
              map("n", "<leader>ds", telescope.lsp_document_symbols, vim.tbl_extend("force", opts, { desc = "Document symbols" }))
              map("n", "<leader>ws", telescope.lsp_dynamic_workspace_symbols, vim.tbl_extend("force", opts, { desc = "Workspace symbols" }))
              map("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover" }))
              map("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename symbol" }))
              map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))
            end,
          })

          local servers = {
            bashls = {},
            jsonls = {},
            lua_ls = {
              settings = {
                Lua = {
                  diagnostics = { globals = { "vim" } },
                  workspace = { checkThirdParty = false },
                  telemetry = { enable = false },
                },
              },
            },
            marksman = {},
            nil_ls = {},
            ts_ls = {},
            yamlls = {},
          }

          for server, server_opts in pairs(servers) do
            server_opts.capabilities = capabilities
            vim.lsp.config(server, server_opts)
            vim.lsp.enable(server)
          end
        '';
      }

      # Completion
      {
        plugin = luasnip;
        type = "lua";
        config = ''require("luasnip.loaders.from_vscode").lazy_load()'';
      }
      friendly-snippets
      {
        plugin = nvim-cmp;
        type = "lua";
        config = ''
          local cmp = require("cmp")
          local luasnip = require("luasnip")

          cmp.setup({
            snippet = {
              expand = function(args)
                luasnip.lsp_expand(args.body)
              end,
            },
            mapping = cmp.mapping.preset.insert({
              ["<C-Space>"] = cmp.mapping.complete(),
              ["<CR>"] = cmp.mapping.confirm({ select = true }),
              ["<Tab>"] = cmp.mapping(function(fallback)
                if cmp.visible() then
                  cmp.select_next_item()
                elseif luasnip.expand_or_jumpable() then
                  luasnip.expand_or_jump()
                else
                  fallback()
                end
              end, { "i", "s" }),
              ["<S-Tab>"] = cmp.mapping(function(fallback)
                if cmp.visible() then
                  cmp.select_prev_item()
                elseif luasnip.jumpable(-1) then
                  luasnip.jump(-1)
                else
                  fallback()
                end
              end, { "i", "s" }),
            }),
            sources = cmp.config.sources({
              { name = "nvim_lsp" },
              { name = "luasnip" },
            }, {
              { name = "buffer" },
            }),
          })
        '';
      }
      cmp-nvim-lsp
      cmp_luasnip
      cmp-buffer
      cmp-path

      # Formatting
      {
        plugin = conform-nvim;
        type = "lua";
        config = ''
          require("conform").setup({
            formatters_by_ft = {
              bash = { "shfmt" },
              javascript = { "prettierd", "prettier" },
              javascriptreact = { "prettierd", "prettier" },
              json = { "prettierd", "prettier" },
              lua = { "stylua" },
              markdown = { "prettierd", "prettier" },
              nix = { "nixpkgs_fmt" },
              sh = { "shfmt" },
              typescript = { "prettierd", "prettier" },
              typescriptreact = { "prettierd", "prettier" },
              yaml = { "prettierd", "prettier" },
              zsh = { "shfmt" },
            },
          })
        '';
      }

      # Auto-pairs
      {
        plugin = nvim-autopairs;
        type = "lua";
        config = ''require("nvim-autopairs").setup()'';
      }

      # Comment toggling
      {
        plugin = comment-nvim;
        type = "lua";
        config = ''require("Comment").setup()'';
      }

      # Which-key — shows available keybindings
      {
        plugin = which-key-nvim;
        type = "lua";
        config = ''
          local wk = require("which-key")
          wk.setup()
          wk.add({
            { "<leader>b", group = "buffer" },
            { "<leader>d", group = "document" },
            { "<leader>f", group = "find" },
            { "<leader>g", group = "git" },
            { "<leader>l", group = "language / diagnostics" },
            { "<leader>s", group = "source / settings" },
            { "<leader>w", group = "workspace" },
          })
        '';
      }

      # Git signs in the gutter
      {
        plugin = gitsigns-nvim;
        type = "lua";
        config = ''require("gitsigns").setup()'';
      }

      nvim-web-devicons
    ];
  };
}
