# LICENSE UPL 1.0
#
# Copyright (c) 2024 Oracle and/or its affiliates. All rights reserved.
#
# Since: Apr, 2024
# Author: ishaan.desai@oracle.com
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.


import sys
import oracledb
import os

def copyBlobFile(primaryDBConnectString, oraclePwd, tableName, blobLoc):
    connections = oracledb.connect(user='sys', password=oraclePwd, dsn=primaryDBConnectString, mode=oracledb.AUTH_MODE_SYSDBA)
    cursor = connections.cursor()
    cursor.execute(f'select FILE_ZIP from {tableName}')        
    blob, = cursor.fetchone()
    offset = 1
    num_bytes_in_chunk = 65536
    with open(os.path.join(blobLoc), "wb") as f:
        while True:
            data = blob.read(offset, num_bytes_in_chunk)
            if data:
                f.write(data)
            if len(data) < num_bytes_in_chunk:
                break
            offset += len(data)


if __name__ == '__main__':
    primaryDBConnectString = sys.argv[1] 
    oraclePwd = sys.argv[2]
    tableName = sys.argv[3]
    blobLoc = sys.argv[4]
    oracledb.init_oracle_client()
    copyBlobFile(primaryDBConnectString, oraclePwd, tableName, blobLoc)
