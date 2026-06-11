import re
import unittest

from oragsm import OraGSM


class ProgExitError(RuntimeError):
    pass


class DummyCommon:
    def __init__(self):
        self.errors = []
        self.infos = []

    def log_error_message(self, msg, _file_name):
        self.errors.append(msg)

    def log_info_message(self, msg, _file_name):
        self.infos.append(msg)

    def prog_exit(self, code):
        raise ProgExitError(str(code))

    def check_key(self, key, dct):
        return key in dct

    def add_key(self, key, value, dct):
        dct[key] = value
        return dct


class DummyEnv:
    def __init__(self, env_dict):
        self._env = env_dict

    def get_instance(self):
        return self

    def get_env_vars(self):
        return self._env


class DummyMachine:
    pass


class OraGSMUserShardGuardTests(unittest.TestCase):
    def _build_gsm(self, env_dict):
        common = DummyCommon()
        env = DummyEnv(env_dict)
        gsm = OraGSM(None, None, env, common)
        gsm.omachine = DummyMachine()
        return gsm, common

    def test_user_dg_rejects_shardspace_without_explicit_primary(self):
        env = {
            "ORACLE_HOME": "/tmp",
            "ADD_SHARD1": "shard_db=s1;shard_pdb=p1;shard_host=h1;shard_space=ss1;deploy_as=standby",
            "ADD_SHARD2": "shard_db=s2;shard_pdb=p2;shard_host=h2;shard_space=ss1",
        }
        gsm, common = self._build_gsm(env)
        gsm._get_sharding_context = lambda: {
            "sharding_type": "user",
            "repl_type": "DG",
            "default_shardspace": "ss1",
        }

        with self.assertRaises(ProgExitError):
            gsm._validate_user_shard_input_constraints(re.compile("ADD_SHARD"))

        self.assertTrue(
            any("Missing PRIMARY for shardspace(s) [ss1]" in m for m in common.errors),
            "Expected missing-primary validation error for ss1",
        )

    def test_user_dg_accepts_when_each_shardspace_has_explicit_primary(self):
        env = {
            "ORACLE_HOME": "/tmp",
            "ADD_SHARD1": "shard_db=s1;shard_pdb=p1;shard_host=h1;shard_space=ss1;deploy_as=primary",
            "ADD_SHARD2": "shard_db=s2;shard_pdb=p2;shard_host=h2;shard_space=ss1;deploy_as=standby",
            "ADD_SHARD3": "shard_db=s3;shard_pdb=p3;shard_host=h3;shard_space=ss2;deploy_as=primary",
        }
        gsm, _common = self._build_gsm(env)
        gsm._get_sharding_context = lambda: {
            "sharding_type": "user",
            "repl_type": "DG",
            "default_shardspace": "ss1,ss2",
        }

        gsm._validate_user_shard_input_constraints(re.compile("ADD_SHARD"))

    def test_guard_is_noop_for_non_user_or_non_dg(self):
        env = {
            "ORACLE_HOME": "/tmp",
            "ADD_SHARD1": "shard_db=s1;shard_pdb=p1;shard_host=h1;shard_space=ss1",
        }
        gsm, _common = self._build_gsm(env)
        gsm._get_sharding_context = lambda: {
            "sharding_type": "system",
            "repl_type": "DG",
            "default_shardspace": None,
        }
        gsm._validate_user_shard_input_constraints(re.compile("ADD_SHARD"))

        gsm._get_sharding_context = lambda: {
            "sharding_type": "user",
            "repl_type": "NATIVE",
            "default_shardspace": None,
        }
        gsm._validate_user_shard_input_constraints(re.compile("ADD_SHARD"))


class OraGSMCompositeMatrixTests(unittest.TestCase):
    def _build_gsm(self, env_dict):
        common = DummyCommon()
        env = DummyEnv(env_dict)
        gsm = OraGSM(None, None, env, common)
        gsm.omachine = DummyMachine()
        return gsm, common

    def test_composite_dg_rejects_standby_cardinality_exceeding_primary(self):
        env = {
            "ORACLE_HOME": "/tmp",
            "SHARD1_GROUP_PARAMS": "group_name=gpri;group_region=dc1;deploy_as=primary;shardspace=ss1",
            "SHARD2_GROUP_PARAMS": "group_name=gstd;group_region=dc2;deploy_as=active_standby;shardspace=ss1",
            "ADD_SHARD1": "shard_db=p1;shard_pdb=pdb1;shard_host=h1;shard_group=gpri",
            "ADD_SHARD2": "shard_db=s1;shard_pdb=pdb2;shard_host=h2;shard_group=gstd",
            "ADD_SHARD3": "shard_db=s2;shard_pdb=pdb3;shard_host=h3;shard_group=gstd",
        }
        gsm, common = self._build_gsm(env)
        gsm._get_sharding_context = lambda: {
            "sharding_type": "composite",
            "repl_type": "DG",
            "default_shardspace": "ss1",
        }

        with self.assertRaises(ProgExitError):
            gsm._validate_composite_shard_cardinality(re.compile("ADD_SHARD"))

        self.assertTrue(
            any("has 2 standby databases but primary shardgroup has only 1 primary databases" in m for m in common.errors),
            "Expected standby cardinality validation error",
        )

    def test_composite_dg_accepts_when_standby_cardinality_within_primary(self):
        env = {
            "ORACLE_HOME": "/tmp",
            "SHARD1_GROUP_PARAMS": "group_name=gpri;group_region=dc1;deploy_as=primary;shardspace=ss1",
            "SHARD2_GROUP_PARAMS": "group_name=gstd;group_region=dc2;deploy_as=active_standby;shardspace=ss1",
            "ADD_SHARD1": "shard_db=p1;shard_pdb=pdb1;shard_host=h1;shard_group=gpri",
            "ADD_SHARD2": "shard_db=p2;shard_pdb=pdb2;shard_host=h2;shard_group=gpri",
            "ADD_SHARD3": "shard_db=s1;shard_pdb=pdb3;shard_host=h3;shard_group=gstd",
            "ADD_SHARD4": "shard_db=s2;shard_pdb=pdb4;shard_host=h4;shard_group=gstd",
        }
        gsm, _common = self._build_gsm(env)
        gsm._get_sharding_context = lambda: {
            "sharding_type": "composite",
            "repl_type": "DG",
            "default_shardspace": "ss1",
        }

        gsm._validate_composite_shard_cardinality(re.compile("ADD_SHARD"))

    def test_composite_dg_deterministic_order_primary_then_standby(self):
        env = {
            "ORACLE_HOME": "/tmp",
            "SHARD1_GROUP_PARAMS": "group_name=grp_std;group_region=dc2;deploy_as=active_standby;shardspace=ss1",
            "SHARD2_GROUP_PARAMS": "group_name=grp_pri;group_region=dc1;deploy_as=primary;shardspace=ss1",
            "ADD_SHARD10": "shard_db=s1;shard_pdb=p1;shard_host=h1;shard_group=grp_std",
            "ADD_SHARD2": "shard_db=p1;shard_pdb=p2;shard_host=h2;shard_group=grp_pri",
            "ADD_SHARD1": "shard_db=p2;shard_pdb=p3;shard_host=h3;shard_group=grp_pri",
        }
        gsm, _common = self._build_gsm(env)
        gsm._get_sharding_context = lambda: {
            "sharding_type": "composite",
            "repl_type": "DG",
            "default_shardspace": "ss1",
        }

        ordered = gsm._ordered_shard_keys(re.compile("ADD_SHARD"))
        self.assertEqual(["ADD_SHARD1", "ADD_SHARD2", "ADD_SHARD10"], ordered)

    def test_rejects_unsupported_external_primary_source_param(self):
        env = {
            "ORACLE_HOME": "/tmp",
            "ADD_SHARD1": "shard_db=s1;shard_pdb=p1;shard_host=h1;shard_group=g1;primaryConnectStrings=foo",
        }
        gsm, common = self._build_gsm(env)
        gsm._get_sharding_context = lambda: {
            "sharding_type": "composite",
            "repl_type": "DG",
            "default_shardspace": "ss1",
        }

        with self.assertRaises(ProgExitError):
            gsm._reject_unsupported_external_primary_source_params(re.compile("ADD_SHARD"))

        self.assertTrue(
            any("not supported in this oragsm workflow" in m for m in common.errors),
            "Expected unsupported external primary source parameter error",
        )


if __name__ == "__main__":
    unittest.main()
