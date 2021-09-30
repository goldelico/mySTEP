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
#import "NSPrivate.h"

#include <unistd.h>
#include <time.h>
#include <sys/time.h>

static NSProcessInfo *__processInfo = nil;
static int __argc;
static char **__argv;
static char **__envp;

static void my_early_main(int argc, char* argv[], char* envp[])
{ // called before objects are loaded
#if 1
	{
	struct timeval tp;
	gettimeofday(&tp, NULL);
	fprintf(stderr, "early_main started: %.24s.%06lu\n", ctime(&tp.tv_sec), (unsigned long) tp.tv_usec);
	fprintf(stderr, "argc=%d\n", argc);
	}
#endif
	__argc=argc;
	__argv=argv;
	__envp=envp;
}

#ifndef __APPLE__
__attribute__((section(".init_array"))) void (* p_my_early_main)(int,char*[],char*[]) = &my_early_main;
#endif

@implementation NSProcessInfo

+ (NSProcessInfo*) processInfo
{
	if(!__processInfo)
		{
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
#if 0
		fprintf(stderr, "NSProcessInfo not yet initialized because main() is not yet called\n");
#endif
		__processInfo = [[NSProcessInfo alloc] _initWithArguments:__argv count:__argc environ:__envp];
		[pool release];
		}
	return __processInfo;
}

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
- (NSString *) operatingSystemName;			{ return @"QuantumSTEP"; }

- (NSString *) operatingSystemVersionString;
{
	// auf dem Mac z.B. "Version 10.14.6 (Build 18G9323)"
	// sollte melden "Stretch 9.13 (armhf 202109)
	// evtl. auch Hostname oder IP-Adresse???
	NSBundle *this=[NSBundle bundleForClass:[self class]];
	NSDictionary *attribs=[[NSFileManager defaultManager] attributesOfItemAtPath:[this executablePath] error:NULL];
	NSDate *date=[attribs objectForKey:NSFileModificationDate];
	NSDateFormatter *dateFormatter = [[NSDateFormatter new] autorelease];
	NSString *arch;
	NSString *build;
	[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[dateFormatter setDateFormat:@"yyyy.MM"];	// .dd?
	build=[dateFormatter stringFromDate:date];	// warning: this takes the locale into account!
	{
		char line[130];
		FILE *fp;
		// FIXME: error handling
		fp = popen("dpkg --print-architecture", "r");
		fgets(line, sizeof(line), fp);
		line[strlen(line)-1] = '\0';	// strip off \n
		arch = [NSString stringWithCString:line encoding:NSASCIIStringEncoding];
	}
	return [NSString stringWithFormat:@"Version %@ (%@ %@)",
			[[NSString stringWithContentsOfFile:@"/etc/debian_version"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]],
			arch,
			build];
}

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
- (oneway void) release					{ return; }

// FIXME: ask kernel
- (NSUInteger) processorCount;			{ return 1; }
- (unsigned long long) physicalMemory;	{ return 0; }
- (NSUInteger) activeProcessorCount;	{ return 1; }

@end
