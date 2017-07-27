//
//  NSPortTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 14.03.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <XCTest/XCTest.h>


@interface NSPortTest : XCTestCase {
	
}

@end


@implementation NSPortTest

#if 0
- (void) test1
{
	NSMutableArray *components;
	NSPort *port=[NSMessagePort port];	// create new message port
	XCTAssertNotNil(port, nil);
	
	[port setDelegate:self];
	
	[[NSMessagePortNameServer sharedInstance] registerPort:port name:@"MessagePortTest"];

	[port scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	
	XCTAssertTrue([port isValid], nil);
	[port sendBeforeDate:[NSDate dateWithTimeIntervalSinceNow:5.0] components:components from:self reserved:0];
	[port invalidate];
	XCTAssertFalse([port isValid], nil);
}
#endif

@end
