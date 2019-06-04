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
	NSView *view5;
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
	window=[[NSWindow alloc] initWithContentRect:NSMakeRect(100.0, 100.0, 300.0, 300.0) styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:YES];
	view1=[[[FlippedView alloc] initWithFrame:NSMakeRect(10.0, 10.0, 280.0, 270.0)] autorelease];
	[[window contentView] addSubview:view1];
	view2=[[[NSView alloc] initWithFrame:NSMakeRect(5.0, 5.0, 270.0, 260.0)] autorelease];
	[view1 addSubview:view2];
	view3=[[[FlippedView alloc] initWithFrame:NSMakeRect(15.0, 15.0, 240.0, 230.0)] autorelease];
	[view2 addSubview:view3];
	// nesting of two flipped views
	view4=[[[FlippedView alloc] initWithFrame:NSMakeRect(7.0, 7.0, 225.0, 215.0)] autorelease];
	[view3 addSubview:view4];
	view5=[[[NSView alloc] initWithFrame:NSMakeRect(6.0, 6.0, 219.0, 214.0)] autorelease];
	[view4 addSubview:view5];
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
	XCTAssert([view4 isFlipped]);
	XCTAssert(![view5 isFlipped]);
}

- (void) test10
{ // test relative coordinates - convertPointFromView: toView: incl. nil view = Window
	NSPoint pnt=NSMakePoint(25.0, 35.0);
	XCTAssertEquals([view1 convertPoint:pnt toView:nil], NSMakePoint(35.0, 245.0), @"");
	XCTAssertEquals([view1 convertPoint:pnt toView:view2], NSMakePoint(20.0, 230.0), @"");
	XCTAssertEquals([view1 convertPoint:pnt fromView:view2], NSMakePoint(30.0, 230.0), @"");
	XCTAssertEquals([view2 convertPoint:pnt toView:nil], NSMakePoint(40.0, 50.0), @"");
	XCTAssertEquals([view2 convertPoint:pnt toView:view1], NSMakePoint(30.0, 230.0), @"");
	XCTAssertEquals([view2 convertPoint:pnt fromView:view1], NSMakePoint(20.0, 230.0), @"");
	XCTAssertEquals([view3 convertPoint:pnt toView:nil], NSMakePoint(55.0, 225.0), @"");
	XCTAssertEquals([view3 convertPoint:pnt toView:view1], NSMakePoint(45.0, 55.0), @"");
	XCTAssertEquals([view3 convertPoint:pnt toView:view2], NSMakePoint(40.0, 210.0), @"");
	XCTAssertEquals([view4 convertPoint:pnt toView:nil], NSMakePoint(62.0, 218.0), @"");
	XCTAssertEquals([view4 convertPoint:pnt toView:view1], NSMakePoint(52.0, 62.0), @"");
	XCTAssertEquals([view4 convertPoint:pnt toView:view2], NSMakePoint(47.0, 203.0), @"");
	XCTAssertEquals([view4 convertPoint:pnt toView:view3], NSMakePoint(32.0, 42.0), @"");
	XCTAssertEquals([view5 convertPoint:pnt toView:nil], NSMakePoint(68.0, 68.0), @"");
	XCTAssertEquals([view5 convertPoint:pnt toView:view1], NSMakePoint(58.0, 212.0), @"");
	XCTAssertEquals([view5 convertPoint:pnt toView:view2], NSMakePoint(53.0, 53.0), @"");
	XCTAssertEquals([view5 convertPoint:pnt toView:view3], NSMakePoint(38.0, 192.0), @"");
	XCTAssertEquals([view5 convertPoint:pnt toView:view4], NSMakePoint(31.0, 185.0), @"");
	XCTAssertEquals([view5 convertPoint:pnt toView:view5], pnt, @"");
}

- (void) test20
{ // test relative coordinates - convertPointFromView: toView: incl. nil view = Window
	NSPoint pnt=NSMakePoint(25.0, 35.0);
	XCTAssertEquals([view1 convertPointToBacking:pnt], NSMakePoint(50.0, -70.0), @"");
	XCTAssertEquals([view2 convertPointToBacking:pnt], NSMakePoint(50.0, 70.0), @"");
}

- (void) test30
{ // test relative coordinates - convertRectFromView: toView: incl. nil view = Window
	NSRect rect=NSMakeRect(25.0, 35.0, 50.0, 45.0);
}

@end
