{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;

    settings = {
      user.name  = "Martin Trenker";
      user.email = "martin@pacabytes.io";
      init.defaultBranch = "main";

      color.ui = "auto";

      core = {
        editor       = "nvim";
        autocrlf     = "input";
        pager        = "delta";
        preloadindex = true;
        fscache      = true;
      };

      # https://dandavison.github.io/delta/
      delta = {
        navigate     = true;
        line-numbers = true;
        side-by-side = false;
      };

      merge = {
        tool          = "vimdiff";
        conflictstyle = "zdiff3";
      };

      diff = {
        tool      = "vimdiff";
        algorithm = "histogram";
      };

      push = {
        default          = "simple";
        autoSetupRemote  = true;
      };

      pull.rebase = true;

      rebase = {
        autoStash  = true;
        autoSquash = true;
      };

      status = {
        showUntrackedFiles = "all";
        submoduleSummary   = true;
      };

      maintenance.auto = true;

      url."git@github.com:".insteadOf = "https://github.com/";

      "credential \"https://dev.azure.com/dglecom\"".helper = "!/home/martin/dev/douglas/credentials-helper.sh dglecom";
      "credential \"https://dev.azure.com/dglas\"".helper   = "!/home/martin/dev/douglas/credentials-helper.sh dglas";

      alias = {
        # basics
        co  = "checkout";
        ci  = "commit";
        br  = "branch";
        pl  = "pull";
        ps  = "push";
        st  = "status -sb";
        df  = "diff";

        # logging
        lg     = "log --oneline --graph --decorate --all";
        ll     = "log --oneline --graph --decorate --all -10";
        last   = "log -1 HEAD";
        lol    = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";

        # undoing
        undo    = "reset --soft HEAD~1";
        unstage = "reset HEAD --";
        amend   = "commit --amend --no-edit";
        fixup   = "commit --fixup";

        # branching
        recent  = "branch --sort=-committerdate";
        cleanup = "!git branch --merged | grep -v '\\*\\|main\\|master\\|develop' | xargs -n 1 git branch -d";

        # stashing
        save = "stash push -m";
        pop  = "stash pop";

        # wip
        wip   = "!git add -A && git commit -m 'wip'";
        unwip = "!git log --oneline -1 | grep -q 'wip' && git reset HEAD~1";

        # sync
        sync = "!git fetch origin && git rebase origin/$(git branch --show-current)";
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
