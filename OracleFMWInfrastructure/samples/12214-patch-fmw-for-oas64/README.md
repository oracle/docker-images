Patch a FMW Infrastructure Image for Oracle Analytics Server 6.4
===============================================
This Dockerfile extends the Oracle FMW Infrastructure image (12.2.1.4), and applies necessary patches required for Oracle Analytics Server 6.4.

## How to build and run
First make sure you have built `oracle/fmw-infrastructure:12.2.1.4`.

Download the following patches from [My Oracle Support](http://support.oracle.com) and place them in the same directory as this README.

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

        $ docker build --force-rm=true --no-cache=true -t oracle/fmw-infrastructure:12.2.1.4-patched-for-oas64 .


# Copyright
Copyright (c) 2022 Oracle and/or its affiliates. All rights reserved.
