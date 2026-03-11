{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;

    settings = {
      user.name  = "Martin Trenker";
      user.email = "martin@pacabytes.io";
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
      rebase.autoStash = true;

      core = {
        editor    = "nvim";
        autocrlf  = "input";
        pager     = "delta";
      };

      # https://dandavison.github.io/delta/
      delta = {
        navigate    = true;
        line-numbers = true;
        side-by-side = false;
      };

      merge.conflictstyle = "zdiff3";
      diff.algorithm      = "histogram";

      url."git@github.com:".insteadOf = "https://github.com/";
      alias = {
        st   = "status -sb";
        lg   = "log --oneline --graph --decorate --all";
        undo = "reset --soft HEAD~1";
        wip  = "!git add -A && git commit -m 'wip'";
        unwip = "!git log --oneline -1 | grep -q 'wip' && git reset HEAD~1";
      };
    };

    ignores = [
      ".DS_Store"
      "*.swp"
      "*.swo"
      ".direnv"
      ".envrc"
      "node_modules"
      "__pycache__"
      "*.pyc"
      ".venv"
      ".env"
    ];
  };

  # delta — a syntax-highlighting pager for git
  home.packages = [ pkgs.delta ];
}
