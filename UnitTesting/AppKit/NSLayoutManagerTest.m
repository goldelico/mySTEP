//
//  NSLayoutManagerTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 26.12.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import <Cocoa/Cocoa.h>


@interface NSLayoutManagerTest : SenTestCase {
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
	STAssertNotNil(textStorage, nil);
	STAssertNotNil(layoutManager, nil);
	STAssertNotNil(textContainer, nil);
	STAssertNotNil(textView, nil);
}

- (void) test02
{ // network setup is ok
	STAssertEqualObjects([textContainer textView], textView, nil);
	STAssertEqualObjects([textContainer layoutManager], layoutManager, nil);
	STAssertEqualObjects([layoutManager textStorage], textStorage, nil);
	STAssertTrue([[textStorage layoutManagers] containsObject:layoutManager], nil);
	STAssertTrue([[layoutManager textContainers] containsObject:textContainer], nil);
	STAssertEqualObjects([textView textContainer], textContainer, nil);
}

- (void) test03
{ // internal classes initialized
	STAssertNotNil([layoutManager typesetter], nil);
	STAssertNotNil([layoutManager glyphGenerator], nil);
}

- (void) test04
{ // default layout settings
	STAssertFalse([layoutManager allowsNonContiguousLayout], nil);
	STAssertFalse([layoutManager backgroundLayoutEnabled], nil);			
}

- (void) test05
{ // default typing attributes
	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"Helvetica", nil);
}

- (void) test06
{
	[[textContainer textView] setTypingAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
												   [NSFont fontWithName:@"LucidaGrande" size:18.0],
												   NSFontAttributeName, nil]];	// set explicit typing Attributes
	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"LucidaGrande", nil);
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
	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"LucidaGrande", nil);
	[[textContainer textView] setTypingAttributes:nil];	// try to clear typing attributes
//	NSLog(@"%@", [[textContainer textView] typingAttributes]);
	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"LucidaGrande", nil);
	[[textContainer textView] setTypingAttributes:[NSDictionary dictionaryWithObjectsAndKeys:nil]];	// set explicit typing Attributes
//	NSLog(@"%@", [[textContainer textView] typingAttributes]);
	STAssertNil([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], nil);
	/* conclusions
	 - it is impossible to completely clear the typing atrributes
	 - setting to nil is ignored
	 - but it is possible to set attributes without NSFontAttributeName
	 */
}

- (void) test08
{ // default layout settings
	NSSize size=[textContainer containerSize];
	STAssertEquals(size, NSMakeSize(1e+07, 1e+07), nil);
}

- (void) test10
{
	STAssertEquals([layoutManager firstUnlaidGlyphIndex], 0u, nil);
	STAssertEquals([layoutManager firstUnlaidCharacterIndex], 0u, nil);			
	[layoutManager ensureGlyphsForGlyphRange:NSMakeRange(0, 5)];
	// since we still see 0 here, firstUnlaidGlyph has nothing to do with the glyph generation
	STAssertEquals([layoutManager firstUnlaidGlyphIndex], 0u, nil);
	STAssertEquals([layoutManager firstUnlaidCharacterIndex], 0u, nil);
	/* conclusions
	 - ensuring glyphRanges has nothing to do with firstUnlaid*Index
	 - it is solely for layout
	 */
}

- (void) test11
{
	STAssertEquals([layoutManager firstUnlaidGlyphIndex], 0u, nil);
	STAssertEquals([layoutManager firstUnlaidCharacterIndex], 0u, nil);
	// this shows that we may have a stale text container assignment even if we have no valid layout!
	// it is not even clear where this comes from!
	// if we check this right after setting up the layout manger it is/was nil
	// most likely there was some initial layout phase during setUp which was reset
	STAssertEqualObjects([layoutManager textContainerForGlyphAtIndex:0 effectiveRange:NULL withoutAdditionalLayout:YES], textContainer, nil);
	STAssertEqualObjects([layoutManager textContainerForGlyphAtIndex:10 effectiveRange:NULL withoutAdditionalLayout:YES], textContainer, nil);
	[layoutManager invalidateGlyphsOnLayoutInvalidationForGlyphRange:NSMakeRange(0, 30)];
	STAssertThrows([layoutManager invalidateLayoutForCharacterRange:NSMakeRange(0, 40) actualCharacterRange:NULL], nil);
	STAssertNoThrow([layoutManager invalidateLayoutForCharacterRange:NSMakeRange(0, 30) actualCharacterRange:NULL], nil);
	// here we get nil because there is no layout for this glyph
	STAssertEquals([layoutManager firstUnlaidGlyphIndex], 0u, nil);
	STAssertEquals([layoutManager firstUnlaidCharacterIndex], 0u, nil);
	STAssertEqualObjects([layoutManager textContainerForGlyphAtIndex:0 effectiveRange:NULL withoutAdditionalLayout:YES], textContainer, nil);
	STAssertEqualObjects([layoutManager textContainerForGlyphAtIndex:10 effectiveRange:NULL withoutAdditionalLayout:YES], textContainer, nil);
	/* conclusions
	 - generating glyphs does not assign text containers
	 - there may be stale text container info attached to glyphs (probably unless we enforce additionalLayout)
	 */
}

- (void) test12
{
	STAssertEquals([layoutManager firstUnlaidGlyphIndex], 0u, nil);
	STAssertEquals([layoutManager firstUnlaidCharacterIndex], 0u, nil);
	[layoutManager ensureGlyphsForCharacterRange:NSMakeRange(0, 10)];
	// ensuring glyphs does not do any layout
	STAssertEquals([layoutManager firstUnlaidGlyphIndex], 0u, nil);
	STAssertEquals([layoutManager firstUnlaidCharacterIndex], 0u, nil);
	/* conclusions
	 - generating glyphs does not assign text containers
	 */
}

- (void) test13
{
	STAssertEquals([layoutManager firstUnlaidGlyphIndex], 0u, nil);
	STAssertEquals([layoutManager firstUnlaidCharacterIndex], 0u, nil);
	[layoutManager ensureLayoutForGlyphRange:NSMakeRange(0, 5)];
	// here we will see 7 because the first line (7 chars/glyphs) was laid out completely
	STAssertEquals([layoutManager firstUnlaidGlyphIndex], 7u, nil);
	STAssertEquals([layoutManager firstUnlaidCharacterIndex], 7u, nil);
	/* conclusions
	 - generating layout is done line by line as far as needed
	 */
}

- (void) test14
{
	STAssertEquals([layoutManager firstUnlaidGlyphIndex], 0u, nil);
	STAssertEquals([layoutManager firstUnlaidCharacterIndex], 0u, nil);
	[layoutManager ensureLayoutForGlyphRange:NSMakeRange(0, 5)];
	// now we have a text container for the first glyph -- which generates all glyphs that fit into the container
	STAssertNil([layoutManager textContainerForGlyphAtIndex:0 effectiveRange:NULL withoutAdditionalLayout:YES], nil);
	STAssertNil([layoutManager textContainerForGlyphAtIndex:7 effectiveRange:NULL withoutAdditionalLayout:YES], nil);
	STAssertNil([layoutManager textContainerForGlyphAtIndex:20 effectiveRange:NULL withoutAdditionalLayout:YES], nil);
	// here we will see all 30 glyphs (all lines!)
	STAssertEquals([layoutManager glyphRangeForTextContainer:textContainer], NSMakeRange(0, 30), nil);
	STAssertEquals([layoutManager firstUnlaidGlyphIndex], 30u, nil);
	STAssertEquals([layoutManager firstUnlaidCharacterIndex], 30u, nil);
	/* conclusions
	 * unclear
	 */
}

- (void) test20
{
	NSRect rect;
	STAssertEquals([layoutManager firstUnlaidGlyphIndex], 0u, nil);
	STAssertEquals([layoutManager firstUnlaidCharacterIndex], 0u, nil);
	// try to invalidate already invalid range - ignored
	[layoutManager invalidateLayoutForCharacterRange:NSMakeRange(7, 5) actualCharacterRange:NULL];
	STAssertEquals([layoutManager firstUnlaidGlyphIndex], 0u, nil);
	STAssertEquals([layoutManager firstUnlaidCharacterIndex], 0u, nil);
	// make full layout
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	STAssertEquals([layoutManager firstUnlaidGlyphIndex], 30u, nil);
	STAssertEquals([layoutManager firstUnlaidCharacterIndex], 30u, nil);
	rect = [layoutManager usedRectForTextContainer:textContainer];
//	NSLog(@"usedRectForTextContainer: %@", NSStringFromRect(rect));
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width >= 1e+07 && rect.size.height == 4*14.0, @"rect=%@", NSStringFromRect(rect));
	// invalidate subrange
	[layoutManager invalidateLayoutForCharacterRange:NSMakeRange(7, 5) actualCharacterRange:NULL];
	STAssertEquals([layoutManager firstUnlaidGlyphIndex], 7u, nil);
	STAssertEquals([layoutManager firstUnlaidCharacterIndex], 7u, nil);
	// should have become smaller
	rect = [layoutManager usedRectForTextContainer:textContainer];
//	NSLog(@"usedRectForTextContainer: %@", NSStringFromRect(rect));
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width >= 1e+07 && rect.size.height == 14.0, @"rect=%@", NSStringFromRect(rect));
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
	STAssertTrue([layoutManager isValidGlyphIndex:5], nil);
	STAssertTrue([layoutManager isValidGlyphIndex:10], nil);
	STAssertTrue([layoutManager isValidGlyphIndex:29], nil);
	STAssertTrue(![layoutManager isValidGlyphIndex:30], nil);
	STAssertTrue(![layoutManager isValidGlyphIndex:50], nil);
}

- (void) test22
{
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(7, 5)];
	STAssertEquals([layoutManager rangeOfNominallySpacedGlyphsContainingIndex:10], NSMakeRange(7, 7), nil);
	[layoutManager locationForGlyphAtIndex:10];	// needs calculation
	// range is unchanged, i.e. locationForGlyphAtIndex appears to interpolate locations within ranges if someone asks (e.g. CircleView)!
	STAssertEquals([layoutManager rangeOfNominallySpacedGlyphsContainingIndex:10], NSMakeRange(7, 7), nil);
	}

- (void) test30
{
	NSRect rect;
	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"Helvetica", nil);
	// try same directly on textstorage
	[textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:@""];
	// now we should have no layout, i.e. 0
	STAssertEquals([layoutManager firstUnlaidGlyphIndex], 0u, nil);
	STAssertEquals([layoutManager firstUnlaidCharacterIndex], 0u, nil);
	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	STAssertEquals([layoutManager firstUnlaidGlyphIndex], 0u, nil);
	STAssertEquals([layoutManager firstUnlaidCharacterIndex], 0u, nil);
	// there is some default font for empty strings
	STAssertEquals([layoutManager usedRectForTextContainer:textContainer], NSMakeRect(0.0, 0.0, 10.0, 14.0), nil);
	// the text container we have provided
	STAssertEqualObjects([layoutManager extraLineFragmentTextContainer], textContainer, nil);
	rect = [layoutManager extraLineFragmentRect];
	// we see an almost infinitely wide container
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width >= 1e+07 && rect.size.height == 14.0, @"rect=%@", NSStringFromRect(rect));
	// the textContainer usedRect is the extraFragmentUsedRect
	STAssertEquals([layoutManager extraLineFragmentUsedRect], NSMakeRect(0.0, 0.0, 10.0, 14.0), nil);
}

- (void) test31
{ // do the same but with setting font attribute doesn't influence empty strings
	NSRect rect;
	[textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:@""];
	[textStorage setFont:[NSFont fontWithName:@"Helvetica" size:24.0]];
	// now we should have no layout, i.e. 0
	STAssertEquals([layoutManager firstUnlaidGlyphIndex], 0u, nil);
	STAssertEquals([layoutManager firstUnlaidCharacterIndex], 0u, nil);
	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	STAssertEquals([layoutManager firstUnlaidGlyphIndex], 0u, nil);
	STAssertEquals([layoutManager firstUnlaidCharacterIndex], 0u, nil);
	// there is some default font for empty strings
	// the 10 width appears to be some default margin?
	STAssertEquals([layoutManager usedRectForTextContainer:textContainer], NSMakeRect(0.0, 0.0, 10.0, 14.0), nil);
	// the text container we have provided
	STAssertEqualObjects([layoutManager extraLineFragmentTextContainer], textContainer, nil);
	rect = [layoutManager extraLineFragmentRect];
	// we see an almost infinitely wide container
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width >= 1e+07 && rect.size.height == 14.0, @"rect=%@", NSStringFromRect(rect));
	// the textContainer usedRect is the extraFragmentUsedRect
	STAssertEquals([layoutManager extraLineFragmentUsedRect], NSMakeRect(0.0, 0.0, 10.0, 14.0), nil);
}

- (void) test32
{ // do the same but with setting font attribute does influence non-empty strings
	NSRect rect;
	[textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:@"x"];
	
	// now we should have no layout, i.e. 0
	STAssertEquals([layoutManager firstUnlaidGlyphIndex], 0u, nil);
	STAssertEquals([layoutManager firstUnlaidCharacterIndex], 0u, nil);
	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	STAssertEquals([layoutManager firstUnlaidGlyphIndex], 1u, nil);
	STAssertEquals([layoutManager firstUnlaidCharacterIndex], 1u, nil);
	// there is some default font for any string with line height 14.0
	STAssertEquals([layoutManager usedRectForTextContainer:textContainer], NSMakeRect(0.0, 0.0, 16.0, 14.0), nil);
	// since we have some characters there is no extra line fragment
	STAssertEqualObjects([layoutManager extraLineFragmentTextContainer], nil, nil);
	// the rect is empty
	STAssertEquals([layoutManager extraLineFragmentRect], NSZeroRect, nil);
	// the rect is empty
	STAssertEquals([layoutManager extraLineFragmentUsedRect], NSZeroRect, nil);

	[textStorage setFont:[NSFont fontWithName:@"Helvetica" size:24.0]];

	// now we should have no layout, i.e. 0
	STAssertEquals([layoutManager firstUnlaidGlyphIndex], 0u, nil);
	STAssertEquals([layoutManager firstUnlaidCharacterIndex], 0u, nil);
	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	STAssertEquals([layoutManager firstUnlaidGlyphIndex], 1u, nil);
	STAssertEquals([layoutManager firstUnlaidCharacterIndex], 1u, nil);
	// now we see the bigger font height
	STAssertEquals([layoutManager usedRectForTextContainer:textContainer], NSMakeRect(0.0, 0.0, 22.0, 29.0), nil);
	// since we have some characters there is no extra line fragment
	STAssertEqualObjects([layoutManager extraLineFragmentTextContainer], nil, nil);
	// the rect is empty - but where does the offset 15.0 come from?
	STAssertEquals([layoutManager extraLineFragmentRect], NSMakeRect(0.0, 15.0, 0.0, 0.0), nil);
	// the rect is empty but starts at second line
	STAssertEquals([layoutManager extraLineFragmentUsedRect], NSMakeRect(0.0, 15.0, 0.0, 0.0), nil);
	
	// [textStorage setFont:nil];	// go back to default font -- this raises an exception
	[textStorage removeAttribute:NSFontAttributeName range:NSMakeRange(0, [textStorage length])];

	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	// there is some default font for any string with line height 14.0
	STAssertEquals([layoutManager usedRectForTextContainer:textContainer], NSMakeRect(0.0, 0.0, 16.0, 14.0), nil);
	
	[textStorage removeAttribute:NSFontAttributeName range:NSMakeRange(0, [textStorage length])];

	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"Helvetica", nil);

	[[textContainer textView] setTypingAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
												   [NSFont fontWithName:@"LucidaGrande" size:18.0],
												   NSFontAttributeName, nil]];	// set explicit typing Attributes
		
	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"LucidaGrande", nil);

	[layoutManager invalidateGlyphsOnLayoutInvalidationForGlyphRange:NSMakeRange(0, INT_MAX)];
	[layoutManager invalidateLayoutForCharacterRange:NSMakeRange(0, [textStorage length]) actualCharacterRange:NULL];
	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	rect = [layoutManager usedRectForTextContainer:textContainer];
	// we still don't see the typingAttributes because the string is not empty - but we have no NSFontAttributeName!
//	NSLog(@"%@", NSStringFromRect(rect));	
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width >= 1e+07 && rect.size.height == 14.0, @"rect=%@", NSStringFromRect(rect));

	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"LucidaGrande", nil);

	// now wipe out the string so that there is no attribute information left over
	[textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:@""];

	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"LucidaGrande", nil);

	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	// now we should see the font height from the typing attributes
	STAssertEquals([layoutManager usedRectForTextContainer:textContainer], NSMakeRect(0.0, 0.0, 10.0, 21.0), nil);

	// but as soon as we have a character again, the typingAttributes are ignored
	
	[textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:@"x"];

	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"Helvetica", nil);

	// now we should have no layout, i.e. 0
	STAssertEquals([layoutManager firstUnlaidGlyphIndex], 0u, nil);
	STAssertEquals([layoutManager firstUnlaidCharacterIndex], 0u, nil);
	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	STAssertEquals([layoutManager firstUnlaidGlyphIndex], 1u, nil);
	STAssertEquals([layoutManager firstUnlaidCharacterIndex], 1u, nil);
	// there is some default font for any string with line height 14.0
	STAssertEquals([layoutManager usedRectForTextContainer:textContainer], NSMakeRect(0.0, 0.0, 16.0, 14.0), nil);
	// since we have some characters there is no extra line fragment
	STAssertEqualObjects([layoutManager extraLineFragmentTextContainer], nil, nil);
	rect = [layoutManager extraLineFragmentRect];
	// the rect is empty
	STAssertEquals(rect, NSZeroRect, nil);
	rect = [layoutManager extraLineFragmentUsedRect];
	// the rect is empty
	STAssertEquals(rect, NSZeroRect, nil);

	// so let's remove it again and the typing attributes should re-appear
	
	[textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:@""];
	
	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"Helvetica", nil);
	
	// now we should have no layout, i.e. 0
	STAssertEquals([layoutManager firstUnlaidGlyphIndex], 0u, nil);
	STAssertEquals([layoutManager firstUnlaidCharacterIndex], 0u, nil);
	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	STAssertEquals([layoutManager firstUnlaidGlyphIndex], 0u, nil);
	STAssertEquals([layoutManager firstUnlaidCharacterIndex], 0u, nil);
	// there is some default font for any string with line height 14.0
	STAssertEquals([layoutManager usedRectForTextContainer:textContainer], NSMakeRect(0.0, 0.0, 10.0, 14.0), nil);
	// since we have no characters there is now an extra line fragment
	STAssertEqualObjects([layoutManager extraLineFragmentTextContainer], textContainer, nil);
	rect = [layoutManager extraLineFragmentRect];
	// the rect is not empty
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width >= 1e+07 && rect.size.height == 14.0, @"rect=%@", NSStringFromRect(rect));
	// the rect is not empty
	STAssertEquals([layoutManager extraLineFragmentUsedRect], NSMakeRect(0.0, 0.0, 10.0, 14.0), nil);
	
	
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

	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"LucidaGrande", nil);
	
	// now we should have no layout, i.e. 0
	STAssertEquals([layoutManager firstUnlaidGlyphIndex], 0u, nil);
	STAssertEquals([layoutManager firstUnlaidCharacterIndex], 0u, nil);
	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	STAssertEquals([layoutManager firstUnlaidGlyphIndex], 0u, nil);
	STAssertEquals([layoutManager firstUnlaidCharacterIndex], 0u, nil);
	// there is some default font for empty string with line height 14.0
	STAssertEquals([layoutManager usedRectForTextContainer:textContainer], NSMakeRect(0.0, 0.0, 10.0, 21.0), nil);
	// since we have some characters there is no extra line fragment
	STAssertEqualObjects([layoutManager extraLineFragmentTextContainer], textContainer, nil);
	rect = [layoutManager extraLineFragmentRect];
	// the rect is not empty
//	NSLog(@"%@", NSStringFromRect(rect));	
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width >= 1e+07 && rect.size.height == 21.0, @"rect=%@", NSStringFromRect(rect));
	// the rect is not empty - but width is always 10.0 (height is 125% * fontSize)
	STAssertEquals([layoutManager extraLineFragmentUsedRect], NSMakeRect(0.0, 0.0, 10.0, 21.0), nil);
	
	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"LucidaGrande", nil);
	
	[[textContainer textView] setTypingAttributes:[NSDictionary dictionaryWithObjectsAndKeys:nil]];	// remove explicit typing Attributes
	
	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], nil, nil);
	
	[layoutManager invalidateGlyphsOnLayoutInvalidationForGlyphRange:NSMakeRange(0, INT_MAX)];
	[layoutManager invalidateLayoutForCharacterRange:NSMakeRange(0, [textStorage length]) actualCharacterRange:NULL];
	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	// now we should see the typing attributes
	STAssertEquals([layoutManager usedRectForTextContainer:textContainer], NSMakeRect(0.0, 0.0, 10.0, 14.0), nil);

	// typing attributes have not been changed by layoutManager
	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], nil, nil);
	
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

	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"Helvetica", nil);

	// no attributes
	[textStorage removeAttribute:NSFontAttributeName range:NSMakeRange(0, [textStorage length])];

	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"Helvetica", nil);

	STAssertEquals([textStorage size], NSMakeSize(44.0, 60.0), nil);

	// with specific font
	[textStorage addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"LucidaGrande" size:20.0] range:NSMakeRange(0, [textStorage length])];

	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"Helvetica", nil);

	STAssertEquals([textStorage size], NSMakeSize(79.638671875, 96.0), nil);

	// make empty string with font
	
	[textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:@""];

	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"Helvetica", nil);

	// NOTE: this is different from asking our layoutManager for the usedRect which is 14.0 in this case!
	STAssertEquals([textStorage size], NSMakeSize(0.0, 15.0), nil);

	// remove font info
	
	[textStorage removeAttribute:NSFontAttributeName range:NSMakeRange(0, [textStorage length])];

	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"Helvetica", nil);

	STAssertEquals([textStorage size], NSMakeSize(0.0, 15.0), nil);
	
	// try the same string with our layout manager
	[layoutManager invalidateGlyphsOnLayoutInvalidationForGlyphRange:NSMakeRange(0, INT_MAX)];
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	STAssertEquals([layoutManager firstUnlaidGlyphIndex], 0u, nil);
	STAssertEquals([layoutManager firstUnlaidCharacterIndex], 0u, nil);
	// there is some default font for any string with line height 14.0 [userFontOfSize.0.0]
	STAssertEquals([layoutManager usedRectForTextContainer:textContainer], NSMakeRect(0.0, 0.0, 10.0, 14.0), nil);
	
	// and again with setting typingAttributes to some systemFont

	[[textContainer textView] setTypingAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
												   [NSFont systemFontOfSize:12.0],
												   NSFontAttributeName, nil]];	// set explicit typing Attributes

	[layoutManager invalidateGlyphsOnLayoutInvalidationForGlyphRange:NSMakeRange(0, INT_MAX)];
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	STAssertEquals([layoutManager firstUnlaidGlyphIndex], 0u, nil);
	STAssertEquals([layoutManager firstUnlaidCharacterIndex], 0u, nil);
	// this results in the same height as string drawing
	STAssertEquals([layoutManager usedRectForTextContainer:textContainer], NSMakeRect(0.0, 0.0, 10.0, 15.0), nil);
	
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
