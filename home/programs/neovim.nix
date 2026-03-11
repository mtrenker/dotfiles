{ config, pkgs, ... }:

{
  programs.neovim = {
    enable      = true;
    defaultEditor = true;
    vimAlias    = true;
    viAlias     = true;

    # Core options written as Lua (loaded as init.lua)
    initLua = ''
      -- ── Options ────────────────────────────────────────────────────────
      vim.opt.number         = true
      vim.opt.relativenumber = true
      vim.opt.signcolumn     = "yes"
      vim.opt.cursorline     = true
      vim.opt.wrap           = false
      vim.opt.scrolloff      = 8
      vim.opt.sidescrolloff  = 8

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

      -- Quick config reload
      map("n", "<leader>sv", "<cmd>source $MYVIMRC<CR>", { desc = "Reload config" })
    '';

    plugins = with pkgs.vimPlugins; [
      # Colour scheme
      {
        plugin = tokyonight-nvim;
        type   = "lua";
        config = ''vim.cmd.colorscheme("tokyonight-night")'';
      }

      # Status line
      {
        plugin = lualine-nvim;
        type   = "lua";
        config = ''require("lualine").setup({ options = { theme = "tokyonight" } })'';
      }

      # File tree
      {
        plugin = nvim-tree-lua;
        type   = "lua";
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
        type   = "lua";
        config = ''
          local t = require("telescope.builtin")
          vim.keymap.set("n", "<leader>ff", t.find_files,  { desc = "Find files" })
          vim.keymap.set("n", "<leader>fg", t.live_grep,   { desc = "Live grep" })
          vim.keymap.set("n", "<leader>fb", t.buffers,     { desc = "Buffers" })
          vim.keymap.set("n", "<leader>fh", t.help_tags,   { desc = "Help tags" })
          require("telescope").load_extension("fzf")
        '';
      }

      # Syntax highlighting
      {
        plugin = nvim-treesitter.withAllGrammars;
        type   = "lua";
        config = ''require("nvim-treesitter").setup()'';
      }

      # Auto-pairs
      {
        plugin = nvim-autopairs;
        type   = "lua";
        config = ''require("nvim-autopairs").setup()'';
      }

      # Comment toggling
      {
        plugin = comment-nvim;
        type   = "lua";
        config = ''require("Comment").setup()'';
      }

      # Which-key — shows available keybindings
      {
        plugin = which-key-nvim;
        type   = "lua";
        config = ''require("which-key").setup()'';
      }

      # Git signs in the gutter
      {
        plugin = gitsigns-nvim;
        type   = "lua";
        config = ''require("gitsigns").setup()'';
      }

      nvim-web-devicons
    ];
  };
}
