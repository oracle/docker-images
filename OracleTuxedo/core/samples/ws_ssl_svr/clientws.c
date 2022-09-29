/*
** Copyright (c) 2022 Oracle and/or its affiliates.
** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/

/*
 *  "BEA TUX-A11 Application Administration"
 *  "/WS Configuration Lab"
 *  "clientws.c"
 *  "Version 1.1"
*/

#include <stdio.h>
#include <string.h>
#include "atmi.h"

#define DATA "teststring"

static void
#if defined(__STDC__) || defined(__cplusplus)
print_err(FILE *out_or_err, char *err_str)
#else
print_err(out_or_err, err_str)
	char	*err_str;
	FILE	*out_or_err;
#endif
{
	(void)userlog(err_str);
	(void)fprintf(out_or_err, strcat(err_str, "\n"));
	return;
}

static void
#if defined(__STDC__) || defined(__cplusplus)
usage(char *name)
#else
usage(name)
     char	*name;
#endif
{
	(void)fprintf(stderr, "Usage: %s\n", name);
	return;
}

int
#if defined(__STDC__) || defined(__cplusplus)
main(int argc, char *argv[])
#else
main(argc, argv)
     int argc;
     char *argv[];
#endif /* __STDC__ || __cplusplus */
{
	char	err_str[160];
	char	*snd_buf;
	char	*rcv_buf;
	long	rcv_len;

	/*
	 * Check to make sure that the proper number of parameters were
	 * passed in.
	*/
	if (1 < argc) {
		usage(argv[0]);
		exit(1);
	}

	/*
	 * Attach to the application.
	*/
	if (tpinit((TPINIT *) NULL) == -1) {
		(void)sprintf(err_str,
			"tpinit failed, error = %d: %s", tperrno,
			tpstrerror(tperrno));
		print_err(stderr, err_str);
		exit(1);
	}

	/*
	 * Allocate the buffers used to pass data between client and server.
	*/
	if ((snd_buf = (char *)tpalloc("STRING", NULL, strlen(DATA) + 1)) ==
		NULL) {
		(void)sprintf(err_str,
			"First tpalloc failed, error = %d: %s", tperrno,
			tpstrerror(tperrno));
		print_err(stderr, err_str);
		(void)tpterm();
		exit(1);
	}
	if ((rcv_buf = (char *)tpalloc("STRING", NULL, strlen(DATA) + 1)) ==
		NULL) {
		(void)sprintf(err_str,
			"Second tpalloc failed, error = %d: %s", tperrno,
			tpstrerror(tperrno));
		print_err(stderr, err_str);
		tpfree(snd_buf);
		(void)tpterm();
		exit(1);
	}

	/*
	 * Send the request to the server and process the results.
	*/
	(void)strcpy(snd_buf, DATA);
	if (tpcall("BASICWS", snd_buf, 0, &rcv_buf, &rcv_len, TPSIGRSTRT) == -1) {
		(void)sprintf(err_str,
			"tpcall failed, error = %d: %s", tperrno,
			tpstrerror(tperrno));
		print_err(stderr, err_str);
		tpfree(snd_buf);
		tpfree(rcv_buf);
		(void)tpterm();
		exit(1);
	}
	else {
		/*
		 * Free the buffers and detach from the application.
		*/
		tpfree(snd_buf);
		tpfree(rcv_buf);
		(void)tpterm();
		(void)sprintf(err_str,
			"tpcall succeeded.");
		print_err(stdout, err_str);
		return(0);
	}
}
