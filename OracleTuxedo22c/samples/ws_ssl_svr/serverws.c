/*
** Copyright (c) 2022 Oracle and/or its affiliates.
** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/

/*
 *  "BEA TUX-A11 Application Administration"
 *  "/WS Configuration Lab"
 *  "serverws.c"
 *  "Version 1.1"
*/

#include <string.h>
#include <stdio.h>
#include "atmi.h"
#include "userlog.h"

#define DATA "teststring"

int
#if defined(__STDC__) || defined(__cplusplus)
tpsvrinit(int argc, char *argv[])
#else
tpsvrinit(argc, argv)
	int	argc;
	char	**argv;
#endif
{
	/* The following two lines prevent warning messages from lint and */
	/* some compilers. */
	argc = argc;
	argv = argv;

	/* Write an initialization message to the user log. */
	userlog("Initializing serverbasic.");
	return(0);
}

#ifdef __cplusplus
extern "C"
#endif
void
#if defined(__STDC__) || defined(__cplusplus)
BASICWS(TPSVCINFO *call_buf)
#else
BASICWS(call_buf)
	TPSVCINFO *call_buf;
#endif
{

	if (!strcmp(call_buf->data, DATA)) {
		tpreturn(TPSUCCESS, 0L, call_buf->data, 0L, 0L);
	}
	else {
		tpreturn(TPFAIL, 0L, call_buf->data, 0L, 0L);
	}
}
