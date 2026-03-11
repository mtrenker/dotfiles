{ config, pkgs, ... }:

{
  programs.fish = {
    enable = true;

    shellInit = ''
      # Suppress the greeting
      set fish_greeting

      # Aliases (defined here so they work in all shell modes)
      alias ..  'cd ..'
      alias ... 'cd ../..'
      alias ls  'eza --group-directories-first'
      alias ll  'eza -lh --group-directories-first'
      alias la  'eza -lah --group-directories-first'
      alias tree 'eza --tree'
      alias cat 'bat --paging=never'
      alias grep rg
      alias find fd
      alias g    git
      alias ga   'git add'
      alias gc   'git commit'
      alias gco  'git checkout'
      alias gd   'git diff'
      alias gl   'git log --oneline --graph --decorate'
      alias gp   'git push'
      alias gs   'git status -sb'
      alias hms  'home-manager switch --flake ~/.dotfiles'
      alias hme  '$EDITOR ~/.dotfiles'

      # fzf key bindings (if fzf is installed)
      if type -q fzf
        fzf --fish | source
      end
    '';

    shellAliases = {};

    # Functions
    functions = {
      # Quick `mkcd` — mkdir + cd
      mkcd = {
        body = "mkdir -p $argv[1] && cd $argv[1]";
        description = "Create a directory and cd into it";
      };
      # `up N` — go N directories up
      up = {
        body = ''
          set count (math (string trim -- $argv[1]) 2>/dev/null; or echo 1)
          for i in (seq $count)
            cd ..
          end
        '';
        description = "Go N directories up";
      };
    };
  };
}
