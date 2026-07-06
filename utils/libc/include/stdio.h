#ifndef _STDIO_H
#define _STDIO_H

#include <stdarg.h>

#ifndef NULL
#define NULL    ((void*)0)
#endif

int sprintf(char* s, const char* format, ...);
int vsprintf(char* s, const char* format, va_list args);

#endif