//
//  NSViewBoundsTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 27.12.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import <Cocoa/Cocoa.h>


@interface NSTestView : NSView {
	BOOL isFlipped;
}

@end

@interface NSViewTest : SenTestCase {
	NSWindow *window;
	NSTestView *view;
}

@end

@implementation NSTestView

- (BOOL) isFlipped
{
	return isFlipped;
}

- (void) setFlipped:(BOOL) flipped;
{
	isFlipped=flipped;
}

@end

@implementation NSViewTest

- (void) setUp;
{
	// create window with defined properties
	view=[[NSTestView alloc] initWithFrame:NSMakeRect(30.0, 50.0, 700.0, 1100.0)];
	// add as subview to contentView
}

- (void) tearDown;
{
	[view release];
}

- (void) test01
{ // allocation did work
	STAssertNotNil(view, nil);
	STAssertFalse([view isFlipped], nil);
	[view setFlipped:YES];
	STAssertTrue([view isFlipped], nil);
	[view setFlipped:NO];
	STAssertFalse([view isFlipped], nil);
}

- (void) test02
{
	STAssertFalse([view needsDisplay], nil);
	[view setNeedsDisplay:YES];	
	STAssertTrue([view needsDisplay], nil);	// false if we have no window
	[view setNeedsDisplay:NO];	
	STAssertFalse([view needsDisplay], nil);
}

// check transform to superview
// with/without flipping
// transform to base
// trasform base to screen (NSWindow?)

@end
