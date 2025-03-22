#!/usr/bin/env python3
import os
import sys
import time

try:
    import psycopg
except ImportError:
    import psycopg2 as psycopg


def try_connect(conn_info, timeout=30):
    start_time = time.time()
    while True:
        try:
            conn = psycopg.connect(**conn_info)
        except psycopg.OperationalError:
            if (time.time() - start_time) < timeout:
                time.sleep(1)
                continue
            raise
        conn.close()
        return


def main():
    # standard env variables for psql
    conn_info = {
        'host': os.environ.get('PGHOST'),
        'port': int(os.environ.get('PGPORT', 5432)),
        'user': os.environ.get('PGUSER'),
        'password': os.environ.get('PGPASSWORD'),
        'dbname': os.environ.get('PGDATABASE', 'postgres'),
    }
    timeout = int(os.environ.get('PGTIMEOUT', 30))
    try:
        try_connect(conn_info, timeout)
    except psycopg.Error as error:
        print("Database connection failure: %s" % error, file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
