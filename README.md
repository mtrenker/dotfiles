# dotfiles

Reproducible Linux environments with [Nix](https://nixos.org/) and
[Home Manager](https://github.com/nix-community/home-manager).

## Structure

```
dotfiles/
├── flake.nix              # Entry point — defines one homeConfiguration per host
├── bootstrap.sh           # One-shot setup script for fresh machines
├── home/
│   ├── common.nix         # Shared config imported by every host
│   ├── programs/
│   │   ├── fish.nix       # Fish shell + aliases + functions
│   │   ├── git.nix        # Git config + delta pager
│   │   ├── neovim.nix     # Neovim with Lua config + plugins
│   │   └── packages.nix   # Common CLI tools + starship, zoxide, direnv
│   └── hosts/
│       ├── work.nix       # Work laptop overrides
│       └── home.nix       # Home desktop overrides
```

## Bootstrap a fresh machine

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/mtrenker/dotfiles/main/bootstrap.sh) work
```

Or clone manually:

```bash
git clone https://github.com/mtrenker/dotfiles ~/.dotfiles
bash ~/.dotfiles/bootstrap.sh work   # or: home
```

The script will:

1. Install Nix (via the
   [Determinate Systems installer](https://github.com/DeterminateSystems/nix-installer))
2. Clone this repo to `~/.dotfiles`
3. Run `home-manager switch` for the chosen host

## Daily usage

| Task              | Command                                                         |
| ----------------- | --------------------------------------------------------------- |
| Apply changes     | `hms` (alias) or `home-manager switch --flake ~/.dotfiles#work` |
| Update all inputs | `nix flake update ~/.dotfiles` then `hms`                       |
| Open dotfiles     | `hme` (alias — opens in `$EDITOR`)                              |
| Format Nix files  | `nix fmt ~/.dotfiles`                                           |

## Adding a new host

1. Copy an existing host file:
   ```bash
   cp ~/.dotfiles/home/hosts/work.nix ~/.dotfiles/home/hosts/laptop.nix
   ```
2. Edit `laptop.nix` — set `home.username`, `home.homeDirectory`, any overrides.
3. Register it in `flake.nix`:
   ```nix
   homeConfigurations = {
     work   = mkHome "work";
     home   = mkHome "home";
     laptop = mkHome "laptop";   # ← add this
   };
   ```
4. Apply: `home-manager switch --flake ~/.dotfiles#laptop`

## Customising

- **Packages**: edit `home/programs/packages.nix`
- **Shell aliases / functions**: edit `home/programs/fish.nix`
- **Neovim plugins**: edit `home/programs/neovim.nix`
- **Git identity**: set per-host in `home/hosts/<hostname>.nix`
- **Host-specific packages**: add to `home.packages` in the host file

## Requirements

- Linux (x86_64 or aarch64 — change `system` in `flake.nix` for aarch64)
- Internet connection (first run only)
- `git` and `curl` pre-installed (standard on most distros)
