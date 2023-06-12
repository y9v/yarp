// This files must be required before any system header
// as it influences which functions system headers declare.

#ifndef YARP_DEFINES_H
#define YARP_DEFINES_H

// For strnlen(), strncasecmp()
#ifndef _XOPEN_SOURCE
#define _XOPEN_SOURCE 700
#endif

#ifndef YP_IMPORTED_FUNCTION
#if defined(_WIN32)
# define YP_IMPORTED_FUNCTION __declspec(dllimport)
#else
# define YP_IMPORTED_FUNCTION __attribute__((__visibility__("default")))
#endif
#endif

#ifndef YP_EXPORTED_FUNCTION
#if defined(_WIN32)
# define YP_EXPORTED_FUNCTION __declspec(dllexport)
#else
# define YP_EXPORTED_FUNCTION __attribute__((__visibility__("default")))
#endif
#endif

#if defined(_WIN32)
# define YP_ATTRIBUTE_UNUSED
#else
# define YP_ATTRIBUTE_UNUSED __attribute__((unused))
#endif

#endif
