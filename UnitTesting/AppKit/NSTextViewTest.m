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
	STAssertEquals([view minSize], NSMakeSize(300.0, 500.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), nil);
	STAssertFalse([view isHorizontallyResizable], nil);
	STAssertTrue([view isVerticallyResizable], nil);
	STAssertEqualObjects([view font], [NSFont userFontOfSize:12], nil);
	/* conclusions
	 * it is only verticallyResizable (i.e. autosizing)
	 * minSize is same as frame.size
	 * maxSize has same width but "infinite" height
	 * font is the userFontOfSize:12 (may be accidentially the same and depend on unknown system or user setttings)
	 */
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
	/* conclusions
	 * the container size has the same width as the frame, and hight is "infinite", i.e. is the same as maxSize
	 * the container is initialized to track the width of the TextView
	 */
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

- (void) test20
{ // sizeToFit
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), nil);
	[view sizeToFit];
	STAssertEquals([[view textStorage] length], 0u, nil);
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), nil);
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), nil);
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), nil);
	// try non-empty string with height
	[view replaceCharactersInRange:NSMakeRange(0, 0) withString:@"test"];
	[view sizeToFit];
	STAssertEquals([[view textStorage] length], 4u, nil);
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), nil);
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), nil);
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), nil);
	// reduce minSize
	[view setMinSize:NSMakeSize(200.0, 200.0)];
	[view setMaxSize:NSMakeSize(210.0, 1e+07)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), nil);
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), nil);
	STAssertEquals([view minSize], NSMakeSize(200.0, 200.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(210.0, 1e+07), nil);
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), nil);
	[view sizeToFit];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 200.0), nil);	// height has been reduced to new minSize.height - but width is not changed!
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 200.0), nil);
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), nil);
	// reduce minSize to 0.0 so that the first line should become influencing
	[view setMinSize:NSMakeSize(200.0, 0.0)];
	[view setMaxSize:NSMakeSize(210.0, 1e+07)];
	STAssertEquals([view minSize], NSMakeSize(200.0, 0.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(210.0, 1e+07), nil);
	[view sizeToFit];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 14.0), nil);
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 14.0), nil);
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), nil);
	/* conclusions
	 * at least with these initializations (!isHorizontallyResizable), the
	 * width is never changed by -sizeToFit even if it does not fit between minSize and maxSize
	 * and the height is controlled by minSize
	 */
	
	// more tests
	// bigger text
	// what happens if line is too wide for current container - is the container made wider (if isHorizontallyResizable)
	// is the container resized to the frame.width?
}

- (void) test21
{ // influence of setFrameSize
	STAssertFalse([view isHorizontallyResizable], nil);
	STAssertTrue([view isVerticallyResizable], nil);
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), nil);
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), nil);
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), nil);
	STAssertEquals([view minSize], NSMakeSize(300.0, 500.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), nil);
	// reduce below minSize
	[view setFrameSize:NSMakeSize(200.0, 400.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 400.0), nil);
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 400.0), nil);
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(200.0, 1e+07), nil);
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);	// width and height was reduced
	STAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), nil);	// initial value is not changed!
	// increase beyond maxSize.width
	[view setFrameSize:NSMakeSize(400.0, 700.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 400.0, 400.0), nil);	// height was not increased beyond maxSize!
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 400.0, 400.0), nil);
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(400.0, 1e+07), nil);
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);	// was not adjusted!
	STAssertEquals([view maxSize], NSMakeSize(400.0, 1e+07), nil);	// was increased
	/* conclusions
	 * setting the frameSize is always accepted
	 * modifies minSize or maxSize but only if necessary
	 * ???
	 */
}

- (void) test22
{ // influence of setFrameSize - if resizability is changed
	STAssertFalse([view isHorizontallyResizable], nil);	// set to true
	STAssertTrue([view isVerticallyResizable], nil);
	// change resizable settings
	[view setHorizontallyResizable:YES];
	[view setVerticallyResizable:YES];
	STAssertTrue([view isHorizontallyResizable], nil);
	STAssertTrue([view isVerticallyResizable], nil);
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), nil);
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), nil);
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), nil);
	STAssertEquals([view minSize], NSMakeSize(300.0, 500.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), nil);
	// reduce below minSize
	[view setFrameSize:NSMakeSize(200.0, 400.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 400.0), nil);
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 400.0), nil);
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(200.0, 1e+07), nil);
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);	// was adjusted!
	STAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), nil);	// initial value is not changed!
	// increase beyond maxSize
	[view setFrameSize:NSMakeSize(400.0, 700.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 400.0), nil);	// was not increased!
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 400.0), nil);	// was not changed again
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(200.0, 1e+07), nil);
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);	// was not adjusted!
	STAssertEquals([view maxSize], NSMakeSize(400.0, 1e+07), nil);	// was increased
	/* conclusions
	 * setting horizontallyResizable makes only a difference by keeping the frame/bounds/container width as it is
	 */
}

- (void) test23
{ // contradicting min/maxSize?
	STAssertFalse([view isHorizontallyResizable], nil);	// set to true
	STAssertTrue([view isVerticallyResizable], nil);
	STAssertEquals([view minSize], NSMakeSize(300.0, 500.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), nil);
	// make minSize bigger than maxSize
	[view setMinSize:NSMakeSize(600.0, 800.0)];
	STAssertEquals([view minSize], NSMakeSize(300.0, 800.0), nil);	// extra large minWidth is ignored
	STAssertEquals([view maxSize], NSMakeSize(600.0, 1e+07), nil);	// but taken for maxSize!
	// make maxSize smaller than minSize
	[view setMaxSize:NSMakeSize(200.0, 400.0)];
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);	// minSize is reduced to maxSize
	STAssertEquals([view maxSize], NSMakeSize(300.0, 400.0), nil);
	/* conclusions
	 * setMinSize and setMaxSize ensure that min <= max by reducing/increasing the other one
	 */
}

- (void) test99
{ // try setting some extreme values
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), nil);
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), nil);
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), nil);
	STAssertEquals([view minSize], NSMakeSize(300.0, 500.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), nil);
	// make minSize negative
	[view setMinSize:NSMakeSize(-600.0, -800.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 800.0), nil);	// frame.height = fabs(minSize.height)
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 800.0), nil);
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), nil);
	STAssertEquals([view minSize], NSMakeSize(-600.0, -800.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), nil);	// initial value is not changed!
	[view setFrameSize:NSMakeSize(-200.0, -400.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, -200.0, 800.0), nil);
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, -200.0, 800.0), nil);
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(-200.0, 1e+07), nil);
	STAssertEquals([view minSize], NSMakeSize(-600.0, -800.0), nil);	// was not changed
	STAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), nil);	// initial value is not changed!
	/* conclusions
	 * setting negative minSize is possible
	 * setting negative frame size is possible
	 * only the indirect setting of the framesize through setMinSize takes the abs(height)
	 */
}


@end
