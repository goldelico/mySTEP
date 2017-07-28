//
//  NSTextViewTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 08.01.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
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


@interface NSTextViewTest : XCTestCase {
	NSTextView *view;
}

@end


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
	XCTAssertNotNil(view, @"");
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), @"");
	XCTAssertNil([view superview], @"");
	XCTAssertNil([view window], @"");
	XCTAssertEquals([view selectedRange], NSMakeRange(0.0, 0.0), @"");	// empty selection
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 500.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), @"");
	XCTAssertFalse([view isHorizontallyResizable], @"");
	XCTAssertTrue([view isVerticallyResizable], @"");
	XCTAssertEqualObjects([view font], [NSFont userFontOfSize:12], @"");
	/* conclusions
	 * it is only verticallyResizable (i.e. autosizing)
	 * minSize is same as frame.size
	 * maxSize has same width but "infinite" height
	 * font is the userFontOfSize:12 (may be accidentially the same and depend on unknown system or user setttings)
	 */
}

- (void) test02;
{ // container initialization
	XCTAssertNotNil([view textContainer], @"");
	XCTAssertEqualObjects([[view textContainer] textView], view, @"");
	XCTAssertEqualObjects([[view textContainer] layoutManager], [view layoutManager], @"");
	// text container has infinite height but given width
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), @"");
	XCTAssertTrue([[view textContainer] widthTracksTextView], @"");
	XCTAssertFalse([[view textContainer] heightTracksTextView], @"");
	XCTAssertTrue([[view textContainer] isSimpleRectangularTextContainer], @"");
	// should have a default margin
	XCTAssertEqual([[view textContainer] lineFragmentPadding], 5.0f, @"");
	/* conclusions
	 * the container size has the same width as the frame, and hight is "infinite", i.e. is the same as maxSize
	 * the container is initialized to track the width of the TextView
	 */
}

- (void) test03;
{ // storage initialization
	XCTAssertNotNil([view textStorage], @"");
}

- (void) test04;
{ // layout manager initialization
	XCTAssertNotNil([view layoutManager], @"");
	XCTAssertEqualObjects([[view layoutManager] textStorage], [view textStorage], @"");
	XCTAssertTrue([[[view textStorage] layoutManagers] containsObject:[view layoutManager]], @"");
	XCTAssertTrue([[[view layoutManager] textContainers] containsObject:[view textContainer]], @"");
}

- (void) test10;
{ // how insertion/replacement modifies selection
	
}

- (void) test20
{ // sizeToFit
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 500.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), @"");
	[view sizeToFit];
	XCTAssertEqual([[view textStorage] length], 0u, @"");
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), @"");
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), @"");
	// try non-empty string with height
	[view replaceCharactersInRange:NSMakeRange(0, 0) withString:@"test"];
	[view sizeToFit];
	XCTAssertEqual([[view textStorage] length], 4u, @"");
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), @"");
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), @"");
	// reduce minSize
	[view setMinSize:NSMakeSize(200.0, 200.0)];
	[view setMaxSize:NSMakeSize(210.0, 1e+07)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 200.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(210.0, 1e+07), @"");
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), @"");
	[view sizeToFit];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 200.0), @"");	// height has been reduced to new minSize.height - but width is not changed!
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 200.0), @"");
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), @"");
	// reduce minSize to 0.0 so that the first line should become influencing
	[view setMinSize:NSMakeSize(200.0, 0.0)];
	[view setMaxSize:NSMakeSize(210.0, 1e+07)];
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 0.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(210.0, 1e+07), @"");
	[view sizeToFit];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 14.0), @"");
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 14.0), @"");
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), @"");
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
	XCTAssertFalse([view isHorizontallyResizable], @"");
	XCTAssertTrue([view isVerticallyResizable], @"");
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), @"");
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 500.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), @"");
	// reduce below minSize
	[view setFrameSize:NSMakeSize(200.0, 400.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 400.0), @"");	// width and height are reduced
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 400.0), @"");
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(200.0, 1e+07), @"");	// container was resized
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// width and height are reduced
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), @"");	// initial value is not changed!
	// increase beyond maxSize.width
	[view setFrameSize:NSMakeSize(400.0, 700.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 400.0, 400.0), @"");	// height was *not* increased, but width!
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 400.0, 400.0), @"");
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(400.0, 1e+07), @"");	// container was resized
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// was not adjusted
	XCTAssertEquals([view maxSize], NSMakeSize(400.0, 1e+07), @"");	// width was increased
	// try again
	[view setFrameSize:NSMakeSize(400.0, 700.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 400.0, 700.0), @"");	// height was increased this time!?!
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 400.0, 700.0), @"");
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(400.0, 1e+07), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// was not adjusted
	XCTAssertEquals([view maxSize], NSMakeSize(400.0, 1e+07), @"");	// width was increased
	// increase beyond maxSize.width
	[view setFrameSize:NSMakeSize(500.0, 700.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 500.0, 400.0), @"");	// height was reset to minSize!?!
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 500.0, 400.0), @"");
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(500.0, 1e+07), @"");	// container was resized
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// was not adjusted
	XCTAssertEquals([view maxSize], NSMakeSize(500.0, 1e+07), @"");	// width was increased
	// decrease a little
	[view setFrameSize:NSMakeSize(490.0, 690.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 490.0, 400.0), @"");	// height was still reset to minSize!?!
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 490.0, 400.0), @"");
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(490.0, 1e+07), @"");	// container was resized
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// was not adjusted
	XCTAssertEquals([view maxSize], NSMakeSize(500.0, 1e+07), @"");	// width was increased
	// try again
	[view setFrameSize:NSMakeSize(490.0, 690.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 490.0, 690.0), @"");	// height was increased this time!?!
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 490.0, 690.0), @"");
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(490.0, 1e+07), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// was not adjusted
	XCTAssertEquals([view maxSize], NSMakeSize(500.0, 1e+07), @"");	// width was increased
	// try to set to minSize.width
	[view setFrameSize:NSMakeSize(200.0, 690.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 400.0), @"");	// height is reset to minSize
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 400.0), @"");
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(200.0, 1e+07), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// was not adjusted
	XCTAssertEquals([view maxSize], NSMakeSize(500.0, 1e+07), @"");	// width was increased
	// try again
	[view setFrameSize:NSMakeSize(200.0, 690.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 690.0), @"");	// height is now set
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 690.0), @"");
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(200.0, 1e+07), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// was not adjusted
	XCTAssertEquals([view maxSize], NSMakeSize(500.0, 1e+07), @"");	// width was increased
	/* conclusions
	 * setting the frameSize is always accepted
	 * container is resized accordingly
	 * modifies minSize or maxSize but only if necessary
	 * unexpected: if width is changed, the height is reset to (new) minSize.height!
	 */
}

- (void) test21c
{ // influence of setConstrainedFrameSize
	XCTAssertFalse([view isHorizontallyResizable], @"");
	XCTAssertTrue([view isVerticallyResizable], @"");
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), @"");
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 500.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), @"");
	// reduce below minSize
	[view setConstrainedFrameSize:NSMakeSize(200.0, 400.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");	// limited
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), @"");
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 500.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), @"");	// initial value is not changed!
	// increase beyond maxSize.width
	[view setConstrainedFrameSize:NSMakeSize(400.0, 700.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 700.0), @"");	// height was adjusted, but not width
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 700.0), @"");
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), @"");	// container was resized
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 500.0), @"");	// was not adjusted!
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), @"");	// width was increased
	/* conclusions
	 * it appears as if isVerticallyResizable/isHorizontallyResizable is applied first
	 * and then the min/max
	 */
}

- (void) test22
{ // influence of resizability on setFrameSize
	XCTAssertFalse([view isHorizontallyResizable], @"");	// set to true
	XCTAssertTrue([view isVerticallyResizable], @"");
	// change resizable settings by enabling both
	[view setHorizontallyResizable:YES];
	[view setVerticallyResizable:YES];
	XCTAssertTrue([view isHorizontallyResizable], @"");
	XCTAssertTrue([view isVerticallyResizable], @"");
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), @"");
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 500.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), @"");
	// reduce below minSize
	[view setFrameSize:NSMakeSize(200.0, 400.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 400.0), @"");
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 400.0), @"");
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(200.0, 1e+07), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// was adjusted!
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), @"");	// initial value is not changed!
	// increase beyond maxSize
	[view setFrameSize:NSMakeSize(400.0, 700.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 400.0), @"");	// was not increased but width and height are reset to _minSize!
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 400.0), @"");	// was not changed again
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(200.0, 1e+07), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// was not adjusted!
	XCTAssertEquals([view maxSize], NSMakeSize(400.0, 1e+07), @"");	// was increased
	/* conclusions
	 * changing resizability does not change frame or size
	 * setting horizontallyResizable makes only a difference by keeping the frame/bounds/container width as it is
	 */
}

- (void) test23
{ // contradicting min/maxSize
	XCTAssertFalse([view isHorizontallyResizable], @"");	// set to true
	XCTAssertTrue([view isVerticallyResizable], @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 500.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), @"");
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");
	// a) make minSize bigger than maxSize
	[view setMinSize:NSMakeSize(600.0, 900.0)];
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 900.0), @"");	// extra large minWidth is ignored
	XCTAssertEquals([view maxSize], NSMakeSize(600.0, 1e+07), @"");	// but taken for maxSize!
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 900.0), @"");	// oops - also increases frameSize!
	// b) make maxSize smaller than minSize
	[view setMaxSize:NSMakeSize(200.0, 400.0)];
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// minSize is reduced to given maxSize which is not touched
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 400.0), @"");	// maxSize is also reduced - but to the old minSize.width?
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), @"");	// oops - also decreases frameSize!
	// c) and minSize again bigger than maxSize
	[view setMinSize:NSMakeSize(600.0, 900.0)];
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 900.0), @"");	// extra large minWidth is ignored
	XCTAssertEquals([view maxSize], NSMakeSize(600.0, 900.0), @"");	// now both are the same height
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 900.0), @"");	// oops - also increases frameSize!
	// d) and again
	[view setMinSize:NSMakeSize(600.0, 900.0)];
	XCTAssertEquals([view minSize], NSMakeSize(600.0, 900.0), @"");	// now, minsize is accepted
	XCTAssertEquals([view maxSize], NSMakeSize(600.0, 900.0), @"");	// both are still the same
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 900.0), @"");	// this time does not change frameSize
	// e) now make smaller
	[view setMinSize:NSMakeSize(400.0, 700.0)];
	XCTAssertEquals([view minSize], NSMakeSize(400.0, 700.0), @"");	// this works now
	XCTAssertEquals([view maxSize], NSMakeSize(600.0, 900.0), @"");
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 900.0), @"");	// this time does not change frameSize
	// f) now make same
	[view setMinSize:NSMakeSize(600.0, 900.0)];
	XCTAssertEquals([view minSize], NSMakeSize(600.0, 900.0), @"");	// this works now
	XCTAssertEquals([view maxSize], NSMakeSize(600.0, 900.0), @"");
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 900.0), @"");	// this time does not change frameSize
	// g) make maxSize partially smaller than minSize
	[view setMaxSize:NSMakeSize(600.0, 350.0)];
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 350.0), @"");	// minSize is reduced to given frameSize or where does the 300.0 come from`
	XCTAssertEquals([view maxSize], NSMakeSize(600.0, 350.0), @"");	// maxSize is also reduced - but to the old minSize.width?
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 350.0), @"");	// oops - also reduces frameSize!
	// h) set frame size
	[view setFrameSize:NSMakeSize(320.0, 700.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 320.0, 350.0), @"");	// was not increased but width and height is reset to _minSize!
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 320.0, 350.0), @"");	// was not changed again
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(320.0, 1e+07), @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 350.0), @"");	// minSize.width is unchanged
	XCTAssertEquals([view maxSize], NSMakeSize(600.0, 350.0), @"");	// was not changed
	// i) make maxSize partially smaller than minSize
	[view setMaxSize:NSMakeSize(250.0, 275.0)];
	XCTAssertEquals([view minSize], NSMakeSize(250.0, 275.0), @"");	// minSize is reduced
	XCTAssertEquals([view maxSize], NSMakeSize(320.0, 275.0), @"");	// maxSize.height is reduced
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 320.0, 275.0), @"");	// reduced as well !?!
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
	XCTAssertFalse([view isHorizontallyResizable], @"");	// set to true
	XCTAssertTrue([view isVerticallyResizable], @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 500.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), @"");
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");
	// change resizability
	[view setHorizontallyResizable:YES];
	[view setVerticallyResizable:NO];
	XCTAssertTrue([view isHorizontallyResizable], @"");	// set to true
	XCTAssertFalse([view isVerticallyResizable], @"");	// set to false
	// a) try to make minSize bigger than maxSize
	[view setMinSize:NSMakeSize(600.0, 900.0)];
	XCTAssertEquals([view minSize], NSMakeSize(600.0, 500.0), @"");	// extra large minHeight is ignored (or limited to frame height)
	XCTAssertEquals([view maxSize], NSMakeSize(600.0, 1e+07), @"");	// maxSize is increased
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 600.0, 500.0), @"");	// oops - also increases frameSize!
	// b) make maxSize smaller than minSize
	[view setMaxSize:NSMakeSize(200.0, 400.0)];
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// minSize is reduced to given maxSize which is not touched
	XCTAssertEquals([view maxSize], NSMakeSize(200.0, 500.0), @"");
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 500.0), @"");	// oops - also decreases frameSize!
	/* conclusions
	 * resizability has an influence!
	 */
}

- (void) test24
{ // interaction of setFrameSize, setMinSize, setMaxSize
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 500.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), @"");
	// reduce minSize.height and then increase until it reaches frame size and beyond
	[view setMinSize:NSMakeSize(300.0, 200)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");	// frame stays stable
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 200.0), @"");	// has been reduced
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), @"");	// unchanged
	// increase minSize.height
	[view setMinSize:NSMakeSize(300.0, 300)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");	// unchanged
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 300.0), @"");	// changed
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), @"");
	// increase minSize.height
	[view setMinSize:NSMakeSize(300.0, 500)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");	// unchanged
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), @"");	// unchanged
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 500.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), @"");	// unchanged
	// increase minSize.height
	[view setMinSize:NSMakeSize(300.0, 800)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 800.0), @"");	// frame growing larger
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 800.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 800.0), @"");	// changed
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), @"");	// unchanged
	/* conclusions
	 * increasing _minSize beyond maxSize/frameSize increases them as well
	 */
}

- (void) test25
{ // interaction of setFrameSize, setMinSize, setMaxSize
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 500.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), @"");
	// change maxSize to be smaller than frameSize 
	[view setMaxSize:NSMakeSize(200.0, 400.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), @"");	// frame gets smaller
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// minSize is also modified
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 400.0), @"");	// maxSize is modified - but not both components
	// reduce minSize.height and then increase until it reaches frame size and goes beyond
	[view setMinSize:NSMakeSize(150.0, 250.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), @"");	// frame stays stable
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(150.0, 250.0), @"");	// has been reduced
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 400.0), @"");	// unchanged
	// increase minSize.height
	[view setMinSize:NSMakeSize(150.0, 300)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), @"");	// unchanged
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(150.0, 300.0), @"");	// changed
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 400), @"");
	// increase minSize.height
	[view setMinSize:NSMakeSize(150.0, 500)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");	// increased
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), @"");	// increased
	XCTAssertEquals([view minSize], NSMakeSize(150.0, 500.0), @"");	// changed
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 500.0), @"");	// also increased
	// reduce minSize.height and then until it reaches frame size and beyond
	[view setMinSize:NSMakeSize(150.0, 800)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 800.0), @"");	// frame growing larger
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 800.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(150.0, 800.0), @"");	// changed
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 800.0), @"");	// changed
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
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 500.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), @"");
	// change maxSize to be smaller than frameSize
	[view setMaxSize:NSMakeSize(200.0, 400.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), @"");	// frame gets smaller
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// minSize is also modified
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 400.0), @"");	// maxSize is modified - but not both components
	// reduce minSize.width and then increase until it reaches frame size and goes beyond
	[view setMinSize:NSMakeSize(150.0, 250.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), @"");	// frame stays stable
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(150.0, 250.0), @"");	// has been reduced
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 400.0), @"");	// unchanged
	// increase minSize.width
	[view setMinSize:NSMakeSize(200.0, 250.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), @"");	// unchanged
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 250.0), @"");	// changed
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 400), @"");
	// increase minSize.width
	[view setMinSize:NSMakeSize(300.0, 250.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), @"");	// unchanged
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 250.0), @"");	// changed
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 400.0), @"");	// also increased
	// increase minSize.width
	[view setMinSize:NSMakeSize(400.0, 250.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), @"");	// unchanged
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(400.0, 250.0), @"");	// changed
	XCTAssertEquals([view maxSize], NSMakeSize(400.0, 400.0), @"");	// changed
	[view setMinSize:NSMakeSize(500.0, 250.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), @"");	// unchanged
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(500.0, 250.0), @"");	// changed
	XCTAssertEquals([view maxSize], NSMakeSize(500.0, 400.0), @"");	// changed
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
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 500.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), @"");
	// change maxSize to be smaller than minSize 
	[view setMaxSize:NSMakeSize(200.0, 400.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), @"");	// frame gets smaller
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// minSize is also modified
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 400.0), @"");	// maxSize is modified - but not both components
	// increase maxSize.height and then increase until it reaches frame size and goes beyond
	[view setMaxSize:NSMakeSize(200.0, 500.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), @"");	// frame stays stable now
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(200.0, 500.0), @"");	// changed
	// increase minSize.height
	[view setMaxSize:NSMakeSize(200.0, 800)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), @"");	// unchanged
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(200.0, 800.0), @"");
	// decrease minSize.height a little
	[view setMaxSize:NSMakeSize(200.0, 750)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), @"");	// unchanged
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(200.0, 750.0), @"");
	// now increase minSize.width a little
	[view setMaxSize:NSMakeSize(250.0, 750)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), @"");	// unchanged
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(250.0, 750.0), @"");
	// now increase minSize.width a little
	[view setMaxSize:NSMakeSize(300.0, 750)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), @"");	// unchanged
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 750.0), @"");
	// now increase minSize.width a little
	[view setMaxSize:NSMakeSize(400.0, 750)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), @"");	// unchanged
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(400.0, 750.0), @"");
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
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 500.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), @"");
	// limit maxSize
	[view setMaxSize:NSMakeSize(300.0, 700.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");	// frame is unchanged
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 500.0), @"");	// unchanged
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 700.0), @"");	// maxSize has been set
	// change frameSize to be smaller than minSize (and maxSize)
	[view setFrameSize:NSMakeSize(200.0, 400.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 400.0), @"");	// frame gets smaller
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// minSize is reduced to given frameSize!
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 700.0), @"");	// maxSize is untouched
	// increase frameSize.height and then increase until it reaches frame size and goes beyond
	[view setFrameSize:NSMakeSize(200.0, 500.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 500.0), @"");	// frame grows
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 500.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// no further change
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 700.0), @"");	// no further change
	// increase frameSize.height
	[view setFrameSize:NSMakeSize(200.0, 800)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 800.0), @"");	// frame grows
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 800.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 800.0), @"");	// maxSize enlarged to given frameSize!
	// decrease frameSize.height a little
	[view setFrameSize:NSMakeSize(200.0, 750.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 750.0), @"");	// reduced
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 750.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// unchanged
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 800.0), @"");	// unchanged
	// now increase frameSize.width a little
	[view setFrameSize:NSMakeSize(250.0, 750.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 250.0, 400.0), @"");	// modifies width AND resets height to minSize.height!
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 250.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// unchanged!
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 800.0), @"");	// unchanged!
	// now increase frameSize.width a little
	[view setFrameSize:NSMakeSize(300.0, 750)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 400.0), @"");	// does not set height!
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 800.0), @"");
	// now increase frameSize.width a little
	[view setFrameSize:NSMakeSize(400.0, 750)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 400.0, 400.0), @"");	// does not set height!
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 400.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(400.0, 800.0), @"");
	// now set the same frameSize.width again
	[view setFrameSize:NSMakeSize(400.0, 750)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 400.0, 750.0), @"");	// now it does set height!
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 400.0, 750.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(400.0, 800.0), @"");
	// now decrease frameSize.width again
	[view setFrameSize:NSMakeSize(350.0, 750)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 350.0, 400.0), @"");	// now it resets the height again!
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 350.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(400.0, 800.0), @"");
	// now decrease frameSize.width again
	[view setFrameSize:NSMakeSize(350.0, 750)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 350.0, 750.0), @"");	// now it sets the height again!
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 350.0, 750.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(400.0, 800.0), @"");
	/* conclusions
	 * reduces minSize if needed
	 * extends maxSize if needed
	 * if and only if frame.width is changed, the height is taken from minSize.height instead of newSize.height
	 * this special rule may only apply if !_tx.isHorizontallyResizable
	 * because that effect could not be seen by increasing frame.height
	 */
}

- (void) test28h	// the same with swapped resizability
{ // interaction of setFrameSize, setMinSize, setMaxSize
	[view setHorizontallyResizable:YES];
	[view setVerticallyResizable:NO];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 500.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), @"");
	// limit maxSize
	[view setMaxSize:NSMakeSize(300.0, 700.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");	// frame is unchanged
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 500.0), @"");	// unchanged
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 700.0), @"");	// maxSize has been set
	// change frameSize to be smaller than minSize (and maxSize)
	[view setFrameSize:NSMakeSize(200.0, 400.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 400.0), @"");	// frame gets smaller
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// minSize is reduced to given frameSize!
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 700.0), @"");	// maxSize is untouched
	// increase frameSize.width and then increase until it reaches frame size and goes beyond
	[view setFrameSize:NSMakeSize(250.0, 400.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 400.0), @"");	// does not grow
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// no further change
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 700.0), @"");	// no further change
	// increase frameSize.width
	[view setFrameSize:NSMakeSize(300.0, 400.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 400.0), @"");	// no change
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 700.0), @"");	// no change
	// increase frameSize.width
	[view setFrameSize:NSMakeSize(350.0, 400.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 400.0), @"");	// no change
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(350.0, 700.0), @"");	// made wider
	// decrease frameSize.width a little
	[view setFrameSize:NSMakeSize(300.0, 400.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 400.0), @"");	// reduced
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// unchanged
	XCTAssertEquals([view maxSize], NSMakeSize(350.0, 700.0), @"");	// unchanged
	// now increase frameSize.height a little
	[view setFrameSize:NSMakeSize(300.0, 450.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 450.0), @"");	// modifies height
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 450.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// unchanged!
	XCTAssertEquals([view maxSize], NSMakeSize(350.0, 700.0), @"");	// unchanged!
	// now increase frameSize.height a little
	[view setFrameSize:NSMakeSize(300.0, 500)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 500.0), @"");	// does not set width!
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 500.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(350.0, 700.0), @"");
	// now increase frameSize.height a little
	[view setFrameSize:NSMakeSize(300.0, 550)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 550.0), @"");	// does not set width!
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 550), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(350.0, 700.0), @"");
	// now set the same frameSize.height again
	[view setFrameSize:NSMakeSize(400.0, 750.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 750.0), @"");	// now it does set height!
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 750.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(400.0, 750.0), @"");
	// now decrease frameSize.height again
	[view setFrameSize:NSMakeSize(400.0, 700.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 700.0), @"");	// now it resets the width again!
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 700.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(400.0, 750.0), @"");
	// now decrease frameSize.width again
	[view setFrameSize:NSMakeSize(350.0, 700)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 700.0), @"");	// now it sets the height again!
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 700.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(400.0, 750.0), @"");
	/* conclusions
	 */
}

- (void) test28n	// the same with NO resizability
{ // interaction of setFrameSize, setMinSize, setMaxSize
	[view setHorizontallyResizable:NO];
	[view setVerticallyResizable:NO];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 500.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), @"");
	// limit maxSize
	[view setMaxSize:NSMakeSize(300.0, 700.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");	// frame is unchanged
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 500.0), @"");	// unchanged
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 700.0), @"");	// maxSize has been set
	// change frameSize to be smaller than minSize (and maxSize)
	[view setFrameSize:NSMakeSize(200.0, 400.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 400.0), @"");	// frame gets smaller
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// minSize is reduced to given frameSize!
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 700.0), @"");	// maxSize is untouched
	// increase frameSize.height and then increase until it reaches frame size and goes beyond
	[view setFrameSize:NSMakeSize(200.0, 500.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 500.0), @"");	// frame grows
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 500.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// no further change
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 700.0), @"");	// no further change
	// increase frameSize.height
	[view setFrameSize:NSMakeSize(200.0, 800)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 800.0), @"");	// frame grows
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 800.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 800.0), @"");	// maxSize enlarged to given frameSize!
	// decrease frameSize.height a little
	[view setFrameSize:NSMakeSize(200.0, 750.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 750.0), @"");	// reduced
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 750.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// unchanged
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 800.0), @"");	// unchanged
	// now increase frameSize.width a little
	[view setFrameSize:NSMakeSize(250.0, 750.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 250.0, 750.0), @"");	// modifies
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 250.0, 750.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// unchanged!
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 800.0), @"");	// unchanged!
	// now increase frameSize.width a little
	[view setFrameSize:NSMakeSize(300.0, 750)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 750.0), @"");
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 750.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 800.0), @"");
	// now increase frameSize.width a little
	[view setFrameSize:NSMakeSize(400.0, 750)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 400.0, 750.0), @"");	// accepted
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 400.0, 750.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(400.0, 800.0), @"");
	// now set the same frameSize.width again
	[view setFrameSize:NSMakeSize(400.0, 750)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 400.0, 750.0), @"");	// accepted
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 400.0, 750.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(400.0, 800.0), @"");
	// now decrease frameSize.width again
	[view setFrameSize:NSMakeSize(350.0, 750)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 350.0, 750.0), @"");	// accepted
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 350.0, 750.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(400.0, 800.0), @"");
	// now decrease frameSize.width again
	[view setFrameSize:NSMakeSize(350.0, 750)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 350.0, 750.0), @"");	// accepted
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 350.0, 750.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(400.0, 800.0), @"");
	/* conclusions
	 if not resizable, the new frame Size is simply accepted
	 */
}

- (void) test28r	// the same with FULL resizability
{ // interaction of setFrameSize, setMinSize, setMaxSize
	[view setHorizontallyResizable:YES];
	[view setVerticallyResizable:YES];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 500.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), @"");
	// limit maxSize
	[view setMaxSize:NSMakeSize(300.0, 700.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");	// frame is unchanged
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 500.0), @"");	// unchanged
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 700.0), @"");	// maxSize has been set
	// change frameSize to be smaller than minSize (and maxSize)
	[view setFrameSize:NSMakeSize(200.0, 400.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 400.0), @"");	// frame gets smaller
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// minSize is reduced to given frameSize!
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 700.0), @"");	// maxSize is untouched
	// increase frameSize.height and then increase until it reaches frame size and goes beyond
	[view setFrameSize:NSMakeSize(200.0, 500.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 500.0), @"");	// frame grows
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 500.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// no further change
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 700.0), @"");	// no further change
	// increase frameSize.height
	[view setFrameSize:NSMakeSize(200.0, 800)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 800.0), @"");	// frame grows
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 800.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 800.0), @"");	// maxSize enlarged to given frameSize!
	// decrease frameSize.height a little
	[view setFrameSize:NSMakeSize(200.0, 750.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 750.0), @"");	// reduced
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 750.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// unchanged
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 800.0), @"");	// unchanged
	// now increase frameSize.width a little
	[view setFrameSize:NSMakeSize(250.0, 750.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 400.0), @"");	// reduced to minimum!
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");	// unchanged!
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 800.0), @"");	// unchanged!
	// now increase frameSize.width a little
	[view setFrameSize:NSMakeSize(300.0, 750)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 400.0), @"");	// reduced to minimum!
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 800.0), @"");
	// now increase frameSize.width a little
	[view setFrameSize:NSMakeSize(400.0, 750)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 400.0), @"");	// reduced to minimum!
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(400.0, 800.0), @"");
	// now set the same frameSize.width again
	[view setFrameSize:NSMakeSize(400.0, 750)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 400.0), @"");	// reduced to minimum!
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(400.0, 800.0), @"");
	// now decrease frameSize.width again
	[view setFrameSize:NSMakeSize(350.0, 750)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 400.0), @"");	// reduced to minimum!
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(400.0, 800.0), @"");
	// now decrease frameSize.width again
	[view setFrameSize:NSMakeSize(350.0, 750)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 400.0), @"");	// reduced to minimum!
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(400.0, 800.0), @"");
	// now set width to the current value
	[view setFrameSize:NSMakeSize(200.0, 750.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 750.0), @"");	// height is accepted!
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 750.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(400.0, 800.0), @"");
	// now set width to the current value
	[view setFrameSize:NSMakeSize(400.0, 750.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 200.0, 400.0), @"");	// width is NOT accepted! Quite a strange particle...
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 200.0, 400.0), @"");
	XCTAssertEquals([view minSize], NSMakeSize(200.0, 400.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(400.0, 800.0), @"");
	/* conclusions
	 * if resizable, the new frame Size is NOT accepted and the minSize is taken
	 * minSize is reduced if needed
	 * maxSize is increased if needed
	 */
}

- (void) test40c
{ // interaction of setFrameSize, setMinSize, setMaxSize with an enclosing NSClipView
	// see how it should work: https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/TextUILayer/Tasks/TextInScrollView.html
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), @"");
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 500.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), @"");
	NSClipView *cv=[[[NSClipView alloc] initWithFrame:NSMakeRect(10.0, 20.0, 400.0, 700.0)] autorelease];
	// now add the NSTextView to the NSClipView
	[cv setDocumentView:view];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 700.0), @"");	// height is adjusted, because it is resizable, width isn't important
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 700.0), @"");
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 700.0), @"");	// height taken from clip view, width isn't important as long as it is less than frame width
	XCTAssertEquals([view maxSize], NSMakeSize(400.0, 1e+07), @"");	// width is copied from clip view
	/* conclusions
	 * setting the NSTextView as the documentView
	 * makes it resize and set minSize/maxSize
	 * so that the NSTextView is at least as large as the ClipView
	 * i.e. the full visible content is covered by the NSTextView
	 */
}

- (void) test40v
{ // is this special behaviour of the NSClipView or setDocumentView?
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), @"");
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 500.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), @"");
	NSView *v=[[[NSView alloc] initWithFrame:NSMakeRect(10.0, 20.0, 400.0, 700.0)] autorelease];
	// now add the NSTextView to the NSView
	[v addSubview:view];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");	// not changed
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), @"");
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 500.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), @"");
	// remove again
	[view removeFromSuperview];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");	// not changed
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), @"");
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 500.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), @"");
	// now simply add to NSCLipView
	NSClipView *cv=[[[NSClipView alloc] initWithFrame:NSMakeRect(10.0, 20.0, 400.0, 700.0)] autorelease];
	[cv addSubview:view];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 700.0), @"");	// height is adjusted, because it is resizable, width isn't important
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 700.0), @"");
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 700.0), @"");	// height taken from clip view, width isn't important as long as it is less than frame width
	XCTAssertEquals([view maxSize], NSMakeSize(400.0, 1e+07), @"");	// width is copied from clip view
	/* conclusions
	 * adding the NSTextView to a NSClipView makes it inherit its frame which also sets the minSize/maxSize
	 */
}

- (void) test50
{
	XCTAssertEqualObjects([view string], @"", @"");
	XCTAssertEqualObjects([view font], [NSFont fontWithName:@"Helvetica" size:12.0], @"");
	XCTAssertEqualObjects([view typingAttributes], [NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Helvetica" size:12.0] forKey:NSFontAttributeName], @"");
	[view setFont:[NSFont fontWithName:@"Times" size:14.0]];
	XCTAssertEqualObjects([view font], [NSFont fontWithName:@"Times" size:14.0], @"");
	XCTAssertEqualObjects([view typingAttributes], [NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Times" size:14.0] forKey:NSFontAttributeName], @"");
	[view setTypingAttributes:[NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Times" size:18.0] forKey:NSFontAttributeName]];
	XCTAssertEqualObjects([view font], [NSFont fontWithName:@"Times" size:18.0], @"");
	XCTAssertEqualObjects([view typingAttributes], [NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Times" size:18.0] forKey:NSFontAttributeName], @"");
	[[view textStorage] replaceCharactersInRange:NSMakeRange(0, [[view textStorage] length]) withString:@"String"];
	XCTAssertEqualObjects([view string], @"String", @"");
	XCTAssertEqualObjects([view font], [NSFont fontWithName:@"Helvetica" size:12.0], @"");
	XCTAssertEqualObjects([view typingAttributes], [NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Helvetica" size:12.0] forKey:NSFontAttributeName], @"");
	XCTAssertEqualObjects([[view textStorage] attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL], [NSFont fontWithName:@"Helvetica" size:12.0], @"");
	[view setTypingAttributes:nil];
	XCTAssertEqualObjects([view font], [NSFont fontWithName:@"Helvetica" size:12.0], @"");
	XCTAssertEqualObjects([view typingAttributes], [NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Helvetica" size:12.0] forKey:NSFontAttributeName], @"");
	[view setFont:[NSFont fontWithName:@"Times" size:14.0]];
	[view setTypingAttributes:[NSDictionary dictionary]];
	XCTAssertEqualObjects([view font], [NSFont fontWithName:@"Times" size:14.0], @"");
	XCTAssertEqualObjects([view typingAttributes], [NSDictionary dictionary], @"");
	XCTAssertThrows([view setFont:nil], @"");
	[view setTypingAttributes:[NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Times" size:18.0] forKey:NSFontAttributeName]];
	[[view textStorage] replaceCharactersInRange:NSMakeRange(0, [[view textStorage] length]) withString:@"Another String"];
	XCTAssertEqualObjects([view string], @"Another String", @"");
	XCTAssertEqualObjects([view font], [NSFont fontWithName:@"Times" size:14.0], @"");
	XCTAssertEqualObjects([view typingAttributes], [NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Times" size:14.0] forKey:NSFontAttributeName], @"");
	XCTAssertEqualObjects([[view textStorage] attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL], [NSFont fontWithName:@"Times" size:14.0], @"");
	/*
	 * typing attributes follow setFont:
	 * changing typing attributes affects setFont:
	 * but replacing an empty character range with a string (and no attributes) resets everything to Helvetica:12 (where is this defined?)
	 * setting typingAttributes to nil is silently ignored
	 * setting nil font raises exception
	 * changing a string with Helvetica:12 resets font and typing attributes to Helvetica:12
	 *
	 * i.e. replacing characters takes the current attributes from the string as new typing attributes
	 * if there are no current attributes of the string, the default is Helvetica:12
	 * setFont/font are NOT simple setter/getter for the NSFontAttributeName component of the typing attributes (see the test where we set empty typing attributes)
	 */
}

- (void) test99
{ // try setting some extreme values
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 500.0), @"");
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 500.0), @"");
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), @"");
	XCTAssertEquals([view minSize], NSMakeSize(300.0, 500.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), @"");
	// make minSize negative
	[view setMinSize:NSMakeSize(-600.0, -800.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, 300.0, 800.0), @"");	// frame.height = fabs(minSize.height)
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, 300.0, 800.0), @"");
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(300.0, 1e+07), @"");
	XCTAssertEquals([view minSize], NSMakeSize(-600.0, -800.0), @"");
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), @"");	// initial value is not changed!
	[view setFrameSize:NSMakeSize(-200.0, -400.0)];
	XCTAssertEquals([view frame], NSMakeRect(100.0, 100.0, -200.0, 800.0), @"");
	XCTAssertEquals([view bounds], NSMakeRect(0.0, 0.0, -200.0, 800.0), @"");
	XCTAssertEquals([[view textContainer] containerSize], NSMakeSize(-200.0, 1e+07), @"");
	XCTAssertEquals([view minSize], NSMakeSize(-600.0, -800.0), @"");	// was not changed
	XCTAssertEquals([view maxSize], NSMakeSize(300.0, 1e+07), @"");	// initial value is not changed!
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
