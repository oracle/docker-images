#!/usr/bin/env python3
"""Query Oracle AI Database with python-oracledb.

Examples:
    python oracledb_example.py --mode thin
    python oracledb_example.py --mode thick --lib-dir /path/to/instantclient
"""

import argparse
from getpass import getpass


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--mode",
        choices=("thin", "thick"),
        default="thin",
        help="python-oracledb mode (default: thin)",
    )
    parser.add_argument(
        "--lib-dir",
        metavar="PATH",
        help="Oracle Instant Client library directory required for Thick mode",
    )
    parser.add_argument(
        "--dsn",
        default="localhost:1521/FREEPDB1",
        help="Oracle connect string (default: localhost:1521/FREEPDB1)",
    )
    parser.add_argument(
        "--user",
        default="app_user",
        help="database user (default: app_user)",
    )
    args = parser.parse_args()

    if args.mode == "thick" and not args.lib_dir:
        parser.error("--lib-dir is required when --mode thick is selected")
    if args.mode == "thin" and args.lib_dir:
        parser.error("--lib-dir can only be used when --mode thick is selected")
    return args


def main() -> None:
    args = parse_args()
    import oracledb

    if args.mode == "thick":
        oracledb.init_oracle_client(lib_dir=args.lib_dir)

    connection = oracledb.connect(
        user=args.user,
        password=getpass("Database password: "),
        dsn=args.dsn,
    )
    try:
        cursor = connection.cursor()
        try:
            cursor.execute("SELECT banner FROM v$version")
            for (banner,) in cursor:
                print(banner)
        finally:
            cursor.close()
    finally:
        connection.close()


if __name__ == "__main__":
    main()
