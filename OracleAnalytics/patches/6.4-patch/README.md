Build a Oracle Analytics Server 6.4 Patched Image
===============================================
This Dockerfile extends the Oracle Analytics Server image (6.4), and applies necessary patches.

## How to build and run
First make sure you have built `oracle/biplatform:6.4`.

Download the following patches from [My Oracle Support](https://support.oracle.com) and place them in the same directory as this README.

(1) p34080315_122140_Generic.zip  
(2) p33958532_122140_Generic.zip  
(3) p34044738_122140_Generic.zip  
(4) p32784652_122140_Generic.zip  
(5) p30613424_122140_Generic.zip  
(6) p31403376_122140_Generic.zip  
(7) p33618954_122140_Generic.zip  
(8) p33546536_12214211129_Generic.zip  
(9) p32575741_122140_Linux-x86-64.zip  
(10) p33950717_122140_Generic.zip  
(11) p34065178_122140_Generic.zip  

To build, run:

        $ docker build --force-rm=true --no-cache=true -t oracle/biplatform:6.4-patch .


# Copyright
Copyright (c) 2022 Oracle and/or its affiliates.
