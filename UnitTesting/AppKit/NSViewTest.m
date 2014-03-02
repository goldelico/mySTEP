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
	window=[[NSWindow alloc] initWithContentRect:NSMakeRect(0.0, 0.0, 1000.0, 1000.0) styleMask:0xf backing:NSBackingStoreBuffered defer:YES];
	view=[[NSTestView alloc] initWithFrame:NSMakeRect(30.0, 50.0, 700.0, 1100.0)];
	[[window contentView] addSubview:view];
}

- (void) tearDown;
{
	[view release];
	[window release];
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
	STAssertTrue([view needsDisplay], nil);	// has already been set by adding the view to a winodw
	[view setNeedsDisplay:NO];	
	STAssertFalse([view needsDisplay], nil);
	[view setNeedsDisplay:YES];	
	STAssertTrue([view needsDisplay], nil);
}

// check transform to superview
// with/without flipping
// transform to base
// trasform base to screen (NSWindow?)

@end
