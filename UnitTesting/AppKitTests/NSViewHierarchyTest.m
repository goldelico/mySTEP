//
//  NSViewBoundsTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 27.12.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Cocoa/Cocoa.h>

// contrary to STAssertEquals(), XCTAssertEqual() can only handle scalar objects
// https://stackoverflow.com/questions/19178109/xctassertequal-error-3-is-not-equal-to-3
// http://www.openradar.me/16281876

#define XCTAssertEquals(a, b, ...) ({ \
	typeof(a) _a=a; typeof(b) _b=b; \
	XCTAssertEqualObjects( \
		[NSValue value:&_a withObjCType:@encode(typeof(a))], \
		[NSValue value:&_b withObjCType:@encode(typeof(b))], \
		##__VA_ARGS__); })


@interface NSViewHierarchyTest : XCTestCase {
	NSWindow *window;
	NSView *view1;
	NSView *view2;
	NSView *view3;
	NSView *view4;
}

@end

@interface FlippedView : NSView

@end

@implementation FlippedView

- (BOOL) isFlipped
{
	return YES;
}

@end

@implementation NSViewHierarchyTest

- (void) setUp;
{
	window=[[NSWindow alloc] initWithContentRect:NSMakeRect(100.0, 100.0, 300.0, 300.0) styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:YES];
	view1=[[[FlippedView alloc] initWithFrame:NSMakeRect(10.0, 10.0, 280.0, 270.0)] autorelease];
	[[window contentView] addSubview:view1];
	view2=[[[NSView alloc] initWithFrame:NSMakeRect(5.0, 5.0, 270.0, 260.0)] autorelease];
	[view1 addSubview:view2];
	view3=[[[FlippedView alloc] initWithFrame:NSMakeRect(15.0, 15.0, 240.0, 230.0)] autorelease];
	[view2 addSubview:view3];
	view4=[[[NSView alloc] initWithFrame:NSMakeRect(7.0, 7.0, 225.0, 215.0)] autorelease];
	[view3 addSubview:view4];
}

- (void) tearDown;
{
	[window release];
}

- (void) test01
{ // allocation did work
	XCTAssertNotNil(window);
}

- (void) test02
{ // default rotation is off and bounds are properly set
	XCTAssertEqual([view1 frameRotation], 0.0f);
	XCTAssertEqual([view1 boundsRotation], 0.0f);
	XCTAssertEquals([view1 frame], NSMakeRect(10.0, 10.0, 280.0, 270.0));
	XCTAssertEquals([view1 bounds], NSMakeRect(0.0, 0.0, 280.0, 270.0));
	XCTAssertEquals([view2 frame], NSMakeRect(5.0, 5.0, 270.0, 260.0));
	XCTAssertEquals([view2 bounds], NSMakeRect(0.0, 0.0, 270.0, 260.0));
}

- (void) test05
{ // setting negative frame size is possible
	XCTAssert([view1 isFlipped]);
	XCTAssert(![view2 isFlipped]);
	XCTAssert([view3 isFlipped]);
	XCTAssert(![view4 isFlipped]);
}

- (void) test10
{ // test relative coordinates - convertPointFromView: toView: incl. nil view = Window
}

@end
