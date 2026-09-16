"""Offline editor checks; plugin installation is tested separately in a sandbox."""
import json
import os
import pathlib
import shutil
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


class NeovimTests(unittest.TestCase):
    def test_plugin_lock_has_exact_commits(self):
        lock = json.loads((ROOT / "config/nvim/lazy-lock.json").read_text())
        self.assertIn("lazy.nvim", lock)
        self.assertIn("nvim-lspconfig", lock)
        for plugin in lock.values():
            self.assertRegex(plugin["commit"], r"^[0-9a-f]{40}$")

    @unittest.skipUnless(shutil.which("nvim"), "requires Neovim")
    def test_lua_and_project_tool_boundary(self):
        with tempfile.TemporaryDirectory() as directory:
            env = dict(os.environ, HOME=directory, XDG_CONFIG_HOME=f"{directory}/config",
                       XDG_DATA_HOME=f"{directory}/data", XDG_STATE_HOME=f"{directory}/state",
                       XDG_CACHE_HOME=f"{directory}/cache")
            result = subprocess.run(
                ["nvim", "--headless", "-u", "NONE", "-l", str(ROOT / "tests/nvim.lua"),
                 str(ROOT / "config/nvim")],
                env=env, capture_output=True, text=True, timeout=20,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("Offline Neovim checks passed", result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
