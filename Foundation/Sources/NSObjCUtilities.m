/*
 NSUtilities.m

 Copyright (C) 1996 Free Software Foundation, Inc.

 Author:	Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
 Date:	August 1994

 NSLog
 Author:	Adam Fedor <fedor@boulder.colorado.edu>
 Date:	November 1996

 Default Encoding
 Author:	Stevo Crvenkovski <stevo@btinternet.com>
 Date:	December 1997

 ARM Softfloat wrapper
 Author:	Nikolaus Schaller <hns@computer.org>
 Date:	2003 - August 2007

 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.

 */

#define TRACE_OBJECT_ALLOCATION	1

#if __arm__
#define atof _atof	// rename atof in loaded header file to handle automatic hard/softfloat
#endif

#include <sys/types.h>
#ifdef __linux__
#include <sys/sysinfo.h>	// ignore warning about using kernel headers from user space
#endif
#if !defined(__WIN32__) && !defined(_WIN32)
#include <pwd.h>		// for getpwnam()
#endif

#include <dlfcn.h>
#include <math.h>

#import <Foundation/NSObjCRuntime.h>

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSCalendarDate.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSProcessInfo.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSEnumerator.h>

#import "NSPrivate.h"

#ifdef __linux__	// compile this on Linux only

//*****************************************************************************
//
//	Definitions and translations for dynamic loading with the simple dynamic
//	loading library (dl).	- unloading modules not implemented
//
//  here some info for Linux: http://www.linux.com/howtos/Program-Library-HOWTO/miscellaneous.shtml
//
//*****************************************************************************

// FIXME: does the dtable still exist?

// From the objc runtime -- needed when invalidating the dtable
extern void __objc_install_premature_dtable(Class);
//extern void sarray_free(struct sarray *);

/* runtime.h defines:
 * extern void (*_objc_load_callback)(Class class, struct objc_category * category);
 * typedef struct objc_category *Category;
 */

// Our current callback function from objc_loadmodule
void (*objc_loadmodule_callback)(Class, Category) = NULL;

// dynamic loader was sucessfully initialized.
static BOOL	__dynamicLoaderInitialized = NO;

// List of modules we have loaded (by handle)
static struct objc_list *__dynamicModules = NULL;

#define CTOR_LIST "__CTOR_LIST__"				// GNU name for the CTOR list

#ifndef RTLD_GLOBAL
#define RTLD_GLOBAL 0
#endif

#ifndef RTLD_NEXT
#define RTLD_NEXT 	((void *) -1l)
#endif

typedef void *dl_handle_t;						// Types defined appropriately
typedef void *dl_symbol_t;						// for the dynamic linker

// Do any initialization necessary.  Return 0
// on success (or if no initialization needed.

static int objc_dynamicInit(const char *exec_path)
{
	return 0;
}

// Link in module given by the name 'module'.
// Return a handle which can be used to get
// information about the loded code. mode is ignored

static dl_handle_t objc_dynamicLink(const char *module, int mode, const char *debug_file)
{
	dl_handle_t *ret;
#if 1
	fprintf(stderr, "objc_dynamicLink(%s, %d, %s)\n", module, mode, debug_file);
#endif
	ret=(dl_handle_t)dlopen(module, RTLD_LAZY | RTLD_GLOBAL);
#if 1
	fprintf(stderr, "objc_dynamicLink => %08lx\n", (unsigned int) ret);
#endif
	return ret;
}

// remove the code from memory associated with
// the module 'handle'

static int objc_dynamicUnlink(dl_handle_t handle)
{
	return dlclose(handle);
}

// Print error message prefaced by error_string
// relevant to the last error encountered

static void objc_dynamicError(FILE *error_stream, const char *error_prefix)
{
	if(error_stream)
		fprintf(error_stream, "%s:%s\n", error_prefix, dlerror());
}

// Debugging define these if they are available

static int __objc_dynamic_undefined_symbol_count(void)		{ return 0; }
static char** __objc_dynamic_list_undefined_symbols(void)	{ return NULL; }

// Check to see if there are any undefined
// symbols. Print them out.

int objc_check_undefineds(FILE *errorStream)
{
	int i, count = __objc_dynamic_undefined_symbol_count();

	if (count != 0)
		{
		char **undefs = __objc_dynamic_list_undefined_symbols();

		if (errorStream)
			fprintf(errorStream, "Undefined symbols:\n");
		for (i = 0; i < count; i++)
			if (errorStream)
				fprintf(errorStream, "  %s\n", undefs[i]);

		return 1;
		}

	return 0;
}

// Invalidate the dtable so it will be rebuild
// when a message is sent to the object

void objc_invalidate_dtable(Class class)
{
	Class s;
#if 0
	fprintf(stderr, "invalidate dtable for %s\n", class_getName(class));
#endif
#if FIXME
	if (class->dtable == objc_get_uninstalled_dtable())
		return;
	sarray_free(class->dtable);
	__objc_install_premature_dtable(class);
	for (s = class->subclass_list; s; s=s->sibling_class)
		objc_invalidate_dtable(s);	// recursive
#endif
}

// FIXME: not really used

int objc_initializeLoading(FILE *errorStream)
{
	const char *path = [[[NSBundle mainBundle] bundlePath] fileSystemRepresentation];

	NSDebugLog(@"(objc-load): initializing dynamic loader for %s\n", path);

	if (objc_dynamicInit(path))
		{
		objc_dynamicError(errorStream, "Error init'ing dynamic linker");
		return 1;
		}

	__dynamicLoaderInitialized = YES;

	return 0;
}

// A callback received from Object initializer
// (_objc_exec_class). Do what we need to do
// and call our own callback.

void objc_load_callback_function(Class class, struct objc_category *category)
{
#if 1
	fprintf(stderr, "objc_load_callback_function(%s, %p)\n", class_getName(class), category);
#endif
#if FIXME
	if (class != Nil && category) 		// Invalidate the dtable, so it will be rebuilt correctly
		{
			objc_invalidate_dtable(class);
			objc_invalidate_dtable(class->class_pointer);
		}

#endif
	if (objc_loadmodule_callback)
		(*objc_loadmodule_callback)(class, (Category) category);	// pass to user provided callback (_bundleLoadCallback)
#if 1
	fprintf(stderr, "objc_load_callback_function done\n");
#endif
}

int objc_loadModule(char *filename,
					void (*loadCB)(Class, Category),
					int *error					)
{ // load a single module
	char *modPtr[2] = { filename, NULL};
	if(objc_loadModules(modPtr, stderr, loadCB, NULL, NULL) == 1)
	   return 1;	// success
	if(error) *error=1;
	return 0;	// nok
}

long objc_loadModules (char *list[],
					   void *errStream,
					   void (*loadCB) (Class, Category),
					   void **header,
					   char *debugFilename)
{
	typedef void (*void_fn)();
	dl_handle_t handle;
	char *filename;
	long success=0;
	while((filename=*list++))
		{
#if 1
		fprintf(stderr, "objc_load_module %s\n", filename);
#endif

		if (!__dynamicLoaderInitialized && objc_initializeLoading(errStream))
			return 0;	// failed to initialize

		// module loading could be serialized by a lock
		if(objc_loadmodule_callback)
			{ // there is already a callback installed
			NSLog(@"objc_loadModule already runing (threads?)");
			return 0;
			}
		objc_loadmodule_callback = loadCB;	// most probably _bundleLoadCallback
		_objc_load_callback = objc_load_callback_function;	// install our callback into objc.so

		NSDebugLog(@"Debug (objc-load): Linking file %s\n", filename);
#if 0
		fprintf(stderr, "objc_load_module: Linking file %s\n", filename);
#endif
		// Link in the object file
		if ((handle = objc_dynamicLink(filename, 1, debugFilename)) == 0)
			{
#if 1
			fprintf(stderr, "objc_load_module: error linking file %s\n", filename);
#endif
			objc_dynamicError(errStream, "Error (objc-load)");
			return 0;
			}
#if 0
		fprintf(stderr, "objc_load_module: linked\n");
#endif
#if FIXME
		__dynamicModules = list_cons(handle, __dynamicModules);
#endif
#if 0
		fprintf(stderr, "objc_load_module: after list_cons\n");
#endif

		// If there are any undefined symbols, we can't load the bundle
		if (objc_check_undefineds(errStream))
			{
#if 1
			fprintf(stderr, "objc_load_module: has undefined symbols, can't really load\n");
#endif
			objc_dynamicUnlink(handle);
			return 1;
			}

		_objc_load_callback = NULL;
		objc_loadmodule_callback = NULL;
		success++;
#if 1
		fprintf(stderr, "objc_load_module: successfully loaded\n");
#endif
		}

	return success;
}

long objc_unloadModules(void *errStream, void (*unloadCb)(Class, Category))
{
	return 0;
}

char *objc_moduleForAddress(const void *address)
{
#ifdef __linux__	// not loaded by <dlfcn.h>
	typedef struct
	{
	__const char *dli_fname;	/* File name of defining object.  */
	void *dli_fbase;			/* Load address of that object.  */
	__const char *dli_sname;	/* Name of nearest symbol.  */
	void *dli_saddr;			/* Exact value of nearest symbol.  */
	} Dl_info;
	extern int dladdr(const void *__address, Dl_info *__info);
#endif
	Dl_info info;
	if(dladdr(address, &info))	// find filename for address of class record
		{
#if 0
		NSLog(@"objc_moduleForAddress filename=%s", info.dli_fname);
#endif
		return (char *) info.dli_fname;
		}
#if 1
	NSLog(@"addr not found");
#endif
	return NULL;
}

#endif	// __linux__


//*****************************************************************************
//
// 		NSRange - range functions
//
//*****************************************************************************

NSRange
NSUnionRange(NSRange aRange, NSRange bRange)
{
	NSRange range;											// Compute a Range from
															// two other Ranges
	range.location = MIN(aRange.location, bRange.location);
	range.length = MAX(NSMaxRange(aRange),NSMaxRange(bRange)) - range.location;

	return range;
}

NSRange
NSIntersectionRange (NSRange aRange, NSRange bRange)
{
	NSRange range;

	if (NSMaxRange(aRange) < bRange.location
		|| NSMaxRange(bRange) < aRange.location)
		return NSMakeRange(0, 0);

	range.location = MAX(aRange.location, bRange.location);
	range.length = MIN(NSMaxRange(aRange),NSMaxRange(bRange)) - range.location;

	return range;
}

NSString *
NSStringFromRange(NSRange range)
{
	return [NSString stringWithFormat:@"{ %u, %u }", range.location, range.length];
}

NSRange NSRangeFromString(NSString *string)
{ // { location, length }
	NSScanner *scanner = [NSScanner scannerWithString:string];
	NSRange range={ 0, 0 };
	[scanner scanString:@"{" intoString:NULL];	// skip
	if([scanner scanInt:(int *) &range.location])		// try to read
		{
		[scanner scanString:@"," intoString:NULL];	// skip
		[scanner scanInt:(int *) &range.length];
		}
	return range;
}

//*****************************************************************************
//
// 		NSUser functions
//
//*****************************************************************************

NSString *
NSUserName (void)							// Return user's login name as an
{											// NSString object.
	struct passwd *pw;
	NSString *uname;
	if ((uname=[[[NSProcessInfo processInfo] environment] objectForKey:@"LOGNAME"]))
		return uname;
	// get effective user id
	if ((pw = getpwuid(geteuid())) && pw->pw_name && *pw->pw_name != '\0')
		return [NSString stringWithCString: pw->pw_name];
	return [NSString stringWithFormat:@"%d", geteuid()];
}

NSString *NSFullUserName(void)
{ // return full user name
	struct passwd *pw;
	if ((pw = getpwnam([NSUserName() cString])) && pw->pw_gecos && *pw->pw_gecos != '\0')
		return [[[NSString stringWithCString: pw->pw_gecos] componentsSeparatedByString:@","] objectAtIndex:0];
	return @"N.N.";
}

NSString *NSOpenStepRootDirectory(void) { return @"/"; }

NSString *NSTemporaryDirectory(void) { return @"/tmp"; }  // accounts for virtual root /home/myPDA

NSString *NSHomeDirectory (void)
{ // return user's home directory
	return NSHomeDirectoryForUser(NSUserName());
}

// FIXME: we can't use the home directory yet since we have our own /Users area

NSString *NSHomeDirectoryForUser (NSString *login_name)
{ // return home dir for login name
	NSString *h;
	struct passwd *pwd=getpwnam([login_name UTF8String]);
	endpwent();
	/*
	 if(!pwd) return nil;
	 else
	 */
	if(pwd && pwd->pw_uid == 0)
		h=@"/";	// root user - FIXME
	else
		{
		BOOL isDir;
#if 1
		h=[NSString stringWithFormat:@"/Users/%@", login_name];
#else
		h=[NSString stringWithUTF8String:pwd->pw_dir];
#endif
		if(![[NSFileManager defaultManager] fileExistsAtPath:h isDirectory:&isDir] || !isDir)
			return nil;
		}
#if 0
	NSLog(@"NSHomeDirectoryForUser(%@) -> %@", login_name, h);
#endif
	return h;
}

NSArray *NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory directory, NSSearchPathDomainMask domainMask, BOOL expandTilde)
{
	NSMutableArray  *paths = [NSMutableArray arrayWithCapacity:10];
	NSString *expandedPath;
#if 0
	NSLog(@"NSSearchPathForDirectoriesInDomains %d mask %d", directory, domainMask);
#endif
#define ADD_PATH(mask, path) \
if ((domainMask & mask) && ![paths containsObject: path] && [[NSFileManager defaultManager] fileExistsAtPath:expandedPath=[path stringByExpandingTildeInPath]]) \
[paths addObject: expandTilde?expandedPath:path];

	// we could read this from an NSDictionary in Info.plist ...

	switch (directory) {
		case NSAllApplicationsDirectory:
			ADD_PATH(NSUserDomainMask, @"~/Applications");
			ADD_PATH(NSUserDomainMask, @"~/Library/Applications");
			ADD_PATH(NSLocalDomainMask, @"/Applications");
			ADD_PATH(NSLocalDomainMask, @"/Applications/Games");
			ADD_PATH(NSLocalDomainMask, @"/Applications/Utilities");
			ADD_PATH(NSLocalDomainMask, @"/Developer/Applications");
			ADD_PATH(NSLocalDomainMask, @"/Developer/Applications/Utilities");
			ADD_PATH(NSNetworkDomainMask, @"/Network/Applications");
			ADD_PATH(NSSystemDomainMask, @"/Library/Applications");
			ADD_PATH(NSSystemDomainMask, @"/System/Applications");
			ADD_PATH(NSSystemDomainMask, @"/System/Library/CoreServices");
			break;
		case NSApplicationDirectory:
			ADD_PATH(NSUserDomainMask, @"~/Applications");
			ADD_PATH(NSLocalDomainMask, @"/Applications");
			ADD_PATH(NSNetworkDomainMask, @"/Network/Applications");
			ADD_PATH(NSSystemDomainMask, @"/Library/Applications");
			ADD_PATH(NSSystemDomainMask, @"/System/Applications");
			break;
		case NSDemoApplicationDirectory:
			ADD_PATH(NSUserDomainMask, @"~/Applications/Games");
			ADD_PATH(NSLocalDomainMask, @"/Applications/games");
			ADD_PATH(NSNetworkDomainMask, @"/Network/Applications/Games");
			break;
		case NSCoreServiceDirectory:
			ADD_PATH(NSSystemDomainMask, @"/System/Library/CoreServices");
			break;
		case NSDesktopDirectory:
			ADD_PATH(NSUserDomainMask, @"~/Desktop");
			break;
		case NSDeveloperApplicationDirectory:
			ADD_PATH(NSLocalDomainMask, @"/Developer/Applications");
			break;
		case NSAdminApplicationDirectory:
			ADD_PATH(NSLocalDomainMask, @"/Applications/Utilities");
			break;
		case NSAllLibrariesDirectory:
			ADD_PATH(NSUserDomainMask, @"~/Library");
			ADD_PATH(NSLocalDomainMask, @"/Library");
			ADD_PATH(NSNetworkDomainMask, @"/Network/Library");
			ADD_PATH(NSSystemDomainMask, @"/System/Library");
			break;
		case NSLibraryDirectory:
			ADD_PATH(NSUserDomainMask, @"~/Library");
			ADD_PATH(NSLocalDomainMask, @"/Library");
			ADD_PATH(NSNetworkDomainMask, @"/Network/Library");
			ADD_PATH(NSSystemDomainMask, @"/System/Library");
			break;
		case NSDeveloperDirectory:
			ADD_PATH(NSSystemDomainMask, @"/Developer");
			break;
		case NSUserDirectory:
			ADD_PATH(NSSystemDomainMask, @"/Users");
			break;
		case NSDocumentationDirectory:
			break;
		case NSDocumentDirectory:
			ADD_PATH(NSUserDomainMask, @"~/Documents");
			break;
		case NSDownloadsDirectory:
			// allow for user configuration
			ADD_PATH(NSUserDomainMask, @"~/Documents/Downloads");
			break;
		case NSCachesDirectory:
			ADD_PATH(NSUserDomainMask, @"~/Library/Caches");
			ADD_PATH(NSLocalDomainMask, @"/Library/Caches");
			ADD_PATH(NSNetworkDomainMask, @"/Network/Library/Caches");
			ADD_PATH(NSSystemDomainMask, @"/System/Library/Caches");
			break;
		case NSApplicationSupportDirectory:
			ADD_PATH(NSUserDomainMask, @"~/Library/Application Support");
			ADD_PATH(NSLocalDomainMask, @"/Library/Application Support");
			ADD_PATH(NSNetworkDomainMask, @"/Network/Library/Application Support");
			ADD_PATH(NSSystemDomainMask, @"/System/Library/Application Support");
			break;
#undef ADD_PATH
#undef ADD_PLATFORM_PATH
	}
	return paths;
}

//*****************************************************************************
//
// 		NSLog
//
//*****************************************************************************

// export NSLog=""   -- off
// export NSLog="on" -- on
// export NSLog="memory"

BOOL __printLog;
BOOL __logMemory;
BOOL __doingNSLog;	// can be used in debugging tools to disable messages generated by NSLog()

void NSLogv(NSString *format, va_list args)
{
#ifndef __mySTEP__
	unsigned long __NSAllocatedObjects=0;
#endif
	if(__printLog)
		{
		NSAutoreleasePool *pool;
		NSString *prefix;
		NSString *message;
		const char *msg;
		if(__doingNSLog)
			{ // any of the NSString, NSCalendarDate, NSProcessInfo methods may have a debugging call to NSLog()
			  // may also occur if -description calls NSLog
				fprintf(stderr, "recursive NSLog(\"%s\", ...)\n", [format UTF8String]);
				return;
			}
		pool = [NSAutoreleasePool new];
		__doingNSLog = YES;
#if 0
		fprintf(stderr, ">> NSRealMemoryAvailable=%u\n", NSRealMemoryAvailable ());
#endif
#if 1
		prefix = [NSString stringWithFormat: __logMemory?@"%@ %@[%d] [%lu/%lu] ":@"%@ %@[%d] ",
				  [[NSCalendarDate calendarDate] descriptionWithCalendarFormat: @"%b %d %H:%M:%S.%F"],
				  [[[NSProcessInfo processInfo] processName] lastPathComponent],
				  getpid(), NSRealMemoryAvailable(), __NSAllocatedObjects
				  ];
#else
		prefix=nil;
#endif
		message = [[NSString alloc] initWithFormat:format arguments:args];
		if(prefix)
			msg = [[prefix stringByAppendingString:message] UTF8String];
		else
			msg = [message UTF8String];
		[message release];
		fputs(msg, stderr);
		if(msg[strlen(msg)-1] != '\n')		// Check if there is already a newline at the end of the string
			fputs("\n", stderr);
		[pool release];
#if 0
		fprintf(stderr, "<< NSRealMemoryAvailable=%u\n", NSRealMemoryAvailable ());
#endif
		__doingNSLog = NO;
		}
}

void
NSLog (NSString *format, ...)
{
	va_list ap;
	va_start (ap, format);
	NSLogv (format, ap);
	va_end (ap);
}

id
GSError (id errorObject, NSString *format, ...)
{
	va_list ap;

	if (errorObject)
		NSLog (@"GSError in %@", [errorObject description]);
	va_start (ap, format);
	NSLogv (format, ap);
	va_end (ap);
	[errorObject release];

	return nil;
}

const char *_NSPrintForDebugger(id object)
{
	return [[object description] cString];
}

//*****************************************************************************
//
// 		NSObjCRuntime
//
//*****************************************************************************

NSString *
NSStringFromSelector(SEL aSelector)
{
	if (aSelector)
		return [NSString stringWithUTF8String:sel_getName(aSelector)];
	return nil;
}

SEL
NSSelectorFromString(NSString *aSelectorName)
{
	const char *selName = [aSelectorName UTF8String];
	if (selName)
		{
		// FIXME: how can we translate/register arbitrary selectors for DO?
		SEL s = sel_registerName(selName);
		if(s)
			return s;
		}
	NSLog(@"NSSelectorFromString(): can't find SEL %@", aSelectorName);
	return (SEL)0;
}

NSString *
NSStringFromClass(Class aClass)
{
	if (aClass)
		return [NSString stringWithUTF8String:class_getName(aClass)];
	return nil;
}

Class
NSClassFromString(NSString *aClassName)
{
	const char *className = [aClassName UTF8String];
	if (className)
		{
		Class c = objc_getClass(className);
		if(c)
			return c;
		}
	NSLog(@"NSClassFromString(): can't find Class %@", aClassName);
	return (Class)0;
}

/**
 * Returns a string object containing the name for
 * aProtocol.  If aProtocol is 0, returns nil.
 */
NSString *
NSStringFromProtocol(Protocol *aProtocol)
{
	if (aProtocol)
		return [NSString stringWithUTF8String:protocol_getName(aProtocol)];
	return nil;
}

/**
 * Returns the protocol whose name is supplied in the
 * aProtocolName argument, or 0 if a nil string is supplied.
 */
Protocol *
NSProtocolFromString(NSString *aProtocolName)
{
	const char *protocolName = [aProtocolName UTF8String];
	if (protocolName)
		{
		Protocol *p = objc_getProtocol(protocolName);
		if(p)
			return p;
		}
	NSLog(@"NSProtocolFromString(): can't find Protocol %@", aProtocolName);
	return (Protocol*) nil;
}

//*****************************************************************************
//
// 		Default Encoding
//
//*****************************************************************************

struct _strenc_ {
	NSStringEncoding enc;
	char *ename;
};
const unsigned int str_encoding_table_size = 17;

const struct _strenc_ str_encoding_table[] =
{
	{NSASCIIStringEncoding,"NSASCIIStringEncoding"},
	{NSNEXTSTEPStringEncoding,"NSNEXTSTEPStringEncoding"},
	{NSJapaneseEUCStringEncoding, "NSJapaneseEUCStringEncoding"},
	{NSISOLatin1StringEncoding,"NSISOLatin1StringEncoding"},
	{NSCyrillicStringEncoding,"NSCyrillicStringEncoding"},
	{NSUTF8StringEncoding,"NSUTF8StringEncoding"},
	{NSSymbolStringEncoding,"NSSymbolStringEncoding"},
	{NSNonLossyASCIIStringEncoding,"NSNonLossyASCIIStringEncoding"},
	{NSShiftJISStringEncoding,"NSShiftJISStringEncoding"},
	{NSISOLatin2StringEncoding,"NSISOLatin2StringEncoding"},
	{NSWindowsCP1251StringEncoding,"NSWindowsCP1251StringEncoding"},
	{NSWindowsCP1252StringEncoding,"NSWindowsCP1252StringEncoding"},
	{NSWindowsCP1253StringEncoding,"NSWindowsCP1253StringEncoding"},
	{NSWindowsCP1254StringEncoding,"NSWindowsCP1254StringEncoding"},
	{NSWindowsCP1250StringEncoding,"NSWindowsCP1250StringEncoding"},
	{NSISO2022JPStringEncoding,"NSISO2022JPStringEncoding "},
	{NSMorseCodeStringEncoding,"NSMorseCodeStringEncoding "},
	{NSUnicodeStringEncoding, "NSUnicodeStringEncoding"}
};

NSStringEncoding
GSDefaultCStringEncoding()
{
	NSStringEncoding ret, tmp;
	char *encoding = getenv("MYSTEP_STRING_ENCODING");

	if (encoding)
		{
		unsigned int count = 0;
		const NSStringEncoding *available = [NSString availableStringEncodings];

		while ((count < str_encoding_table_size)
			   && strcmp(str_encoding_table[count].ename, encoding))
			count++;

		if( !(count == str_encoding_table_size))
			{
			ret = str_encoding_table[count].enc;
			if ((ret == NSUTF8StringEncoding)
				|| (ret == NSUnicodeStringEncoding)
				|| (ret == NSSymbolStringEncoding))
				{
				fprintf(stderr, "WARNING: %s - encoding is not", encoding);
				fprintf(stderr," supported as default c string encoding.\n");
				fprintf(stderr, "NSASCIIStringEncoding set as default.\n");
				ret = NSASCIIStringEncoding;
				}
			else 								// encoding should be supported
				{								// but is it implemented?
					count = 0;
					tmp = 0;
					while (!(available[count] == 0))
						{
						if (!(ret == available[count]))
							tmp = 0;
						else
							{
							tmp = ret;
							break;
							}
						count++;
						};
					if (!tmp)
						{
						fprintf(stderr, "WARNING: %s - encoding is not", encoding);
						fprintf(stderr, " yet implemented.\n" /* , encoding */);
						fprintf(stderr, "NSASCIIStringEncoding set as default.\n");
						ret = NSASCIIStringEncoding;
						}	}	}
		else 											// encoding not found
			{
			fprintf(stderr,"WARNING: %s - encoding not supported.\n",encoding);
			fprintf(stderr, "NSASCIIStringEncoding set as default.\n");
			ret = NSASCIIStringEncoding;
			}	}
	else 										// envirinment var not found
		{
		//		fprintf(stderr, "WARNING: MYSTEP_STRING_ENCODING env var not found\n");
		ret = NSASCIIStringEncoding;
		}

	return ret;
}

NSString *
GSGetEncodingName(NSStringEncoding encoding)
{
	char *ret;
	unsigned int count = 0;

	while ((count < str_encoding_table_size) &&
		   !(str_encoding_table[count].enc == encoding))
		count++;
	if ( !(count == str_encoding_table_size) )
		ret = str_encoding_table[count].ename;
	else
		ret = "Unknown encoding";

	return [NSString stringWithCString:ret];
}

const char *NSGetSizeAndAlignment(const char *typePtr,
								  NSUInteger *sizep,
								  NSUInteger *alignp)
{
	*sizep=objc_sizeof_type(typePtr);
	*alignp=objc_aligned_size(typePtr);
	return objc_skip_typespec(typePtr);
}

//*****************************************************************************
//
// 		NSPageSize
//
//*****************************************************************************

#include <string.h>
#if __mach__
#include <mach.h>
#endif

#ifdef __linux__
// #include <linux/kernel.h>
// #include <linux/sys.h>
#endif

#ifdef __WIN32__
#define getpagesize() vm_page_size
#endif

#ifdef __SOLARIS__
#define getpagesize() sysconf(_SC_PAGESIZE)
#endif

#ifdef __svr4__
#define getpagesize() sysconf(_SC_PAGESIZE)
#endif

#if __mach__
#define getpagesize vm_page_size
#endif
// Cache size of a memory page
// to avoid repeated calls to
static unsigned _pageSize = 0;					// getpagesize() system call

NSUInteger										// Return the number of bytes
NSPageSize (void)								// in a memory page.
{
	return (!_pageSize) ? (_pageSize = (unsigned) getpagesize()) : _pageSize;
}

NSUInteger
NSLogPageSize (void)							// Return log base 2 of the
{												// number of bytes in a memory
	unsigned tmp_page_size = NSPageSize();			// page.
	unsigned log = 0;

	while (tmp_page_size >>= 1)
		log++;

	return log;
}

NSUInteger
NSRoundDownToMultipleOfPageSize (NSUInteger bytes)
{												// Round BYTES down to the
	unsigned a = NSPageSize();						// nearest multiple of the
													// memory page size, and return
	return (bytes / a) * a;						// it.
}
// Round BYTES up to nearest
NSUInteger										// multiple of the memory page
NSRoundUpToMultipleOfPageSize (NSUInteger bytes)	// size, and return it.
{
	unsigned a = NSPageSize();
	return ((bytes % a) ? ((bytes / a + 1) * a) : bytes);
}

NSUInteger NSRealMemoryAvailable()
{
#ifdef __linux__
#if __TYPICALLY_SOMETHING_LIKE__
	struct sysinfo {
		long uptime;			/* Seconds since boot */
		unsigned long loads[3];		/* 1, 5, and 15 minute load averages */
		unsigned long totalram;		/* Total usable main memory size */
		unsigned long freeram;		/* Available memory size */
		unsigned long sharedram;	/* Amount of shared memory */
		unsigned long bufferram;	/* Memory used by buffers */
		unsigned long totalswap;	/* Total swap space size */
		unsigned long freeswap;		/* swap space still available */
		unsigned short procs;		/* Number of current processes */
		unsigned short pad;		/* explicit padding for m68k */
		unsigned long totalhigh;	/* Total high memory size */
		unsigned long freehigh;		/* Available high memory size */
		unsigned int mem_unit;		/* Memory unit size in bytes */
		char _f[20-2*sizeof(long)-sizeof(int)];	/* Padding: libc5 uses this.. */
	};
#endif /* __TYPICALLY_SOMETHING_LIKE__ */

	struct sysinfo info;
#if 0
	sysinfo(&info);
	NSLog(@"uptime=%ld", info.uptime);
	NSLog(@"totalram=%lu", info.totalram);
	NSLog(@"freeram=%lu", info.freeram);
	NSLog(@"sharedram=%lu", info.sharedram);
	NSLog(@"bufferram=%lu", info.bufferram);
	NSLog(@"totalswap=%lu", info.totalswap);
	NSLog(@"freeswap=%lu", info.freeswap);
	NSLog(@"procs=%u", info.procs);
#endif
	return ((sysinfo(&info)) != 0) ? 0 : (unsigned) info.freeram;
#else
	fprintf (stderr, "NSRealMemoryAvailable() not implemented.\n");
	return 0;
#endif
}

void *NSAllocateMemoryPages (NSUInteger bytes)
{
	void *where;
#if __mach__
	kern_return_t r = vm_allocate (mach_task_self(), &where, (vm_size_t) bytes, 1);

	return (r != KERN_SUCCESS) ? NULL : where;
#else
	if ((where = malloc (bytes)) == NULL)
		return NULL;
	memset (where, 0, bytes);
	return where;
#endif
}

void NSDeallocateMemoryPages (void *ptr, NSUInteger bytes)
{
#if __mach__
	vm_deallocate (mach_task_self (), ptr, bytes);
#else
	free (ptr);
#endif
}

void
NSCopyMemoryPages (const void *source, void *dest, NSUInteger bytes)
{
#if __mach__
	kern_return_t r = vm_copy (mach_task_self(), source, bytes, dest);

	NSParameterAssert (r == KERN_SUCCESS);
#else
	memcpy (dest, source, bytes);
#endif
}

#ifdef __mySTEP__
// @class NSDataStatic;

#ifdef TRACE_OBJECT_ALLOCATION
struct __NSAllocationCount
{
	NSUInteger alloc;			// number of +alloc
	NSUInteger instances;		// number of instances (balance of +alloc and -dealloc)
	NSUInteger linstances;		// last number of instances (when we did print the last time)
	NSUInteger peak;			// maximum instances
								// could also count/balance retains&releases ??
};
@class NSMapTable;
NSMapTable *__NSAllocationCountTable;
#endif

void __NSCountAllocate(Class aClass)
{
	struct __NSAllocationCount *cnt=NULL;
	static BOOL initialized=NO;
	//	fprintf(stderr, "__NSCountAllocate %s\n", aClass->name);
	if(!initialized)
		{ // get flags from environment
			char *log=getenv("NSLog");
			__printLog=log && log[0] != 0;
			__logMemory=__printLog && strcmp(log, "memory") == 0;
			initialized=YES;
		}
	if(!__logMemory)
		return;
	if(!__NSAllocationCountTable)
		{
		fprintf(stderr, "!__NSAllocationCountTable\n");
		fprintf(stderr, "  aClass = %p %s\n", aClass, class_getName(aClass));
		fprintf(stderr, "  [NSMapTable class] = %p %s\n", [NSMapTable class], class_getName([NSMapTable class]));
		if(aClass == [NSMapTable class])
			return;		// avoid recursion for allocating the __NSAllocationCountTable
		__NSAllocationCountTable = NSCreateMapTable (NSNonOwnedPointerMapKeyCallBacks, NSOwnedPointerMapValueCallBacks, 0);	// create table
		}
	else
		cnt=NSMapGet(__NSAllocationCountTable, aClass);
	if(!cnt)
		{	// not (yet) found - create new counter
			cnt=objc_calloc(1, sizeof(*cnt));
			NSMapInsert(__NSAllocationCountTable, aClass, cnt);
		}
	cnt->alloc++;	// total allocs
	if(++cnt->instances > cnt->peak)
		cnt->peak=cnt->instances;
	//	fprintf(stderr, "%s %d\n", aClass->name, cnt->instances);
	//	cnt=NSMapGet(__NSAllocationCountTable, [NSDataStatic class]);
	//	if(cnt)
	//		fprintf(stderr, "NSDataStatic %d\n", cnt->instances);
}

void __NSCountDeallocate(Class aClass)
{
	extern NSMapTable *__NSAllocationCountTable;
	//	fprintf(stderr, "__NSCountDeallocate %s\n", aClass->name);
	if(__logMemory && __NSAllocationCountTable)
		{
		struct __NSAllocationCount *cnt=NSMapGet(__NSAllocationCountTable, aClass);
		if(cnt)
			{
			NSCAssert(cnt->instances > 0, @"never allocated!");
			cnt->instances--;
			}
		//				cnt=NSMapGet(__NSAllocationCountTable, [NSDataStatic class]);
		//				if(cnt)
		//					fprintf(stderr, "NSDataStatic %d\n", cnt->instances);
		}
}

void __NSPrintAllocationCount(void)
{ // print current object allocation to stderr plus a trace in /tmp
	if(__logMemory && __NSAllocationCountTable)
		{
		int cntLevel=1;	// cnt-Level to print next
		unsigned long total=0;
		fprintf(stderr, "\fCurrent Object Allocation\n");
		while(YES)
			{
			NSMapEnumerator e=NSEnumerateMapTable(__NSAllocationCountTable);
			Class key;
			struct __NSAllocationCount *cnt;
			int nextLevel=99999999;
			while(NSNextMapEnumeratorPair(&e, (void *) &key, (void *) &cnt))
				{ // get all key/value pairs
					FILE *file;
					char name[200];
					if(cnt->instances != cntLevel)
						{	// don't print this level
							if(cnt->instances > cntLevel)
								nextLevel=MIN(nextLevel, cnt->instances);	// next level to print
							continue;
						}
					if(cnt->instances > 0)	// this does not print alloc/peak but we don't want to see it on the screen - just in the files
						fprintf(stderr, "%c %9lu %s: alloc %lu peak %lu dealloc %lu\n", ((cnt->instances>cnt->linstances)?'+':((cnt->instances<cnt->linstances)?'-':' ')), cnt->instances, class_getName(key), cnt->alloc, cnt->peak, cnt->alloc-cnt->instances);
					total += cnt->instances;
					sprintf(name, "/tmp/%u/%s", getpid(), class_getName(key));
					file=fopen(name, "a");
					if(file)
						{
						fprintf(file, "%s: alloc %lu instances %lu peak %lu dealloc %lu\n", class_getName(key), cnt->alloc, cnt->instances, cnt->peak, cnt->alloc-cnt->instances);
						fclose(file);
						}
					cnt->linstances=cnt->instances;	// to allow to compare to last print
				}
			if(nextLevel == cntLevel)
				break;	// done (i.e. we did run with maximum level)
			cntLevel=nextLevel;
			}
		fprintf(stderr, "total: %lu\n", total);
		}
}

#endif

/*
 * Workaround for ARM-OABI systems with softfloat libraries and hardfloat CPU (e.g. OpenMoko Neo 1973)
 */

#if defined(__arm__) && !defined(__ARM_EABI__)

static void *_libc;
static void *_libm;
static BOOL _softFloat;

static void * _load(char *lib)
{ // load system defined library and determine if we run on hardfloat capable processor with softfloat library
	void *libp;
#if 0
	printf("_load %s\n", lib); fflush(stdout);
#endif
	libp=dlopen(lib, RTLD_NOW);
	if(!libp)
		{
		fprintf(stderr, "can't dlopen(%s)\n", lib);
		exit(99);	// really fatal
		}
#if 0
	printf("libp=%p\n", libp); fflush(stdout);
#endif
	if(!_libm)
		{ // first call - try to determine which type of library we have
			double r;
			double (*sqrtfn)(double);
			sqrtfn=dlsym(libp, "sqrt");	// original, unwrapped sqrt function
#if 0
			printf("sqrtfn=%p\n", sqrtfn); fflush(stdout);
#endif
			r=(*sqrtfn)(4.0);	// should leave r0 with 4.0
			if(r == 2.0)
				_softFloat=NO;	// appears to be hartfloat library that properly returns the float in fp0
			else
				_softFloat=YES;	// did return value in r0/r1 instead of fp0
#if 1
			fprintf(stderr, "%s appears to be %s libc/libm\n", lib, _softFloat?"softfloat":"hardfloat");
#endif
			if(_softFloat && sqrt(4.0) != 2.0)
				fprintf(stderr, "softfloat wrapper error sqrt(4.0) -> %f", sqrt(4.0));
		}
	return libp;
}

#define NEED(LIB) if(!_libm) { _libm=_load("/lib/libm.so.6"); _libc=_load("/lib/libc.so.6"); }

// add cache for symbol pointer

#define FNP(FP, LIB, F) \
FP?FP:(FP=dlsym(_##LIB, #F))

#define WRAP_FLOAT(LIB, FUNCTION, TYPE, ARG) float FUNCTION(TYPE ARG) \
{ static float (*fp)(); \
NEED(LIB); \
if(_softFloat) \
{ \
static long (*lp)(); \
volatile union { float f; long l; } val; \
val.l=(FNP(lp, LIB, FUNCTION))(ARG); \
return val.f; \
} \
else \
return (FNP(fp, LIB, FUNCTION))(ARG); \
}

// FIXME - is this swapping rule correct?
// it looks like -O3 optimizes too much so that it does not work

#define WRAP_DOUBLE(LIB, FUNCTION, TYPE, ARG) double FUNCTION(TYPE ARG) \
{ static double (*fp)(); \
NEED(LIB); \
if(_softFloat) \
{ \
static long long (*lp)(); \
volatile union { double f; long long l; } val; \
val.l=(FNP(lp, LIB, FUNCTION))(ARG); \
return val.f; \
} \
else \
return (FNP(fp, LIB, FUNCTION))(ARG); \
}

#define WRAP_DOUBLE2(LIB, FUNCTION, TYPE1, ARG1, TYPE2, ARG2) double FUNCTION(TYPE1 ARG1, TYPE2 ARG2) \
{ static double (*fp)(); \
NEED(LIB); \
if(_softFloat) \
{ \
static long long (*lp)(); \
volatile union { double f; long long l; } val; \
val.l=(FNP(lp, LIB, FUNCTION))(ARG1, ARG2); \
return val.f; \
} \
else \
return (FNP(fp, LIB, FUNCTION))(ARG1, ARG2); \
}

#if 1
// the following functions are known to be used by QuantumSTEP

#undef atof

WRAP_DOUBLE(libc, atof, const char *, nptr);	// is in libc!

WRAP_DOUBLE(libm, acos, double, x);
WRAP_DOUBLE(libm, asin, double, x);
WRAP_DOUBLE(libm, atan, double, x);
WRAP_DOUBLE2(libm, atan2, double, x, double, y);
WRAP_DOUBLE(libm, ceil, double, x);
WRAP_FLOAT(libm, ceilf, float, x);
WRAP_DOUBLE(libm, cos, double, x);
WRAP_FLOAT(libm, cosf, float, x);
WRAP_DOUBLE(libm, exp, double, x);
WRAP_DOUBLE(libm, floor, double, x);
WRAP_FLOAT(libm, floorf, float, x);
WRAP_DOUBLE2(libm, fmod, double, x, double, y);
// WRAP_FLOAT2(libm, fmodf, double, x, double, y);
WRAP_DOUBLE(libm, log, double, x);
WRAP_DOUBLE2(libm, pow, double, x, double, y);
WRAP_DOUBLE(libm, rint, double, x);
WRAP_FLOAT(libm, rintf, float, x);
WRAP_DOUBLE(libm, sin, double, x);
WRAP_FLOAT(libm, sinf, float, x);
WRAP_DOUBLE(libm, sqrt, double, x);
WRAP_FLOAT(libm, sqrtf, float, x);
WRAP_DOUBLE(libm, tan, double, x);
WRAP_DOUBLE(libm, tgamma, double, x);

#endif

#endif
