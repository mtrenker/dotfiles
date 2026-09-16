# dotfiles

Machine setup for Arch/CachyOS using [mise bootstrap](https://mise.jdx.dev/bootstrap.html).
The `mise-bootstrap` branch is a migration in progress, not yet a complete
replacement for Home Manager. The current machine is **defiant**.

## Ownership

| Resource | Owner | Declaration |
| --- | --- | --- |
| Everyday CLI applications, Neovim, Bash | pacman | `[bootstrap.packages]` in root/host TOMLs |
| Claude Code, Codex, and Herdr (all machines) | mise tools, native binaries | `config/mise/common.toml` |
| Machine preferences and config files | mise dotfiles | `[dotfiles]` in root/host TOMLs |
| Bash mise activation | mise bootstrap | `[bootstrap.mise_shell_activate]` |
| Runtimes, SDKs, language servers, formatters, linters | Each project | `[tools]` in that project's `mise.toml` |

This repository does not install a global development toolchain. .NET belongs
in the repositories that use it, as do Node, Go, pnpm, and project language tools.
Neovim itself is a machine application; plugins/configuration are separate from
project-specific language-tool installation. Pacman may pull runtimes as application
dependencies; do not remove those to enforce this boundary.

For example, a .NET repository could declare:

```toml
[tools]
dotnet = "10"
```

Then run `mise trust` and `mise install` there. Choose the SDK required by that
project, not every SDK from the old machine setup. Use `global.json` for .NET SDK
selection: mise's default .NET backend shares `DOTNET_ROOT`, so a mise version
request alone does not isolate the SDK resolver. Use exact project versions when
needed; machine bootstrap should not decide them.

## Bootstrap this machine

Requires a recent mise with native bootstrap and global `conf.d` support
(tested with 2026.9.7), Bash, and an Arch-family system. Perform a full system
update before adding packages:

```bash
sudo pacman -Syu --needed mise git curl
cd ~/dotfiles
mise trust
bash bootstrap.sh defiant --dry-run
bash bootstrap.sh defiant
```

For another machine, clone this repository first. Until the migration is merged,
check out the `mise-bootstrap` branch (it must be pushed to clone it remotely).

All four hosts (`defiant`, `voyager`, `serenity`, `work`) use the same shared
applications and preferences. `work` additionally includes its legacy Azure Git
credential helpers; the referenced scripts/authentication must exist separately.
`defiant` additionally installs Noctalia, Docker Engine, and Docker Compose through
pacman bootstrap packages. `voyager` and `serenity` remain placeholders for future host resources.

On `defiant`, bootstrap also links the Hyprland Lua config and desktop language
preferences. Hyprland must already be installed; other hosts' desktops remain
unmanaged. Noctalia's dependencies are handled by pacman, and its settings remain
local. Bootstrap does not uninstall anything already present.

### Hyprland and Noctalia (defiant)

Defiant adds a managed Hyprland autostart block to `~/.bash_profile`. Logging in
on tty1 runs `start-hyprland`; other consoles and SSH keep normal shells. Existing
profile content is preserved. Remove any manually added equivalent autostart block
before applying, so it does not run before the managed block. The tty1 default
username is a separate system-level getty setting, not managed by bootstrap.

- `config/hypr/shared.lua`: appearance, German keyboard layout (`de`), shortcuts,
  and Noctalia autostart instead of Waybar/Mako.
- `config/hypr/hosts/defiant.lua`: monitor layout, ultrawide tiling, and existing Proton Pass agent startup.
- `config/hypr/hyprland.lua`: loads shared settings and the selected `host.lua`.
- `config/environment.d/20-desktop-language.conf`: English defaults for user services.
  Hyprland sets the same environment for directly launched applications.

Defiant defaults to scrolling with one-third-width columns, including when only
one window is open. `Super+Ctrl+Left/Right` cycles the focused column's width
through one-third, half, two-thirds, and full width (scrolling only). Existing
`Super+Arrow` focus bindings remain unchanged.

Compare layouts with `Super+Ctrl+F1` (scrolling), `Super+Ctrl+F2` (centered master,
half-width main area), and `Super+Ctrl+F3` (dwindle). These change the session-wide
default, not just the focused workspace; reloading restores scrolling. In master,
new windows join the side stack rather than replacing the main window. This is
layout configuration, not application/session restoration.

`Super+R` toggles Noctalia's launcher (`noctalia msg panel-toggle launcher`).
Noctalia also provides a control center, window switcher, screenshot tools, and
media controls; existing shortcuts are otherwise preserved. These commands target
Noctalia 5's CLI, as installed on defiant.

App language defaults to English using `C.UTF-8`, which needs no additional locale
generation. Keyboard layout stays German. Apps with their own language preferences
may need changing separately. Log out and back in after applying to start Noctalia
and refresh the language environment; a config reload does not rerun autostart or
change the language of already-running apps.

Before first applying on another installation, back up existing files under
`~/.config/hypr/` and `~/.config/environment.d/`. The host declaration links individual
files, not whole directories. Keep Noctalia's UI-managed settings local for now.

The wrapper requires an explicit host and runs `mise bootstrap --skip tools`.
The repo's bootstrap task then runs only `mise install claude codex herdr gh`, after linking
the shared global config. This avoids a broad install of unrelated personal tools.
Claude Code, Codex, Herdr, and GitHub CLI use mise's aqua backends without requiring Node/npm; btop
comes from pacman. Authentication is separate: launch `claude` or `codex` and
follow its login flow, or run `gh auth login` for GitHub CLI. Update these apps explicitly with `mise upgrade claude codex herdr gh`. It does not install Nix, reset Git changes,
change the login shell, or silently replace conflicting dotfiles.

Bootstrap links shared preferences and CLI application declarations into `~/.config/mise/conf.d/20-dotfiles.toml`,
preserving `~/.config/mise/config.toml` and unrelated fragments. Your existing
personal Node/tool choices remain untouched. No runtime versions are declared
in the managed fragment.

Open a new Bash shell for activation. Review existing unmarked mise activation
lines to avoid duplicate hooks. Desktop language variables are configured for defiant only. Custom XDG config directories are not supported by these target
paths yet.

## Tailscale

Bootstrap installs Tailscale through pacman on all hosts. Service activation and
joining a tailnet are manual, per-machine steps:

```bash
sudo systemctl enable --now tailscaled.service
sudo tailscale up
tailscale status
```

Run these after bootstrap and follow the sign-in URL from `tailscale up`.
Authentication state stays outside this repository. Bootstrap does not configure
exit nodes, subnet routes, or Tailscale SSH.

## Development containers (defiant)

Defiant declares Docker Engine and the Compose plugin in `mise.defiant.toml`.
Projects own their `compose.yaml`, image versions, and data; bootstrap only
installs the machine packages. Docker Desktop is not required.

For an existing installation, install just these packages with a full Arch update,
then activate the service and grant your login user access:

```bash
sudo pacman -Syu --needed docker docker-compose
sudo systemctl enable --now docker.service
sudo usermod -aG docker "$(id -un)"
```

The `docker` group grants root-equivalent access to the machine. Only trusted
users and tools should access the Docker socket; never make it world-writable
or expose the daemon over TCP. Use rootless Docker instead if this privilege
model is unsuitable. Bootstrap does not change group membership or enable services.

Log out of the desktop session and back in so terminals and editors inherit the
new group, then verify without sudo:

```bash
docker version
docker compose version
docker run --rm hello-world
```

The last command downloads a small test image and removes its container on exit.
Docker starts at boot; individual project services start only when requested unless
their Compose configuration specifies a restart policy.

### Project PostgreSQL example

Put this `compose.yaml` in the project repository, not in dotfiles:

```yaml
services:
  db:
    image: postgres:17
    environment:
      POSTGRES_USER: app
      POSTGRES_PASSWORD: local-dev-only
      POSTGRES_DB: app
    ports:
      - "127.0.0.1:${POSTGRES_PORT:-5432}:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app -d app"]
      interval: 2s
      timeout: 5s
      retries: 15

volumes:
  postgres-data:
```

Run from the project directory:

```bash
docker compose up -d --wait
docker compose logs -f db
docker compose exec db psql -U app -d app
docker compose down                  # preserves database data
```

Connect host applications to `127.0.0.1:5432`, database/user `app`, password
`local-dev-only`. These credentials are for disposable local development only.
The localhost binding avoids exposing PostgreSQL to the LAN or tailnet.

For simultaneous projects, set a different `POSTGRES_PORT` in each project's
local `.env` (for example `POSTGRES_PORT=5433`). Compose scopes networks and volumes
by project name, normally the directory name. For same-named checkouts or worktrees,
set distinct `COMPOSE_PROJECT_NAME` values in their `.env` files as well as distinct
ports. Avoid fixed `container_name` and explicit global volume names.

`docker compose down -v` permanently deletes the project's database volumes.
Do not use it for routine shutdown. Changing PostgreSQL major versions requires a
planned database migration; changing initialization credentials does not update an
existing database volume. This example uses the PostgreSQL 17 data path; check the
image's instructions before adopting another major version.

## Bash and Git

Shared Bash config is linked to `~/.config/bash/interactive.bash` and sourced
from a marker-owned block in `~/.bashrc`. Existing file content, including the
Proton Pass agent and personal PATH settings, stays intact. The fragment ports
aliases, `mkcd`, `up`, fzf, zoxide, direnv, and starship integration. Missing
applications are skipped; hooks initialize once per shell. Private overrides
can go in `~/.bashrc.local`. Legacy `hms`/`hme` commands and nix-direnv integration
are not carried over.

Git defaults and ignores are linked under `~/.config/git/`. A managed include
block is appended to `~/.gitconfig`: shared config, work config on the work host,
then optional `~/.gitconfig.local`. Existing file content is preserved, but later
Git includes win for single-valued settings. Put private identity or setting
overrides in `~/.gitconfig.local`; multi-valued settings follow Git's merge rules.
Git uses delta and Neovim (`nvimdiff` for diff/merge tools). The old GitHub
HTTPS-to-SSH rewrite is preserved, so GitHub access needs working SSH credentials.

Preview just configuration changes without installing applications:

```bash
mise -E defiant bootstrap --only dotfiles,shell --dry-run
```

Before applying on Defiant:

- Install the declared pacman applications. Delta and the shell integrations
  were absent during migration validation; applying Git config without delta
  would leave its pager unavailable.
- Remove the existing unmarked `eval "$(~/.local/bin/mise activate bash)"` line
  from `~/.bashrc` when adopting mise's managed activation block. Back up the file
  first. Do not remove the Proton Pass or Pi settings.
- Review conflicts. Bootstrap must not force existing files or Home Manager links.

## Neovim

`config/nvim/` is linked to `~/.config/nvim`. Requires Neovim 0.12 or newer
(tested with pacman's 0.12.5). Apply the config, then start the editor:

```bash
cd ~/dotfiles
mise -E defiant bootstrap --only dotfiles --dry-run
mise -E defiant bootstrap --only dotfiles
nvim
```

The first start downloads editor plugins with lazy.nvim. The plugin manager is
pinned and `config/nvim/lazy-lock.json` records plugin commits. Public plugin URLs
use HTTPS with explicit port 443 so the shared GitHub SSH rewrite does not require
an SSH credential for plugin downloads. Startup fails visibly if bootstrap fails;
no system packages or development tools are installed by Neovim.

Retained: Tokyo Night, lualine, file tree, Telescope, completion/snippets, LSP
integration, Conform, autopairs, comments, which-key, and gitsigns. `<Space>e`
opens the tree, `<Space>ff` finds files, `<Space>fg` searches text, and `<Space>lf`
formats explicitly. No format-on-save. `<Space>ls` searches workspace symbols;
`<Space>w` still writes the file. `<Space>sv` edits the config; restart to reload.

### Project tools

Launch from the repository whose tool environment you want:

```bash
cd /path/to/project
mise install                 # only tools that project declares
mise exec -- nvim .
```

Neovim does not trust configs, run mise installs, or download language servers.
LSP is enabled only when its command is on the inherited PATH. The migrated
server configurations cover Bash, JSON, Lua, Markdown, Nix, TypeScript, and YAML.
Other languages, including C#, need their own server configuration as well as
project-owned tools. Formatting uses existing project executables, then an
available LSP formatter; Prettierd/Prettier are alternatives, not sequential
passes. Missing tools leave editing available without those language features.

After installing a server or changing repositories, restart from that project's
environment. An existing editor does not switch its PATH per buffer. Desktop
launchers may not inherit your project's mise environment.

### Parsers and plugin updates

Treesitter uses available parsers without automatic downloads; normal syntax
highlighting remains the fallback. Unlike the Nix setup, we do not install every
grammar. If needed, install selected parsers explicitly with `:TSInstall lua`
(or another language). This requires a C compiler and tree-sitter CLI 0.26.1+
on PATH, installed separately. The native Telescope fzf extension is omitted to
avoid a mandatory compilation step; Telescope uses its built-in sorter.

Run `:Lazy update` deliberately and review the changed lockfile in this repo.
Use `:Lazy restore` to restore the recorded plugin versions. No background update
checks are enabled. `:checkhealth`, `:checkhealth vim.lsp`, and `:ConformInfo`
help diagnose missing clipboard providers, language servers, and formatters.
Desktop/clipboard packages remain deferred; Neovim may report no clipboard provider.

## Inspect and update

```bash
cd ~/dotfiles
mise -E defiant bootstrap status
bash bootstrap.sh defiant --dry-run
sudo pacman -Syu              # full Arch system upgrade
```

Update project tools from their respective repositories, not from this setup.
Do not use scoped `mise bootstrap packages upgrade` as a substitute for
`pacman -Syu`: Arch does not support partial system upgrades.

For a phase-specific operation, use mise directly, for example:
`mise -E defiant bootstrap --only dotfiles --dry-run`. Do not combine `--only`
with the wrapper's `--skip` flag.

This setup is additive. Changing host selections does not uninstall packages or
remove previous dotfiles. Review obsolete resources explicitly; there is no
automatic pruning.

## Validation

```bash
PYTHONDONTWRITEBYTECODE=1 python -m unittest discover -s tests
bash -n bootstrap.sh
bash bootstrap.sh defiant --dry-run
```

Tests check package ownership, host composition, the global AI-application allowlist,
and the wrapper's exclusion of broad tool installation. Bash tests exercise helpers and
one-time hook initialization. Native mise integration tests apply Bash/Git twice
in disposable homes, checking idempotency, preserved local content, private Git
overrides, and work-only credential configuration. Offline Neovim tests check Lua
syntax, options, formatter selection, and LSP executable gating without downloading
plugins. A separate disposable-profile smoke test installed the locked plugins and
opened a Lua buffer successfully. Dry runs do not install packages.

## Migration still pending

- Apply and verify Neovim interactively on Defiant. Bash/Git have been applied;
  the new editor configuration has only been exercised in disposable profiles.
- Decide on the desktop setup separately. Do not port the legacy Niri feature
  while desktop work is deferred.
- Migrate locale/session environment and convenience commands.
- Test package installation and shell behavior on the target machine.
- Remove old Home Manager symlinks safely, resolve file conflicts, and audit
  duplicate installs. Do not remove Nix before migrating its config sources.

`home/`, `flake.nix`, and `flake.lock` remain migration references. The new
bootstrap does not apply them. Existing application configs are not overwritten.
