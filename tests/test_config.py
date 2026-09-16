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
                self.assertEqual(config["tasks"]["bootstrap"]["run"], "mise install claude codex herdr gh")
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
            self.assertEqual(set(config), {"env", "tools"})
            self.assertEqual(config["tools"], {"claude": "latest", "codex": "latest", "herdr": "latest", "gh": "latest"})
            self.assertNotIn("config_root", path.read_text())

    def test_host_composition_and_sources(self):
        base = load("mise.toml")
        self.assertIn(COMMON_TARGET, base["dotfiles"])
        for host in HOSTS:
            config = load(f"mise.{host}.toml")
            if host == "defiant":
                self.assertEqual(config["bootstrap"]["packages"], {
                    "pacman:noctalia": "latest",
                    "pacman:docker": "latest",
                    "pacman:docker-compose": "latest",
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
        }
        for host in HOSTS:
            entries = load("mise.toml")["dotfiles"] | load(f"mise.{host}.toml").get("dotfiles", {})
            for target, source in expected.items():
                if host == "defiant":
                    self.assertEqual(entries[target], {"source": source, "mode": "symlink"})
                else:
                    self.assertNotIn(target, entries)

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
