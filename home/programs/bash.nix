{ config, pkgs, ... }:

{
  programs.bash = {
    enable = true;

    shellAliases = {
      ".."   = "cd ..";
      "..."  = "cd ../..";
      ls     = "eza --group-directories-first";
      ll     = "eza -lh --group-directories-first";
      la     = "eza -lah --group-directories-first";
      tree   = "eza --tree";
      cat    = "bat --paging=never";
      grep   = "rg";
      find   = "fd";
      g      = "git";
      ga     = "git add";
      gc     = "git commit";
      gco    = "git checkout";
      gd     = "git diff";
      gl     = "git log --oneline --graph --decorate";
      gp     = "git push";
      gs     = "git status -sb";
      hms    = "home-manager switch --flake ~/dotfiles -b backup";
      hme    = "\${EDITOR} ~/dotfiles";
    };

    initExtra = ''
      # Create a directory and cd into it
      mkcd() {
        mkdir -p "$1" && cd "$1"
      }

      # Go N directories up (default: 1)
      up() {
        local count=''${1:-1}
        for _ in $(seq "$count"); do
          cd ..
        done
      }
    '';
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      add_newline = true;
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol   = "[❯](bold red)";
      };
      nix_shell.disabled = false;
    };
  };

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
  };
}
