/* 
   NSProcessInfo.m

   Determine and maintain process information.  

   Copyright (C) 1999 free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:	January 1999
   Author:  H. Nikolaus Schaller <hns@computer.org>
   Date:	August 2003

   Portions were derived from Georg Tuparev's implementation of 
   NSProcessInfo and from Mircea Oancea's implementation.
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <Foundation/NSString.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSProcessInfo.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSObjCRuntime.h>

#import <unistd.h>
#include <time.h>
#include <sys/time.h>

// Global variables
static id __processInfo = nil;
// extern char **environ;


@implementation NSProcessInfo

+ (NSProcessInfo*) processInfo				{ return __processInfo; }

- (void) dealloc
{ // should never be called...
	[_hostName release];   
	[_processName release];
	[_operatingSystem release];				
	[_environment release];
	[_arguments release];
	[super dealloc];
}

- (id) _initWithArguments:(char**)argv count:(int)argc environ:(char**)env
{
	int i, count;
	char hostName[1024];
	NSString **argstr;
	
	_processName = [[NSString alloc] initWithCString:argv[0]];
	_processName = [[_processName lastPathComponent] retain];
	_pid=getpid();
	
	argstr = malloc (argc * sizeof(argstr[0]));				// Copy argument list
	for (i = 0; i < argc; i++)
			{
				argstr[i] = [[[NSString alloc] initWithCString:argv[i]] autorelease];
#if 0 && defined(__mySTEP__)
			free(malloc(8192));	// segfaults???
#endif
#if 0
				NSLog(@"%@: %@ - %s", NSStringFromClass([argstr[i] class]), argstr[i], argv[i]);
#endif
			}
	
	_arguments = [[NSArray alloc] initWithObjects:argstr count:argc];
	free (argstr);
#if 0 && defined(__mySTEP__)
	free(malloc(8192));	// segfaults???
#endif
	
	for (count = 0; env[count]; count++)
		; // Count the evironment variables.
	
	{
		NSString **keys = malloc (count * sizeof(keys[0]));				// Copy the environment variables				
		NSString **vals = malloc (count * sizeof(vals[0]));									
		
		for (i = 0; i < count; i++) 
				{
					char *cp, *p;
					
					p = strdup (env[i]);
					for (cp = p; *cp != '=' && *cp; cp++);
					*cp = '\0';
					vals[i] = [[NSString alloc] initWithCString:(cp + 1)];
					keys[i] = [[NSString alloc] initWithCString:p];
					free (p);
				}
		
		_environment = [NSDictionary alloc];
		[_environment initWithObjects:vals forKeys:keys count:count];
#if 0 && defined(__mySTEP__)
	free(malloc(8192));	// segfaults???
#endif
	
		free (keys);
		free (vals);
	}
	
	// should we use [[NSHost currentHost] name]?
	
	gethostname(hostName, sizeof(hostName)-1);
	hostName[sizeof(hostName)-1]=0;
	_hostName = [[NSString alloc] initWithCString:hostName];
#if 0 && defined(__mySTEP__)
	free(malloc(8192));	// segfaults???
#endif
	
	return self;
}

- (NSArray*) arguments						{ return _arguments; }
- (NSDictionary*) environment				{ return _environment; }
- (NSString*) hostName						{ return _hostName; }
- (unsigned int) operatingSystem
#ifdef __APPLE__
	{ return NSMACHOperatingSystem; }
#endif
#ifdef __linux__
	{ return NSLinuxOperatingSystem; }
#endif
- (NSString*) operatingSystemName;			{ return @"QuantumSTEP"; }
- (NSString *) operatingSystemVersionString;	{ return @"2.0"; }

- (NSString*) processName					{ return _processName; }
- (int) processIdentifier;					{ return _pid; }

- (NSString*) globallyUniqueString
{
	static int sequence=12345;
	return [NSString stringWithFormat:@"%04X-%.0lf-%04x@%@", 
						(int)getpid(), [[NSDate date] timeIntervalSince1970],
						sequence++, _hostName];
}

- (void) setProcessName:(NSString*)aName
{
    if (aName && [aName length])
		{
		[_processName autorelease];
		_processName = [aName copy];
		}
}

// disable release
- (id) autorelease						{ return self; }
- (id) retain							{ return self; }
- (oneway void) release						{ return; }
- (NSUInteger) processorCount;			{ return 1; }
- (unsigned long long) physicalMemory;	{ return 0; }
- (NSUInteger) activeProcessorCount;	{ return 1; }

@end


#ifdef main													// redefine main()
#undef main

extern int objc_main(int argc, char** argv, char** env);

#define MEMORY_LIMIT 0

#if MEMORY_LIMIT

static void *(*saved_objc_malloc)(size_t);

void *malloclimit(size_t size)
{
	if(size > NSRealMemoryAvailable()/6)
		{ // more than reasonable...
		fprintf(stderr, "available memory:     %10d\n", NSRealMemoryAvailable());
		fprintf(stderr, "trying to objc_malloc(%10ld)\n", (long) size);
		abort();	// trap to debugger
		}
	return (*saved_objc_malloc)(size);
}
#endif

int main(int argc, char** argv, char** env)
{
	NSAutoreleasePool *pool;
#if 0 && defined(__mySTEP__)
	free(malloc(8192));	// segfaults???
#endif
#if 1
	{ // print when we enter the main function to find out how long framework initialization takes
		struct timeval tp;
		gettimeofday(&tp, NULL);
		fprintf(stderr, "process started: %.24s.%06lu\n", ctime(&tp.tv_sec), (unsigned long) tp.tv_usec);
	}
#endif
	pool=[NSAutoreleasePool new];	
#if MEMORY_LIMIT
	extern void *(*_objc_malloc)(size_t);
	saved_objc_malloc=_objc_malloc;
	_objc_malloc=malloclimit;
#endif
	__processInfo = [[NSProcessInfo alloc] _initWithArguments:argv count:argc environ:env];
    [pool release];
#if 1
	{ // print when we enter the main function to find out how long framework initialization takes
		struct timeval tp;
		gettimeofday(&tp, NULL);
		fprintf(stderr, "main started: %.24s.%06lu\n", ctime(&tp.tv_sec), (unsigned long) tp.tv_usec);
	}
#endif
	return objc_main(argc, argv, env);
}

#endif /* main */
