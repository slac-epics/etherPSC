#include "bitPSCInclude.h"
#include <osiSock.h>

typedef struct
	{
	    struct ETHERPSCNODE	*pnode;
	    struct sockaddr_in	sockAddr;	/* for transmission */
	    unsigned int	sockAddrSize;
	    unsigned short	present;
	    unsigned short	busy;
	    unsigned short	unanswered;
	    PSCRECORD		record[SIGNAL_MAXNUM+1];
	} ETHERPSCNODE;

typedef struct
	{
	    int			sock;
	    ETHERPSCNODE	*pnode;
	} ETHERPSC;

long	etherPSCdrvInitRecord( struct bitbusio*, struct dbCommon* );

