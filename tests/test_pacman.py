"""Exercise the real pacman setup script without sudo or system files."""
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/configure-pacman.sh"


class PacmanTests(unittest.TestCase):
    def run_script(self, path):
        return subprocess.run(["bash", str(SCRIPT), str(path)],
                              text=True, capture_output=True)

    def test_enables_only_in_options_and_preserves_existing_config(self):
        for preference in ("", "#ILoveCandy\n"):
            with self.subTest(preference=preference), tempfile.TemporaryDirectory() as directory:
                path = pathlib.Path(directory) / "pacman.conf"
                original = ("# Local config\n[options] # General\n" + preference
                            + "Color\nParallelDownloads = 5\n\n[core]\n"
                            + "Include = /etc/pacman.d/mirrorlist\n#ILoveCandy\n")
                path.write_text(original)
                path.chmod(0o640)
                result = self.run_script(path)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(path.read_text(), original.replace(
                    "[options] # General\n", "[options] # General\nILoveCandy\n"))
                self.assertEqual(path.stat().st_mode & 0o777, 0o640)
                backup = path.with_name("pacman.conf.dotfiles.bak")
                self.assertEqual(backup.read_text(), original)
                stat = path.stat()
                result = self.run_script(path)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(path.stat().st_ino, stat.st_ino)
                self.assertEqual(path.stat().st_mtime_ns, stat.st_mtime_ns)
                self.assertEqual(backup.read_text(), original)

    def test_existing_option_is_untouched(self):
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "pacman.conf"
            original = "[options]\n  ILoveCandy  # Already enabled\n[core]"
            path.write_text(original)
            stat = path.stat()
            result = self.run_script(path)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(path.read_text(), original)
            self.assertEqual(path.stat().st_ino, stat.st_ino)
            self.assertEqual(list(path.parent.iterdir()), [path])

    def test_missing_options_fails_without_changing_file(self):
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "pacman.conf"
            original = "[core]\nInclude = /etc/pacman.d/mirrorlist\n"
            path.write_text(original)
            result = self.run_script(path)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("[options]", result.stderr)
            self.assertEqual(path.read_text(), original)
            self.assertEqual(list(path.parent.iterdir()), [path])


if __name__ == "__main__":
    unittest.main()
