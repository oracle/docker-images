/*
	Copyright (c) 2011 Oracle, Inc.
	All rights reserved

	THIS IS UNPUBLISHED PROPRIETARY
	SOURCE CODE OF ORACLE, Inc.
	The copyright notice above does not
	evidence any actual or intended
	publication of such source code.
*/


/*	(c) 2003 BEA Systems, Inc. All Rights Reserved. */
/*	Copyright (c) 1997 BEA Systems, Inc.
  	All rights reserved

  	THIS IS UNPUBLISHED PROPRIETARY
  	SOURCE CODE OF BEA Systems, Inc.
  	The copyright notice above does not
  	evidence any actual or intended
  	publication of such source code.
*/

/* #ident	"@(#) samples/atmi/simpapp/simpserv.c	$Revision: 1.7 $" */

#include <stdio.h>
#include <ctype.h>
#include <atmi.h>	/* TUXEDO Header File */
#include <userlog.h>	/* TUXEDO Header File */

/* tpsvrinit is executed when a server is booted, before it begins
   processing requests.  It is not necessary to have this function.
   Also available is tpsvrdone (not used in this example), which is
   called at server shutdown time.
*/

#if defined(__STDC__) || defined(__cplusplus)
tpsvrinit(int argc, char *argv[])
#else
tpsvrinit(argc, argv)
int argc;
char **argv;
#endif
{
	/* Some compilers warn if argc and argv aren't used. */
	argc = argc;
	argv = argv;

	/* simpapp is non-transactional, so there is no need for tpsvrinit()
	   to call tx_open() or tpopen().  However, if this code is modified
	   to run in a Tuxedo group associated with a Resource Manager then
	   either a call to tx_open() or a call to tpopen() must be inserted
	   here.
	*/

	/* userlog writes to the central TUXEDO message log */
	userlog("Welcome to the simple server");
	return(0);
}

/* This function performs the actual service requested by the client.
   Its argument is a structure containing among other things a pointer
   to the data buffer, and the length of the data buffer.
*/

#ifdef __cplusplus
extern "C"
#endif
void
#if defined(__STDC__) || defined(__cplusplus)
TOUPPER(TPSVCINFO *rqst)
#else
TOUPPER(rqst)
TPSVCINFO *rqst;
#endif
{

	int i;

	for(i = 0; i < rqst->len-1; i++)
		rqst->data[i] = toupper(rqst->data[i]);

	/* Return the transformed buffer to the requestor. */
	tpreturn(TPSUCCESS, 0, rqst->data, 0L, 0);
}
