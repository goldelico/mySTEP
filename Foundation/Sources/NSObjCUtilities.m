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

#define LOG_MEMORY 1	// NSLog prints real memory and number of allocated objects

#if __arm__
#define atof _atof	// rename atof in loaded header file
#endif

#include <sys/types.h>
#ifdef __linux__
#include <sys/sysinfo.h>
#endif
#if !defined(__WIN32__) && !defined(_WIN32)
#include <pwd.h>		// for getpwnam()
#endif

#include <dlfcn.h>

#import <Foundation/NSObjCRuntime.h>

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

#ifdef __linux__	// compile on Linux only

//*****************************************************************************
//
//	Definitions and translations for dynamic loading with the simple dynamic
//	loading library (dl).	- unloading modules not implemented
//
//  here some info for Linux: http://www.linux.com/howtos/Program-Library-HOWTO/miscellaneous.shtml
//
//*****************************************************************************

// From the objc runtime -- needed when invalidating the dtable 
extern void __objc_install_premature_dtable(Class);
//extern void sarray_free(struct sarray *);

// objc-api.h: defines extern void (*_objc_load_callback)(Class class, Category* category);

// Our current callback function from objc_loadmodule
void (*objc_loadmodule_callback)(Class, Category *) = 0;

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

static int __objc_dynamic_init(const char *exec_path)
{
	return 0;
}

// Link in module given by the name 'module'.
// Return a handle which can be used to get 
// information about the loded code. mode is ignored

static dl_handle_t __objc_dynamic_link(const char *module, int mode, const char *debug_file)
{
	dl_handle_t *ret;
#if 0
	fprintf(stderr, "__objc_dynamic_link(%s, %d, %s)\n", module, mode, debug_file);
#endif
	ret=(dl_handle_t)dlopen(module, RTLD_LAZY | RTLD_GLOBAL);
#if 0
	fprintf(stderr, "__objc_dynamic_link => %08lx\n", (unsigned int) ret);
#endif
	return ret;
}

// remove the code from memory associated with 
// the module 'handle'

static int __objc_dynamic_unlink(dl_handle_t handle)
{
    return dlclose(handle);
}

// Print error message prefaced by error_string 
// relevant to the last error encountered

static void __objc_dynamic_error(FILE *error_stream, const char *error_string)
{
    fprintf(error_stream, "%s:%s\n", error_string, dlerror());
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
	
    if (class->dtable == objc_get_uninstalled_dtable()) 
		return;
    sarray_free(class->dtable);
    __objc_install_premature_dtable(class);
    for (s = class->subclass_list; s; s=s->sibling_class) 
		objc_invalidate_dtable(s);
}

int objc_initialize_loading(FILE *errorStream)
{
	const char *path = [[[NSBundle mainBundle] bundlePath] fileSystemRepresentation];
	
    NSDebugLog(@"(objc-load): initializing dynamic loader for %s\n", path);
	
    if (__objc_dynamic_init(path)) 
		{
		if (errorStream)
			__objc_dynamic_error(errorStream, "Error init'ing dynamic linker");
		return 1;
		} 
	
	__dynamicLoaderInitialized = YES;
	
    return 0;
}

// A callback received from Object initializer 
// (_objc_exec_class). Do what we need to do 
// and call our own callback.

void objc_load_callback(Class class, Category *category)
{
#if 0
	fprintf(stderr, "objc_load_callback\n");
#endif
    if (class != 0 && category != 0) 		// Invalidate the dtable, so it 
		{									// will be rebuilt correctly
		objc_invalidate_dtable(class);
		objc_invalidate_dtable(class->class_pointer);
		}
	
    if (objc_loadmodule_callback)
		(*objc_loadmodule_callback)(class, category);
}

long objc_load_module(const char *filename,
				 FILE *errorStream,
				 void (*loadCallback)(Class, Category*),
				 void **header,
				 char *debugFilename)
{
	typedef void (*void_fn)();
	dl_handle_t handle;
	
#if 0
	fprintf(stderr, "objc_load_module\n");
#endif
	
    if (!__dynamicLoaderInitialized)
        if (objc_initialize_loading(errorStream))
            return 1;
	
    objc_loadmodule_callback = loadCallback;	// most probably _bundleLoadCallback
    _objc_load_callback = objc_load_callback;	// install our callback into objc.so
	
    NSDebugLog(@"Debug (objc-load): Linking file %s\n", filename);
#if 0
	fprintf(stderr, "objc_load_module: Linking file %s\n", filename);
#endif
	// Link in the object file
	if ((handle = __objc_dynamic_link(filename, 1, debugFilename)) == 0) 
		{
#if 0
		fprintf(stderr, "objc_load_module: error linking file %s\n", filename);
#endif
		if (errorStream)
			__objc_dynamic_error(errorStream, "Error (objc-load)");
		return 1;
		}
#if 0
	fprintf(stderr, "objc_load_module: linked\n");
#endif
    __dynamicModules = list_cons(handle, __dynamicModules);
#if 0
	fprintf(stderr, "objc_load_module: after list_cons\n");
#endif
	
	// If there are any undefined symbols, we can't load the bundle
	if (objc_check_undefineds(errorStream)) 
		{
#if 1
		fprintf(stderr, "objc_load_module: has undefined symbols, can't really load\n");
#endif
		__objc_dynamic_unlink(handle);
		return 1;
		}
	
    _objc_load_callback = NULL;
    objc_loadmodule_callback = NULL;
#if 0
	fprintf(stderr, "objc_load_module: successfully loaded\n");
#endif
	
    return 0;
}

char *objc_dynamic_find_file(const void *address)
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
#if 0
	if(dladdr(aClass, &info))	// find filename for address of class record
		NSLog(@"Dl_info filename=%s", info.dli_fname);
	else
		NSLog(@"addr not found");
#endif
	if(dladdr(address, &info))	// find filename for address of class record
		return (char *) info.dli_fname;
	return NULL;
}

#endif	__linux__

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
    return [NSString stringWithFormat:@"{ %d, %d }", range.location, range.length];
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
	return nil;
}

NSString *NSOpenStepRootDirectory(void) { return @"/"; }

NSString *NSTemporaryDirectory(void) { return @"/tmp"; }  // accounts for virtual root /home/myPDA

NSString *NSHomeDirectory (void)
{ // return user's home directory
	return NSHomeDirectoryForUser(NSUserName());
}

// FIXME: we can't read the home directory directly since we have our own /Users area

NSString *NSHomeDirectoryForUser (NSString *login_name)
{ // return home dir for login name
	struct passwd *pwd=getpwnam([login_name UTF8String]);
	endpwent();
	if(!pwd)
		return @"/Unknown User";
	if(pwd->pw_uid == 0)
		return @"/";	// root user
#if 1
	return [NSString stringWithFormat:@"/Users/%@", login_name];
#else
	return [NSString stringWithUTF8String:pwd->pw_dir];
#endif
}

//*****************************************************************************
//
// 		NSLog 
//
//*****************************************************************************

#ifndef __mySTEP__
#undef LOG_MEMORY
#define LOG_MEMORY 0
#endif

void NSLogv(NSString *format, va_list args)
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	NSString *prefix;
	NSString *message;
#if 0
	fprintf(stderr, ">> NSRealMemoryAvailable=%u\n", NSRealMemoryAvailable ());
#endif
#if LOG_MEMORY
	prefix = [NSString stringWithFormat: @"%@ %@[%d] [%lu/%lu] ",
#else
	prefix = [NSString stringWithFormat: @"%@ %@[%d] ",
#endif
				[[NSCalendarDate calendarDate] descriptionWithCalendarFormat: @"%b %d %H:%M:%S.%F"],
				[[[NSProcessInfo processInfo] processName] lastPathComponent],
				getpid()
#if LOG_MEMORY
				, NSRealMemoryAvailable(), __NSAllocatedObjects
#endif
		];
	message = [[NSString alloc] initWithFormat:format arguments:args];
	fputs([[prefix stringByAppendingString:message] UTF8String], stderr);
	if(![message hasSuffix:@"\n"])		// Check if there is already a newline at the end of the string
		fputs("\n", stderr);
	[message release];
	[pool release];
#if 0
	fprintf(stderr, "<< NSRealMemoryAvailable=%u\n", NSRealMemoryAvailable ());
#endif
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

//*****************************************************************************
//
// 		NSObjCRuntime 
//
//*****************************************************************************

NSString *
NSStringFromSelector(SEL aSelector)
{
	if (aSelector != (SEL)0)
		return [NSString stringWithFormat: @"%s", (char *) sel_get_name(aSelector)];
	return nil;
}

SEL
NSSelectorFromString(NSString *aSelectorName)
{
	if (aSelectorName != nil)
		{
		const char *selName = [aSelectorName cString];
		SEL s = sel_get_any_uid(selName);
		if(!s)
			NSLog(@"NSSelectorFromString(): can't find SEL %@", aSelectorName);
		return s;
		}
	return (SEL)0;
}

NSString *
NSStringFromClass(Class aClass)
{
	if (aClass != (Class)0)
	   return [NSString stringWithCString:(char *) class_get_class_name(aClass)];
	return nil;
}

Class
NSClassFromString(NSString *aClassName)
{
	if (aClassName != nil)
		{
		const char *className = [aClassName cString];
		Class c = objc_lookup_class(className);
		if(!c)
			NSLog(@"NSClassFromString(): can't find Class %@", aClassName);
		return c;
		}
	return (Class)0;
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
#include <linux/kernel.h>
#include <linux/sys.h>
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

unsigned										// Return the number of bytes 
NSPageSize (void)								// in a memory page.
{
	return (!_pageSize) ? (_pageSize = (unsigned) getpagesize()) : _pageSize;
}

unsigned									
NSLogPageSize (void)							// Return log base 2 of the 
{												// number of bytes in a memory 
unsigned tmp_page_size = NSPageSize();			// page.
unsigned log = 0;

	while (tmp_page_size >>= 1)
		log++;

	return log;
}

unsigned
NSRoundDownToMultipleOfPageSize (unsigned bytes)
{												// Round BYTES down to the 
unsigned a = NSPageSize();						// nearest multiple of the 
												// memory page size, and return 
	return (bytes / a) * a;						// it.
}
												// Round BYTES up to nearest 
unsigned										// multiple of the memory page
NSRoundUpToMultipleOfPageSize (unsigned bytes)	// size, and return it.
{
	unsigned a = NSPageSize();
	return ((bytes % a) ? ((bytes / a + 1) * a) : bytes);
}

unsigned NSRealMemoryAvailable()
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

void *NSAllocateMemoryPages (unsigned bytes)
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

void NSDeallocateMemoryPages (void *ptr, unsigned bytes)
{
#if __mach__
	vm_deallocate (mach_task_self (), ptr, bytes);
#else
	free (ptr);
#endif
}

void
NSCopyMemoryPages (const void *source, void *dest, unsigned bytes)
{
#if __mach__
kern_return_t r = vm_copy (mach_task_self(), source, bytes, dest);

	NSParameterAssert (r == KERN_SUCCESS);
#else
	memcpy (dest, source, bytes);
#endif
}

/*
 * Workaround for ARM system with softfloat libraries and hardfloat CPU (e.g. OpenMoko)
*/

#if __arm__

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
		sqrtfn=dlsym(libp, "sqrt");
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