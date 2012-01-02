//
//  NSTextContainerTest.m
//  AppKit
//
//  Created by H. Nikolaus Schaller on 28.03.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSTextContainerTest.h"

// see http://developer.apple.com/tools/unittest.html
// and http://www.cocoadev.com/index.pl?OCUnit

@interface MyLayoutManager : NSLayoutManager
@end

static id textContainerChangedGeometryArg;
static BOOL didCalltextContainerChangedGeometry;

@implementation MyLayoutManager

- (void)textContainerChangedGeometry:(NSTextContainer *)aTextContainer
{
	textContainerChangedGeometryArg=aTextContainer;
	didCalltextContainerChangedGeometry=YES;
}

@end

@implementation NSTextContainerTest

- (void) testTextContainer;
{
	NSTextContainer *c = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(20.0, 30.0)];
	NSRect lfr, propRect, remRect, r;
	NSLayoutManager *lm=[[MyLayoutManager alloc] init];
	[c setLayoutManager:lm];
	STAssertEqualObjects([c layoutManager], lm, nil);

	// line padding 0
	textContainerChangedGeometryArg=nil;
	didCalltextContainerChangedGeometry=NO;
	[c setLineFragmentPadding:0.0];
	STAssertTrue([c lineFragmentPadding] == 0.0, nil);
	STAssertTrue(didCalltextContainerChangedGeometry, nil);
	STAssertEqualObjects(textContainerChangedGeometryArg, c, nil);	
	
	propRect=NSMakeRect(0.0, 0.0, 40.0, 20.0);	// wider and less tall than full container
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	r=NSMakeRect(0.0, 0.0, 20.0, 20.0);
	STAssertTrue(NSEqualRects(lfr, r), @"%@ should be %@", NSStringFromRect(lfr), NSStringFromRect(r));
	r=NSMakeRect(0.0, 0.0, 0.0, 0.0);
	STAssertTrue(NSEqualRects(remRect, r), @"%@ should be %@", NSStringFromRect(remRect), NSStringFromRect(r));
	
	// same with smaller propRect
	propRect=NSMakeRect(0.0, 0.0, 10.0, 50.0);	// less wide and taller than full container
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	r=NSMakeRect(0.0, 0.0, 0.0, 0.0);
	STAssertTrue(NSEqualRects(lfr, r), @"%@ should be %@", NSStringFromRect(lfr), NSStringFromRect(r));
	r=NSMakeRect(0.0, 0.0, 0.0, 0.0);
	STAssertTrue(NSEqualRects(remRect, r), @"%@ should be %@", NSStringFromRect(remRect), NSStringFromRect(r));
	
	// same with propRect larger than container
	propRect=NSMakeRect(-10.0, -20.0, 80.0, 100.0);	// totally larger than container
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	r=NSMakeRect(0.0, 0.0, 0.0, 0.0);
	STAssertTrue(NSEqualRects(lfr, r), @"%@ should be %@", NSStringFromRect(lfr), NSStringFromRect(r));
	r=NSMakeRect(0.0, 0.0, 0.0, 0.0);
	STAssertTrue(NSEqualRects(remRect, r), @"%@ should be %@", NSStringFromRect(remRect), NSStringFromRect(r));
	
	// totally smaller than container
	propRect=NSMakeRect(5.0, 5.0, 10.0, 10.0);	// totally larger than container
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	r=NSMakeRect(5.0, 5.0, 10.0, 10.0);
	STAssertTrue(NSEqualRects(lfr, r), @"%@ should be %@", NSStringFromRect(lfr), NSStringFromRect(r));
	r=NSMakeRect(0.0, 0.0, 0.0, 0.0);
	STAssertTrue(NSEqualRects(remRect, r), @"%@ should be %@", NSStringFromRect(remRect), NSStringFromRect(r));
	
	// same as container
	propRect=NSMakeRect(0.0, 0.0, 80.0, 25.0);	// totally larger than container
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	r=NSMakeRect(0.0, 0.0, 20.0, 25.0);
	STAssertTrue(NSEqualRects(lfr, r), @"%@ should be %@", NSStringFromRect(lfr), NSStringFromRect(r));
	r=NSMakeRect(0.0, 0.0, 0.0, 0.0);
	STAssertTrue(NSEqualRects(remRect, r), @"%@ should be %@", NSStringFromRect(remRect), NSStringFromRect(r));

	// Result so far: propRect can be wider but not taller

	propRect=NSMakeRect(10.0, 0.0, 80.0, 25.0);
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	r=NSMakeRect(10.0, 0.0, 10.0, 25.0);
	STAssertTrue(NSEqualRects(lfr, r), @"%@ should be %@", NSStringFromRect(lfr), NSStringFromRect(r));
	r=NSMakeRect(0.0, 0.0, 0.0, 0.0);
	STAssertTrue(NSEqualRects(remRect, r), @"%@ should be %@", NSStringFromRect(remRect), NSStringFromRect(r));
		
	propRect=NSMakeRect(20.0, 0.0, 80.0, 25.0);
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	r=NSMakeRect(20.0, 0.0, 0.0, 25.0);
	STAssertTrue(NSEqualRects(lfr, r), @"%@ should be %@", NSStringFromRect(lfr), NSStringFromRect(r));
	r=NSMakeRect(0.0, 0.0, 0.0, 0.0);
	STAssertTrue(NSEqualRects(remRect, r), @"%@ should be %@", NSStringFromRect(remRect), NSStringFromRect(r));
	
	propRect=NSMakeRect(30.0, 0.0, 80.0, 25.0);
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	r=NSMakeRect(30.0, 0.0, 0.0, 25.0);
	STAssertTrue(NSEqualRects(lfr, r), @"%@ should be %@", NSStringFromRect(lfr), NSStringFromRect(r));
	r=NSMakeRect(0.0, 0.0, 0.0, 0.0);
	STAssertTrue(NSEqualRects(remRect, r), @"%@ should be %@", NSStringFromRect(remRect), NSStringFromRect(r));
	
	propRect=NSMakeRect(-30.0, 0.0, 80.0, 25.0);
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	r=NSMakeRect(0.0, 0.0, 20.0, 25.0);
	STAssertTrue(NSEqualRects(lfr, r), @"%@ should be %@", NSStringFromRect(lfr), NSStringFromRect(r));
	r=NSMakeRect(0.0, 0.0, 0.0, 0.0);
	STAssertTrue(NSEqualRects(remRect, r), @"%@ should be %@", NSStringFromRect(remRect), NSStringFromRect(r));
	
	// line padding != 0
	[c setLineFragmentPadding:5.0];
	STAssertTrue([c lineFragmentPadding] == 5.0, nil);

	propRect=NSMakeRect(0.0, 0.0, 40.0, 20.0);	// wider and less tall than full container
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	r=NSMakeRect(0.0, 0.0, 20.0, 20.0);
	STAssertTrue(NSEqualRects(lfr, r), @"%@ should be %@", NSStringFromRect(lfr), NSStringFromRect(r));
	r=NSMakeRect(0.0, 0.0, 0.0, 0.0);
	STAssertTrue(NSEqualRects(remRect, r), @"%@ should be %@", NSStringFromRect(remRect), NSStringFromRect(r));
		
	[c release];
}

@end
