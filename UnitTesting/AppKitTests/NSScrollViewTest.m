//
//  NSScrollViewTest.m
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
@end	// defined for ClipViewTest

@interface NSScrollViewTest : XCTestCase
{
	NSWindow *window;
	NSScrollView *scrollView;
	NSClipView *clipView;
	DocumentView *view;
}
@end

@implementation NSScrollViewTest

- (void) setUp;
{
	window=[[NSWindow alloc] initWithContentRect:NSMakeRect(0.0, 0.0, 1000.0, 1000.0) styleMask:0xf backing:NSBackingStoreBuffered defer:YES];
	scrollView=[[NSScrollView alloc] initWithFrame:NSMakeRect(300.0, 300.0, 200.0, 200.0)];
	clipView=[[NSClipView alloc] initWithFrame:NSMakeRect(50.0, 50.0, 200.0, 200.0)];
	view=[[DocumentView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 700.0, 1100.0)];
	[scrollView setContentView:clipView];
	[scrollView setDocumentView:view];
	[[window contentView] addSubview:scrollView];
}

- (void) tearDown;
{
	[scrollView release];
	[clipView release];
	[view release];
	[window release];
}

- (void) test01
{ // allocation did work
	XCTAssertNotNil(scrollView);
	XCTAssertNotNil(clipView);
	XCTAssertNotNil(view);
	XCTAssertTrue([clipView documentView] == view);
	XCTAssertTrue([scrollView documentView] == view);
	XCTAssertTrue([view enclosingScrollView] == scrollView);
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

- (void) test300;
{ // magnification defaults
	XCTAssertTrue([scrollView magnification] == 1.0);
	XCTAssertTrue([scrollView minMagnification] == 0.25);
	XCTAssertTrue([scrollView maxMagnification] == 4.0);
}

- (void) test301;
{ // limitations of magnification
	XCTAssertTrue([scrollView magnification] == 1.0);
	[scrollView setMagnification:100.0];
	XCTAssertTrue([scrollView magnification] == [scrollView maxMagnification]);
	[scrollView setMagnification:0.1];
	XCTAssertTrue([scrollView magnification] == [scrollView minMagnification]);
	[scrollView setMagnification:0.0];
	XCTAssertTrue([scrollView magnification] == [scrollView minMagnification]);
	[scrollView setMagnification:-20.0];
	XCTAssertTrue([scrollView magnification] == [scrollView minMagnification]);
}

- (void) test302;
{ // changing limits of magnification
	[scrollView setMagnification:1.0];
	XCTAssertTrue([scrollView magnification] == 1.0);
	XCTAssertTrue([scrollView minMagnification] == 0.25);
	XCTAssertTrue([scrollView maxMagnification] == 4.0);
	[scrollView setMaxMagnification:5.0];
	XCTAssertTrue([scrollView minMagnification] == 0.25);
	XCTAssertTrue([scrollView maxMagnification] == 5.0);
	XCTAssertTrue([scrollView magnification] == 1.0);
	[scrollView setMaxMagnification:1.0];
	XCTAssertTrue([scrollView minMagnification] == 0.25);
	XCTAssertTrue([scrollView maxMagnification] == 1.0);
	XCTAssertTrue([scrollView magnification] == 1.0);
	[scrollView setMaxMagnification:0.8];
	XCTAssertTrue([scrollView minMagnification] == 0.25);
	XCTAssertTrue([scrollView maxMagnification] == 0.8);
	XCTAssertTrue([scrollView magnification] == 1.0);	// NOT immediately changed
	// raises an NSInvalidArgumentException
	[scrollView setMinMagnification:1.2];	// > max
	XCTAssertTrue([scrollView minMagnification] == 0.8);
	XCTAssertTrue([scrollView maxMagnification] == 0.8);
	XCTAssertTrue([scrollView magnification] == 1.0);
}

- (void) test303;
{ // trying to set very small or even negative magnification
	[scrollView setMinMagnification:1e-9];
	XCTAssertTrue([scrollView minMagnification] == 1e-4);	// internal minimum!
	[scrollView setMinMagnification:0];
	XCTAssertTrue([scrollView minMagnification] == 1e-4);	// internal minimum!
	[scrollView setMinMagnification:1.0];	// so that we see that the next setting is not simply ignored
	XCTAssertTrue([scrollView minMagnification] == 1.0);
	[scrollView setMinMagnification:-0.25];
	XCTAssertTrue([scrollView minMagnification] == 1e-4);	// internal minimum!
	[scrollView setMaxMagnification:1e9];
	XCTAssertTrue([scrollView maxMagnification] == 1e9);	// not really an internal maximum!
	[scrollView setMaxMagnification:1e20];
	XCTAssertTrue([scrollView maxMagnification] == 1e20);	// not really an internal maximum!
}

@end
