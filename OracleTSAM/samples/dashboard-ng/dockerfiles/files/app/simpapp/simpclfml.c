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
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <stdint.h>
#include <errno.h>
#include <time.h>

#include "atmi.h"
#include "optfml.h"
#include "fml32.h"

/*
typedef struct
{
	char		m_data[0];
} map_t;
*/

int 
psetpbegin(unsigned long timeout, long flags)
{
	return 0;
}

int 
psetpcommit(long flags)
{
	return 0;
}

int 
psetpabort(long flags)
{
	return 0;
}

char *myindex(char *str,int c)
{
    int i,j,k,s;
    while(*str != 0 && *str != c)
    {   
        str++;
    }
    return str;
}

int gcd(int x,int y)
{
    int     t;

    if(0 == x || y == 0)
    {
        return -1;
    }

    if(x < y)
    {
        t = x;
        x = y;
        y = t;
    }

    while((t = x % y) != 0)
    {
        x = y;
        y = t;
    }

    return y;
}

void 
usage(char *name)
{
	fprintf(stderr,"Usage:\n %s -I -N -D -s -n -i -e -t\n" , name);
	fprintf(stderr," capital is for server, lowercase is for client\n");
}
#if defined(__stdc__) || defined(__cplusplus)
main(int argc, char *argv[])
#else
main(argc, argv)
int argc;
char *argv[];
#endif
{
	FBFR32			*sendbuf;
	char			*recvbuf;
	char			*svcname;
	long			sendlen, recvlen;
	int				ret;
	char			opt;
	int				igerr;
	int 			interval;
	int				times;
	int (*ptpbegin)(unsigned long timeout, long flags); 
	int	(*ptpcommit)(long flags) ;
	int	(*ptpabort)(long flags);
	int				timeout;
	int				i,j,k,s;
	struct timespec req;
	struct timeval	start;
	struct timeval	end;
	int				cntub;
	char			is_e;
	char			is_t;
	int				len;
	int				seq;
	short			opt_n;
	short			opt_d;
	short			opt_i;
	char			opt_o[50];
	char			opt_z[500];
	char			opt_zbk[500];
	char			stop;
    int             dn_cnt;
    int             d_first;
    int             d_last;
    int             n_first;
    int             n_last;
    int             d_cnt;
    int             n_cnt;
    char            *str;
    int            **call_array;
    int             silent;


	svcname = NULL;
	ptpbegin = psetpbegin;
	ptpcommit = psetpcommit;
	ptpabort = psetpabort;
	igerr = 0;
	interval = 0;
	times = 1;
	is_e = 0;
	is_t = 0;
	opt_n = 1;
	opt_d = 1;
	opt_i = 0;
        d_first = 1;
        d_last = 1;
        n_first = 1;
        n_last = 1;
        silent = 0;


	memset(opt_z,0,sizeof(opt_z));
	memset(opt_o,0,sizeof(opt_o));
	cntub = 0;

	for(i = 1;i < argc;)
	{
		if(argv[i][0] != '-')
		{
			ret = sprintf(opt_z + cntub,"%s ",argv[i]);
			cntub += ret;
			i++;
			continue;
		}
		else if(argv[i][2] != 0) /*length > 2*/
		{
			printf("option err:%s\n",argv[i]);
			exit(1);
		}

		opt = argv[i][1];

		switch(opt)
		{
			case 'D':
			{
                str = myindex(argv[i + 1],'-');
                if(*str != 0)
                {
                    d_last = atoi(str + 1);
				    if(d_last < 1 || d_last > 15)
				    {
					    fprintf(stderr,"Option D must be between 1 and 15\n",argv[i]);
				    	exit(1);
				    }
                }
                else
                {
                    d_last = -1;
                }

                *str=0;
                d_first = atoi(argv[i + 1]);
				if(d_first < 1 || d_first > 15)
				{
					fprintf(stderr,"Option D must be between 1 and 15\n",argv[i]);
					exit(1);
				}

                if(d_last == -1)
                {
                    d_last = d_first;
                }


				i += 2;
				break;
			}
			case 'N':
			{
                str = myindex(argv[i + 1],'-');
                if(*str != 0)
                {
                    n_last = atoi(str + 1);
				    if(n_last < 1)
				    {
				    	fprintf(stderr,"Option N must be bigger than 1\n");
				    	exit(1);
				    }   
                }
                else
                {
                    n_last = -1;
                }

                *str=0;
                n_first = atoi(argv[i + 1]);
				if(n_first < 1)
				{
					fprintf(stderr,"Option N must be bigger than 1\n");
					exit(1);
				}

                if(n_last == -1)
                {
                    n_last = n_first;
                }

				i += 2;
				break;
			}
			case 'n':
			{
				times = atoi(argv[i + 1]);
				i += 2;
				
				break;
			}
			case 'I':
			{
				ret = atoi(argv[i + 1]);
				if(ret < 0)
				{
					fprintf(stderr,"the %s must be bigger than 0\n",argv[i]);
					exit(1);
				}

				opt_i = ret;

				i += 2;
				break;
			}
			case 'i':
			{
				interval = atoi(argv[i + 1]);
				if(interval < 0)
				{
					fprintf(stderr,"the %s must be bigger than 0\n",argv[i]);
					exit(1);
				}

				req.tv_sec = interval / 1000;
				req.tv_nsec = (interval % 1000) * 1000000;
				i += 2;
				break;
			}
			case 't':
			{
				if(is_e == 1)
				{
					fprintf(stderr,"argument -e and -t can't be together\n");
                    exit(1);
				}
				is_t = 1;

				timeout = atoi(argv[i + 1]);
				if(timeout < 0)
				{
					fprintf(stderr,"the %s must be bigger than 0\n",argv[i]);
					exit(1);
				}
/*				printf("timeout %d\n",timeout);*/

				ptpbegin = tpbegin;
				ptpcommit = tpcommit;
				ptpabort = tpabort;
			
				i += 2;
				break;
			}
			case 's':
			{
				svcname = argv[i + 1];
				i += 2;
				break;
			}
			case 'e':
			{
				if(is_t == 1)
				{
					fprintf(stderr,"argument -e and -t can't be together\n");
                    exit(1);
				}
				is_e = 1;

				igerr = 1;
				i += 1;
				break;
			}
                        case 'S':
                        {
                                silent = 1;
                                i += 1;
                                break;

                        }
	/*		case '-':
			{
				ret = sprintf(opt_z + cntub,"%s ",argv[i + 1]);
				cntub += ret;
				i += 2;

				break;
			}*/
			case 'h':
			{
				system("cat ./ReadMe.txt");
				exit(0);
			}
			default:
			{
				printf("Error:%s is unable to be recognized\n",argv[0]);
				exit(1);
			}
		}
	}
    
    i = d_last - d_first;
    if(i < 0)
    {
        printf("Option D error:%d-%d\n",d_first,d_last);
        exit(1);
    }
    i++;

    j = n_last - n_first;
    if(j < 0)
    {
        printf("Option N error:%d-%d\n",n_first,n_last);
        exit(1);
    }
    j++;

    
    dn_cnt = gcd(i,j);
    dn_cnt = i * j / dn_cnt;
    call_array = (int **)malloc(sizeof(int *) * dn_cnt); 

    d_cnt = 0;
    n_cnt = 0;
    for(i = 0;i < dn_cnt;i++)
    {
        call_array[i] = (int *)malloc(sizeof(int) * 2);
        call_array[i][0] = d_first + d_cnt;
        call_array[i][1] = n_first + n_cnt;

        d_cnt++;
        if(d_first + d_cnt > d_last)
        {
            d_cnt = 0;
        }

        n_cnt++;
        if(n_first + n_cnt > n_last)
        {
            n_cnt = 0;
        }
    }


	if(NULL == svcname)
	{
		system("cat ./ReadMe.txt");
		exit(1);
	}


/*	printf("d %d,n %d,i %d,l %d,o %s,z %s\n",opt_d,opt_n,opt_i,opt_d,opt_o,opt_z);*/

	/* Request the service TOUPPER, waiting for a reply */

	gettimeofday(&start,NULL);
	
	if(times <= 0)
	{
		stop = 1; 
	}
	else
	{
		stop = 0;
	}

    s = 0;
	strcpy(opt_zbk,opt_z);

	/* Attach to System/T as a Client Process */
	if(tpinit((TPINIT *) NULL) == -1) 
	{
		(void) fprintf(stderr, "Tpinit failed -- %s\n",tpstrerror(tperrno));
		exit(1);
	}

	for(k = 0;k < times || stop;k++)
	{

	ret = ptpbegin(timeout,0);
	if(-1 == ret)
	{
		fprintf(stderr, "tpbegin failed -- %s\n",tpstrerror(tperrno));
	        goto tran_begin;
        }

	if((sendbuf = (FBFR32 *) tpalloc("FML32", NULL, Fneeded32(6,500))) == NULL) 
	{
		fprintf(stderr, "tpalloc sendbuf failed -- %s\n",tpstrerror(tperrno));
		goto alloc_send;
	}

	if((recvbuf = (char *) tpalloc("STRING", NULL, 0L )) == NULL) 
	{
		fprintf(stderr, "tpalloc recvbuf failed -- %s\n",tpstrerror(tperrno));
		goto alloc_recv;
	}
	
 
                opt_d = call_array[s][0];
                opt_n = call_array[s][1];
                s++;
                if(s == dn_cnt)
                {
                    s = 0;
                }
		/*deal buffer for z_opt*/
		strcpy(opt_z,opt_zbk);
		ret = strlen(opt_z);
		if(ret > 0)
		{
    	    ret--;
            opt_z[ret]=0;
		}
	/*	printf("opt_z %d ,%d,%d\n",ret,opt_z[0],opt_z[1]);*/
	
		for(i = 0;i < opt_d;i++)
		{
			opt_z[ret + i] = 'x';
		}
		opt_z[ret + i] = 0;

		/*deal buffer for opt_o*/
		len = strlen(svcname);
		for(i = len - 1;i >= 0;i--)
		{
			if(svcname[i] < '0' || svcname[i] > '9')
			{
				break;
			}
		}

		seq = atoi(svcname + i + 1);
		for(i = 0,j = seq;j < seq + opt_d;j++)
		{
			ret = sprintf(opt_o + i,"%d,",j);
			i += ret;
		}
		i--;
		opt_o[i] = 0;

	Fadd32(sendbuf,OPT_D,(char *)&opt_d,(FLDLEN32)sizeof(opt_d));
/*	printf("ret int %d,D %d,d %d,rr %s\n",ret,OPT_D,opt_d,Fstrerror32(Ferror32));*/
	Fadd32(sendbuf,OPT_N,(char *)&opt_n,(FLDLEN32)0);
	Fadd32(sendbuf,OPT_L,(char *)&opt_d,(FLDLEN32)0);
	Fadd32(sendbuf,OPT_I,(char *)&opt_i,(FLDLEN32)0);
/*	printf("ret int %d,rr %s\n",ret,Fstrerror32(Ferror32));*/
	Fadd32(sendbuf,OPT_O,opt_o,(FLDLEN32)0);
	Fadd32(sendbuf,OPT_Z,opt_z,(FLDLEN32)0);

		ret = tpcall(svcname, (char *)sendbuf, 0, (char **)&recvbuf, &recvlen, (long)0);
		if(-1 == ret)
		{
			fprintf(stderr, "tpcall failed -- %s, times %d\n",tpstrerror(tperrno),k);
			if(!igerr)
			{
				goto call;
			}
		}
		else
		{
                        if(!silent)
                        {
			    printf("Returned string is: %s\n", recvbuf);
                        }
		}

		if(interval != 0)
		{
			ret = nanosleep(&req,NULL);
			if(ret < 0)
			{
				fprintf(stderr,"nanosleep failed -- errno %d\n",errno);
			}
		}
		ptpcommit(0);
		tpfree((char *)sendbuf);
		tpfree((char *)recvbuf);
	}
	tpterm();
	gettimeofday(&end,NULL);
	printf("total time:%ldms \n",(end.tv_sec - start.tv_sec) * 1000 + (end.tv_usec - start.tv_usec) / 1000);

	return 0;

call:
	tpfree((char *)recvbuf);
alloc_recv:
	tpfree((char *)sendbuf);
alloc_send:
	ptpabort(0);
tran_begin:	
	tpterm();
	fprintf(stderr,"clean err \n");
	return 1;
}
