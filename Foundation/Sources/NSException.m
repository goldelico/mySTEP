/* 
   NSException.m

   Object encapsulation of a general exception handler.

   Copyright (C) 1993, 1994, 1996, 1997 Free Software Foundation, Inc.

   Author:	Adam Fedor <fedor@boulder.colorado.edu>
   Date:	Mar 1995

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#import <Foundation/NSException.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSThread.h>
#import <Foundation/NSDictionary.h>
#import "NSPrivate.h"

#include <stdarg.h>

static /*volatile*/ void
_NSFoundationUncaughtExceptionHandler(NSException *exception)
{
    NSLog(@"Uncaught exception %@, reason: %@", [exception name], [exception reason]);
    abort();
}

@implementation NSAssertionHandler

+ (NSAssertionHandler *) currentHandler;
{
	NSMutableDictionary *ct=[[NSThread currentThread] threadDictionary];
	NSAssertionHandler *handler=[ct objectForKey:@"NSAssertionHandler"];
	if(!handler)
		{
			handler=[self new];
			[ct setObject:handler forKey:@"NSAssertionHandler"];	// retain in thread dictionary
			[handler release];
		}
	return handler;
}

- (void) handleFailureInMethod:(SEL) sel object:(id) object file:(NSString *) file lineNumber:(NSInteger) line description:(NSString *) desc, ...
{
	NSString *description;
	va_list args;
    va_start(args, desc);
	description = [[[NSString alloc] initWithFormat:desc arguments:args] autorelease];
    va_end(args);
#if 0
	NSLog(@"desc=%@", desc);
	NSLog(@"description=%@", description);
	NSLog(@"file=%@", file);
	NSLog(@"line=%d", line);
#endif
	NSLog(@"Assertion failed: %@; method: %@ file: %@ line: %d", description, NSStringFromSelector(sel), file, line);
#if 1
    abort();
#endif
	[NSException raise:NSInternalInconsistencyException format:@"Assertion failed: %@; method: %@ file: %@ line: %d", description, NSStringFromSelector(sel), file, line];
}

- (void) handleFailureInFunction:(NSString *) name file:(NSString *) file lineNumber:(NSInteger) line description:(NSString *) desc, ...
{
	NSString *description;
	va_list args;
    va_start(args, desc);
	description = [[[NSString alloc] initWithFormat:desc arguments:args] autorelease];
    va_end(args);
#if 0
	NSLog(@"desc=%@", desc);
	NSLog(@"description=%@", description);
	NSLog(@"file=%@", file);
	NSLog(@"line=%d", line);
#endif
	NSLog(@"Assertion failed: %@; function: %@ file: %@ line: %d", description, name, file, line);
#if 1
    abort();
#endif
	[NSException raise:NSInternalInconsistencyException format:@"Assertion failed: %@; function: %@ file: %@ line: %d", description, name, file, line];
}

@end

@implementation NSException

+ (NSException *) exceptionWithName:(NSString *)name
							 reason:(NSString *)reason
							 userInfo:(NSDictionary *)userInfo 
{
    return [[[self alloc] initWithName:name 
						  reason:reason
						  userInfo:userInfo] autorelease];
}

+ (volatile void) raise:(NSString *)name format:(NSString *)format,...
{
	va_list args;
    va_start(args, format);
    [self raise:name format:format arguments:args];
    va_end(args);
	// FIXME: This probably doesn't matter,
	// but va_end won't get called
}

+ (volatile void) raise:(NSString *)name
				  format:(NSString *)format
				  arguments:(va_list)argList
{
	NSString *reason = [[NSString alloc] initWithFormat:format arguments:argList];
	NSException *except = [self exceptionWithName:name reason:reason userInfo:nil];
	[reason release];
    [except raise];
}

- (NSArray *) callStackReturnAddresses;
{
	// FIXME:
	return [NSArray array];
}

- (id) initWithName:(NSString *)name 
			 reason:(NSString *)reason
			 userInfo:(NSDictionary *)userInfo 
{
    if((self = [super init]))
		{
		e_name = [name retain];
		e_reason = [reason retain];
		e_info = [userInfo retain];
		}
    return self;
}

- (void) dealloc
{
	[e_name release];
	e_name = nil;
	[e_reason release];
	e_reason = nil;
	[e_info release];
	e_info = nil;
	[super dealloc];
}

- (NSString *) description;
{
	if(e_info)
		return [NSString stringWithFormat:@"%@ - %@: %@ - %@", NSStringFromClass([self class]), e_name, e_reason, e_info];
	return [NSString stringWithFormat:@"%@ - %@: %@", NSStringFromClass([self class]), e_name, e_reason];
}

- (/*volatile*/ void) raise
{
	NSThread *thread;
	NSHandler2 *handler;
#if 1
	NSLog(@"-[NSException raise] %@", self);
#endif
    if (_NSUncaughtExceptionHandler == NULL)
        _NSUncaughtExceptionHandler = _NSFoundationUncaughtExceptionHandler;
    thread = [NSThread currentThread];
    handler = thread->_exception_handler;
    if (handler == NULL)
    	_NSUncaughtExceptionHandler(self);
	else
		{
		thread->_exception_handler = handler->next;
		handler->exception = self;
		longjmp(handler->jumpState, 1);
		}
}

- (NSString *) name										{ return e_name; }
- (NSString *) reason									{ return e_reason; }
- (NSDictionary *) userInfo								{ return e_info; }
- (Class) classForPortCoder								{ return isa;}

- (id) replacementObjectForPortCoder:(NSPortCoder*) coder { return self; }	// send exceptions bycopy

- (void) encodeWithCoder:(NSCoder *) aCoder
{
    [aCoder encodeObject:e_name]; 
    [aCoder encodeObject:e_reason]; 
    [aCoder encodeObject:e_info]; 
}

- (id) initWithCoder:(NSCoder *) aDecoder
{
    e_name = [[aDecoder decodeObject] retain];
    e_reason = [[aDecoder decodeObject] retain];
    e_info = [[aDecoder decodeObject] retain];
    return self;
}

- (id) copyWithZone:(NSZone *) zone	{ return [self retain]; }		// NSCopying

@end

// we could make this partof the NS_DURING... macros or make it inline code

void _NSAddHandler2(NSHandler2 *handler)
{
	// NSThread *thread=(id) objc_thread_get_data();
	NSThread *thread = [NSThread currentThread];
    handler->next = thread->_exception_handler;
    thread->_exception_handler = handler;
}

void _NSRemoveHandler2(NSHandler2 *handler)
{
	// NSThread *thread=(id) objc_thread_get_data();
	NSThread *thread = [NSThread currentThread];
    thread->_exception_handler = thread->_exception_handler->next;
}
