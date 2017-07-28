//
//  NSTextContainerTest.m
//  AppKit
//
//  Created by H. Nikolaus Schaller on 28.03.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

// contrary to STAssertEquals(), XCTAssertEqual() can only handle scalar objects
// https://stackoverflow.com/questions/19178109/xctassertequal-error-3-is-not-equal-to-3
// http://www.openradar.me/16281876

#define XCTAssertEquals(a, b, ...) ({ \
	typeof(a) _a=a; typeof(b) _b=b; \
	XCTAssertEqualObjects( \
		[NSValue value:&_a withObjCType:@encode(typeof(a))], \
		[NSValue value:&_b withObjCType:@encode(typeof(b))], \
		##__VA_ARGS__); })


@interface NSTextContainerTest : XCTestCase {
	
}

@end

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

- (void) test01;
{
	NSTextContainer *c = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(20.0, 30.0)];
	NSRect lfr, propRect, remRect;
	NSLayoutManager *lm=[[MyLayoutManager alloc] init];

	// default settings
	XCTAssertEquals([c lineFragmentPadding], 5.0f, @"");
	XCTAssertFalse([c heightTracksTextView], @"");
	XCTAssertFalse([c widthTracksTextView], @"");
	XCTAssertNil([c layoutManager], @"");
	XCTAssertNil([c textView], @"");
	XCTAssertEquals([c containerSize], NSMakeSize(20.0, 30.0), @"");
	
	[c setLayoutManager:lm];
	XCTAssertEqualObjects([c layoutManager], lm, @"");

	// set line padding 0
	textContainerChangedGeometryArg=nil;
	didCalltextContainerChangedGeometry=NO;
	[c setLineFragmentPadding:0.0];
	XCTAssertEquals([c lineFragmentPadding], 0.0f, @"");
	// check if it did call textContainerChangedGeometry
	XCTAssertTrue(didCalltextContainerChangedGeometry, @"");
	XCTAssertEqualObjects(textContainerChangedGeometryArg, c, @"");	
	
	// set container size
	textContainerChangedGeometryArg=nil;
	didCalltextContainerChangedGeometry=NO;
	[c setContainerSize:NSMakeSize(20.0, 30.0)];
	XCTAssertEquals([c containerSize], NSMakeSize(20.0, 30.0), @"");
	XCTAssertFalse(didCalltextContainerChangedGeometry, @"optimizes for unchanged container");
	[c setContainerSize:NSMakeSize(20.1, 30.0)];
	XCTAssertTrue(didCalltextContainerChangedGeometry, @"container size really changed");
	XCTAssertEqualObjects(textContainerChangedGeometryArg, c, @"");
	[c setContainerSize:NSMakeSize(20.0, 30.0)];	// restore

	// wider but less tall than full container
	propRect=NSMakeRect(0.0, 0.0, 40.0, 20.0);
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	XCTAssertEquals(lfr, NSMakeRect(0.0, 0.0, 20.0, 20.0), @"");
	XCTAssertEquals(remRect, NSMakeRect(0.0, 0.0, 0.0, 0.0), @"");
	
	// opposite sweep
	propRect=NSMakeRect(0.0, 0.0, 40.0, 20.0);
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepLeft movementDirection:NSLineMovesDown remainingRect:&remRect];
	XCTAssertEquals(lfr, NSMakeRect(0.0, 0.0, 20.0, 20.0), @"");
	XCTAssertEquals(remRect, NSMakeRect(0.0, 0.0, 0.0, 0.0), @"");

	// same with smaller propRect
	propRect=NSMakeRect(0.0, 0.0, 10.0, 50.0);
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	XCTAssertEquals(lfr, NSMakeRect(0.0, 0.0, 0.0, 0.0), @"");
	XCTAssertEquals(remRect, NSMakeRect(0.0, 0.0, 0.0, 0.0), @"");
	
	// same request larger than container
	propRect=NSMakeRect(-10.0, -20.0, 80.0, 100.0);
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	XCTAssertEquals(lfr, NSMakeRect(0.0, 0.0, 0.0, 0.0), @"");
	XCTAssertEquals(remRect, NSMakeRect(0.0, 0.0, 0.0, 0.0), @"");
	
	// fully fits into container
	propRect=NSMakeRect(5.0, 5.0, 10.0, 10.0);
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	XCTAssertEquals(lfr, NSMakeRect(5.0, 5.0, 10.0, 10.0), @"");
	XCTAssertEquals(remRect, NSMakeRect(0.0, 0.0, 0.0, 0.0), @"");
	
	// same as container
	propRect=NSMakeRect(0.0, 0.0, 80.0, 25.0);
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	XCTAssertEquals(lfr, NSMakeRect(0.0, 0.0, 20.0, 25.0), @"");
	XCTAssertEquals(remRect, NSMakeRect(0.0, 0.0, 0.0, 0.0), @"");

	// request wider than container
	propRect=NSMakeRect(10.0, 0.0, 80.0, 25.0);
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	XCTAssertEquals(lfr, NSMakeRect(10.0, 0.0, 10.0, 25.0), @"");
	XCTAssertEquals(remRect, NSMakeRect(0.0, 0.0, 0.0, 0.0), @"");
	
	// starting at right end of container
	propRect=NSMakeRect(20.0, 0.0, 80.0, 25.0);
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	XCTAssertEquals(lfr, NSMakeRect(20.0, 0.0, 0.0, 25.0), @"");
	XCTAssertEquals(remRect, NSMakeRect(0.0, 0.0, 0.0, 0.0), @"");
	
	// starting beyond container width
	propRect=NSMakeRect(30.0, 0.0, 80.0, 25.0);
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	XCTAssertEquals(lfr, NSMakeRect(30.0, 0.0, 0.0, 25.0), @"");	// width is clamped not to be negative
	XCTAssertEquals(remRect, NSMakeRect(0.0, 0.0, 0.0, 0.0), @"");

	// starting before container
	propRect=NSMakeRect(-30.0, 0.0, 80.0, 25.0);
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	XCTAssertEquals(lfr, NSMakeRect(0.0, 0.0, 20.0, 25.0), @"");
	XCTAssertEquals(remRect, NSMakeRect(0.0, 0.0, 0.0, 0.0), @"");

	// starting before container but ending within
	propRect=NSMakeRect(-30.0, 0.0, 35.0, 25.0);
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	XCTAssertEquals(lfr, NSMakeRect(0.0, 0.0, 5.0, 25.0), @"");
	XCTAssertEquals(remRect, NSMakeRect(0.0, 0.0, 0.0, 0.0), @"");
	
	// working with negative width
	propRect=NSMakeRect(30.0, 0.0, -35.0, 25.0);
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	XCTAssertEquals(lfr, NSMakeRect(30.0, 0.0, 0.0, 25.0), @"");
	XCTAssertEquals(remRect, NSMakeRect(0.0, 0.0, 0.0, 0.0), @"");

	// working with negative height
	propRect=NSMakeRect(30.0, 30.0, -35.0, -25.0);
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	XCTAssertEquals(lfr, NSMakeRect(30.0, 30.0, 0.0, -25.0), @"");
	XCTAssertEquals(remRect, NSMakeRect(0.0, 0.0, 0.0, 0.0), @"");
	
	// line padding != 0
	[c setLineFragmentPadding:5.0];
	XCTAssertEquals([c lineFragmentPadding], 5.0f, @"");

	propRect=NSMakeRect(0.0, 0.0, 40.0, 20.0);	// wider and less tall than full container
	lfr=[c lineFragmentRectForProposedRect:propRect sweepDirection:NSLineSweepRight movementDirection:NSLineMovesDown remainingRect:&remRect];
	XCTAssertEquals(lfr, NSMakeRect(0.0, 0.0, 20.0, 20.0), @"");
	XCTAssertEquals(remRect, NSMakeRect(0.0, 0.0, 0.0, 0.0), @"");
		
	[c release];
}

- (void) test99
{ // test extreme values
	NSTextContainer *c = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(20.0, 30.0)];
	[c setContainerSize:NSMakeSize(-20.0, -30.0)];
	XCTAssertEquals([c containerSize], NSMakeSize(-20.0, -30.0), @"");
	
}

// more tests:
// better cover the influence of the NSLineSweepDirection

@end
