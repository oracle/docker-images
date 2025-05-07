# Build a Oracle Analytics Server 2025 (8.2) Patched Image

This Dockerfile extends the Oracle Analytics Server 2025 (8.2) image,
and applies necessary patches.

## How to build and run

First make sure you have built `oracle/analyticsserver:2025`.

Download the following patches from
[My Oracle Support](https://support.oracle.com)
and place them in the same directory as this README.

1. p37804819_122140_Generic.zip
2. p34809489_122140_Generic.zip
3. p36649916_122140_Generic.zip
4. p37284722_122140_Generic.zip
5. p37684007_122140_Generic.zip
6. p36316422_122140_Generic.zip
7. p36946553_122140_Generic.zip
8. p37388935_122140_Generic.zip
9. p37526122_122140_Linux-x86-64.zip
10. p37665839_122140_Linux-x86-64.zip

To build, run:

```bash
docker build --force-rm=true --no-cache=true -t oracle/analyticsserver:2025-patch .
```

## Copyright

Copyright (c) 2025 Oracle and/or its affiliates.
