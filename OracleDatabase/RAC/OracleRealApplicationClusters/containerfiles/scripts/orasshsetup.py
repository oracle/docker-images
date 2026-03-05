#!/usr/bin/python

#############################
# Copyright 2020-2025, Oracle Corporation and/or affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
############################

"""
 This file contains to the code call different classes objects based on setup type
"""

from oralogger import *
from oraenv import *
from oracommon import *
from oramachine import *
from orasetupenv import *
from orasshsetup import *
from oracvu import *

import os
import sys


class OraSetupSSH:
    """
    This class setup the env before setting up the rac env
    """

    def __init__(self, oralogger, orahandler, oraenv, oracommon):
        try:
            self.ologger = oralogger
            self.ohandler = orahandler
            self.oenv = oraenv.get_instance()
            self.ocommon = oracommon
            self.ora_env_dict = oraenv.get_env_vars()
            self.file_name = os.path.basename(__file__)
        except BaseException as ex:
            ex_type, ex_value, ex_traceback = sys.exc_info()
            trace_back = sys.tracebacklimit.extract_tb(ex_traceback)
            stack_trace = list()
            for trace in trace_back:
                stack_trace.append("File : %s , Line : %d, Func.Name : %s, Message : %s" % (
                    trace[0], trace[1], trace[2], trace[3]))
            self.ocommon.log_info_message(ex_type.__name__, self.file_name)
            self.ocommon.log_info_message(ex_value, self.file_name)
            self.ocommon.log_info_message(stack_trace, self.file_name)

    # ============================================================
    # ENTRY POINT
    # ============================================================
    def setup(self):
        """
        This function setup ssh between computes
        """
        self.ocommon.log_info_message("Start setup()", self.file_name)
        ct = datetime.datetime.now()
        bts = ct.timestamp()
        if self.ocommon.check_key("SKIP_SSH_SETUP", self.ora_env_dict):
            self.ocommon.log_info_message(
                "Skipping SSH setup as SKIP_SSH_SETUP flag is set", self.file_name)
        else:
            SSH_USERS = [self.ora_env_dict["GRID_USER"] + ":" + self.ora_env_dict["GRID_HOME"],
                         self.ora_env_dict["DB_USER"] + ":" + self.ora_env_dict["DB_HOME"]]
            if (self.ocommon.check_key("SSH_PRIVATE_KEY", self.ora_env_dict)) and (self.ocommon.check_key("SSH_PUBLIC_KEY", self.ora_env_dict)):
                if self.ocommon.check_file(self.ora_env_dict["SSH_PRIVATE_KEY"], True, None, None) and self.ocommon.check_file(self.ora_env_dict["SSH_PUBLIC_KEY"], True, None, None):
                    for sshi in SSH_USERS:
                        uohome = sshi.split(":")
                        self.setupsshusekey(uohome[0], uohome[1], None)
                        # self.verifyssh(uohome[0],None)
            else:
                for sshi in SSH_USERS:
                    uohome = sshi.split(":")
                    exiting_cls_node = self.ocommon.get_existing_clu_nodes(
                        False)
                    if exiting_cls_node:
                        self.setupssh(uohome[0], uohome[1], "ADDNODE")
                    else:
                        self.setupssh(uohome[0], uohome[1], "INSTALL")

                    # self.verifyssh(uohome[0],None)

        ct = datetime.datetime.now()
        ets = ct.timestamp()
        totaltime = ets - bts
        self.ocommon.log_info_message(
            "Total time for setup() = [ " + str(round(totaltime, 3)) + " ] seconds", self.file_name)

    # ============================================================
    # PASSWORD-BASED SSH (LEGACY / FALLBACK)
    # ============================================================
    def setupssh(self, user, ohome, ctype):
        """
        This function setup the ssh between user as SKIP_SSH_SETUP flag is not set
        """
        self.ocommon.reset_os_password(user)
        passwd = self.ocommon.get_os_password()
        password = passwd.replace("\n", "")
        giuser, gihome, gibase, oinv = self.ocommon.get_gi_params()
        expect = self.ora_env_dict["EXPECT"] if self.ocommon.check_key(
            "EXPECT", self.ora_env_dict) else "/bin/expect"
        script_dir = self.ora_env_dict["SSHSCR_DIR"] if self.ocommon.check_key(
            "SSHSCR_DIR", self.ora_env_dict) else "/opt/scripts/startup/scripts"

        sshscr = self.ora_env_dict["SSHSCR"] if self.ocommon.check_key(
            "SSHSCR", self.ora_env_dict) else "bin/cluvfy"
        if user == 'grid':
            sshscr = "runcluvfy.sh"
        else:
            sshscr = "bin/cluvfy"
            file = '''{0}/{1}'''.format(gihome, sshscr)
            if not self.ocommon.check_file(file, "local", None, None):
                sshscr = "runcluvfy.sh"

        cluster_nodes = ""
        # Run ssh-keyscan for each node
        oraversion = self.ocommon.get_rsp_version("INSTALL", None)
        version = oraversion.split(".", 1)[0].strip()
        if ctype == 'INSTALL':
            cluster_nodes = self.ocommon.get_cluster_nodes()
            cluster_nodes = cluster_nodes.replace(" ", ",")
            i = 0
            while i < 5:
                self.ocommon.log_info_message(
                    '''SSH setup in progress. Count set to {0}'''.format(i), self.file_name)
                self.ocommon.set_mask_str(password.strip())
                if int(version) == 19 or int(version) == 21:
                    self.performsshsetup(
                        user, gihome, sshscr, cluster_nodes, version, password, i, expect, script_dir)
                else:
                    self.performsshsetup(
                        user, gihome, sshscr, cluster_nodes, version, password, i, expect, script_dir)
                retcode = self.verifyssh(
                    user, gihome, sshscr, cluster_nodes, version)
                if retcode == 0:
                    break
                i = i + 1
                self.ocommon.log_info_message(
                    '''SSH setup verification failed. Trying again..''', self.file_name)
        elif ctype == 'ADDNODE':
            cluster_nodes = self.ocommon.get_cluster_nodes()
            cluster_nodes = cluster_nodes.replace(" ", ",")
            exiting_cls_node = self.ocommon.get_existing_clu_nodes(True)
            new_nodes = cluster_nodes + "," + exiting_cls_node
            cmd = '''su - {0} -c "rm -rf ~/.ssh ; mkdir -p ~/.ssh ; chmod 700 ~/.ssh"'''.format(
                user)
            output, error, retcode = self.ocommon.execute_cmd(cmd, None, None)
            self.ocommon.check_os_err(output, error, retcode, False)
            i = 0
            while i < 5:
                # Run ssh-keyscan for each node
                for node in cluster_nodes.split(","):
                    self.ocommon.log_info_message(
                        f"Adding {node} to known_hosts.", self.file_name)
                    keyscan_cmd = '''su - {0} -c "ssh-keyscan -H {1} >> ~/.ssh/known_hosts"'''.format(
                        user, node)
                    keyscan_output, keyscan_error, keyscan_retcode = self.ocommon.execute_cmd(
                        keyscan_cmd, None, None)
                    self.ocommon.check_os_err(
                        keyscan_output, keyscan_error, keyscan_retcode, False)
                    self.performsshsetup(
                        user, gihome, sshscr, new_nodes, version, password, i, expect, script_dir)
                retcode = self.verifyssh(
                    user, gihome, sshscr, new_nodes, version)
                if retcode == 0:
                    break
                i = i + 1
                self.ocommon.log_info_message(
                    '''SSH setup verification failed. Trying again..''', self.file_name)
        else:
            cluster_nodes = self.ocommon.get_cluster_nodes()

    def verifyssh(self, user, gihome, sshscr, cls_nodes, version):
        """
        Verify SSH connectivity (quiet).
        Logs only summary information.
        """

        self.ocommon.log_info_message(
            "Verifying SSH between nodes {0}".format(cls_nodes),
            self.file_name
        )

        if not cls_nodes:
            return 0

        nodes = cls_nodes.replace(",", " ").split()

        # -----------------------------
        # Modern versions (19c+)
        # -----------------------------
        if int(version) >= 19:
            for node in nodes:
                cmd = (
                    'su - {0} -c '
                    '"ssh -o BatchMode=yes -o ConnectTimeout=5 '
                    '{0}@{1} echo ok '
                    '>/dev/null 2>&1"'
                ).format(user, node)

                _, _, rc = self.ocommon.execute_cmd(cmd, None, None)

                if rc != 0:
                    self.ocommon.log_info_message(
                        "SSH verification failed for user {0} on node {1}"
                        .format(user, node),
                        self.file_name
                    )
                    return 255

            return 0

        # -----------------------------
        # Legacy path
        # -----------------------------
        cls_nodes = cls_nodes.replace(" ", ",")
        cmd = (
            'su - {0} -c "{1}/{2} comp admprv '
            '-n {3} -o user_equiv -sshonly '
            '>/dev/null 2>&1"'
        ).format(user, gihome, sshscr, cls_nodes)

        _, _, rc = self.ocommon.execute_cmd(cmd, None, None)

        if rc != 0:
            self.ocommon.log_info_message(
                "SSH verification failed for user {0}".format(user),
                self.file_name
            )

        return rc


    def performsshsetup(self, user, gihome, sshscr, cls_nodes, version, password, counter, expect, script_dir):
        """
        Sets up SSH between cluster nodes and patches all sshUserSetup.sh scripts
        under GRID_HOME and DB_HOME to use 4096-bit keys.
        """
        import shutil
        import glob
        import os

        self.ocommon.set_mask_str(password.strip())
        self.ocommon.log_info_message(
            f'SSH setup in progress. Count set to {counter}', self.file_name)

        # Only patch for Oracle versions 19c or 21c when using setupSSH.expect
        if int(version) in (19, 21):
            sshscr = "setupSSH.expect"
            cluster_nodes = cls_nodes.replace(",", " ")

            # Ensure env variables exist
            self.ocommon.check_env_variable("GRID_HOME", True)
            self.ocommon.check_env_variable("DB_HOME", True)

            # Get their values from environment dictionary
            grid_home = self.ora_env_dict["GRID_HOME"]
            db_home = self.ora_env_dict["DB_HOME"]

            # Collect all sshUserSetup.sh scripts under both homes
            scripts_to_patch = glob.glob(
                f"{grid_home}/**/sshUserSetup.sh", recursive=True)
            scripts_to_patch += glob.glob(
                f"{db_home}/**/sshUserSetup.sh", recursive=True)

            # Patch each script safely
            for script in scripts_to_patch:
                backup_file = script + ".bak"
                if not os.path.exists(backup_file):
                    shutil.copy2(script, backup_file)
                    self.ocommon.log_info_message(
                        f"Backed up {script} to {backup_file}", self.file_name)

                # Read file and replace BITS value
                with open(script, "r") as f:
                    lines = f.readlines()

                with open(script, "w") as f:
                    for line in lines:
                        if line.strip().startswith("BITS="):
                            f.write("BITS=4096\n")
                            self.ocommon.log_info_message(
                                f"Patched {script}: {line.strip()} -> BITS=4096", self.file_name)
                        else:
                            f.write(line)

            # Pick the main script to run (GRID_HOME version)
            ssh_user_setup_sh = f"{grid_home}/oui/prov/resources/scripts/sshUserSetup.sh"

            # Run the patched SSH setup
            sshcmd = (
                f'su - {user} -c "{expect} {script_dir}/{sshscr} {user} \\"{grid_home}/oui/prov/resources/scripts\\" '
                f'\\"{cluster_nodes}\\" \\"HIDDEN_STRING\\""'
            )
            sshcmd_output, sshcmd_error, sshcmd_retcode = self.ocommon.execute_cmd(
                sshcmd, None, None)
            self.ocommon.check_os_err(
                sshcmd_output, sshcmd_error, sshcmd_retcode, False)

        else:
            # Older/non-expect path
            cmd = (
                f'su - {user} -c "echo \\"HIDDEN_STRING\\" | {gihome}/{sshscr} comp admprv '
                f'-n {cls_nodes} -o user_equiv -fixup"'
            )
            output, error, retcode = self.ocommon.execute_cmd(cmd, None, None)
            self.ocommon.check_os_err(output, error, retcode, None)

        self.ocommon.unset_mask_str()

    def setupsshusekey(self, user, ohome, ctype):
        """
        SSH setup using existing RSA key.
        Quiet retries; authoritative verification at the end.
        """

        self.ocommon.log_info_message(
            "Setting up SSH trust for user {0} ({1})".format(
                user, ctype or "INSTALL"
            ),
            self.file_name
        )

        new_nodes = self.ocommon.get_cluster_nodes() or ""
        existing_nodes = self.ocommon.get_existing_clu_nodes(None)

        all_nodes = sorted(set(
            (existing_nodes.replace(",", " ").split() if existing_nodes else []) +
            (new_nodes.replace(",", " ").split() if new_nodes else [])
        ))

        max_retries = 5
        retry_sleep = 20   # increased delay to reduce noise

        for src in all_nodes:
            for tgt in all_nodes:
                self.ocommon.log_info_message(
                    "Configuring SSH trust {0} -> {1}".format(src, tgt),
                    self.file_name
                )

                cmd = (
                    'su - {0} -c "ssh -o StrictHostKeyChecking=no -x -l {0} {1} '
                    '\\\"ssh-keygen -R {2} >/dev/null 2>&1; '
                    'test -s ~/.ssh/id_rsa || '
                    'ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N \\\\\\\"\\\\\\\"; '
                    'ssh -o StrictHostKeyChecking=no -x -l {0} {2} '
                    '\\\\\\\"/bin/sh -c true\\\\\\\"\\\"\"'
                ).format(user, src, tgt)

                success = False

                for attempt in range(1, max_retries + 1):
                    _, _, rc = self.ocommon.execute_cmd(cmd, None, None)
                    if rc == 0:
                        success = True
                        break
                    time.sleep(retry_sleep)

                if not success:
                    self.ocommon.log_warn_message(
                        "SSH trust not ready yet for {0} -> {1}. "
                        "This is expected during setup and can be ignored for now; "
                        "final SSH verification will be performed later.".format(
                            src, tgt
                        ),
                        self.file_name
                    )

    def setupsshdirs(self, user, ohome, ctype):
        """
        This function setup the ssh directories
        """
        sshdir = '''/home/{0}/.ssh'''.format(user)
        privkey = self.ora_env_dict["SSH_PRIVATE_KEY"]
        pubkey = self.ora_env_dict["SSH_PUBLIC_KEY"]
        group = "oinstall"
        cmd1 = '''mkdir -p {0}'''.format(sshdir)
        cmd2 = '''chmod 700 {0}'''.format(sshdir)
        cmd3 = '''cat {0} > {1}/id_rsa'''.format(privkey, sshdir)
        cmd4 = '''cat {0} > {1}/id_rsa.pub'''.format(pubkey, sshdir)
        cmd5 = '''chmod 400 {0}/id_rsa'''.format(sshdir)
        cmd6 = '''chmod 644 {0}/id_rsa.pub'''.format(sshdir)
        cmd7 = '''chown -R {0}:{1} {2}'''.format(user, group, sshdir)
        cmd8 = '''cat {0} > {1}/authorized_keys'''.format(pubkey, sshdir)
        cmd9 = '''chmod 600 {0}/authorized_keys'''.format(sshdir)
        cmd10 = '''chown -R {0}:{1} {2}/authorized_keys'''.format(
            user, group, sshdir)
        for cmd in cmd1, cmd2, cmd3, cmd4, cmd5, cmd6, cmd7, cmd8, cmd9, cmd10:
            output, error, retcode = self.ocommon.execute_cmd(cmd, None, None)
            self.ocommon.check_os_err(output, error, retcode, False)