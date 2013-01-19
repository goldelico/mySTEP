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
	STAssertEquals([view minSize], NSMakeSize(300.0, 500.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), nil);
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
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 400.0), nil);	// width and height are reduced
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 400.0), nil);
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(200.0, 1e+07), nil);	// container was resized
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);	// width and height are reduced
	STAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), nil);	// initial value is not changed!
	// increase beyond maxSize.width
	[view setFrameSize:NSMakeSize(400.0, 700.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 400.0, 400.0), nil);	// height was *not* increased, but width!
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 400.0, 400.0), nil);
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(400.0, 1e+07), nil);	// container was resized
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);	// was not adjusted
	STAssertEquals([view maxSize], NSMakeSize(400.0, 1e+07), nil);	// width was increased
	// try again
	[view setFrameSize:NSMakeSize(400.0, 700.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 400.0, 700.0), nil);	// height was increased this time!?!
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 400.0, 700.0), nil);
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(400.0, 1e+07), nil);
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);	// was not adjusted
	STAssertEquals([view maxSize], NSMakeSize(400.0, 1e+07), nil);	// width was increased
	// increase beyond maxSize.width
	[view setFrameSize:NSMakeSize(500.0, 700.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 500.0, 400.0), nil);	// height was reset to minSize!?!
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 500.0, 400.0), nil);
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(500.0, 1e+07), nil);	// container was resized
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);	// was not adjusted
	STAssertEquals([view maxSize], NSMakeSize(500.0, 1e+07), nil);	// width was increased
	// decrease a little
	[view setFrameSize:NSMakeSize(490.0, 690.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 490.0, 400.0), nil);	// height was still reset to minSize!?!
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 490.0, 400.0), nil);
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(490.0, 1e+07), nil);	// container was resized
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);	// was not adjusted
	STAssertEquals([view maxSize], NSMakeSize(500.0, 1e+07), nil);	// width was increased
	// try again
	[view setFrameSize:NSMakeSize(490.0, 690.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 490.0, 690.0), nil);	// height was increased this time!?!
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 490.0, 690.0), nil);
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(490.0, 1e+07), nil);
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);	// was not adjusted
	STAssertEquals([view maxSize], NSMakeSize(500.0, 1e+07), nil);	// width was increased
	// try to set to minSize.width
	[view setFrameSize:NSMakeSize(200.0, 690.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 400.0), nil);	// height is reset to minSize
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 400.0), nil);
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(200.0, 1e+07), nil);
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);	// was not adjusted
	STAssertEquals([view maxSize], NSMakeSize(500.0, 1e+07), nil);	// width was increased
	// try again
	[view setFrameSize:NSMakeSize(200.0, 690.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 690.0), nil);	// height is now set
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 690.0), nil);
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(200.0, 1e+07), nil);
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);	// was not adjusted
	STAssertEquals([view maxSize], NSMakeSize(500.0, 1e+07), nil);	// width was increased
	/* conclusions
	 * setting the frameSize is always accepted
	 * container is resized accordingly
	 * modifies minSize or maxSize but only if necessary
	 * unexpected: if width is changed, the height is reset to (new) minSize.height!
	 */
}

- (void) test21c
{ // influence of setConstrainedFrameSize
	STAssertFalse([view isHorizontallyResizable], nil);
	STAssertTrue([view isVerticallyResizable], nil);
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), nil);
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), nil);
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), nil);
	STAssertEquals([view minSize], NSMakeSize(300.0, 500.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), nil);
	// reduce below minSize
	[view setConstrainedFrameSize:NSMakeSize(200.0, 400.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), nil);	// limited
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), nil);
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), nil);
	STAssertEquals([view minSize], NSMakeSize(300.0, 500.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), nil);	// initial value is not changed!
	// increase beyond maxSize.width
	[view setConstrainedFrameSize:NSMakeSize(400.0, 700.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 700.0), nil);	// height was adjusted, but not width
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 700.0), nil);
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), nil);	// container was resized
	STAssertEquals([view minSize], NSMakeSize(300.0, 500.0), nil);	// was not adjusted!
	STAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), nil);	// width was increased
	/* conclusions
	 * it appears as if isVerticallyResizable/isHorizontallyResizable is applied first
	 * and then the min/max
	 */
}

- (void) test22
{ // influence of resizability on setFrameSize
	STAssertFalse([view isHorizontallyResizable], nil);	// set to true
	STAssertTrue([view isVerticallyResizable], nil);
	// change resizable settings by enabling both
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
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 400.0), nil);	// was not increased but width and height are reset to _minSize!
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 400.0), nil);	// was not changed again
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(200.0, 1e+07), nil);
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);	// was not adjusted!
	STAssertEquals([view maxSize], NSMakeSize(400.0, 1e+07), nil);	// was increased
	/* conclusions
	 * setting horizontallyResizable makes only a difference by keeping the frame/bounds/container width as it is
	 */
}

- (void) test23
{ // contradicting min/maxSize
	STAssertFalse([view isHorizontallyResizable], nil);	// set to true
	STAssertTrue([view isVerticallyResizable], nil);
	STAssertEquals([view minSize], NSMakeSize(300.0, 500.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), nil);
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), nil);
	// a) make minSize bigger than maxSize
	[view setMinSize:NSMakeSize(600.0, 900.0)];
	STAssertEquals([view minSize], NSMakeSize(300.0, 900.0), nil);	// extra large minWidth is ignored
	STAssertEquals([view maxSize], NSMakeSize(600.0, 1e+07), nil);	// but taken for maxSize!
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 900.0), nil);	// oops - also increases frameSize!
	// b) make maxSize smaller than minSize
	[view setMaxSize:NSMakeSize(200.0, 400.0)];
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);	// minSize is reduced to given maxSize which is not touched
	STAssertEquals([view maxSize], NSMakeSize(300.0, 400.0), nil);	// maxSize is also reduced - but to the old minSize.width?
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), nil);	// oops - also decreases frameSize!
	// c) and minSize again bigger than maxSize
	[view setMinSize:NSMakeSize(600.0, 900.0)];
	STAssertEquals([view minSize], NSMakeSize(300.0, 900.0), nil);	// extra large minWidth is ignored
	STAssertEquals([view maxSize], NSMakeSize(600.0, 900.0), nil);	// now both are the same height
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 900.0), nil);	// oops - also increases frameSize!
	// d) and again
	[view setMinSize:NSMakeSize(600.0, 900.0)];
	STAssertEquals([view minSize], NSMakeSize(600.0, 900.0), nil);	// now, minsize is accepted
	STAssertEquals([view maxSize], NSMakeSize(600.0, 900.0), nil);	// both are still the same
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 900.0), nil);	// this time does not change frameSize
	// e) now make smaller
	[view setMinSize:NSMakeSize(400.0, 700.0)];
	STAssertEquals([view minSize], NSMakeSize(400.0, 700.0), nil);	// this works now
	STAssertEquals([view maxSize], NSMakeSize(600.0, 900.0), nil);
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 900.0), nil);	// this time does not change frameSize
	// f) now make same
	[view setMinSize:NSMakeSize(600.0, 900.0)];
	STAssertEquals([view minSize], NSMakeSize(600.0, 900.0), nil);	// this works now
	STAssertEquals([view maxSize], NSMakeSize(600.0, 900.0), nil);
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 900.0), nil);	// this time does not change frameSize
	// g) make maxSize partially smaller than minSize
	[view setMaxSize:NSMakeSize(600.0, 350.0)];
	STAssertEquals([view minSize], NSMakeSize(300.0, 350.0), nil);	// minSize is reduced to given frameSize or where does the 300.0 come from`
	STAssertEquals([view maxSize], NSMakeSize(600.0, 350.0), nil);	// maxSize is also reduced - but to the old minSize.width?
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 350.0), nil);	// oops - also reduces frameSize!
	// h) set frame size
	[view setFrameSize:NSMakeSize(320.0, 700.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 320.0, 350.0), nil);	// was not increased but width and height is reset to _minSize!
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 320.0, 350.0), nil);	// was not changed again
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(320.0, 1e+07), nil);
	STAssertEquals([view minSize], NSMakeSize(300.0, 350.0), nil);	// minSize.width is unchanged
	STAssertEquals([view maxSize], NSMakeSize(600.0, 350.0), nil);	// was not changed
	// i) make maxSize partially smaller than minSize
	[view setMaxSize:NSMakeSize(250.0, 275.0)];
	STAssertEquals([view minSize], NSMakeSize(250.0, 275.0), nil);	// minSize is reduced
	STAssertEquals([view maxSize], NSMakeSize(320.0, 275.0), nil);	// maxSize.height is reduced
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 320.0, 275.0), nil);	// reduced as well !?!
	/* conclusions
	 * quite complicated rules if minSize and current maxSize contradict each other
	 * and contradict frameSize which may also be adjusted
	 *
	 * a) if newMin > currentMax adjust currentMax, otherwise set as currentMin
	 *     separately for width&height
	 * b) if newMax < currentMin adjust currentMin, otherwise set as currentMax
	 *    if newMax < currentMax, adjust currentMax
	 *     separately for width&height
	 * c) same as a)
	 * d, e) as expected
	 * f) shows that a) is really newMin > currentMax and not newMin >= currentMax
	 */
}

- (void) test23v
{ // contradicting min/maxSize - does it depend on *allyResizable?
	STAssertFalse([view isHorizontallyResizable], nil);	// set to true
	STAssertTrue([view isVerticallyResizable], nil);
	STAssertEquals([view minSize], NSMakeSize(300.0, 500.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), nil);
	// change resizability
	[view setHorizontallyResizable:YES];
	[view setVerticallyResizable:NO];
	STAssertTrue([view isHorizontallyResizable], nil);	// set to true
	STAssertFalse([view isVerticallyResizable], nil);	// set to false
	// a) make minSize bigger than maxSize
	[view setMinSize:NSMakeSize(600.0, 900.0)];
	STAssertEquals([view minSize], NSMakeSize(600.0, 500.0), nil);	// extra large minHeight is ignored
	STAssertEquals([view maxSize], NSMakeSize(600.0, 1e+07), nil);	// maxSize is increased
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 600.0, 500.0), nil);	// oops - also increases frameSize!
	// b) make maxSize smaller than minSize
	[view setMaxSize:NSMakeSize(200.0, 400.0)];
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);	// minSize is reduced to given maxSize which is not touched
	STAssertEquals([view maxSize], NSMakeSize(200.0, 500.0), nil);
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 500.0), nil);	// oops - also decreases frameSize!
	/* conclusions
	 * resizability has an influence!
	 */
}

- (void) test24
{ // interaction of setFrameSize, setMinSize, setMaxSize
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), nil);
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), nil);
	STAssertEquals([view minSize], NSMakeSize(300.0, 500.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), nil);
	// reduce minSize.height and then increase until it reaches frame size and beyond
	[view setMinSize:NSMakeSize(300.0, 200)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), nil);	// frame stays stable
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), nil);
	STAssertEquals([view minSize], NSMakeSize(300.0, 200.0), nil);	// has been reduced
	STAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), nil);	// unchanged
	// increase minSize.height
	[view setMinSize:NSMakeSize(300.0, 300)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), nil);	// unchanged
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), nil);
	STAssertEquals([view minSize], NSMakeSize(300.0, 300.0), nil);	// changed
	STAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), nil);
	// increase minSize.height
	[view setMinSize:NSMakeSize(300.0, 500)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), nil);	// unchanged
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), nil);	// unchanged
	STAssertEquals([view minSize], NSMakeSize(300.0, 500.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), nil);	// unchanged
	// increase minSize.height
	[view setMinSize:NSMakeSize(300.0, 800)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 800.0), nil);	// frame growing larger
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 800.0), nil);
	STAssertEquals([view minSize], NSMakeSize(300.0, 800.0), nil);	// changed
	STAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), nil);	// unchanged
	/* conclusions
	 * increasing _minSize beyond maxSize/frameSize increases them as well
	 */
}

- (void) test25
{ // interaction of setFrameSize, setMinSize, setMaxSize
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), nil);
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), nil);
	STAssertEquals([view minSize], NSMakeSize(300.0, 500.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), nil);
	// change maxSize to be smaller than frameSize 
	[view setMaxSize:NSMakeSize(200.0, 400.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), nil);	// frame gets smaller
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), nil);
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);	// minSize is also modified
	STAssertEquals([view maxSize], NSMakeSize(300.0, 400.0), nil);	// maxSize is modified - but not both components
	// reduce minSize.height and then increase until it reaches frame size and goes beyond
	[view setMinSize:NSMakeSize(150.0, 250.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), nil);	// frame stays stable
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), nil);
	STAssertEquals([view minSize], NSMakeSize(150.0, 250.0), nil);	// has been reduced
	STAssertEquals([view maxSize], NSMakeSize(300.0, 400.0), nil);	// unchanged
	// increase minSize.height
	[view setMinSize:NSMakeSize(150.0, 300)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), nil);	// unchanged
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), nil);
	STAssertEquals([view minSize], NSMakeSize(150.0, 300.0), nil);	// changed
	STAssertEquals([view maxSize], NSMakeSize(300.0, 400), nil);
	// increase minSize.height
	[view setMinSize:NSMakeSize(150.0, 500)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), nil);	// increased
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), nil);	// increased
	STAssertEquals([view minSize], NSMakeSize(150.0, 500.0), nil);	// changed
	STAssertEquals([view maxSize], NSMakeSize(300.0, 500.0), nil);	// also increased
	// reduce minSize.height and then until it reaches frame size and beyond
	[view setMinSize:NSMakeSize(150.0, 800)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 800.0), nil);	// frame growing larger
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 800.0), nil);
	STAssertEquals([view minSize], NSMakeSize(150.0, 800.0), nil);	// changed
	STAssertEquals([view maxSize], NSMakeSize(300.0, 800.0), nil);	// changed
	/* conclusions
	 * is verticallyResizable:
	 * setMinSize:
	 * maxSize.height is enforced to be >= minSize.height
	 * frameSize.height is enforced to be >= minSize.height
	 * maxSize.width is never changed
	 */
}

- (void) test26
{ // interaction of setFrameSize, setMinSize, setMaxSize
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), nil);
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), nil);
	STAssertEquals([view minSize], NSMakeSize(300.0, 500.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), nil);
	// change maxSize to be smaller than frameSize
	[view setMaxSize:NSMakeSize(200.0, 400.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), nil);	// frame gets smaller
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), nil);
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);	// minSize is also modified
	STAssertEquals([view maxSize], NSMakeSize(300.0, 400.0), nil);	// maxSize is modified - but not both components
	// reduce minSize.width and then increase until it reaches frame size and goes beyond
	[view setMinSize:NSMakeSize(150.0, 250.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), nil);	// frame stays stable
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), nil);
	STAssertEquals([view minSize], NSMakeSize(150.0, 250.0), nil);	// has been reduced
	STAssertEquals([view maxSize], NSMakeSize(300.0, 400.0), nil);	// unchanged
	// increase minSize.width
	[view setMinSize:NSMakeSize(200.0, 250.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), nil);	// unchanged
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), nil);
	STAssertEquals([view minSize], NSMakeSize(200.0, 250.0), nil);	// changed
	STAssertEquals([view maxSize], NSMakeSize(300.0, 400), nil);
	// increase minSize.width
	[view setMinSize:NSMakeSize(300.0, 250.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), nil);	// unchanged
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), nil);
	STAssertEquals([view minSize], NSMakeSize(300.0, 250.0), nil);	// changed
	STAssertEquals([view maxSize], NSMakeSize(300.0, 400.0), nil);	// also increased
	// increase minSize.width
	[view setMinSize:NSMakeSize(400.0, 250.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), nil);	// unchanged
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), nil);
	STAssertEquals([view minSize], NSMakeSize(400.0, 250.0), nil);	// changed
	STAssertEquals([view maxSize], NSMakeSize(400.0, 400.0), nil);	// changed
	[view setMinSize:NSMakeSize(500.0, 250.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), nil);	// unchanged
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), nil);
	STAssertEquals([view minSize], NSMakeSize(500.0, 250.0), nil);	// changed
	STAssertEquals([view maxSize], NSMakeSize(500.0, 400.0), nil);	// changed
	/* conclusions
	 * is !horizontallyResizable:
	 * setMinSize:
	 * maxSize.width is enforced to be >= minSize.width
	 * maxSize.width is enforced to be >= frameSize.width
	 * frameSize.width is not enforced
	 */
}

- (void) test27
{ // interaction of setFrameSize, setMinSize, setMaxSize
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), nil);
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), nil);
	STAssertEquals([view minSize], NSMakeSize(300.0, 500.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), nil);
	// change maxSize to be smaller than minSize 
	[view setMaxSize:NSMakeSize(200.0, 400.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), nil);	// frame gets smaller
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), nil);
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);	// minSize is also modified
	STAssertEquals([view maxSize], NSMakeSize(300.0, 400.0), nil);	// maxSize is modified - but not both components
	// increase maxSize.height and then increase until it reaches frame size and goes beyond
	[view setMaxSize:NSMakeSize(200.0, 500.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), nil);	// frame stays stable now
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), nil);
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(200.0, 500.0), nil);	// changed
	// increase minSize.height
	[view setMaxSize:NSMakeSize(200.0, 800)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), nil);	// unchanged
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), nil);
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(200.0, 800.0), nil);
	// decrease minSize.height a little
	[view setMaxSize:NSMakeSize(200.0, 750)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), nil);	// unchanged
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), nil);
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(200.0, 750.0), nil);
	// now increase minSize.width a little
	[view setMaxSize:NSMakeSize(250.0, 750)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), nil);	// unchanged
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), nil);
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(250.0, 750.0), nil);
	// now increase minSize.width a little
	[view setMaxSize:NSMakeSize(300.0, 750)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), nil);	// unchanged
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), nil);
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(300.0, 750.0), nil);
	// now increase minSize.width a little
	[view setMaxSize:NSMakeSize(400.0, 750)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), nil);	// unchanged
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), nil);
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(400.0, 750.0), nil);
	/* conclusions
	 * reducing maxSize.height reduces the frame.height as well
	 * increasing maxSize.height does not increase frame.height
	 * reducing maxSize may also reduce minSize.height
	 *
	 * rule appears to be (for isVerticallyResizable)
	 * minSize.height is enforced to be <= maxSize.height
	 * frameSize.height is enforced to be <= maxSize.height
	 *
	 * i.e. the latter depends on is*allyResizable
	 */
}

- (void) test28
{ // interaction of setFrameSize, setMinSize, setMaxSize
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), nil);
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), nil);
	STAssertEquals([view minSize], NSMakeSize(300.0, 500.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), nil);
	// limit maxSize
	[view setMaxSize:NSMakeSize(300.0, 700.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), nil);	// frame is unchanged
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), nil);
	STAssertEquals([view minSize], NSMakeSize(300.0, 500.0), nil);	// unchanged
	STAssertEquals([view maxSize], NSMakeSize(300.0, 700.0), nil);	// maxSize has been set
	// change frameSize to be smaller than minSize (and maxSize)
	[view setFrameSize:NSMakeSize(200.0, 400.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 400.0), nil);	// frame gets smaller
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 400.0), nil);
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);	// minSize is reduced to given frameSize!
	STAssertEquals([view maxSize], NSMakeSize(300.0, 700.0), nil);	// maxSize is untouched
	// increase frameSize.height and then increase until it reaches frame size and goes beyond
	[view setFrameSize:NSMakeSize(200.0, 500.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 500.0), nil);	// frame grows
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 500.0), nil);
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);	// no further change
	STAssertEquals([view maxSize], NSMakeSize(300.0, 700.0), nil);	// no further change
	// increase frameSize.height
	[view setFrameSize:NSMakeSize(200.0, 800)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 800.0), nil);	// frame grows
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 800.0), nil);
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(300.0, 800.0), nil);	// maxSize enlarged to given frameSize!
	// decrease frameSize.height a little
	[view setFrameSize:NSMakeSize(200.0, 750.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 750.0), nil);	// reduced
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 750.0), nil);
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);	// unchanged
	STAssertEquals([view maxSize], NSMakeSize(300.0, 800.0), nil);	// unchanged
	// now increase frameSize.width a little
	[view setFrameSize:NSMakeSize(250.0, 750.0)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 250.0, 400.0), nil);	// modifies width AND resets height to minSize.height!
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 250.0, 400.0), nil);
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);	// unchanged!
	STAssertEquals([view maxSize], NSMakeSize(300.0, 800.0), nil);	// unchanged!
	// now increase frameSize.width a little
	[view setFrameSize:NSMakeSize(300.0, 750)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), nil);	// does not set height!
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), nil);
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(300.0, 800.0), nil);
	// now increase frameSize.width a little
	[view setFrameSize:NSMakeSize(400.0, 750)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 400.0, 400.0), nil);	// does not set height!
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 400.0, 400.0), nil);
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(400.0, 800.0), nil);
	// now set the same frameSize.width again
	[view setFrameSize:NSMakeSize(400.0, 750)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 400.0, 750.0), nil);	// now it does set height!
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 400.0, 750.0), nil);
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(400.0, 800.0), nil);
	// now decrease frameSize.width again
	[view setFrameSize:NSMakeSize(350.0, 750)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 350.0, 400.0), nil);	// now it resets the height again!
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 350.0, 400.0), nil);
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(400.0, 800.0), nil);
	// now decrease frameSize.width again
	[view setFrameSize:NSMakeSize(350.0, 750)];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 350.0, 750.0), nil);	// now it sets the height again!
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 350.0, 750.0), nil);
	STAssertEquals([view minSize], NSMakeSize(200.0, 400.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(400.0, 800.0), nil);
	/* conclusions
	 * reduces minSize if needed
	 * extends maxSize if needed
	 * if and only if frame.width is changed, the height is taken from minSize.height instead of newSize.height
	 * this special rule may only apply if !_tx.isHorizontallyResizable
	 * because that effect could not be seen by increasing frame.height
	 */
}

- (void) test40c
{ // interaction of setFrameSize, setMinSize, setMaxSize with an enclosing NSClipView
	// see how it should work: https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/TextUILayer/Tasks/TextInScrollView.html
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), nil);
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), nil);
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), nil);
	STAssertEquals([view minSize], NSMakeSize(300.0, 500.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), nil);
	NSClipView *cv=[[[NSClipView alloc] initWithFrame:NSMakeRect(10.0, 20.0, 400.0, 700.0)] autorelease];
	// now add the NSTextView to the NSClipView
	[cv setDocumentView:view];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 700.0), nil);	// height is adjusted, because it is resizable, width isn't important
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 700.0), nil);
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), nil);
	STAssertEquals([view minSize], NSMakeSize(300.0, 700.0), nil);	// height taken from clip view, width isn't important as long as it is less than frame width
	STAssertEquals([view maxSize], NSMakeSize(400.0, 1e+07), nil);	// width is copied from clip view
	/* conclusions
	 * setting the NSTextView as the documentView
	 * makes it resize and set minSize/maxSize
	 * so that the NSTextView is at least as large as the ClipView
	 * i.e. the full visible content is covered by the NSTextView
	 */
}

- (void) test40v
{ // is this special behaviour of the NSClipView or setDocumentView?
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), nil);
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), nil);
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), nil);
	STAssertEquals([view minSize], NSMakeSize(300.0, 500.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), nil);
	NSView *v=[[[NSView alloc] initWithFrame:NSMakeRect(10.0, 20.0, 400.0, 700.0)] autorelease];
	// now add the NSTextView to the NSView
	[v addSubview:view];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), nil);	// not changed
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), nil);
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), nil);
	STAssertEquals([view minSize], NSMakeSize(300.0, 500.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), nil);
	// remove again
	[view removeFromSuperview];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), nil);	// not changed
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), nil);
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), nil);
	STAssertEquals([view minSize], NSMakeSize(300.0, 500.0), nil);
	STAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), nil);
	// now simply add to NSCLipView
	NSClipView *cv=[[[NSClipView alloc] initWithFrame:NSMakeRect(10.0, 20.0, 400.0, 700.0)] autorelease];
	[cv addSubview:view];
	STAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 700.0), nil);	// height is adjusted, because it is resizable, width isn't important
	STAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 700.0), nil);
	STAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), nil);
	STAssertEquals([view minSize], NSMakeSize(300.0, 700.0), nil);	// height taken from clip view, width isn't important as long as it is less than frame width
	STAssertEquals([view maxSize], NSMakeSize(400.0, 1e+07), nil);	// width is copied from clip view
	/* conclusions
	 * adding the NSTextView to a NSClipView makes it inherit its frame which also sets the minSize/maxSize
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

/*
 * more tests:
 *
 * influence of setFont: and setRichText:NO
 */

@end
