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


@interface NSViewHierarchyTest : XCTestCase
{
	NSWindow *window;

	NSView *view1;
	NSView *view2;
	NSView *view3;
	NSView *view4;
	NSView *view5;

	NSView *view6;
	NSView *view7;
	NSView *view8;
	NSView *view9;
	NSView *view10;

	NSView *view11;
	NSView *view12;
	NSView *view13;
	NSView *view14;
	NSView *view15;

	NSView *view16;
	NSView *view17;

	NSWindow *window2;
	NSView *view18;
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

	// mixed nesting of flipped and non-flipped
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

	// nesting of multiple flipped views
	view6=[[[FlippedView alloc] initWithFrame:NSMakeRect(10.0, 10.0, 280.0, 270.0)] autorelease];
	[[window contentView] addSubview:view6];
	view7=[[[FlippedView alloc] initWithFrame:NSMakeRect(5.0, 5.0, 270.0, 260.0)] autorelease];
	[view6 addSubview:view7];
	view8=[[[FlippedView alloc] initWithFrame:NSMakeRect(15.0, 15.0, 240.0, 230.0)] autorelease];
	[view7 addSubview:view8];
	view9=[[[FlippedView alloc] initWithFrame:NSMakeRect(7.0, 7.0, 225.0, 215.0)] autorelease];
	[view8 addSubview:view9];
	view10=[[[FlippedView alloc] initWithFrame:NSMakeRect(6.0, 6.0, 219.0, 214.0)] autorelease];
	[view9 addSubview:view10];

	// nesting of non-flipped views
	view11=[[[NSView alloc] initWithFrame:NSMakeRect(10.0, 10.0, 280.0, 270.0)] autorelease];
	[[window contentView] addSubview:view11];
	view12=[[[NSView alloc] initWithFrame:NSMakeRect(5.0, 5.0, 270.0, 260.0)] autorelease];
	[view11 addSubview:view12];
	view13=[[[NSView alloc] initWithFrame:NSMakeRect(15.0, 15.0, 240.0, 230.0)] autorelease];
	[view12 addSubview:view13];
	view14=[[[NSView alloc] initWithFrame:NSMakeRect(7.0, 7.0, 225.0, 215.0)] autorelease];
	[view13 addSubview:view14];
	view15=[[[NSView alloc] initWithFrame:NSMakeRect(6.0, 6.0, 219.0, 214.0)] autorelease];
	[view14 addSubview:view15];

	// views without window
	view16=[[[FlippedView alloc] initWithFrame:NSMakeRect(10.0, 10.0, 280.0, 270.0)] autorelease];
	view17=[[[FlippedView alloc] initWithFrame:NSMakeRect(5.0, 5.0, 270.0, 260.0)] autorelease];
	[view16 addSubview:view17];

	window2=[[NSWindow alloc] initWithContentRect:NSMakeRect(200.0, 200.0, 300.0, 300.0) styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:YES];
	view18=[[[FlippedView alloc] initWithFrame:NSMakeRect(10.0, 10.0, 280.0, 270.0)] autorelease];
	[[window2 contentView] addSubview:view18];
}

- (void) tearDown;
{
	[window release];
}

- (void) test_windows_01
{ // allocation did work
	XCTAssertNotNil(window);
	XCTAssertTrue([view5 window] == window);
	XCTAssertTrue([view10 window] == window);
	XCTAssertTrue([view15 window] == window);
	XCTAssertNil([view17 window]);
	XCTAssertNotNil(window2);
	XCTAssertTrue([view1 window] != [view18 window]);
}

- (void) test_frame_and_bounds_02
{ // default rotation is off and bounds are properly set
	XCTAssertEqual([view1 frameRotation], 0.0f);
	XCTAssertEqual([view1 boundsRotation], 0.0f);
	XCTAssertEquals([view1 frame], NSMakeRect(10.0, 10.0, 280.0, 270.0));
	XCTAssertEquals([view1 bounds], NSMakeRect(0.0, 0.0, 280.0, 270.0));
	XCTAssertEquals([view2 frame], NSMakeRect(5.0, 5.0, 270.0, 260.0));
	XCTAssertEquals([view2 bounds], NSMakeRect(0.0, 0.0, 270.0, 260.0));
	XCTAssertEquals([view2 visibleRect], NSMakeRect(0, 0, 270.0, 260.0));

	XCTAssertEqual([view6 frameRotation], 0.0f);
	XCTAssertEqual([view6 boundsRotation], 0.0f);
	XCTAssertEquals([view6 frame], NSMakeRect(10.0, 10.0, 280.0, 270.0));
	XCTAssertEquals([view6 bounds], NSMakeRect(0.0, 0.0, 280.0, 270.0));
	XCTAssertEquals([view7 frame], NSMakeRect(5.0, 5.0, 270.0, 260.0));
	XCTAssertEquals([view7 bounds], NSMakeRect(0.0, 0.0, 270.0, 260.0));
	XCTAssertEquals([view7 visibleRect], NSMakeRect(0, 0, 270.0, 260.0));

	XCTAssertEquals([view14 visibleRect], NSMakeRect(0, 0, 225.0, 215.0));
}

- (void) test_isflipped_05
{ // check flipped status
	XCTAssertTrue([view1 isFlipped]);
	XCTAssertFalse([view2 isFlipped]);
	XCTAssertTrue([view3 isFlipped]);
	XCTAssertTrue([view4 isFlipped]);
	XCTAssertFalse([view5 isFlipped]);

	XCTAssertTrue([view6 isFlipped]);
	XCTAssertTrue([view7 isFlipped]);
	XCTAssertTrue([view8 isFlipped]);
	XCTAssertTrue([view9 isFlipped]);
	XCTAssertTrue([view10 isFlipped]);
}

- (void) test_mixed_11
{ // test relative coordinates - convertPointFromView: toView: incl. nil view = Window
	NSPoint pnt=NSMakePoint(25.0, 35.0);
	XCTAssertEquals([view1 convertPoint:pnt toView:nil], NSMakePoint(35.0, 245.0));
	XCTAssertEquals([view1 convertPoint:pnt toView:view2], NSMakePoint(20.0, 230.0));
	XCTAssertEquals([view1 convertPoint:pnt fromView:view2], NSMakePoint(30.0, 230.0));

	XCTAssertEquals([view6 convertPoint:pnt toView:nil], NSMakePoint(35.0, 245.0));
	XCTAssertEquals([view6 convertPoint:pnt toView:view7], NSMakePoint(20.0, 30.0));
	XCTAssertEquals([view6 convertPoint:pnt fromView:view7], NSMakePoint(30.0, 40.0));
};

- (void) test_mixed_12
	{ // test relative coordinates - convertPointFromView: toView: incl. nil view = Window
	NSPoint pnt=NSMakePoint(25.0, 35.0);
	XCTAssertEquals([view2 convertPoint:pnt toView:nil], NSMakePoint(40.0, 50.0));
	XCTAssertEquals([view2 convertPoint:pnt toView:view1], NSMakePoint(30.0, 230.0));
	XCTAssertEquals([view2 convertPoint:pnt fromView:view1], NSMakePoint(20.0, 230.0));

	XCTAssertEquals([view7 convertPoint:pnt toView:nil], NSMakePoint(40.0, 240.0));
	XCTAssertEquals([view7 convertPoint:pnt toView:view6], NSMakePoint(30.0, 40.0));
	XCTAssertEquals([view7 convertPoint:pnt fromView:view6], NSMakePoint(20.0, 30.0));
};

- (void) test_mixed_13
{ // test relative coordinates - convertPointFromView: toView: incl. nil view = Window
	NSPoint pnt=NSMakePoint(25.0, 35.0);
	XCTAssertEquals([view3 convertPoint:pnt toView:nil], NSMakePoint(55.0, 225.0));
	XCTAssertEquals([view3 convertPoint:pnt toView:view1], NSMakePoint(45.0, 55.0));
	XCTAssertEquals([view3 convertPoint:pnt toView:view2], NSMakePoint(40.0, 210.0));

	XCTAssertEquals([view8 convertPoint:pnt toView:nil], NSMakePoint(55.0, 225.0));
	XCTAssertEquals([view8 convertPoint:pnt toView:view6], NSMakePoint(45.0, 55.0));
	XCTAssertEquals([view8 convertPoint:pnt toView:view7], NSMakePoint(40.0, 50.0));
};

- (void) test_mixed_14
{ // test relative coordinates - convertPointFromView: toView: incl. nil view = Window
	NSPoint pnt=NSMakePoint(25.0, 35.0);
	/*
	 NSViewHierarchyTest.m:122: error: -[NSViewHierarchyTest test14] : '{62, 217}' should be equal to '{62, 218}'
	 NSViewHierarchyTest.m:123: error: -[NSViewHierarchyTest test14] : '{52, 63}' should be equal to '{52, 62}'
	 NSViewHierarchyTest.m:124: error: -[NSViewHierarchyTest test14] : '{47, 202}' should be equal to '{47, 203}'
	 NSViewHierarchyTest.m:125: error: -[NSViewHierarchyTest test14] : '{32, 43}' should be equal to '{32, 42}'
	 */
	XCTAssertEquals([view4 convertPoint:pnt toView:nil], NSMakePoint(62.0, 218.0));
	XCTAssertEquals([view4 convertPoint:pnt toView:view1], NSMakePoint(52.0, 62.0));
	XCTAssertEquals([view4 convertPoint:pnt toView:view2], NSMakePoint(47.0, 203.0));
	XCTAssertEquals([view4 convertPoint:pnt toView:view3], NSMakePoint(32.0, 42.0));

	XCTAssertEquals([view9 convertPoint:pnt toView:nil], NSMakePoint(62.0, 218.0));
	XCTAssertEquals([view9 convertPoint:pnt toView:view6], NSMakePoint(52.0, 62.0));
	XCTAssertEquals([view9 convertPoint:pnt toView:view7], NSMakePoint(47.0, 57.0));
	XCTAssertEquals([view9 convertPoint:pnt toView:view8], NSMakePoint(32.0, 42.0));
};

- (void) test_mixed_15
{ // test relative coordinates - convertPointFromView: toView: incl. nil view = Window
	NSPoint pnt=NSMakePoint(25.0, 35.0);
	/*
	 NSViewHierarchyTest.m:131: error: -[NSViewHierarchyTest test15] : '{68, 78}' should be equal to '{68, 68}'
	 NSViewHierarchyTest.m:132: error: -[NSViewHierarchyTest test15] : '{58, 202}' should be equal to '{58, 212}'
	 NSViewHierarchyTest.m:133: error: -[NSViewHierarchyTest test15] : '{53, 63}' should be equal to '{53, 53}'
	 NSViewHierarchyTest.m:134: error: -[NSViewHierarchyTest test15] : '{38, 182}' should be equal to '{38, 192}'
	 NSViewHierarchyTest.m:135: error: -[NSViewHierarchyTest test15] : '{31, 174}' should be equal to '{31, 185}'
	 */
	XCTAssertEquals([view5 convertPoint:pnt toView:nil], NSMakePoint(68.0, 68.0));
	XCTAssertEquals([view5 convertPoint:pnt toView:view1], NSMakePoint(58.0, 212.0));
	XCTAssertEquals([view5 convertPoint:pnt toView:view2], NSMakePoint(53.0, 53.0));
	XCTAssertEquals([view5 convertPoint:pnt toView:view3], NSMakePoint(38.0, 192.0));
	XCTAssertEquals([view5 convertPoint:pnt toView:view4], NSMakePoint(31.0, 185.0));
	XCTAssertEquals([view5 convertPoint:pnt toView:view5], pnt);
}

- (void) test_flipped_only_16
{ // test flipped only
	NSPoint pnt=NSMakePoint(25.0, 35.0);
	XCTAssertEquals([view6 convertPoint:pnt toView:nil], NSMakePoint(35.0, 245.0));
	XCTAssertEquals([view6 convertPoint:pnt toView:view7], NSMakePoint(20.0, 30.0));
	XCTAssertEquals([view6 convertPoint:pnt fromView:view7], NSMakePoint(30.0, 40.0));
	XCTAssertEquals([view7 convertPoint:pnt toView:nil], NSMakePoint(40.0, 240.0));
	XCTAssertEquals([view7 convertPoint:pnt toView:view6], NSMakePoint(30.0, 40.0));
	XCTAssertEquals([view7 convertPoint:pnt fromView:view6], NSMakePoint(20.0, 30.0));
	XCTAssertEquals([view8 convertPoint:pnt toView:nil], NSMakePoint(55.0, 225.0));
	XCTAssertEquals([view8 convertPoint:pnt toView:view6], NSMakePoint(45.0, 55.0));
	XCTAssertEquals([view8 convertPoint:pnt toView:view7], NSMakePoint(40.0, 50.0));
	XCTAssertEquals([view9 convertPoint:pnt toView:nil], NSMakePoint(62.0, 218.0));
	XCTAssertEquals([view9 convertPoint:pnt toView:view6], NSMakePoint(52.0, 62.0));
	XCTAssertEquals([view9 convertPoint:pnt toView:view7], NSMakePoint(47.0, 57.0));
	XCTAssertEquals([view9 convertPoint:pnt toView:view8], NSMakePoint(32.0, 42.0));
	XCTAssertEquals([view10 convertPoint:pnt toView:nil], NSMakePoint(68.0, 212.0));
	XCTAssertEquals([view10 convertPoint:pnt toView:view6], NSMakePoint(58.0, 68.0));
	XCTAssertEquals([view10 convertPoint:pnt toView:view7], NSMakePoint(53.0, 63.0));
	XCTAssertEquals([view10 convertPoint:pnt toView:view8], NSMakePoint(38.0, 48.0));
	XCTAssertEquals([view10 convertPoint:pnt toView:view9], NSMakePoint(31.0, 41.0));
	XCTAssertEquals([view10 convertPoint:pnt toView:view10], pnt);
}

- (void) test_nonflipped_only_17
	{ // test nonflipped only
	NSPoint pnt=NSMakePoint(25.0, 35.0);
	XCTAssertEquals([view15 convertPoint:pnt toView:view11], NSMakePoint(58.0, 68.0));
	XCTAssertEquals([view15 convertPoint:pnt toView:view12], NSMakePoint(53.0, 63.0));
	XCTAssertEquals([view15 convertPoint:pnt toView:view13], NSMakePoint(38.0, 48.0));
	XCTAssertEquals([view15 convertPoint:pnt toView:view14], NSMakePoint(31.0, 41.0));
	XCTAssertEquals([view15 convertPoint:pnt toView:view15], pnt);
	}

- (void) test_across_hierarchy_18
{ // test across view hierarchies
	NSPoint pnt=NSMakePoint(25.0, 35.0);
	XCTAssertEquals([view15 convertPoint:pnt toView:view5], NSMakePoint(25.0, 45.0));
	XCTAssertEquals([view15 convertPoint:pnt toView:view10], NSMakePoint(25.0, 169.0));
	// really different windows does not raise an exception
	XCTAssertEquals([view11 convertPoint:pnt toView:view18], NSMakePoint(25.0, 235.0));
}

- (void) test_windowless_19
{ // test windowless views (seems to have some default)
	NSPoint pnt=NSMakePoint(25.0, 35.0);
	XCTAssertEquals([view16 convertPoint:pnt toView:nil], NSMakePoint(35.0, 245.0));
	XCTAssertEquals([view16 convertPoint:pnt toView:view17], NSMakePoint(20.0, 30.0));
	XCTAssertEquals([view17 convertPoint:pnt toView:nil], NSMakePoint(40.0, 240.0));
	XCTAssertEquals([view17 convertPoint:pnt toView:view16], NSMakePoint(30.0, 40.0));
	XCTAssertEquals([view17 convertPoint:pnt toView:view5], NSMakePoint(-3.0, 207.0));
}

#if 0	// n/a yet available with mySTEP
- (void) test_20
{ // test relative coordinates - convertPointToBacking:
	NSPoint pnt=NSMakePoint(25.0, 35.0);
	XCTAssertEquals([view1 convertPointToBacking:pnt], NSMakePoint(50.0, -70.0));
	XCTAssertEquals([view2 convertPointToBacking:pnt], NSMakePoint(50.0, 70.0));
}
#endif

- (void) test_rect_31
{ // test relative coordinates - convertRectFromView: toView: incl. nil view = Window
	NSRect rect=NSMakeRect(25.0, 35.0, 50.0, 45.0);
	// to window
	XCTAssertEquals([view1 convertRect:rect toView:nil], NSMakeRect(35.0, 200.0, 50.0, 45.0));
	XCTAssertEquals([view6 convertRect:rect toView:nil], NSMakeRect(35.0, 200.0, 50.0, 45.0));
	XCTAssertEquals([view11 convertRect:rect toView:nil], NSMakeRect(35.0, 45.0, 50.0, 45.0));

	// within hierarchies
	XCTAssertEquals([view1 convertRect:rect toView:view2], NSMakeRect(20.0, 185.0, 50.0, 45.0));
	XCTAssertEquals([view1 convertRect:rect toView:view5], NSMakeRect(-8.0, 167.0, 50.0, 45.0));
	XCTAssertEquals([view1 convertRect:rect fromView:view2], NSMakeRect(30.0, 185.0, 50.0, 45.0));
	XCTAssertEquals([view1 convertRect:rect fromView:view5], NSMakeRect(58.0, 167.0, 50.0, 45.0));

	XCTAssertEquals([view6 convertRect:rect toView:view7], NSMakeRect(20.0, 30.0, 50.0, 45.0));
	XCTAssertEquals([view6 convertRect:rect toView:view10], NSMakeRect(-8.0, 2.0, 50.0, 45.0));
	XCTAssertEquals([view6 convertRect:rect fromView:view10], NSMakeRect(58.0, 68.0, 50.0, 45.0));

	XCTAssertEquals([view11 convertRect:rect toView:view12], NSMakeRect(20.0, 30.0, 50.0, 45.0));
	XCTAssertEquals([view11 convertRect:rect toView:view15], NSMakeRect(-8.0, 2.0, 50.0, 45.0));
	XCTAssertEquals([view11 convertRect:rect fromView:view15], NSMakeRect(58.0, 68.0, 50.0, 45.0));

	// across hierarchies
	XCTAssertEquals([view6 convertRect:rect toView:view2], NSMakeRect(20.0, 185.0, 50.0, 45.0));
	XCTAssertEquals([view6 convertRect:rect fromView:view2], NSMakeRect(30.0, 185.0, 50.0, 45.0));
	XCTAssertEquals([view11 convertRect:rect toView:view2], NSMakeRect(20.0, 30.0, 50.0, 45.0));
	XCTAssertEquals([view11 convertRect:rect fromView:view2], NSMakeRect(30.0, 40.0, 50.0, 45.0));
	XCTAssertEquals([view15 convertRect:rect fromView:view5], NSMakeRect(25.0, 25.0, 50.0, 45.0));
	XCTAssertEquals([view15 convertRect:rect fromView:view10], NSMakeRect(25.0, 124.0, 50.0, 45.0));
}

/* more rect transforms */

/* transform NSSize */

- (void) test_rect_100
{ // special test for NSBox
	NSBox *box=[[NSBox alloc] initWithFrame:NSMakeRect(263.0,16.0,140.0,146.0)];
	[[window contentView] addSubview:box];
	XCTAssertEquals([box frame], NSMakeRect(263.0, 16.0, 140.0, 146.0));
	XCTAssertEquals([box bounds], NSMakeRect(0.0, 0.0, 140.0, 146.0));
	XCTAssertEquals([[box contentView] frame], NSMakeRect(7.0, 7.0, 126.0, 124.0));
	XCTAssertEquals([[box contentView] bounds], NSMakeRect(0.0, 0.0, 126.0, 124.0));
	NSRect subRect=[box convertRect:NSMakeRect(0.0,0.0,140.0,146.0) toView:[box contentView]];
	XCTAssertEquals(subRect, NSMakeRect(-7.0, -7.0, 140.0, 146.0));
}

@end
