#include "config.h"
#define _BSD_SOURCE
#include <string.h>

#ifndef HAVE_STRNCPY
static void strncpy(void) {};
#endif
#ifndef HAVE_STRNCAT
static void strncat(void) {};
#endif
#ifndef HAVE_STRDUP
static void strdup(void) {};
#endif
#ifndef HAVE_STRLCPY
static void strlcpy(void) {};
#endif
#ifndef HAVE_STRLCAT
static void strlcat(void) {};
#endif

int main(void) {
	return 0;
}
