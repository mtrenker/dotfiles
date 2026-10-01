"""Offline checks: python -m unittest discover -s tests."""
import os
import pathlib
import subprocess
import tempfile
import tomllib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
HOSTS = ("defiant", "voyager", "serenity", "work")
COMMON_TARGET = "~/.config/mise/conf.d/20-dotfiles.toml"


def load(path):
    return tomllib.loads((ROOT / path).read_text())


class ConfigTests(unittest.TestCase):
    def test_machine_configs_do_not_install_toolchains(self):
        for name in ("mise.toml", *(f"mise.{h}.toml" for h in HOSTS)):
            config = load(name)
            self.assertNotIn("tools", config, name)
            if name == "mise.toml":
                self.assertEqual(config["tasks"]["bootstrap"]["run"], "mise install claude codex pi herdr gh")
            elif name == "mise.voyager.toml":
                self.assertEqual(config["tasks"]["bootstrap"]["run"], [
                    load("mise.toml")["tasks"]["bootstrap"]["run"],
                    'bash "{{config_root}}/scripts/install-pass-cli.sh"',
                ])
            else:
                self.assertNotIn("tasks", config, name)
            for package, version in config.get("bootstrap", {}).get("packages", {}).items():
                self.assertTrue(package.startswith("pacman:"), package)
                self.assertEqual(version, "latest", package)

    def test_global_fragments_only_contain_preferences_and_ai_apps(self):
        paths = list((ROOT / "config/mise").glob("*.toml"))
        self.assertEqual([p.name for p in paths], ["common.toml"])
        for path in paths:
            config = tomllib.loads(path.read_text())
            self.assertEqual(set(config), {"env", "tools", "tasks"})
            self.assertEqual(set(config["tasks"]), {"default-browser", "proton-drive:install"})
            self.assertEqual(config["tools"], {"claude": "latest", "codex": "latest", "pi": "latest", "herdr": "latest", "gh": "latest"})
            self.assertNotIn("config_root", path.read_text())

    def test_proton_drive_installer(self):
        script = load("config/mise/common.toml")["tasks"]["proton-drive:install"]["run"]
        subprocess.run(["bash", "-n"], input=script, text=True, check=True)
        self.assertIn("version=0.8.0", script)
        self.assertIn("platform=linux-x64-baseline", script)
        self.assertRegex(script, r"sha512=[0-9a-f]{128}\n")
        self.assertLess(script.index("sha512sum --check"), script.index("chmod 755"))
        self.assertIn("mv -fT", script)
        self.assertNotIn("proton-drive", load("mise.toml")["tasks"]["bootstrap"]["run"])

    def test_pass_cli_installer(self):
        script = (ROOT / "scripts/install-pass-cli.sh").read_text()
        subprocess.run(["bash", "-n"], input=script, text=True, check=True)
        self.assertIn("version=2.4.1", script)
        self.assertRegex(script, r"sha256=[0-9a-f]{64}\n")
        self.assertLess(script.index('"$staging/pass-cli" | sha256sum --check'),
                        script.index("chmod 755"))
        self.assertIn("mv -fT", script)
        self.assertNotIn("pass-cli", load("mise.toml")["tasks"]["bootstrap"]["run"])

    def test_host_composition_and_sources(self):
        base = load("mise.toml")
        self.assertIn(COMMON_TARGET, base["dotfiles"])
        for host in HOSTS:
            config = load(f"mise.{host}.toml")
            if host == "defiant":
                self.assertEqual(config["bootstrap"]["packages"], {
                    "pacman:noctalia": "latest",
                    "pacman:grim": "latest",
                    "pacman:slurp": "latest",
                    "pacman:wl-clipboard": "latest",
                    "pacman:docker": "latest",
                    "pacman:docker-compose": "latest",
                })
            elif host == "voyager":
                self.assertEqual(config["bootstrap"]["packages"], {
                    "pacman:python-huggingface-hub": "latest",
                    "pacman:docker": "latest",
                    "pacman:docker-compose": "latest",
                    "pacman:keyutils": "latest",
                })
            else:
                self.assertNotIn("bootstrap", config, host)
            entries = base["dotfiles"] | config.get("dotfiles", {})
            self.assertEqual("~/.config/git/dotfiles-work.gitconfig" in entries, host == "work")
            for target, entry in entries.items():
                if "source" in entry:
                    self.assertEqual(entry["mode"], "symlink")
                    self.assertTrue((ROOT / entry["source"]).exists(), target)
                else:
                    self.assertIn("block", entry, target)

    def test_desktop_and_project_packages_are_not_shared(self):
        excluded = {
            "niri", "noctalia", "noctalia-shell", "ghostty", "foot", "fuzzel", "waybar",
            "mako", "swaybg", "swaylock", "wl-clipboard", "grim", "slurp",
            "brightnessctl", "playerctl", "xdg-desktop-portal-gnome",
            "xdg-desktop-portal-gtk", "nodejs", "npm", "pnpm", "go",
            "dotnet-sdk", "base-devel", "docker", "docker-compose",
        }
        packages = load("mise.toml")["bootstrap"]["packages"]
        self.assertFalse(excluded.intersection(p.removeprefix("pacman:") for p in packages))

    def test_tailscale_is_a_shared_system_package(self):
        packages = load("mise.toml")["bootstrap"]["packages"]
        self.assertEqual(packages["pacman:tailscale"], "latest")

    def test_shared_font_coverage(self):
        packages = load("mise.toml")["bootstrap"]["packages"]
        for package in ("noto-fonts", "noto-fonts-cjk", "noto-fonts-emoji"):
            self.assertEqual(packages[f"pacman:{package}"], "latest")

    def test_hyprland_is_host_scoped(self):
        expected = {
            "~/.config/hypr/hyprland.lua": "config/hypr/hyprland.lua",
            "~/.config/hypr/shared.lua": "config/hypr/shared.lua",
            "~/.config/hypr/host.lua": "config/hypr/hosts/defiant.lua",
            "~/.config/environment.d/20-desktop-language.conf":
                "config/environment.d/20-desktop-language.conf",
            "~/.config/environment.d/30-proton-pass-ssh.conf":
                "config/environment.d/30-proton-pass-ssh.conf",
            "~/.config/systemd/user/proton-pass-ssh-agent.service":
                "config/systemd/user/proton-pass-ssh-agent.service",
        }
        for host in HOSTS:
            entries = load("mise.toml")["dotfiles"] | load(f"mise.{host}.toml").get("dotfiles", {})
            for target, source in expected.items():
                if host == "defiant" or (host == "voyager" and "proton-pass" in target):
                    self.assertEqual(entries[target], {"source": source, "mode": "symlink"})
                else:
                    self.assertNotIn(target, entries)

    def test_pass_agent_vault_is_host_scoped(self):
        target = "~/.config/systemd/user/proton-pass-ssh-agent.service.d/vault.conf"
        for host in HOSTS:
            entries = load(f"mise.{host}.toml").get("dotfiles", {})
            if host not in ("defiant", "voyager"):
                self.assertNotIn(target, entries)
                continue
            source = f"config/systemd/user/proton-pass-ssh-agent.{host}.conf"
            self.assertEqual(entries[target], {"source": source, "mode": "symlink"})
            self.assertEqual((ROOT / source).read_text(),
                             "[Service]\nExecStart=\n"
                             "ExecStart=%h/.local/bin/pass-cli ssh-agent start "
                             "--socket-path %t/proton-pass-agent.sock "
                             f"--vault-name {host}\n")

    def test_voyager_herdr_service(self):
        target = "~/.config/systemd/user/herdr.service"
        for host in HOSTS:
            self.assertEqual(target in load(f"mise.{host}.toml").get("dotfiles", {}),
                             host == "voyager")
        service = (ROOT / "config/systemd/user/herdr.service").read_text()
        self.assertIn("ExecStart=/usr/bin/keyctl session - /bin/bash -c", service)
        self.assertIn("get_persistent @s > /dev/null && exec /usr/bin/mise exec herdr -- herdr server", service)
        self.assertIn("WorkingDirectory=%h", service)
        self.assertIn("KillMode=control-group", service)

    def test_voyager_agent_shell_environment(self):
        block = load("mise.voyager.toml")["dotfiles"]["~/.bashrc/proton-pass-ssh"]["block"]
        for connection, original, expected in (
            ("", "", "/run/user/1234/proton-pass-agent.sock"),
            ("ssh-session", "", "/run/user/1234/proton-pass-agent.sock"),
            ("ssh-session", "/tmp/forwarded-agent", "/tmp/forwarded-agent"),
        ):
            env = dict(os.environ, XDG_RUNTIME_DIR="/run/user/1234",
                       SSH_CONNECTION=connection, SSH_AUTH_SOCK=original)
            result = subprocess.run(["bash", "-c", block + '\nprintf "%s" "$SSH_AUTH_SOCK"'],
                                    env=env, text=True, capture_output=True, check=True)
            self.assertEqual(result.stdout, expected)

    def test_defiant_idle_policy(self):
        target = "~/.config/noctalia/20-idle.toml"
        source = "config/noctalia/defiant-idle.toml"
        self.assertNotIn(target, load("mise.toml")["dotfiles"])
        for host in HOSTS:
            entries = load(f"mise.{host}.toml").get("dotfiles", {})
            if host == "defiant":
                self.assertEqual(entries[target], {"source": source, "mode": "symlink"})
            else:
                self.assertNotIn(target, entries)
        idle = load(source)["idle"]
        self.assertEqual(idle["behavior_order"], ["screen-off", "suspend"])
        self.assertEqual(idle["pre_action_fade_seconds"], 0)
        behaviors = idle["behavior"]
        self.assertFalse(behaviors["lock"]["enabled"])
        self.assertFalse(behaviors["lock-and-suspend"]["enabled"])
        self.assertEqual(behaviors["screen-off"], {
            "enabled": True, "action": "screen_off", "timeout": 300,
        })
        self.assertEqual(behaviors["suspend"], {
            "enabled": True, "action": "suspend", "timeout": 3600,
            "lock_before_suspend": False,
        })

    def test_desktop_language_and_shell(self):
        shared = (ROOT / "config/hypr/shared.lua").read_text()
        self.assertIn('kb_layout  = "de"', shared)
        self.assertIn('local menu        = "noctalia msg panel-toggle launcher"', shared)
        self.assertIn('hl.exec_cmd("noctalia")', shared)
        for legacy in ("waybar", "mako"):
            self.assertNotIn(f'hl.exec_cmd("{legacy}")', shared)
        environment = (ROOT / "config/environment.d/20-desktop-language.conf").read_text()
        for name, value in (("LANG", "C.UTF-8"), ("LC_MESSAGES", "C.UTF-8"), ("LANGUAGE", "en")):
            self.assertIn(f"{name}={value}\n", environment)
            self.assertIn(f'hl.env("{name}", "{value}")', shared)
        self.assertNotIn("hl.monitor(", shared)
        self.assertNotIn("/home/martin", shared)

    def test_wrapper_skips_broad_tool_installation(self):
        # Fake both executables so this test never touches real package/tool state.
        with tempfile.TemporaryDirectory() as directory:
            bin_dir = pathlib.Path(directory)
            (bin_dir / "pacman").write_text("#!/bin/sh\nexit 0\n")
            (bin_dir / "mise").write_text(
                '#!/bin/sh\nprintf "%s\\n" "$MISE_ENV" "$@"\n'
            )
            for path in bin_dir.iterdir():
                path.chmod(0o755)
            env = dict(os.environ, PATH=f"{bin_dir}:{os.environ['PATH']}", MISE_ENV="voyager")
            result = subprocess.run(
                ["bash", str(ROOT / "bootstrap.sh"), "defiant", "--dry-run"],
                env=env, text=True, capture_output=True, check=True,
            )
            self.assertEqual(result.stdout.splitlines(),
                             ["defiant", "bootstrap", "--skip", "tools", "--dry-run"])
            invalid = subprocess.run(
                ["bash", str(ROOT / "bootstrap.sh"), "unknown"],
                env=env, text=True, capture_output=True,
            )
            self.assertEqual(invalid.returncode, 2)


if __name__ == "__main__":
    unittest.main()
