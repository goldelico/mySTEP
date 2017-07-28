//
//  NSLayoutManagerTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 26.12.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Cocoa/Cocoa.h>

// contrary to STAssertEquals(), XCTAssertEqual() can only handle scalar objects
// https://stackoverflow.com/questions/19178109/xctassertequal-error-3-is-not-equal-to-3
// http://www.openradar.me/16281876

#define XCTAssertEquals(a, b, ...) ({ \
	typeof(a) _a=(a); typeof(b) _b=(b); \
	XCTAssertEqualObjects( \
		[NSValue value:&_a withObjCType:@encode(typeof(_a))], \
		[NSValue value:&_b withObjCType:@encode(typeof(_b))], \
		##__VA_ARGS__); })


@interface NSLayoutManagerTest : XCTestCase {
	NSTextStorage *textStorage;
	NSLayoutManager *layoutManager;
	NSTextContainer *textContainer;
	NSTextView *textView;	
}

@end


@implementation NSLayoutManagerTest

- (void) setUp;	// runs before each test (+setUp would run only once)
{
//	NSLog(@"-setUp");
	// create text network
	textStorage = [[NSTextStorage alloc] initWithString:@"Direct\ndrawing\nmultiple\nlines."];
	layoutManager = [[NSLayoutManager alloc] init];
	textContainer = [[NSTextContainer alloc] init];
	textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 500.0, 500.0)];	// has its own textContainer
	[layoutManager setBackgroundLayoutEnabled:NO];
	[layoutManager setUsesScreenFonts:NO];
	[textContainer setTextView:textView];	// if we do that later, it already does layout in the layoutManager
	[layoutManager addTextContainer:textContainer];
	[textContainer release];	// The layoutManager will retain the textContainer
	[textStorage addLayoutManager:layoutManager];
	[layoutManager release];	// The textStorage will retain the layoutManager
	[textView release];
#if 0	// would rise an exception:
	[layoutManager glyphAtIndex:100];
#endif
	[layoutManager invalidateGlyphsOnLayoutInvalidationForGlyphRange:NSMakeRange(0, INT_MAX)];
	[layoutManager invalidateLayoutForCharacterRange:NSMakeRange(0, [textStorage length]) actualCharacterRange:NULL];
}

- (void) tearDown;	// runs after each test
{
//	NSLog(@"-tearDown");
	[textStorage release];
}

- (void) test01
{ // allocation did work
	XCTAssertNotNil(textStorage, @"");
	XCTAssertNotNil(layoutManager, @"");
	XCTAssertNotNil(textContainer, @"");
	XCTAssertNotNil(textView, @"");
}

- (void) test02
{ // network setup is ok
	XCTAssertEqualObjects([textContainer textView], textView, @"");
	XCTAssertEqualObjects([textContainer layoutManager], layoutManager, @"");
	XCTAssertEqualObjects([layoutManager textStorage], textStorage, @"");
	XCTAssertTrue([[textStorage layoutManagers] containsObject:layoutManager], @"");
	XCTAssertTrue([[layoutManager textContainers] containsObject:textContainer], @"");
	XCTAssertEqualObjects([textView textContainer], textContainer, @"");
}

- (void) test03
{ // internal classes initialized
	XCTAssertNotNil([layoutManager typesetter], @"");
	XCTAssertNotNil([layoutManager glyphGenerator], @"");
}

- (void) test04
{ // default layout settings
	XCTAssertFalse([layoutManager allowsNonContiguousLayout], @"");
	XCTAssertFalse([layoutManager backgroundLayoutEnabled], @"");			
}

- (void) test05
{ // default typing attributes
	XCTAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"Helvetica", @"");
}

- (void) test06
{
	[[textContainer textView] setTypingAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
												   [NSFont fontWithName:@"LucidaGrande" size:18.0],
												   NSFontAttributeName, nil]];	// set explicit typing Attributes
	XCTAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"LucidaGrande", @"");
}

- (void) test07
{
	[[textContainer textView] setTypingAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
												   [NSFont fontWithName:@"LucidaGrande" size:18.0],
												   NSFontAttributeName, 
												   [NSColor redColor],
												   NSForegroundColorAttributeName,
												   nil]];	// set explicit typing Attributes
//	NSLog(@"%@", [[textContainer textView] typingAttributes]);
	XCTAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"LucidaGrande", @"");
	[[textContainer textView] setTypingAttributes:nil];	// try to clear typing attributes
//	NSLog(@"%@", [[textContainer textView] typingAttributes]);
	XCTAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"LucidaGrande", @"");
	[[textContainer textView] setTypingAttributes:[NSDictionary dictionaryWithObjectsAndKeys:nil]];	// set explicit typing Attributes
//	NSLog(@"%@", [[textContainer textView] typingAttributes]);
	XCTAssertNil([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"");
	/* conclusions
	 - it is impossible to completely clear the typing atrributes
	 - setting to nil is ignored
	 - but it is possible to set attributes without NSFontAttributeName
	 */
}

- (void) test08
{ // default layout settings
	NSSize size=[textContainer containerSize];
	XCTAssertEquals(size, NSMakeSize(1e+07, 1e+07), @"");
}

- (void) test10
{
	XCTAssertEqual([layoutManager firstUnlaidGlyphIndex], 0u, @"");
	XCTAssertEqual([layoutManager firstUnlaidCharacterIndex], 0u, @"");
	[layoutManager ensureGlyphsForGlyphRange:NSMakeRange(0, 5)];
	// since we still see 0 here, firstUnlaidGlyph has nothing to do with the glyph generation
	XCTAssertEqual([layoutManager firstUnlaidGlyphIndex], 0u, @"");
	XCTAssertEqual([layoutManager firstUnlaidCharacterIndex], 0u, @"");
	/* conclusions
	 - ensuring glyphRanges has nothing to do with firstUnlaid*Index
	 - it is solely for layout
	 */
}

- (void) test11
{
	XCTAssertEqual([layoutManager firstUnlaidGlyphIndex], 0u, @"");
	XCTAssertEqual([layoutManager firstUnlaidCharacterIndex], 0u, @"");
	// this shows that we may have a stale text container assignment even if we have no valid layout!
	// it is not even clear where this comes from!
	// if we check this right after setting up the layout manger it is/was nil
	// most likely there was some initial layout phase during setUp which was reset
	XCTAssertEqualObjects([layoutManager textContainerForGlyphAtIndex:0 effectiveRange:NULL withoutAdditionalLayout:YES], textContainer, @"");
	XCTAssertEqualObjects([layoutManager textContainerForGlyphAtIndex:10 effectiveRange:NULL withoutAdditionalLayout:YES], textContainer, @"");
	[layoutManager invalidateGlyphsOnLayoutInvalidationForGlyphRange:NSMakeRange(0, 30)];
	XCTAssertThrows([layoutManager invalidateLayoutForCharacterRange:NSMakeRange(0, 40) actualCharacterRange:NULL], @"");
	XCTAssertNoThrow([layoutManager invalidateLayoutForCharacterRange:NSMakeRange(0, 30) actualCharacterRange:NULL], @"");
	// here we get nil because there is no layout for this glyph
	XCTAssertEqual([layoutManager firstUnlaidGlyphIndex], 0u, @"");
	XCTAssertEqual([layoutManager firstUnlaidCharacterIndex], 0u, @"");
	XCTAssertEqualObjects([layoutManager textContainerForGlyphAtIndex:0 effectiveRange:NULL withoutAdditionalLayout:YES], textContainer, @"");
	XCTAssertEqualObjects([layoutManager textContainerForGlyphAtIndex:10 effectiveRange:NULL withoutAdditionalLayout:YES], textContainer, @"");
	/* conclusions
	 - generating glyphs does not assign text containers
	 - there may be stale text container info attached to glyphs (probably unless we enforce additionalLayout)
	 */
}

- (void) test12
{
	XCTAssertEqual([layoutManager firstUnlaidGlyphIndex], 0u, @"");
	XCTAssertEqual([layoutManager firstUnlaidCharacterIndex], 0u, @"");
	[layoutManager ensureGlyphsForCharacterRange:NSMakeRange(0, 10)];
	// ensuring glyphs does not do any layout
	XCTAssertEqual([layoutManager firstUnlaidGlyphIndex], 0u, @"");
	XCTAssertEqual([layoutManager firstUnlaidCharacterIndex], 0u, @"");
	/* conclusions
	 - generating glyphs does not assign text containers
	 */
}

- (void) test13
{
	XCTAssertEqual([layoutManager firstUnlaidGlyphIndex], 0u, @"");
	XCTAssertEqual([layoutManager firstUnlaidCharacterIndex], 0u, @"");
	[layoutManager ensureLayoutForGlyphRange:NSMakeRange(0, 5)];
	// here we will see 7 because the first line (7 chars/glyphs) was laid out completely
	XCTAssertEqual([layoutManager firstUnlaidGlyphIndex], 7u, @"");
	XCTAssertEqual([layoutManager firstUnlaidCharacterIndex], 7u, @"");
	/* conclusions
	 - generating layout is done line by line as far as needed
	 */
}

- (void) test14
{
	XCTAssertEqual([layoutManager firstUnlaidGlyphIndex], 0u, @"");
	XCTAssertEqual([layoutManager firstUnlaidCharacterIndex], 0u, @"");
	[layoutManager ensureLayoutForGlyphRange:NSMakeRange(0, 5)];
	// now we have a text container for the first glyph -- which generates all glyphs that fit into the container
	XCTAssertNil([layoutManager textContainerForGlyphAtIndex:0 effectiveRange:NULL withoutAdditionalLayout:YES], @"");
	XCTAssertNil([layoutManager textContainerForGlyphAtIndex:7 effectiveRange:NULL withoutAdditionalLayout:YES], @"");
	XCTAssertNil([layoutManager textContainerForGlyphAtIndex:20 effectiveRange:NULL withoutAdditionalLayout:YES], @"");
	// here we will see all 30 glyphs (all lines!)
	XCTAssertEquals([layoutManager glyphRangeForTextContainer:textContainer], NSMakeRange(0, 30), @"");
	XCTAssertEqual([layoutManager firstUnlaidGlyphIndex], 30u, @"");
	XCTAssertEqual([layoutManager firstUnlaidCharacterIndex], 30u, @"");
	/* conclusions
	 * unclear
	 */
}

- (void) test20
{
	NSRect rect;
	XCTAssertEqual([layoutManager firstUnlaidGlyphIndex], 0u, @"");
	XCTAssertEqual([layoutManager firstUnlaidCharacterIndex], 0u, @"");
	// try to invalidate already invalid range - ignored
	[layoutManager invalidateLayoutForCharacterRange:NSMakeRange(7, 5) actualCharacterRange:NULL];
	XCTAssertEqual([layoutManager firstUnlaidGlyphIndex], 0u, @"");
	XCTAssertEqual([layoutManager firstUnlaidCharacterIndex], 0u, @"");
	// make full layout
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	XCTAssertEqual([layoutManager firstUnlaidGlyphIndex], 30u, @"");
	XCTAssertEqual([layoutManager firstUnlaidCharacterIndex], 30u, @"");
	rect = [layoutManager usedRectForTextContainer:textContainer];
//	NSLog(@"usedRectForTextContainer: %@", NSStringFromRect(rect));
	XCTAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width >= 1e+07 && rect.size.height == 4*14.0, @"rect=%@", NSStringFromRect(rect));
	// invalidate subrange
	[layoutManager invalidateLayoutForCharacterRange:NSMakeRange(7, 5) actualCharacterRange:NULL];
	XCTAssertEqual([layoutManager firstUnlaidGlyphIndex], 7u, @"");
	XCTAssertEqual([layoutManager firstUnlaidCharacterIndex], 7u, @"");
	// should have become smaller
	rect = [layoutManager usedRectForTextContainer:textContainer];
//	NSLog(@"usedRectForTextContainer: %@", NSStringFromRect(rect));
	XCTAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width >= 1e+07 && rect.size.height == 14.0, @"rect=%@", NSStringFromRect(rect));
	/* conclusions
	 - invalidation of already invalid ranges is ignored
	 - invalidation resets the firstUnlaid*Index to the beginning
	 - usedRect is reduced by invalidated areas
	 - i.e. layout generation is incremental and decremental
	 */
}

- (void) test21
{
	// it appears that this method also generates all glyphs at least up to the index
	XCTAssertTrue([layoutManager isValidGlyphIndex:5], @"");
	XCTAssertTrue([layoutManager isValidGlyphIndex:10], @"");
	XCTAssertTrue([layoutManager isValidGlyphIndex:29], @"");
	XCTAssertTrue(![layoutManager isValidGlyphIndex:30], @"");
	XCTAssertTrue(![layoutManager isValidGlyphIndex:50], @"");
}

- (void) test22
{
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(7, 5)];
	XCTAssertEquals([layoutManager rangeOfNominallySpacedGlyphsContainingIndex:10], NSMakeRange(7, 7), @"");
	[layoutManager locationForGlyphAtIndex:10];	// needs calculation
	// range is unchanged, i.e. locationForGlyphAtIndex appears to interpolate locations within ranges if someone asks (e.g. CircleView)!
	XCTAssertEquals([layoutManager rangeOfNominallySpacedGlyphsContainingIndex:10], NSMakeRange(7, 7), @"");
	}

- (void) test30
{
	NSRect rect;
	XCTAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"Helvetica", @"");
	// try same directly on textstorage
	[textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:@""];
	// now we should have no layout, i.e. 0
	XCTAssertEqual([layoutManager firstUnlaidGlyphIndex], 0u, @"");
	XCTAssertEqual([layoutManager firstUnlaidCharacterIndex], 0u, @"");
	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	XCTAssertEqual([layoutManager firstUnlaidGlyphIndex], 0u, @"");
	XCTAssertEqual([layoutManager firstUnlaidCharacterIndex], 0u, @"");
	// there is some default font for empty strings
	XCTAssertEquals([layoutManager usedRectForTextContainer:textContainer], NSMakeRect(0.0, 0.0, 10.0, 14.0), @"");
	// the text container we have provided
	XCTAssertEqualObjects([layoutManager extraLineFragmentTextContainer], textContainer, @"");
	rect = [layoutManager extraLineFragmentRect];
	// we see an almost infinitely wide container
	XCTAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width >= 1e+07 && rect.size.height == 14.0, @"rect=%@", NSStringFromRect(rect));
	// the textContainer usedRect is the extraFragmentUsedRect
	XCTAssertEquals([layoutManager extraLineFragmentUsedRect], NSMakeRect(0.0, 0.0, 10.0, 14.0), @"");
}

- (void) test31
{ // do the same but with setting font attribute doesn't influence empty strings
	NSRect rect;
	[textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:@""];
	[textStorage setFont:[NSFont fontWithName:@"Helvetica" size:24.0]];
	// now we should have no layout, i.e. 0
	XCTAssertEqual([layoutManager firstUnlaidGlyphIndex], 0u, @"");
	XCTAssertEqual([layoutManager firstUnlaidCharacterIndex], 0u, @"");
	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	XCTAssertEqual([layoutManager firstUnlaidGlyphIndex], 0u, @"");
	XCTAssertEqual([layoutManager firstUnlaidCharacterIndex], 0u, @"");
	// there is some default font for empty strings
	// the 10 width appears to be some default margin?
	XCTAssertEquals([layoutManager usedRectForTextContainer:textContainer], NSMakeRect(0.0, 0.0, 10.0, 14.0), @"");
	// the text container we have provided
	XCTAssertEqualObjects([layoutManager extraLineFragmentTextContainer], textContainer, @"");
	rect = [layoutManager extraLineFragmentRect];
	// we see an almost infinitely wide container
	XCTAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width >= 1e+07 && rect.size.height == 14.0, @"rect=%@", NSStringFromRect(rect));
	// the textContainer usedRect is the extraFragmentUsedRect
	XCTAssertEquals([layoutManager extraLineFragmentUsedRect], NSMakeRect(0.0, 0.0, 10.0, 14.0), @"");
}

- (void) test32
{ // do the same but with setting font attribute does influence non-empty strings
	NSRect rect;
	[textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:@"x"];
	
	// now we should have no layout, i.e. 0
	XCTAssertEqual([layoutManager firstUnlaidGlyphIndex], 0u, @"");
	XCTAssertEqual([layoutManager firstUnlaidCharacterIndex], 0u, @"");
	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	XCTAssertEqual([layoutManager firstUnlaidGlyphIndex], 1u, @"");
	XCTAssertEqual([layoutManager firstUnlaidCharacterIndex], 1u, @"");
	// there is some default font for any string with line height 14.0
	XCTAssertEquals([layoutManager usedRectForTextContainer:textContainer], NSMakeRect(0.0, 0.0, 16.0, 14.0), @"");
	// since we have some characters there is no extra line fragment
	XCTAssertEqualObjects([layoutManager extraLineFragmentTextContainer], nil, @"");
	// the rect is empty
	XCTAssertEquals([layoutManager extraLineFragmentRect], NSZeroRect, @"");
	// the rect is empty
	XCTAssertEquals([layoutManager extraLineFragmentUsedRect], NSZeroRect, @"");

	[textStorage setFont:[NSFont fontWithName:@"Helvetica" size:24.0]];

	// now we should have no layout, i.e. 0
	XCTAssertEqual([layoutManager firstUnlaidGlyphIndex], 0u, @"");
	XCTAssertEqual([layoutManager firstUnlaidCharacterIndex], 0u, @"");
	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	XCTAssertEqual([layoutManager firstUnlaidGlyphIndex], 1u, @"");
	XCTAssertEqual([layoutManager firstUnlaidCharacterIndex], 1u, @"");
	// now we see the bigger font height
	XCTAssertEquals([layoutManager usedRectForTextContainer:textContainer], NSMakeRect(0.0, 0.0, 22.0, 29.0), @"");
	// since we have some characters there is no extra line fragment
	XCTAssertEqualObjects([layoutManager extraLineFragmentTextContainer], nil, @"");
	// the rect is empty - but where does the offset 15.0 come from?
	XCTAssertEquals([layoutManager extraLineFragmentRect], NSMakeRect(0.0, 15.0, 0.0, 0.0), @"");
	// the rect is empty but starts at second line
	XCTAssertEquals([layoutManager extraLineFragmentUsedRect], NSMakeRect(0.0, 15.0, 0.0, 0.0), @"");
	
	// [textStorage setFont:nil];	// go back to default font -- this raises an exception
	[textStorage removeAttribute:NSFontAttributeName range:NSMakeRange(0, [textStorage length])];

	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	// there is some default font for any string with line height 14.0
	XCTAssertEquals([layoutManager usedRectForTextContainer:textContainer], NSMakeRect(0.0, 0.0, 16.0, 14.0), @"");
	
	[textStorage removeAttribute:NSFontAttributeName range:NSMakeRange(0, [textStorage length])];

	XCTAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"Helvetica", @"");

	[[textContainer textView] setTypingAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
												   [NSFont fontWithName:@"LucidaGrande" size:18.0],
												   NSFontAttributeName, nil]];	// set explicit typing Attributes
		
	XCTAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"LucidaGrande", @"");

	[layoutManager invalidateGlyphsOnLayoutInvalidationForGlyphRange:NSMakeRange(0, INT_MAX)];
	[layoutManager invalidateLayoutForCharacterRange:NSMakeRange(0, [textStorage length]) actualCharacterRange:NULL];
	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	rect = [layoutManager usedRectForTextContainer:textContainer];
	// we still don't see the typingAttributes because the string is not empty - but we have no NSFontAttributeName!
//	NSLog(@"%@", NSStringFromRect(rect));	
	XCTAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width >= 1e+07 && rect.size.height == 14.0, @"rect=%@", NSStringFromRect(rect));

	XCTAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"LucidaGrande", @"");

	// now wipe out the string so that there is no attribute information left over
	[textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:@""];

	XCTAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"LucidaGrande", @"");

	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	// now we should see the font height from the typing attributes
	XCTAssertEquals([layoutManager usedRectForTextContainer:textContainer], NSMakeRect(0.0, 0.0, 10.0, 21.0), @"");

	// but as soon as we have a character again, the typingAttributes are ignored
	
	[textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:@"x"];

	XCTAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"Helvetica", @"");

	// now we should have no layout, i.e. 0
	XCTAssertEqual([layoutManager firstUnlaidGlyphIndex], 0u, @"");
	XCTAssertEqual([layoutManager firstUnlaidCharacterIndex], 0u, @"");
	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	XCTAssertEqual([layoutManager firstUnlaidGlyphIndex], 1u, @"");
	XCTAssertEqual([layoutManager firstUnlaidCharacterIndex], 1u, @"");
	// there is some default font for any string with line height 14.0
	XCTAssertEquals([layoutManager usedRectForTextContainer:textContainer], NSMakeRect(0.0, 0.0, 16.0, 14.0), @"");
	// since we have some characters there is no extra line fragment
	XCTAssertEqualObjects([layoutManager extraLineFragmentTextContainer], nil, @"");
	rect = [layoutManager extraLineFragmentRect];
	// the rect is empty
	XCTAssertEquals(rect, NSZeroRect, @"");
	rect = [layoutManager extraLineFragmentUsedRect];
	// the rect is empty
	XCTAssertEquals(rect, NSZeroRect, @"");

	// so let's remove it again and the typing attributes should re-appear
	
	[textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:@""];
	
	XCTAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"Helvetica", @"");
	
	// now we should have no layout, i.e. 0
	XCTAssertEqual([layoutManager firstUnlaidGlyphIndex], 0u, @"");
	XCTAssertEqual([layoutManager firstUnlaidCharacterIndex], 0u, @"");
	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	XCTAssertEqual([layoutManager firstUnlaidGlyphIndex], 0u, @"");
	XCTAssertEqual([layoutManager firstUnlaidCharacterIndex], 0u, @"");
	// there is some default font for any string with line height 14.0
	XCTAssertEquals([layoutManager usedRectForTextContainer:textContainer], NSMakeRect(0.0, 0.0, 10.0, 14.0), @"");
	// since we have no characters there is now an extra line fragment
	XCTAssertEqualObjects([layoutManager extraLineFragmentTextContainer], textContainer, @"");
	rect = [layoutManager extraLineFragmentRect];
	// the rect is not empty
	XCTAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width >= 1e+07 && rect.size.height == 14.0, @"rect=%@", NSStringFromRect(rect));
	// the rect is not empty
	XCTAssertEquals([layoutManager extraLineFragmentUsedRect], NSMakeRect(0.0, 0.0, 10.0, 14.0), @"");
	
	
	/* conclusions
	 - typesetting characters with no font information defaults to some built-in font ([NSFont userFontOfSize:0.0])
	 - the extra Fragment uses the default height of the typingAttributes of the extraFragmenContainer's textView - if any
	 */
}

- (void) test33
{ // what happens with empty string and no NSFontAttributeName in typingAttributes?
	NSRect rect;
	[textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:@""];
	[[textContainer textView] setTypingAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
												   [NSFont fontWithName:@"LucidaGrande" size:18.0],
												   NSFontAttributeName, nil]];	// set explicit typing Attributes

	XCTAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"LucidaGrande", @"");
	
	// now we should have no layout, i.e. 0
	XCTAssertEqual([layoutManager firstUnlaidGlyphIndex], 0u, @"");
	XCTAssertEqual([layoutManager firstUnlaidCharacterIndex], 0u, @"");
	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	XCTAssertEqual([layoutManager firstUnlaidGlyphIndex], 0u, @"");
	XCTAssertEqual([layoutManager firstUnlaidCharacterIndex], 0u, @"");
	// there is some default font for empty string with line height 14.0
	XCTAssertEquals([layoutManager usedRectForTextContainer:textContainer], NSMakeRect(0.0, 0.0, 10.0, 21.0), @"");
	// since we have some characters there is no extra line fragment
	XCTAssertEqualObjects([layoutManager extraLineFragmentTextContainer], textContainer, @"");
	rect = [layoutManager extraLineFragmentRect];
	// the rect is not empty
//	NSLog(@"%@", NSStringFromRect(rect));	
	XCTAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width >= 1e+07 && rect.size.height == 21.0, @"rect=%@", NSStringFromRect(rect));
	// the rect is not empty - but width is always 10.0 (height is 125% * fontSize)
	XCTAssertEquals([layoutManager extraLineFragmentUsedRect], NSMakeRect(0.0, 0.0, 10.0, 21.0), @"");
	
	XCTAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"LucidaGrande", @"");
	
	[[textContainer textView] setTypingAttributes:[NSDictionary dictionaryWithObjectsAndKeys:nil]];	// remove explicit typing Attributes
	
	XCTAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], nil, @"");
	
	[layoutManager invalidateGlyphsOnLayoutInvalidationForGlyphRange:NSMakeRange(0, INT_MAX)];
	[layoutManager invalidateLayoutForCharacterRange:NSMakeRange(0, [textStorage length]) actualCharacterRange:NULL];
	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	// now we should see the typing attributes
	XCTAssertEquals([layoutManager usedRectForTextContainer:textContainer], NSMakeRect(0.0, 0.0, 10.0, 14.0), @"");

	// typing attributes have not been changed by layoutManager
	XCTAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], nil, @"");
	
	/* conclusions
	 - there is a hierarchy of default fonts
	 -- if empty string: font=typingAttributes
	 -- if non-empty string: font=attribute
	 -- if !font use userFontOfSize:0.0
	 - the width of the extra Fragment is always 10.0 (2*5 for some internal margin/padding?)
	 */
}

- (void) test40
{ // string drawing has a different default font metrics for empty strings
	NSRect rect;

	XCTAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"Helvetica", @"");

	// no attributes
	[textStorage removeAttribute:NSFontAttributeName range:NSMakeRange(0, [textStorage length])];

	XCTAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"Helvetica", @"");

	XCTAssertEquals([textStorage size], NSMakeSize(44.0, 60.0), @"");

	// with specific font
	[textStorage addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"LucidaGrande" size:20.0] range:NSMakeRange(0, [textStorage length])];

	XCTAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"Helvetica", @"");

	XCTAssertEquals([textStorage size], NSMakeSize(79.638671875, 96.0), @"");

	// make empty string with font
	
	[textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:@""];

	XCTAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"Helvetica", @"");

	// NOTE: this is different from asking our layoutManager for the usedRect which is 14.0 in this case!
	XCTAssertEquals([textStorage size], NSMakeSize(0.0, 15.0), @"");

	// remove font info
	
	[textStorage removeAttribute:NSFontAttributeName range:NSMakeRange(0, [textStorage length])];

	XCTAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"Helvetica", @"");

	XCTAssertEquals([textStorage size], NSMakeSize(0.0, 15.0), @"");
	
	// try the same string with our layout manager
	[layoutManager invalidateGlyphsOnLayoutInvalidationForGlyphRange:NSMakeRange(0, INT_MAX)];
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	XCTAssertEqual([layoutManager firstUnlaidGlyphIndex], 0u, @"");
	XCTAssertEqual([layoutManager firstUnlaidCharacterIndex], 0u, @"");
	// there is some default font for any string with line height 14.0 [userFontOfSize.0.0]
	XCTAssertEquals([layoutManager usedRectForTextContainer:textContainer], NSMakeRect(0.0, 0.0, 10.0, 14.0), @"");
	
	// and again with setting typingAttributes to some systemFont

	[[textContainer textView] setTypingAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
												   [NSFont systemFontOfSize:12.0],
												   NSFontAttributeName, nil]];	// set explicit typing Attributes

	[layoutManager invalidateGlyphsOnLayoutInvalidationForGlyphRange:NSMakeRange(0, INT_MAX)];
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	XCTAssertEqual([layoutManager firstUnlaidGlyphIndex], 0u, @"");
	XCTAssertEqual([layoutManager firstUnlaidCharacterIndex], 0u, @"");
	// this results in the same height as string drawing
	XCTAssertEquals([layoutManager usedRectForTextContainer:textContainer], NSMakeRect(0.0, 0.0, 10.0, 15.0), @"");
	
	/* conclusions
	 - string drawing uses a different default for empty line height (or font) than the manually set up layoutManager!
	 - typing attributes are not touched by string drawing
	 - default typing attributes are Helvetica-12
	 - most likely string drawing has its own private NSTextView with default typing attributes
	 */
	
	// FIXME: make tests out of this:
	
	// [astr boundingRectWithSize:options:0]={{0, -3}, {0, 15}}
	NSLog(@"[astr boundingRectWithSize:options:%u]=%@", 0, NSStringFromRect([textStorage boundingRectWithSize:NSMakeSize(FLT_MAX, FLT_MAX) options:0]));
	// [astr boundingRectWithSize:options:1]={{0, 0}, {0, 15}}
	NSLog(@"[astr boundingRectWithSize:options:%u]=%@", NSStringDrawingUsesLineFragmentOrigin, NSStringFromRect([textStorage boundingRectWithSize:NSMakeSize(FLT_MAX, FLT_MAX) options: NSStringDrawingUsesLineFragmentOrigin]));	
}

- (void) test99
{
	NSAttributedString *astr;
	NSDictionary *attrs=[NSDictionary dictionaryWithObjectsAndKeys:
						 [NSFont fontWithName:@"Helvetica" size:24.0], 
						 NSFontAttributeName, nil];
	// set the textView typingAttributes
	// reset them to nil
	// apply font to textStorage
	
	// FIXME: make tests out of this:

	NSLog(@"[astr size]=%@", NSStringFromSize([textStorage size]));
	NSLog(@"[astr boundingRectWithSize:options:%u]=%@", 0, NSStringFromRect([textStorage boundingRectWithSize:NSMakeSize(FLT_MAX, FLT_MAX) options:0]));
	NSLog(@"[astr boundingRectWithSize:options:%u]=%@", NSStringDrawingUsesLineFragmentOrigin, NSStringFromRect([textStorage boundingRectWithSize:NSMakeSize(FLT_MAX, FLT_MAX) options: NSStringDrawingUsesLineFragmentOrigin]));
	NSLog(@"[astr size]=%@", NSStringFromSize([textStorage size]));
	// [astr boundingRectWithSize:options:0]={{0, -3}, {0, 15}} -- single line!
	NSLog(@"[astr boundingRectWithSize:options:%u]=%@", 0, NSStringFromRect([textStorage boundingRectWithSize:NSMakeSize(FLT_MAX, FLT_MAX) options:0]));
	// [astr boundingRectWithSize:options:1]={{0, 0}, {0, 30}} -- double line
	NSLog(@"[astr boundingRectWithSize:options:%u]=%@", NSStringDrawingUsesLineFragmentOrigin, NSStringFromRect([textStorage boundingRectWithSize:NSMakeSize(FLT_MAX, FLT_MAX) options: NSStringDrawingUsesLineFragmentOrigin]));
	// change the font
	NSLog(@"[astr size]=%@", NSStringFromSize([textStorage size]));
	NSLog(@"[astr boundingRectWithSize:options:%u]=%@", 0, NSStringFromRect([textStorage boundingRectWithSize:NSMakeSize(FLT_MAX, FLT_MAX) options:0]));
	NSLog(@"[astr boundingRectWithSize:options:%u]=%@", NSStringDrawingUsesLineFragmentOrigin, NSStringFromRect([textStorage boundingRectWithSize:NSMakeSize(FLT_MAX, FLT_MAX) options: NSStringDrawingUsesLineFragmentOrigin]));
	
}
@end
