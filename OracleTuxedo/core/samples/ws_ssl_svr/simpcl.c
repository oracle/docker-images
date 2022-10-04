/*
** Copyright (c) 2022 Oracle and/or its affiliates.
** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/

/* #ident	"@(#) samples/atmi/simpapp/simpcl.c	$Revision: 1.5 $" */

#include <stdio.h>
#include "atmi.h"		/* TUXEDO  Header File */


#if defined(__STDC__) || defined(__cplusplus)
main(int argc, char *argv[])
#else
main(argc, argv)
int argc;
char *argv[];
#endif

{

	char *sendbuf, *rcvbuf;
	long sendlen, rcvlen;
	int ret;

	if(argc != 2) {
		(void) fprintf(stderr, "Usage: simpcl string\n");
		exit(1);
	}

	/* Attach to System/T as a Client Process */
	if (tpinit((TPINIT *) NULL) == -1) {
		(void) fprintf(stderr, "Tpinit failed\n");
		exit(1);
	}
	
	sendlen = strlen(argv[1]);

	/* Allocate STRING buffers for the request and the reply */

	if((sendbuf = (char *) tpalloc("STRING", NULL, sendlen+1)) == NULL) {
		(void) fprintf(stderr,"Error allocating send buffer\n");
		tpterm();
		exit(1);
	}

	if((rcvbuf = (char *) tpalloc("STRING", NULL, sendlen+1)) == NULL) {
		(void) fprintf(stderr,"Error allocating receive buffer\n");
		tpfree(sendbuf);
		tpterm();
		exit(1);
	}

	(void) strcpy(sendbuf, argv[1]);

	/* Request the service TOUPPER, waiting for a reply */
	ret = tpcall("TOUPPER", (char *)sendbuf, 0, (char **)&rcvbuf, &rcvlen, (long)0);

	if(ret == -1) {
		(void) fprintf(stderr, "Can't send request to service TOUPPER\n");
		(void) fprintf(stderr, "Tperrno = %d\n", tperrno);
		tpfree(sendbuf);
		tpfree(rcvbuf);
		tpterm();
		exit(1);
	}

	(void) fprintf(stdout, "Returned string is: %s\n", rcvbuf);

	/* Free Buffers & Detach from System/T */
	tpfree(sendbuf);
	tpfree(rcvbuf);
	tpterm();
	return(0);
}
