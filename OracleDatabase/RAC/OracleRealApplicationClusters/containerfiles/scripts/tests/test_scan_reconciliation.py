#!/usr/bin/env python3

# Copyright 2026, Oracle Corporation and/or affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl

import os
import socket
import sys
import unittest
from unittest import mock


SCRIPT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

from oracommon import OraCommon


class ScanReconciliationTest(unittest.TestCase):
    def setUp(self):
        self.common = OraCommon.__new__(OraCommon)
        self.common.ora_env_dict = {"SCAN_NAME": "racnode-scan"}
        self.common.file_name = "oracommon.py"
        self.common.log_info_message = mock.Mock()
        self.common.log_warn_message = mock.Mock()
        self.common.log_error_message = mock.Mock()
        self.common._get_ordered_scan_nodes = mock.Mock(
            return_value=["racnode1-0", "racnode2-0", "racnode3-0"])

    def test_resolve_scan_ipv4_addresses_returns_unique_sorted_addresses(self):
        address_info = [
            (socket.AF_INET, socket.SOCK_STREAM, 6, "", ("10.0.0.3", 0)),
            (socket.AF_INET, socket.SOCK_STREAM, 6, "", ("10.0.0.1", 0)),
            (socket.AF_INET, socket.SOCK_STREAM, 6, "", ("10.0.0.3", 0)),
        ]

        with mock.patch("oracommon.socket.getaddrinfo", return_value=address_info):
            addresses = self.common._resolve_scan_ipv4_addresses()

        self.assertEqual(["10.0.0.1", "10.0.0.3"], addresses)

    def test_remote_cluster_node_states_parses_olsnodes_output(self):
        self.common.execute_cmd_checked = mock.Mock(return_value=(
            "racnode1-0\tActive\nracnode2-0 Inactive\nracnode3-0 Active\n",
            "",
            0,
        ))

        states = self.common._get_remote_cluster_node_states(
            "grid", "/u01/app/grid", "racnode2-0")

        self.assertEqual({
            "racnode1-0": "Active",
            "racnode2-0": "Inactive",
            "racnode3-0": "Active",
        }, states)

    def test_waits_without_mutation_when_node_or_address_is_missing(self):
        self.common._get_remote_cluster_node_states = mock.Mock(return_value={
            "racnode1-0": "Active",
            "racnode2-0": "Active",
            "racnode3-0": "Inactive",
        })
        self.common._resolve_scan_ipv4_addresses = mock.Mock(
            return_value=["10.0.0.1", "10.0.0.2"])
        self.common.update_scan = mock.Mock()
        self.common.update_scan_lsnr = mock.Mock()
        self.common._get_scan_status_summary = mock.Mock()

        result = self.common.reconcile_scan_resources(
            "grid", "/u01/app/grid", "racnode2-0",
            expected_count=3, max_attempts=1, sleep_seconds=0)

        self.assertFalse(result)
        self.common.update_scan.assert_not_called()
        self.common.update_scan_lsnr.assert_not_called()
        self.common._get_scan_status_summary.assert_not_called()

    @mock.patch("oracommon.time.sleep")
    def test_eventually_converges_after_readiness_recovers(self, sleep_mock):
        self.common._get_remote_cluster_node_states = mock.Mock(side_effect=[
            {
                "racnode1-0": "Active",
                "racnode2-0": "Active",
                "racnode3-0": "Inactive",
            },
            {
                "racnode1-0": "Active",
                "racnode2-0": "Active",
                "racnode3-0": "Active",
            },
        ])
        self.common._resolve_scan_ipv4_addresses = mock.Mock(side_effect=[
            ["10.0.0.1", "10.0.0.2"],
            ["10.0.0.1", "10.0.0.2", "10.0.0.3"],
        ])
        self.common.update_scan = mock.Mock()
        self.common.update_scan_lsnr = mock.Mock()
        self.common._reconcile_numbered_scan_resources = mock.Mock()
        self.common._scan_topology_matches_order = mock.Mock(return_value=True)
        ready_summary = (
            {"1", "2", "3"},
            {"1", "2", "3"},
            {"1": "racnode1-0", "2": "racnode2-0", "3": "racnode3-0"},
            "all resources are running",
        )
        self.common._get_scan_status_summary = mock.Mock(
            side_effect=[ready_summary, ready_summary, ready_summary, ready_summary])

        result = self.common.reconcile_scan_resources(
            "grid", "/u01/app/grid", "racnode2-0",
            expected_count=3, max_attempts=2, sleep_seconds=15)

        self.assertTrue(result)
        sleep_mock.assert_called_once_with(15)
        self.common.update_scan.assert_called_once()
        self.common.update_scan_lsnr.assert_called_once()

    def test_rejects_two_resource_topology_when_three_are_expected(self):
        self.common._get_remote_cluster_node_states = mock.Mock(return_value={
            "racnode1-0": "Active",
            "racnode2-0": "Active",
            "racnode3-0": "Active",
        })
        self.common._resolve_scan_ipv4_addresses = mock.Mock(
            return_value=["10.0.0.1", "10.0.0.2", "10.0.0.3"])
        self.common.update_scan = mock.Mock()
        self.common.update_scan_lsnr = mock.Mock()
        self.common._reconcile_numbered_scan_resources = mock.Mock()
        two_resource_summary = (
            {"1", "2"},
            {"1", "2"},
            {"1": "racnode1-0", "2": "racnode2-0"},
            "two resources are running",
        )
        self.common._get_scan_status_summary = mock.Mock(side_effect=[
            two_resource_summary,
            two_resource_summary,
            two_resource_summary,
            two_resource_summary,
        ])

        result = self.common.reconcile_scan_resources(
            "grid", "/u01/app/grid", "racnode2-0",
            expected_count=3, max_attempts=1, sleep_seconds=0)

        self.assertFalse(result)


if __name__ == "__main__":
    unittest.main()
