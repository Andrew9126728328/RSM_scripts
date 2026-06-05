#include <stddef.h>

#define VENDOR			"SPE SARMAT"
#define PRODUCT			"MUGS-02"
#define VERSION_MAJOR	0
#define VERSION_MINOR	4

#define PROJ_VER_STRING_(ma,mi)     ""#ma"."#mi""
#define PROJ_VER_STRING(ma,mi)      PROJ_VER_STRING_(ma,mi) 

typedef struct signatute_s
{
	struct
	{
		char date[16];
		char time[16];
	}build;
	long crc;
	char vendor[16];
	char product[32];
	char version[16];
}signature_t;

#pragma segment CONST=signature,attr=CONST,locate=0xfe0002

const signature_t signature =
{
	__DATE__,__TIME__, 0, VENDOR, PRODUCT, PROJ_VER_STRING(VERSION_MAJOR,VERSION_MINOR)
};

#pragma 
