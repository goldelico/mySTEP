//
//  NSConnectionTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 08.03.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "NSConnectionTest.h"

// FIXME: we have a problem with these mock objects defined as categories for
// existing Foundation classes
// the problem is that one category is applied to the full FoundationTests suite!

#if 0

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
