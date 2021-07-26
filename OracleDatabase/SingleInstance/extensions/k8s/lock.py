#! /usr/bin/python -u
# LICENSE UPL 1.0
#
# Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.
#
# Since: Mar, 2020
# Author: mohammed.qureshi@oracle.com
# Description: Provides file locking support
#
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

import os
import time
import sys
import signal
import argparse
import fcntl
import tempfile
import threading, subprocess
from multiprocessing.connection import Listener, Client

# Multiprocess communication auth key
AUTHKEY = 'vkidSQkgAHc='
DIR_LOCK_FILE = os.sep + '.dirlock'

def acquire_lock(lock_file, sock_file, block, heartbeat):
    """
    Acquire a lock on the passed file, block if needed
    :param lock_file:
    :param sock_file:
    :param block:
    :return:
    """

    # get dir lock first to check lock file existence
    with open(os.path.dirname(lock_file) + DIR_LOCK_FILE, 'w') as dir_lh:
        fcntl.flock(dir_lh, fcntl.LOCK_EX)
        if not os.path.exists(lock_file):
            print('[%s]: Creating %s' % (time.strftime('%Y:%m:%d %H:%M:%S'), os.path.basename(lock_file)))
            open(lock_file, 'w').close()

    lock_handle = open(lock_file)
    print('[%s]: Acquiring lock %s with heartbeat %s secs' %
         (time.strftime('%Y:%m:%d %H:%M:%S'), os.path.basename(lock_file), heartbeat))
    while True:
        try:
            fcntl.flock(lock_handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
            print('[%s]: Lock acquired' % (time.strftime('%Y:%m:%d %H:%M:%S')))
            with open(os.path.dirname(lock_file) + DIR_LOCK_FILE, 'w') as dir_lh:
                fcntl.flock(dir_lh, fcntl.LOCK_EX)
                print('[%s]: Starting heartbeat' % (time.strftime('%Y:%m:%d %H:%M:%S')))
                os.utime(lock_file, None)
            break
        except IOError as e:
            if not block:
                print(e)
                return 1

            time.sleep(0.1)

            # to handle stale NFS locks
            pulse = int(time.time() - os.path.getmtime(lock_file))
            if heartbeat < pulse:
                # something is wrong
                print('[%s]: Lost heartbeat by %s secs' % (time.strftime('%Y:%m:%d %H:%M:%S'), pulse))
                lock_handle.close()
                # get dir lock
                with open(os.path.dirname(lock_file) + DIR_LOCK_FILE, 'w') as dir_lh:
                    fcntl.flock(dir_lh, fcntl.LOCK_EX)
                    # pulse check again after acquring dir lock
                    if heartbeat < int(time.time() - os.path.getmtime(lock_file)):
                        print('[%s]: Recreating %s' % (time.strftime('%Y:%m:%d %H:%M:%S'), os.path.basename(lock_file)))
                        os.remove(lock_file)
                        open(lock_file, 'w').close()

                lock_handle = open(lock_file)
                print('[%s]: Reacquiring lock %s' %
                     (time.strftime('%Y:%m:%d %H:%M:%S'), os.path.basename(lock_file)))


    if os.fork():
        return 0
    else:
        # Spawn a child process to hold on to the lock
        if os.path.exists(sock_file):
            os.remove(sock_file)
        print('[%s]: Lock held %s' % (time.strftime('%Y:%m:%d %H:%M:%S'), os.path.basename(lock_file)))
        listener = Listener(address=sock_file, authkey=AUTHKEY)

        def listen():
            while True:
                conn = listener.accept()
                if conn.recv():
                    break
            release()

        def release(sig=None, frame=None):
            """
            Release if the process is stopped/terminated
            :param sig:
            :param frame:
            :return:
            """
            # Hold on to the lock for other container
            # processes to terminate first. Allow 30 secs timeout
            if sig:	    
                time.sleep(30)
            lock_handle.close()
            listener.close()
            print('[%s]: Lock released %s' % (time.strftime('%Y:%m:%d %H:%M:%S'), os.path.basename(lock_file)))

        signal.signal(signal.SIGTERM, release)
        signal.signal(signal.SIGINT, release)
        threading.Thread(target=listen).start()

        while not lock_handle.closed:
            os.utime(lock_file, None)
            time.sleep(5)


def check_lock(sock_file):
    """
    Check if lock is held
    :param sock_file:
    :return:
    """
    if not os.path.exists(sock_file):
        return 1
    print('[%s]: Connecting to the lock process %s' % (time.strftime('%Y:%m:%d %H:%M:%S'), sock_file))
    cl = Client(address=sock_file, authkey=AUTHKEY)
    cl.send(False)
    cl.close()
    print('[%s]: Lock held %s' % (time.strftime('%Y:%m:%d %H:%M:%S'), os.path.basename(sock_file)))
    return 0


def release_lock(sock_file):
    """
    Release the lock by connecting to lock process and terminating it
    :param sock_file:
    :return:
    """
    if not os.path.exists(sock_file):
        return 1
    print('[%s]: Releasing lock %s' % (time.strftime('%Y:%m:%d %H:%M:%S'), os.path.basename(sock_file)))
    cl = Client(address=sock_file, authkey=AUTHKEY)
    cl.send(True)
    cl.close()
    return 1


def main():
    """
    Main function, sets up arg parsing
    :return:
    """
    parser = argparse.ArgumentParser(prog=sys.argv[0])
    parser.add_argument('--acquire', action='store_true', dest='acquire')
    parser.add_argument('--check', action='store_true', dest='check')
    parser.add_argument('--release', action='store_true', dest='release')
    parser.add_argument('--file', dest='lock_file')
    parser.add_argument('--block', action='store_true', dest='block')
    # heartbeat in secs
    parser.add_argument('--heartbeat', type=int, dest='heartbeat', default=30)
    args = parser.parse_args()
    if not args.lock_file:
        parser.print_help()
        sys.exit()
    # Derive sock_file name from lock_file
    sock_file = os.path.join(tempfile.gettempdir(), os.path.basename(args.lock_file))
    if args.acquire:
        sys.exit(acquire_lock(args.lock_file, sock_file, args.block, args.heartbeat))
    elif args.check:
        sys.exit(check_lock(sock_file))
    elif args.release:
        sys.exit(release_lock(sock_file))


# Entry point
if __name__ == '__main__':
    main()
