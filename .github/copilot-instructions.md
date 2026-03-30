# Copilot Instructions

This repository is a [Nix Flake](https://nixos.wiki/wiki/Flakes) + [Home Manager](https://github.com/nix-community/home-manager) dotfiles setup for multi-host Linux configuration.

## Key commands

| Task | Command |
|------|---------|
| Apply config (alias) | `hms` or `home-manager switch --flake ~/dotfiles -b backup` |
| Apply for a specific host | `home-manager switch --flake ~/.dotfiles#work` |
| Format all `.nix` files | `nix fmt` |
| Update all flake inputs | `nix flake update` then `hms` |
| Open dotfiles in editor | `hme` |

There are no automated tests. Validate changes by running `nix fmt` and then `hms` to apply.

## Architecture

```
flake.nix                   # Entry point — registers homeConfigurations per host
home/
  common.nix                # Imported by every host; sets EDITOR, PAGER, XDG, imports programs/
  programs/                 # One file per tool; all imported from common.nix
    bash.nix                # Bash, aliases, fzf, zoxide, starship, direnv
    git.nix                 # Git settings, delta pager, aliases
    neovim.nix              # Neovim + plugins
    packages.nix            # Shared CLI packages (bat, eza, ripgrep, gh, node, dotnet…)
  hosts/
    work.nix                # Work-specific overrides (username, email, packages)
    home.nix                # Home-specific overrides
bootstrap.sh                # One-shot setup for fresh machines (installs Nix, clones repo, runs hms)
```

The flake's `mkHome` helper composes `common.nix` + `home/hosts/<hostname>.nix` for each host. All host files receive `hostname` via `extraSpecialArgs`.

## Conventions

- **Adding a program**: create `home/programs/<tool>.nix`, then add it to the `imports` list in `home/common.nix`.
- **Host-specific overrides**: add to the relevant `home/hosts/<hostname>.nix`. This is the only place to set `home.username`, `home.homeDirectory`, and per-host git email.
- **Host-specific packages**: add to `home.packages` inside the host file, not `packages.nix`.
- **Shared packages**: add to `home/programs/packages.nix`.
- **New host**: create `home/hosts/<name>.nix`, then register it in `flake.nix` under `homeConfigurations` using `mkHome "<name>"`.
- All `.nix` files use the `{ config, pkgs, ... }:` module signature. Use `with pkgs;` inside `home.packages` lists.
- `home.stateVersion` is set in `common.nix` — do not change it in host files.
- The flake targets `x86_64-linux`. For aarch64, change `system` in `flake.nix`.
