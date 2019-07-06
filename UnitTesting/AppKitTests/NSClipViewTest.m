//
//  NSClipViewTest.m
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

@interface DocumentView : NSView
{
	BOOL isFlipped;
}
- (BOOL) isFlipped;
- (void) setFlipped:(BOOL) flipped;
@end

@implementation DocumentView


- (BOOL) isFlipped
{
	return isFlipped;
}

- (void) setFlipped:(BOOL) flipped;
{
	isFlipped=flipped;
}

@end

@interface NSClipViewTest : XCTestCase {
	NSWindow *window;
	NSClipView *clipView;
	DocumentView *view;
}

@end

@implementation NSClipViewTest

- (void) setUp;
{
	window=[[NSWindow alloc] initWithContentRect:NSMakeRect(0.0, 0.0, 1000.0, 1000.0) styleMask:0xf backing:NSBackingStoreBuffered defer:YES];
	// NOTE: we are NOT embedded in a NSScrollView!
	clipView=[[NSClipView alloc] initWithFrame:NSMakeRect(50.0, 50.0, 200.0, 200.0)];
	view=[[DocumentView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 700.0, 1100.0)];
	[clipView setDocumentView:view];
	[[window contentView] addSubview:clipView];
}

- (void) tearDown;
{
	[view release];
	[window release];
}

- (void) test01
{ // allocation did work
	XCTAssertNotNil(clipView);
	XCTAssertNotNil(view);
	XCTAssertTrue([clipView documentView] == view);
	XCTAssertNil([view enclosingScrollView]);
	XCTAssertFalse([clipView isFlipped]);
	XCTAssertFalse([view isFlipped]);
	XCTAssertTrue([clipView wantsDefaultClipping]);
	XCTAssertTrue([view wantsDefaultClipping]);
}

- (void) test02
{ // initial parameters
	XCTAssertEquals([view frame], NSMakeRect(0.0, 0.0, 700.0, 1100.0));
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 700.0, 1100.0));
	XCTAssertEquals([view visibleRect], NSMakeRect(0.0, 0.0, 200.0, 200.0));
	XCTAssertEquals([clipView frame], NSMakeRect(50.0, 50.0, 200.0, 200.0));
	XCTAssertEquals([clipView bounds], NSMakeRect(0.0, 0.0, 200.0, 200.0));
	XCTAssertEquals([clipView documentRect], NSMakeRect(0.0, 0.0, 700.0, 1100.0));
	XCTAssertEquals([clipView documentVisibleRect], NSMakeRect(0.0, 0.0, 200.0, 200.0));
	XCTAssertEquals([clipView visibleRect], NSMakeRect(0.0, 0.0, 200.0, 200.0));
}

- (void) test10
{ // translation
	XCTAssertEquals([clipView frame], NSMakeRect(50.0, 50.0, 200.0, 200.0));
	XCTAssertEquals([clipView bounds], NSMakeRect(0.0, 0.0, 200.0, 200.0));
	XCTAssertEquals([clipView visibleRect], NSMakeRect(0.0, 0.0, 200.0, 200.0));
	XCTAssertEquals([clipView documentRect], NSMakeRect(0.0, 0.0, 700.0, 1100.0));
	XCTAssertEquals([clipView documentVisibleRect], NSMakeRect(0.0, 0.0, 200.0, 200.0));
	XCTAssertEquals([view visibleRect], NSMakeRect(0.0, 0.0, 200.0, 200.0));
}

- (void) test11
{
	[clipView scrollToPoint:NSMakePoint(20.0, 30.0)];
	XCTAssertEquals([clipView frame], NSMakeRect(50.0, 50.0, 200.0, 200.0));
	XCTAssertEquals([clipView bounds], NSMakeRect(20.0, 30.0, 200.0, 200.0));
	XCTAssertEquals([clipView visibleRect], NSMakeRect(20.0, 30.0, 200.0, 200.0));
	XCTAssertEquals([clipView documentRect], NSMakeRect(0.0, 0.0, 700.0, 1100.0));
	XCTAssertEquals([clipView documentVisibleRect], NSMakeRect(20.0, 30.0, 200.0, 200.0));
	XCTAssertEquals([view visibleRect], NSMakeRect(20.0, 30.0, 200.0, 200.0));
}

- (void) test20
{ // make document smaller than clip view
	[view setFrameSize:NSMakeSize(50,50)];
	XCTAssertEquals([view frame], NSMakeRect(0.0, 0.0, 50.0, 50.0));	// became smaller
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 50.0, 50.0));	// became smaller
	XCTAssertEquals([view visibleRect], NSMakeRect(0.0, 0.0, 50.0, 50.0));	// became smaller
	XCTAssertEquals([clipView frame], NSMakeRect(50.0, 50.0, 200.0, 200.0));
	XCTAssertEquals([clipView bounds], NSMakeRect(0.0, 0.0, 200.0, 200.0));
	XCTAssertEquals([clipView documentRect], NSMakeRect(0.0, 0.0, 200.0, 200.0));	// enlarged to clip view size
	XCTAssertEquals([clipView documentVisibleRect], NSMakeRect(0.0, 0.0, 200.0, 200.0));
	XCTAssertEquals([clipView visibleRect], NSMakeRect(0.0, 0.0, 200.0, 200.0));
}

- (void) test30
{ // flip the document view and resize
	[view setFlipped:YES];	// make document view being flipped
	XCTAssertTrue([view isFlipped]);	// document view becomes flipped
	XCTAssertFalse([clipView isFlipped]);	// ClipView remains unflipped!
	[view setFrameSize:NSMakeSize(50,50)];
	XCTAssertEquals([view frame], NSMakeRect(0.0, 0.0, 50.0, 50.0));	// became smaller
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 50.0, 50.0));	// became smaller
	XCTAssertEquals([view visibleRect], NSMakeRect(0.0, 0.0, 50.0, 50.0));	// became smaller
	XCTAssertEquals([clipView frame], NSMakeRect(50.0, 50.0, 200.0, 200.0));
	XCTAssertEquals([clipView bounds], NSMakeRect(0.0, 0.0, 200.0, 200.0));
	XCTAssertEquals([clipView documentRect], NSMakeRect(0.0, 0.0, 200.0, 200.0));	// enlarged to clip view size
	XCTAssertEquals([clipView documentVisibleRect], NSMakeRect(0.0, -150.0, 200.0, 200.0));
	XCTAssertEquals([clipView visibleRect], NSMakeRect(0.0, 0.0, 200.0, 200.0));
}

- (void) test300;	// should be a separate test!
{
	NSScrollView *sv=[[NSScrollView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 200.0, 200.0)];
	XCTAssertFalse([sv hasVerticalScroller]);
	XCTAssertNil([sv verticalScroller]);
	[sv setHasVerticalScroller:YES];
	XCTAssertTrue([sv hasVerticalScroller]);
	XCTAssertNotNil([sv verticalScroller]);	// has created one
	[sv setHasVerticalScroller:NO];
	XCTAssertFalse([sv hasVerticalScroller]);
	XCTAssertNotNil([sv verticalScroller]);	// is not removed
}

@end
