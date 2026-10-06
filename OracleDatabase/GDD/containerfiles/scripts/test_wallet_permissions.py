import os
import stat
import tempfile
import unittest

from oracommon import OraCommon


class DummyLogger:
    def __init__(self):
        self.msg_ = None
        self.logtype_ = None
        self.force_console_ = False


class DummyHandler:
    def handle(self, _logger):
        return None


class DummyEnv:
    def get_instance(self):
        return self

    def get_env_vars(self):
        return {}


class OraCommonWalletPermissionTests(unittest.TestCase):
    def _build_common(self):
        return OraCommon(DummyLogger(), DummyHandler(), DummyEnv())

    def test_secures_wallet_files_and_parent_directories(self):
        common = self._build_common()

        with tempfile.TemporaryDirectory() as tmpdir:
            wallet_dir = os.path.join(tmpdir, "CATCDB", "shard")
            os.makedirs(wallet_dir, mode=0o777)
            wallet_file = os.path.join(wallet_dir, "cwallet.sso")
            with open(wallet_file, "w", encoding="utf-8") as fobj:
                fobj.write("wallet")
            os.chmod(wallet_file, 0o777)

            secured = common.secure_wallet_permissions(os.path.join(tmpdir, "CATCDB"))

            self.assertEqual(1, secured)
            self.assertEqual(0o600, stat.S_IMODE(os.stat(wallet_file).st_mode))
            self.assertEqual(0o700, stat.S_IMODE(os.stat(wallet_dir).st_mode))
            self.assertEqual(0o700, stat.S_IMODE(os.stat(os.path.join(tmpdir, "CATCDB")).st_mode))

    def test_noop_when_wallet_root_missing(self):
        common = self._build_common()
        self.assertEqual(0, common.secure_wallet_permissions("/tmp/does-not-exist-codex-wallet-root"))


if __name__ == "__main__":
    unittest.main()
