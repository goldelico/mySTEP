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

	// default settings
	STAssertEquals([c lineFragmentPadding], 5.0f, nil);
	STAssertFalse([c heightTracksTextView], nil);
	STAssertFalse([c widthTracksTextView], nil);
	STAssertNil([c layoutManager], nil);
	STAssertNil([c textView], nil);
	STAssertEquals([c containerSize], NSMakeSize(20.0, 30.0), nil);
	
	[c setLayoutManager:lm];
	STAssertEqualObjects([c layoutManager], lm, nil);

	// set line padding 0
	textContainerChangedGeometryArg=nil;
	didCalltextContainerChangedGeometry=NO;
	[c setLineFragmentPadding:0.0];
	STAssertEquals([c lineFragmentPadding], 0.0f, nil);
	// check if it did call textContainerChangedGeometry
	STAssertTrue(didCalltextContainerChangedGeometry, nil);
	STAssertEqualObjects(textContainerChangedGeometryArg, c, nil);	
	
	// set container size
	textContainerChangedGeometryArg=nil;
	didCalltextContainerChangedGeometry=NO;
	[c setContainerSize:NSMakeSize(20.0, 30.0)];
	STAssertEquals([c containerSize], NSMakeSize(20.0, 30.0), nil);
	STAssertFalse(didCalltextContainerChangedGeometry, @"optimizes for unchanged container");
	[c setContainerSize:NSMakeSize(20.1, 30.0)];
	STAssertTrue(didCalltextContainerChangedGeometry, @"container size really changed");
	STAssertEqualObjects(textContainerChangedGeometryArg, c, nil);
	[c setContainerSize:NSMakeSize(20.0, 30.0)];	// restore

	propRect=NSMakeRect(0.0, 0.0, 40.0, 20.0);	// wider and less tall than full container
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	r=NSMakeRect(0.0, 0.0, 20.0, 20.0);
	STAssertEquals(lfr, r, nil);
	r=NSMakeRect(0.0, 0.0, 0.0, 0.0);
	STAssertEquals(remRect, r, nil);
	
	// same with smaller propRect
	propRect=NSMakeRect(0.0, 0.0, 10.0, 50.0);	// less wide and taller than full container
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	r=NSMakeRect(0.0, 0.0, 0.0, 0.0);
	STAssertEquals(lfr, r, nil);
	r=NSMakeRect(0.0, 0.0, 0.0, 0.0);
	STAssertEquals(remRect, r, nil);
	
	// same with propRect larger than container
	propRect=NSMakeRect(-10.0, -20.0, 80.0, 100.0);	// totally larger than container
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	r=NSMakeRect(0.0, 0.0, 0.0, 0.0);
	STAssertEquals(lfr, r, nil);
	r=NSMakeRect(0.0, 0.0, 0.0, 0.0);
	STAssertEquals(remRect, r, nil);
	
	// totally smaller than container
	propRect=NSMakeRect(5.0, 5.0, 10.0, 10.0);	// totally larger than container
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	r=NSMakeRect(5.0, 5.0, 10.0, 10.0);
	STAssertEquals(lfr, r, nil);
	r=NSMakeRect(0.0, 0.0, 0.0, 0.0);
	STAssertEquals(remRect, r, nil);
	
	// same as container
	propRect=NSMakeRect(0.0, 0.0, 80.0, 25.0);	// totally larger than container
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	r=NSMakeRect(0.0, 0.0, 20.0, 25.0);
	STAssertEquals(lfr, r, nil);
	r=NSMakeRect(0.0, 0.0, 0.0, 0.0);
	STAssertEquals(remRect, r, nil);

	// Result so far: propRect can be wider but not taller

	propRect=NSMakeRect(10.0, 0.0, 80.0, 25.0);
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	r=NSMakeRect(10.0, 0.0, 10.0, 25.0);
	STAssertEquals(lfr, r, nil);
	r=NSMakeRect(0.0, 0.0, 0.0, 0.0);
	STAssertEquals(remRect, r, nil);
		
	propRect=NSMakeRect(20.0, 0.0, 80.0, 25.0);
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	r=NSMakeRect(20.0, 0.0, 0.0, 25.0);
	STAssertEquals(lfr, r, nil);
	r=NSMakeRect(0.0, 0.0, 0.0, 0.0);
	STAssertEquals(remRect, r, nil);
	
	propRect=NSMakeRect(30.0, 0.0, 80.0, 25.0);
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	r=NSMakeRect(30.0, 0.0, 0.0, 25.0);
	STAssertEquals(lfr, r, nil);
	r=NSMakeRect(0.0, 0.0, 0.0, 0.0);
	STAssertEquals(remRect, r, nil);
	
	propRect=NSMakeRect(-30.0, 0.0, 80.0, 25.0);
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	r=NSMakeRect(0.0, 0.0, 20.0, 25.0);
	STAssertEquals(lfr, r, nil);
	r=NSMakeRect(0.0, 0.0, 0.0, 0.0);
	STAssertEquals(remRect, r, nil);
	
	// line padding != 0
	[c setLineFragmentPadding:5.0];
	STAssertEquals([c lineFragmentPadding], 5.0f, nil);

	propRect=NSMakeRect(0.0, 0.0, 40.0, 20.0);	// wider and less tall than full container
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	r=NSMakeRect(0.0, 0.0, 20.0, 20.0);
	STAssertEquals(lfr, r, nil);
	r=NSMakeRect(0.0, 0.0, 0.0, 0.0);
	STAssertEquals(remRect, r, nil);
		
	[c release];
}

@end
