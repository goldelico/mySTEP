//
//  NSTextViewTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 08.01.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "NSTextViewTest.h"


@implementation NSTextViewTest

 -(void) setUp
{
	view=[[NSTextView alloc] initWithFrame:NSMakeRect(100.0, 100.0, 300.0, 500.0)];
}

- (void) tearDown
{
	[view release];
}

- (void) test01
{ // NSView initialization
	STAssertNotNil(view, nil);
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), nil);
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), nil);
	STAssertNil([view superview], nil);
	STAssertNil([view window], nil);
	STAssertEquals([view selectedRange], NSMakeRange(0.0, 0.0), nil);	// empty selection
}

- (void) test02;
{ // container initialization
	STAssertNotNil([view textContainer], nil);
	STAssertEqualObjects([[view textContainer] textView], view, nil);
	STAssertEqualObjects([[view textContainer] layoutManager], [view layoutManager], nil);
	// text container has infinite height but given width
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), nil);
	STAssertTrue([[view textContainer] widthTracksTextView], nil);
	STAssertFalse([[view textContainer] heightTracksTextView], nil);
	STAssertTrue([[view textContainer] isSimpleRectangularTextContainer], nil);
	// should have a default margin
	STAssertEquals([[view textContainer] lineFragmentPadding], 5.0f, nil);
}

- (void) test03;
{ // storage initialization
	STAssertNotNil([view textStorage], nil);
}

- (void) test04;
{ // layout manager initialization
	STAssertNotNil([view layoutManager], nil);
	STAssertEqualObjects([[view layoutManager] textStorage], [view textStorage], nil);
	STAssertTrue([[[view textStorage] layoutManagers] containsObject:[view layoutManager]], nil);
	STAssertTrue([[[view layoutManager] textContainers] containsObject:[view textContainer]], nil);
}

- (void) test10;
{ // how insertion/replacement modifies selection
}

@end
