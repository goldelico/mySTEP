//
//  NSConnectionTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 08.03.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "NSConnectionTest.h"

#if 0

// FIXME: we have a problem with these mock objects defined as categories for
// existing Foundation classes
// the problem is that one category is applied to the full FoundationTests suite!

/* use mock objects to provide a controllable environment for the NSConnection */

@interface MockPort : NSObject
@end

@implementation MockPort

- (id) init
{
	return self;
}

- (void) dealloc
{
	NSLog(@"-[MockPort dealloc]");
	[super dealloc];
}

- (void) encodeWithCoder:(NSCoder *) coder
{
	int val=0x12345678;
	[coder encodeValueOfObjCType:@encode(int) at:&val];
}

- (unsigned) reservedSpaceLength
{
	return 0;
}

- (void) addConnection:(NSConnection *) connection toRunLoop:(NSRunLoop *) rl forMode:(NSString *) mode
{
	NSLog(@"-[MockPort addConnection:%@ toRunLoop:%p forMode:%@]", connection, rl, mode);
	// check in which modes we are added
}

- (void) removeConnection:(NSConnection *) connection fromRunLoop:(NSRunLoop *) rl forMode:(NSString *) mode
{
	NSLog(@"-[MockPort removeConnection:%@ fromRunLoop:%p forMode:%@]", connection, rl, mode);
	// check in which modes we are removed
}

#if 0	// if we want to see how a NSPort is encoded by NSPortCoder

encodeWithCoder:

#endif

@end


@implementation NSPort (override)

+ (id) allocWithZone:(NSZone *)zone
{
	NSLog(@"+[NSPort allocWithZone:]");
	[self release];
	return [MockPort allocWithZone:zone];
}

@end

#endif

@protocol Server

- (float) a:(float) a plusB:(float) b;	// test parameter passing
- (bycopy NSString *) gimmeSugar;	// test bycopy - remote proxy
- (byref NSString *) gimmeMoreSugar;	// test byref - remote proxy
- (byref id) echo:(byref id) object;	// check if we get back our own object and how the local version deviates from the proxy

@end

// set up a socket port connection on port 50000 on localhost
// check for proxies being initialized
// spawn a server in a subthread
// communicate with the server and test for certain answers
// we may inspect the server through directly accessing some objects (we know that the thread is waiting in its runloop at certain situtations)

@implementation NSConnectionTest

- (void) setUp
{
	NSPort *port=[NSPort port];
	unsigned int cnt=[[NSConnection allConnections] count];
	connection=[NSConnection connectionWithReceivePort:port sendPort:port];
	STAssertNotNil(connection, nil);
	STAssertEquals([[NSConnection allConnections] count], cnt+1, nil);	// is added here to the connection list
	//	NSLog(@"connection object: %@", connection);
	// check if ports are added to runloop
}

- (void) tearDown;
{
	unsigned int cnt=[[NSConnection allConnections] count];
	[connection	invalidate];
	STAssertEquals([[NSConnection allConnections] count], cnt-1, nil);	// is removed here from the connection list
	// check if ports are already removed from runloop here
}

@end
