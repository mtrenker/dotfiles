"""Bash checks and native mise application in disposable homes only."""
import os
import pathlib
import shutil
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
MISE = shutil.which("mise")


class ShellTests(unittest.TestCase):
    def test_syntax_and_noninteractive_guard(self):
        source = ROOT / "config/bash/interactive.bash"
        subprocess.run(["bash", "-n", str(source)], check=True)
        subprocess.run(["bash", "--noprofile", "--norc", "-c",
                        'source "$1"; ! declare -F mkcd', "test", str(source)], check=True)

    def test_helpers_aliases_and_hooks_only_initialize_once(self):
        with tempfile.TemporaryDirectory() as directory:
            home = pathlib.Path(directory)
            bin_dir = home / "bin"
            bin_dir.mkdir()
            for tool in ("fzf", "zoxide", "direnv", "starship"):
                path = bin_dir / tool
                path.write_text('#!/bin/sh\nprintf "HOOK_CALLS=\\$((HOOK_CALLS + 1))\\n"\n')
                path.chmod(0o755)
            env = dict(os.environ, HOME=directory, PATH=f"{bin_dir}:{os.environ['PATH']}")
            (home / ".bashrc.local").write_text("LOCAL_LOADED=yes\n")
            script = '''
source "$1"
source "$1"
[[ $HOOK_CALLS == 4 && $LOCAL_LOADED == yes ]] || exit 1
[[ $(alias gs) == "alias gs='git status -sb'" ]] || exit 1
cd "$HOME"
mkcd 'parent/space dir/child' || exit 1
up 02 || exit 1
[[ $PWD == "$HOME/parent" ]] || exit 1
up invalid 2>/dev/null && exit 1
mkcd 2>/dev/null && exit 1
exit 0
'''
            subprocess.run(["bash", "--noprofile", "--norc", "-ic", script,
                            "test", str(ROOT / "config/bash/interactive.bash")],
                           env=env, check=True, capture_output=True, text=True)


@unittest.skipUnless(MISE, "mise is required for native dotfile integration tests")
class DotfileTests(unittest.TestCase):
    def test_apply_preserves_local_content_is_idempotent_and_scopes_work_helpers(self):
        for host in ("defiant", "work"):
            with self.subTest(host=host), tempfile.TemporaryDirectory() as directory:
                home = pathlib.Path(directory)
                # Do not inherit live mise config or Git config overrides.
                env = {k: v for k, v in os.environ.items()
                       if not k.startswith(("MISE_", "GIT_CONFIG"))}
                env.update({
                    "HOME": directory,
                    "XDG_CONFIG_HOME": str(home / ".config"),
                    "XDG_DATA_HOME": str(home / ".local/share"),
                    "XDG_CACHE_HOME": str(home / ".cache"),
                    "XDG_STATE_HOME": str(home / ".local/state"),
                    "MISE_CONFIG_DIR": str(home / ".config/mise"),
                    "MISE_DATA_DIR": str(home / ".local/share/mise"),
                    "MISE_CACHE_DIR": str(home / ".cache/mise"),
                    "MISE_STATE_DIR": str(home / ".local/state/mise"),
                    "MISE_TRUSTED_CONFIG_PATHS": f"{ROOT}:{home}",
                    "GIT_CONFIG_NOSYSTEM": "1",
                })
                bash_original = '# Keep private shell settings\nexport KEEP_ME=yes\n'
                git_original = '[user]\n    email = existing@example.test\n'
                (home / ".bashrc").write_text(bash_original)
                (home / ".gitconfig").write_text(git_original)
                (home / ".gitconfig.local").write_text('[user]\n    email = private@example.test\n')
                command = [MISE, "-E", host, "bootstrap", "--only", "dotfiles,shell", "--yes"]
                def apply():
                    subprocess.run(command, cwd=ROOT, env=env, check=True,
                                   capture_output=True, text=True)
                apply()
                first = {name: (home / name).read_bytes()
                         for name in (".bashrc", ".bash_profile", ".gitconfig")}
                apply()
                self.assertEqual(first, {name: (home / name).read_bytes() for name in first})
                self.assertTrue((home / ".bashrc").read_text().startswith(bash_original))
                self.assertTrue((home / ".gitconfig").read_text().startswith(git_original))
                self.assertTrue((home / ".config/bash/interactive.bash").is_symlink())
                def git(*args):
                    return subprocess.run(["git", "config", "--global", "--includes", *args],
                                          env=env, cwd=home, text=True, capture_output=True)
                self.assertEqual(git("--get", "user.email").stdout.strip(), "private@example.test")
                self.assertEqual(git("--get", "core.pager").stdout.strip(), "delta")
                self.assertEqual(git("--get", "alias.wtls").stdout.strip(), "worktree list")
                self.assertEqual(git("--get", "url.git@github.com:.insteadOf").stdout.strip(),
                                 "https://github.com/")
                helpers = git("--get-regexp", r"credential\..*\.helper")
                self.assertEqual(helpers.returncode, 0 if host == "work" else 1)
                self.assertFalse((home / ".local/share/mise/installs").exists())


if __name__ == "__main__":
    unittest.main()
