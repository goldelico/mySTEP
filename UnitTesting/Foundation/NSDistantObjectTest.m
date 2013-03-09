//
//  NSDistantObjectTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 08.03.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "NSDistantObjectTest.h"

@interface NSPortCoder (NSConcretePortCoder)
- (NSArray *) components;
- (void) encodeInvocation:(NSInvocation *) i;
- (void) encodeReturnValue:(NSInvocation *) r;
- (id) decodeRetainedObject;

@end


@interface MyConnection : NSObject
@end

@implementation MyConnection

- (void) _incrementLocalProxyCount;
{
	NSLog(@"did call _incrementLocalProxyCount");
}

- (NSPort *) receivePort
{
	return nil;
}

- (NSPort *) sendPort
{
	return nil;
}

@end


@implementation NSDistantObjectTest

#if 0	// FIXME: this modifies the encoding of NSPortCoder if this test is called before NSPortCoderTest...


- (void) test1
{
	NSObject *obj=[NSObject new];
	NSConnection *conn=[MyConnection new];
	NSDistantObject *d;
	NSPort *port=[[NSPort new] autorelease];
	d=[[NSDistantObject alloc] initWithLocal:obj connection:nil];
	STAssertNil(d, nil);	// does not create objects without connection
	d=[[NSDistantObject alloc] initWithLocal:obj connection:conn];
	STAssertNotNil(d, nil);	// does not create objects without connection - but we can pass an arbitrary object!
	STAssertEqualObjects([d connectionForProxy], conn, nil);
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:port sendPort:port components:nil];
	[d encodeWithCoder:pc];	// encode with port coder
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<00>", nil);
	[conn release];
	[obj release];
	[d release];
}

#if 0	// this one fails at all
- (void) test2
{
	NSObject *obj=[NSObject new];
	NSConnection *conn=[MyConnection new];
	NSDistantObject *d;
	NSPort *port=[[NSPort new] autorelease];
	d=[[NSDistantObject alloc] initWithTarget:obj connection:nil];
	STAssertNil(d, nil);	// does not create objects without connection
	d=[[NSDistantObject alloc] initWithTarget:obj connection:conn];
	STAssertNotNil(d, nil);	// does not create objects without connection - but we can pass an arbitrary object!
	STAssertEqualObjects([d connectionForProxy], conn, nil);
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:port sendPort:port components:nil];
	[d encodeWithCoder:pc];	// encode with port coder
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<00>", nil);
	[conn release];
	[obj release];
	[d release];
}
#endif

// can we create a distant object for a nil local object or target?

#endif

@end
