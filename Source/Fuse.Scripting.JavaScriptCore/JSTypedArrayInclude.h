#include <Availability.h>
#ifndef __MAC_10_12
	#define __MAC_10_12 101200
#endif
#ifndef __IPHONE_10_0
	#define __IPHONE_10_0 100000
#endif
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0 || __MAC_OS_X_VERSION_MAX_ALLOWED >= __MAC_10_12
	#include <JavaScriptCore/JSTypedArray.h>
	#define JAVASCRIPTCORE_ARRAYBUFFER_SUPPORT
#endif
