# dotfiles

Machine setup for Arch/CachyOS using [mise bootstrap](https://mise.jdx.dev/bootstrap.html).
Mise manages bootstrap and dotfiles; pacman installs machine applications.
The current machine is **defiant**. Nix and Home Manager are no longer used by
this repository.

## Ownership

| Resource | Owner | Declaration |
| --- | --- | --- |
| Everyday CLI applications, Neovim, Bash | pacman | `[bootstrap.packages]` in root/host TOMLs |
| Claude Code, Codex, Pi, and Herdr (all machines) | mise tools, native binaries | `config/mise/common.toml` |
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
pacman bootstrap packages. `voyager` additionally installs Proton Pass CLI and
Hugging Face CLI (`hf`), Docker Engine, and Docker Compose; `serenity` remains a
placeholder for future host resources.

On `defiant`, bootstrap also links the Hyprland Lua config and desktop language
preferences. Hyprland must already be installed; other hosts' desktops remain
unmanaged. Noctalia's dependencies are handled by pacman. Its idle policy is
managed on Defiant; other settings remain local. Bootstrap does not uninstall
anything already present.

### Hyprland and Noctalia (defiant)

Defiant adds a managed Hyprland autostart block to `~/.bash_profile`. Logging in
on tty1 runs `start-hyprland`; other consoles and SSH keep normal shells. Existing
profile content is preserved. Remove any manually added equivalent autostart block
before applying, so it does not run before the managed block. The tty1 default
username is a separate system-level getty setting, not managed by bootstrap.

- `config/hypr/shared.lua`: appearance, German keyboard layout (`de`), shortcuts,
  and Noctalia autostart instead of Waybar/Mako.
- `config/hypr/hosts/defiant.lua`: monitor layout, ultrawide tiling, and the Proton Pass SSH socket environment.
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

`Super+Shift+S` lets you drag-select an area and copies the screenshot to the
clipboard for pasting with `Ctrl+V`. Press `Esc` to cancel without replacing the
clipboard. No file is saved. The binding lives in `config/hypr/shared.lua`;
`mise.defiant.toml` declares `grim`, `slurp`, and `wl-clipboard` as dependencies.
`Super+Ctrl+S` moves the focused window to the scratchpad; `Super+S` toggles it.

App language defaults to English using `C.UTF-8`, which needs no additional locale
generation. Keyboard layout stays German. Apps with their own language preferences
may need changing separately. Log out and back in after applying to start Noctalia
and refresh the language environment; a config reload does not rerun autostart or
change the language of already-running apps.

Before first applying on another installation, back up existing files under
`~/.config/hypr/` and `~/.config/environment.d/`. The host declaration links individual
files, not whole directories. Keep Noctalia's UI-managed settings local for now.

### Idle power management (defiant)

Mise links `config/noctalia/defiant-idle.toml` to
`~/.config/noctalia/20-idle.toml`. Noctalia turns monitors off after **5 minutes**
of inactivity and suspends Defiant after **1 hour** of inactivity (both measured
from the last activity). It restores monitors on activity. There is no automatic
lock, including before idle suspend; manual locking remains available.

Noctalia handles idle inhibition, so do not start a second idle manager such as
Hypridle or Swayidle. For long-running agents or remote work, enable Noctalia's
caffeine mode to prevent idle actions:

```bash
noctalia msg caffeine-enable
# Restore normal idle timers when finished:
noctalia msg caffeine-disable
```

Running jobs alone do not prevent idle suspend. Suspended Defiant pauses agents
and is unavailable over SSH until it wakes. Voyager has no desktop idle policy
and remains always-on.

The fragment hot-reloads; validate the effective settings with
`noctalia config validate` and inspect them with `noctalia config export full`.
GUI changes in `~/.local/state/noctalia/settings.toml` take precedence over this
fragment. Remove only conflicting idle overrides there if the managed policy
stops taking effect; do not delete unrelated settings.

The wrapper requires an explicit host and runs `mise bootstrap --skip tools`.
The repo's bootstrap task then runs only `mise install claude codex pi herdr gh`, after linking
the shared global config. This avoids a broad install of unrelated personal tools.
Claude Code, Codex, Pi, Herdr, and GitHub CLI use mise's aqua backends without requiring Node/npm; btop
comes from pacman. Authentication is separate: launch `claude` or `codex` and
follow its login flow, launch `pi` and use `/login`, or run `gh auth login` for GitHub CLI. Update these apps explicitly with `mise upgrade claude codex pi herdr gh`. It does not install Nix, reset Git changes,
change the login shell, or silently replace conflicting dotfiles.

Bootstrap links shared preferences and CLI application declarations into `~/.config/mise/conf.d/20-dotfiles.toml`,
preserving `~/.config/mise/config.toml` and unrelated fragments. Your existing
personal Node/tool choices remain untouched. No runtime versions are declared
in the managed fragment.

Open a new Bash shell for activation. Review existing unmarked mise activation
lines to avoid duplicate hooks. Desktop language variables are configured for defiant only. Custom XDG config directories are not supported by these target
paths yet.

## Proton Drive CLI (opt-in)

After the shared mise config is linked, install the official standalone CLI:

```bash
mise run proton-drive:install
proton-drive auth login
proton-drive filesystem list /my-files
```

The task pins version 0.8.0, verifies Proton's published SHA-512 checksum, and
atomically installs `~/.local/bin/proton-drive`. Ensure `~/.local/bin` is on PATH.
It uses the Linux x86_64 baseline build, which does not require AVX2. Bun is
embedded; no separate runtime is installed. Bootstrap does not run this task.
Update the version and checksum together in `config/mise/common.toml` using the
[official download page](https://proton.me/download/drive/cli/index.html), then
rerun the task. `mise upgrade` does not update this task-managed binary.

Login is manual and uses the existing, unlocked desktop secret store (`libsecret`
and GNOME Keyring on defiant). Leave credentials and the CLI's default XDG
cache/data/log directories outside this repository. The `pass` credential backend
means password-store/GPG, not Proton Pass. Do not use `unsafe_file`.

This installs a transfer CLI, not a background sync service. Scheduled uploads,
retention, and restore testing require separate configuration.

## Voyager: Proton Pass and Hugging Face CLI

On Voyager, run:

```bash
bash bootstrap.sh voyager --dry-run
bash bootstrap.sh voyager
export PATH="$HOME/.local/bin:$PATH"
pass-cli login
hf auth login
hf auth whoami
```

Voyager installs `hf` through pacman's `python-huggingface-hub` package and
Proton Pass CLI 2.4.1 at `~/.local/bin/pass-cli`. Its bootstrap task installs the
shared mise applications, then runs `scripts/install-pass-cli.sh`, which verifies
Proton's published SHA-256 before atomically replacing the binary. An unchanged,
verified installation is skipped. Keep `~/.local/bin` on PATH. To update Pass,
change the version and checksum together using Proton's
[release manifest](https://proton.me/download/pass-cli/versions.json) and rerun
bootstrap. Pacman updates `hf`.

Authentication is manual; credentials stay outside this repository. Voyager also
links the Proton Pass SSH agent service and socket environment described below.
Its desktop remains unmanaged.

## Proton Pass SSH agent (defiant and voyager)

On Defiant, install `pass-cli` at `~/.local/bin/pass-cli` separately; Voyager's
bootstrap installs it. Authenticate/unlock it manually on either machine.
Each host also links a `proton-pass-ssh-agent.service.d/vault.conf` override:
Defiant loads keys only from the `defiant` vault; Voyager only from `voyager`.
These names are exact. Create the vaults and move the corresponding SSH key
items into them before starting the services. This filters exposed identities;
it is not an access boundary if the signed-in account can access both vaults.

After bootstrap links the service and override, enable it once per machine:

```bash
pass-cli ssh-agent daemon stop  # only when switching from the old daemon
systemctl --user daemon-reload
systemctl --user enable --now proton-pass-ssh-agent.service
ssh-add -l
```

The user service starts at login and restarts after failures with a 30-second delay.
Defiant's Hyprland and both hosts' user services use
`$XDG_RUNTIME_DIR/proton-pass-agent.sock`. Voyager also gets a managed Bash block
that sets `SSH_AUTH_SOCK`, preserving an existing forwarded agent in SSH sessions.
Open a new shell after applying; log out and back in for desktop applications to
inherit the environment. Keep any other shell-level socket overrides consistent.
Do not also start the CLI daemon.
Unlocking Pass remains manual; after unlocking, use
`systemctl --user restart proton-pass-ssh-agent.service` to retry immediately.
Check service status with `systemctl --user status proton-pass-ssh-agent.service`
and logs with `journalctl --user -u proton-pass-ssh-agent.service`.
`pass-cli ssh-agent daemon status` tracks the old daemon, not this systemd service.
After changing a vault override, run `systemctl --user daemon-reload` and restart
the service. Verify the local agent explicitly, even inside forwarded SSH sessions:

```bash
SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/proton-pass-agent.sock" ssh-add -l
```

## Persistent Herdr server (voyager)

Voyager links `config/systemd/user/herdr.service` through mise. The service starts
Herdr through mise in a fresh kernel session keyring and links the user's
persistent keyring. This avoids inheriting an SSH login keyring that
`pam_keyinit.so force revoke` revokes when the originating connection ends.
Reconnecting a client cannot repair an already revoked server keyring.

Bootstrap only links the unit. To switch, first finish or stop all work in
Voyager's Herdr panes. Run the following from a **plain SSH session**, not a
Herdr pane, and keep Herdr clients disconnected until the service is started:

```bash
ssh voyager
herdr server stop  # stops existing panes and agents on Voyager
systemctl --user daemon-reload
systemctl --user enable --now herdr.service
systemctl --user status herdr.service
```

Reconnect Herdr after the service is running. For persistence beyond the last
login, enable user lingering with `loginctl enable-linger "$USER"` (already
enabled on Voyager). Do not run a second Herdr server for the default session.
Named sessions are not covered by this unit. Stopping/restarting this service
also stops its panes; schedule such changes rather than doing them in bootstrap.
Herdr updates that restart or hand off the server need coordination with this
service; the unit does not implement live handoff.

This does not unlock Proton Pass or persist kernel-held keys across reboot.
Authenticate Pass manually when needed, then restart its SSH agent service.
No PAM protections are disabled and no credentials are stored in dotfiles.

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

## Development containers (defiant and voyager)

Defiant and Voyager declare Docker Engine and the Compose plugin in their host TOMLs.
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
highlighting remains the fallback. We do not install every grammar. If needed, install selected parsers explicitly with `:TSInstall lua`
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

## Remaining machine setup

- Apply and verify Neovim interactively on Defiant. Bash/Git have been applied;
  the new editor configuration has only been exercised in disposable profiles.
- Verify desktop and locale/session settings on each host. Defiant uses Hyprland;
  desktop setup for other hosts remains deferred.
- Add convenience commands as needed.
- Test package installation and shell behavior on the target machine.
- Audit old Home Manager symlinks and duplicate installs before uninstalling Nix
  on existing machines. Back up any active configs pointing into `/nix/store`,
  replace them with mise-managed configs, and verify a fresh shell/session first.
  Removing repository files does not uninstall Nix or clean up its shell hooks.

The former `home/`, `flake.nix`, and `flake.lock` are available in Git history,
not part of the supported setup. Bootstrap does not overwrite existing application
configs or automatically remove legacy machine state.
