/*
	Copyright (c) 2017 Oracle, Inc.
	All rights reserved

	THIS IS UNPUBLISHED PROPRIETARY
	SOURCE CODE OF ORACLE, Inc.
	The copyright notice above does not
	evidence any actual or intended
	publication of such source code.
*/

#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <ctype.h>
#include <atmi.h>	/* TUXEDO Header File */
#include <userlog.h>	/* TUXEDO Header File */
#include <fml32.h>
#include "optfml.h"

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

/*	tpopen();*/
	return(0);
}

/* This function performs the actual service requested by the client.
   Its argument is a structure containing among other things a pointer
   to the data buffer, and the length of the data buffer.
*/

char *myindex(char *str,int c)
{
        int i,j,k,s;
        while(*str != 0 && *str != c)
        {
                str++;
        }
   return str;
}
int get_callnum(char *str,int depth,char c,int len)
{
	int				i,j,k,s;
	char			*tmp;


	s = str[len];
	str[len] = 0;

	if(depth < 2)
	{
		return -1;
	}

	tmp = str;
	for(i = 0;i < depth - 1;i++)
	{
		tmp = myindex(tmp,c);		
/*userlog("the index get %d\n",tmp);*/
		tmp++; 
	}

	i = atoi(tmp);
	str[len] = s;

	return i;
}

#ifdef __cplusplus
extern "C"
#endif
void
#if defined(__STDC__) || defined(__cplusplus)
_SVCNAME_(TPSVCINFO *rqst)
#else
_SVCNAME_(rqst)
TPSVCINFO *rqst;
#endif
{
	int					i,j,k,s;
	short				depth;
	short				interval;
	short				times;
	FBFR32				*buf;
	char				*recvbuf;
	char				log[100];
	char				temp[300];
	int					tol_len;
	int					ret;
	struct timespec		delay;
	char				opt;
	short				tol_depth;
	char				call[50];
	char				opt_z[500];
	char				opt_o[50];
	char				initcall;
	int					pos_seq;
	int					next_depth;
	int					next_call;
	FLDLEN32			len;
	char				*sendbuf;
    char                *log_env;

    log_env = getenv("PRINT_SERVER_LOG");

	buf = (FBFR32 *)rqst->data;
	
	memset(call,0,sizeof(call));
	memset(temp,0,sizeof(temp));
	memset(opt_z,0,sizeof(opt_z));
	memset(opt_o,0,sizeof(opt_o));
	initcall = '0';
	interval = -2;

	len = sizeof(depth);
	Fget32(buf,OPT_D,0,(char *)&depth,&len);
	if(depth < 1 || depth > 10000)
	{
		sprintf(log,"Error:-D must be between 1 and 10000");
		userlog(log);
		tpreturn(TPFAIL,0,rqst->data,0L,0);
	}
 

	len = sizeof(times);
	ret = Fget32(buf,OPT_N,0,(char *)&times,&len);
	if(times < 1)
	{
		sprintf(log,"Error:-N must be bigger than 0");
		userlog(log);
		tpreturn(TPFAIL,0,rqst->data,0L,0);
	}
if(ret < 0)
{
	sprintf(log,"ret int %d,len %d,err %s,in %d",ret,len,Fstrerror32(Ferror32),interval);
	userlog(log);
}
	len = sizeof(interval);
	ret = Fget32(buf,OPT_I,0,(char *)&interval,&len);
	if(interval < 0)
	{
		sprintf(log,"Error:-I must be bigger than 0");
		userlog(log);
		tpreturn(TPFAIL,0,rqst->data,0L,0);
	}
	delay.tv_sec = interval / 1000;
	delay.tv_nsec = (interval % 1000) * 1000000;

	if(ret < 0)
{

	sprintf(log,"ret int %d,len %d,err %s,in %d",ret,len,Fstrerror32(Ferror32),interval);
	userlog(log);
}
	len = sizeof(tol_depth);
	Fget32(buf,OPT_L,0,(char *)&tol_depth,&len);
	if(tol_depth < 1 || tol_depth > 10000)
	{
		sprintf(log,"Error:-L must be between 1 and 10000");
		userlog(log);
		tpreturn(TPFAIL,0,rqst->data,0L,0);
	}

	len = sizeof(opt_z);
	ret = Fget32(buf,OPT_Z,0,(char *)&opt_z,&len);
	if(NULL == opt_z || 0 == opt_z[0])
	{
		sprintf(log,"Error:no -Z argument");
		userlog(log);
		tpreturn(TPFAIL,0,rqst->data,0L,0);
	}
if(ret < 0)
{
	sprintf(log,"ret int %d,len %d,err %s,s %s",ret,len,Fstrerror32(Ferror32),opt_z);
	userlog(log);
}
	len = sizeof(opt_o);
	Fget32(buf,OPT_O,0,(char *)&opt_o,&len);
	if(NULL == opt_o || 0 == opt_o[0])
	{
		sprintf(log,"Error:no -O argument");
		userlog(log);
		tpreturn(TPFAIL,0,rqst->data,0L,0);
	}

	/*get one level call*/
	if(depth == tol_depth)
	{
		initcall = '1';
	}
	
    if(log_env != NULL)
    {
    	sprintf(log,"tol:%d,depth:%d,total times:%d,interval:%d,seq:%s,data:%s",tol_depth , depth ,times,interval,opt_o,opt_z);
    	userlog(log);
    }
	/*make character upper*/
	for(i = 0;i < strlen(opt_z) - depth;i++)
	{
		if(opt_z[i] >= 'a' && opt_z[i] <= 'z')
		{
			opt_z[i] -= 0x20;
		}
	}
	opt_z[i] = '!';

	Fchg32(buf,OPT_Z,0,opt_z,(FLDLEN32)0);

    if(log_env != NULL)
    {
    	sprintf(log,"depth:%d,total times:%d,interval:%d,seq:%s,data:%s",tol_depth - depth + 1,times,interval,opt_o,opt_z);
    	userlog(log);
    }

	if(interval > 0)
	{
		nanosleep(&delay,NULL);
	}
	if(depth > 1)
	{
		/*make depth - 1*/
		depth--;	

		for(i = 0;i < times;i++)
		{
			buf = (FBFR32 *)rqst->data;

            if(log_env != NULL)
            { 
	            sprintf(log,"get next call depth:%d,total times:%d,interval:%d,seq:%s,data:%s",tol_depth - depth + 1,times,interval,opt_o,opt_z);
	            userlog(log);
            }
			next_depth = tol_depth - depth + 1;
			next_call = get_callnum(opt_o,next_depth,',',strlen(opt_o));
			sprintf(call,"TOUPPER%d",next_call);

            if(log_env != NULL)
            { 
			    userlog(call);
            }

    if(log_env != NULL)
    {
    	sprintf(log,"been call1");
    	userlog(log);
    }
   
			Fchg32(buf,OPT_D,0,(char *)&depth,(FLDLEN32)0);
    if(log_env != NULL)
    {
    	sprintf(log,"been call2");
    	userlog(log);
    }
			s = tpcall(call,rqst->data,0,&rqst->data,&rqst->len,0);
			if(-1 == s)
			{
				sprintf(log, "tpcall failed -- %s, times %d\n",tpstrerror(tperrno),i);
				userlog(log);
				tpreturn(TPFAIL,0,rqst->data,0,0);
			}
    if(log_env != NULL)
    {
    	sprintf(log,"been cal3");
    	userlog(log);
    }
			if(interval > 0)
			{
				nanosleep(&delay,NULL);
			}

		}
	}

	if('1' == initcall)
	{
		buf = (FBFR32 *)rqst->data;
		len = sizeof(opt_z);
		Fget32(buf,OPT_Z,0,(char *)&opt_z,&len);
		sendbuf = tpalloc("STRING",NULL,0);
		strcpy(sendbuf,opt_z);
		tpreturn(TPSUCCESS, 0, sendbuf, 0L, 0);
	}

	tpreturn(TPSUCCESS, 0, rqst->data, 0L, 0);
}
