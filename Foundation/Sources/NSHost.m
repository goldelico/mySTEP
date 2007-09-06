/* 
   NSHost.m

   Implementation of host class

   Copyright (C) 1996, 1997 Free Software Foundation, Inc.
   
   Author:	Luke Howard <lukeh@xedoc.com.au> 
   Date:	1996
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#include <sys/param.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>

#import <Foundation/NSLock.h>
#import <Foundation/NSHost.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSCoder.h>
#import "NSPrivate.h"

// Class variables
static NSLock *__hostCacheLock = nil;
static BOOL __hostCacheEnabled = YES;
static NSMutableDictionary *__hostCache = nil;


@implementation NSHost

+ (void) initialize
{
	__hostCacheLock = [[NSConditionLock alloc] init];
	__hostCache = [NSMutableDictionary new];
}

+ (NSHost *) _hostWithHostEntry:(struct hostent *)entry name:(NSString *) name
{
	NSHost *h = nil;
	if (__hostCacheEnabled == YES)
		{
#if 0
		NSLog(@"NSHost: __hostCache lock");
#endif
		[__hostCacheLock lock];
		h = [__hostCache objectForKey:name];
		[__hostCacheLock unlock];
		}

	if(h == nil && (entry != (struct hostent *)NULL) && (name != nil))
		{ // new entry
		int i;
		char *ptr;
		struct in_addr in;
		NSString *h_name;

		h = [[self alloc] autorelease];	// no call to init!
		h->_names = [[NSMutableArray array] retain];
		h->_addresses = [[NSMutableArray array] retain];
		
		[h->_names addObject:name];
		h_name = [NSString stringWithCString:entry->h_name];
		
		if (![h_name isEqual:name])
			[h->_names addObject:h_name];
		
		ptr = entry->h_aliases[0];
		for (i = 0; ptr != NULL; i++, ptr = entry->h_aliases[i])
			[h->_names addObject:[NSString stringWithUTF8String:ptr]];
	
		ptr = entry->h_addr_list[0];
		for (i = 0; ptr != NULL; i++, ptr = entry->h_addr_list[i])
			{
			memcpy((void *) &in.s_addr, (const void *)ptr, entry->h_length);
			[h->_addresses addObject:[NSString stringWithCString:inet_ntoa(in)]];
			}
	
		if (__hostCacheEnabled == YES)
			{
#if 0
			NSLog(@"NSHost: __hostCache lock");
#endif
			[__hostCacheLock lock];
			[__hostCache setObject:h forKey:name];
			[__hostCacheLock unlock];
		}	}

	return h;
}

+ (NSHost *) currentHost
{
	// try @"fe80::1"
	return [self hostWithAddress:@"127.0.0.1"];
#if 0
	char name[MAXHOSTNAMELEN];	
	if(gethostname(name, sizeof(name)-1) < 0)
		return GSError(nil, @"Unable to determine current host's name");
	return [self hostWithName:[NSString stringWithUTF8String:name]];
#endif
}

+ (NSHost *) hostWithName:(NSString *)name
{
	struct hostent *h;

	if (name == nil)
		return GSError(nil, @"nil host name sent to +[NSHost hostWithName]");

	if ((h = gethostbyname((char *)[name UTF8String])) == NULL)
		return GSError(nil, @"Host '%@' not found via gethostbyname()", name);
	
	return [self _hostWithHostEntry:h name:name];
}

+ (NSHost *) hostWithAddress:(NSString *)address
{
	struct hostent *h;
	struct in_addr addr;
	
	if (address == nil)
		return GSError(nil, @"nil address sent to +[NSHost hostWithAddress]");

	if (!inet_aton((char *)[address cString], &addr))
		return nil;
		
	if ((h = gethostbyaddr((char *)&addr, sizeof(addr), AF_INET)) == NULL)
		return GSError(nil, @"Unable to determine host via gethostbyaddr()");

	return [self _hostWithHostEntry:h 
				 name:[NSString stringWithUTF8String:h->h_name]];
}

+ (void) setHostCacheEnabled:(BOOL)flag		{ __hostCacheEnabled = flag; }
+ (BOOL) isHostCacheEnabled					{ return __hostCacheEnabled; }

+ (void) flushHostCache
{
#if 0
	NSLog(@"NSHost: __hostCache lock");
#endif
	[__hostCacheLock lock];
	[__hostCache removeAllObjects];
	[__hostCacheLock unlock];
}

- (id) init												{ return NIMP; }
- (Class) classForPortCoder								{ return [self class];}

- (id) replacementObjectForPortCoder:(NSPortCoder*)coder
{ // default is to encode a proxy
	if([coder isBycopy])
		return self;
	return [super replacementObjectForPortCoder:coder];
}

- (void) dealloc
{
	[_names autorelease];
	[_addresses autorelease];
	[super dealloc];
}

/*
	The OpenStep spec says that [-hash] must be the same for any two
	objects that [-isEqual:] returns YES for.  We have a problem in
	that [-isEqualToHost:] is specified to return YES if any name or
	address part of two hosts is the same.  That means we can't
	reasonably calculate a hash since two hosts with radically
	different ivar contents may be 'equal'.  The best I can think of
	is for all hosts to hash to the same value - which makes it very
	inefficient to store them in a set, dictionary, map or hash table.
*/
- (unsigned) hash
{
	return 1;
}

- (BOOL) isEqual:(id)other
{
	if (other == self)
		return YES;
	if ([other isKindOfClass: [NSHost class]])
		return [self isEqualToHost: (NSHost*)other];
	return NO;
}

- (BOOL) isEqualToHost:(NSHost *)aHost
{
NSArray *a;
int i, count;

	if (aHost == self)
		return YES;
	
	a = [aHost addresses];
	for (i = 0, count = [a count]; i < count; i++)
		if ([_addresses containsObject:[a objectAtIndex:i]])
			return YES;
	
	a = [aHost names];
	for (i = 0, count = [a count]; i < count; i++)
		if ([_addresses containsObject:[a objectAtIndex:i]])
			return YES;
	
	return NO;
}

- (NSString*) name						{ return [_names objectAtIndex:0]; }
- (NSArray *) names						{ return _names; }
- (NSString*) address					{ return [_addresses objectAtIndex:0];}
- (NSArray *) addresses					{ return _addresses ; }

- (NSString *) description
{
	return [NSString stringWithFormat:@"Host %@ (%@ %@)", 
										[self name],
										[[self names] description], 
										[[self addresses] description]];
}

- (void) encodeWithCoder:(NSCoder*)aCoder
{
    [aCoder encodeObject: [self address]];
}

- (id) initWithCoder:(NSCoder*)aCoder
{
	[self release];
    return [NSHost hostWithAddress: [aCoder decodeObject]];
}

@end
