//
//  NSLayoutManagerTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 26.12.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "NSLayoutManagerTest.h"


@implementation NSLayoutManagerTest

- (void) setUp;	// runs before each test
{
	NSLog(@"setUp");
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
	[layoutManager invalidateGlyphsOnLayoutInvalidationForGlyphRange:NSMakeRange(0, INT_MAX)];
	[layoutManager invalidateLayoutForCharacterRange:NSMakeRange(0, [textStorage length]) actualCharacterRange:NULL];
}

- (void) tearDown;	// runs after each test
{
	NSLog(@"tearDown");
	[textStorage release];
}

- (void) test01
{ // allocation did work
	STAssertTrue(textStorage != nil, nil);
	STAssertTrue(layoutManager != nil, nil);
	STAssertTrue(textContainer != nil, nil);
	STAssertTrue(textView != nil, nil);
}

- (void) test02
{ // network setup is ok
	STAssertTrue([textContainer textView] == textView, nil);
	STAssertTrue([textContainer layoutManager] == layoutManager, nil);
	STAssertTrue([layoutManager textStorage] == textStorage, nil);
	STAssertTrue([[textStorage layoutManagers] containsObject:layoutManager], nil);
	STAssertTrue([[layoutManager textContainers] containsObject:textContainer], nil);
	STAssertTrue([textView textContainer] == textContainer, nil);
}

- (void) test03
{ // internal classes initialized
	STAssertTrue([layoutManager typesetter] != nil, nil);
	STAssertTrue([layoutManager glyphGenerator] != nil, nil);
}

- (void) test04
{ // default layout settings
	STAssertTrue([layoutManager allowsNonContiguousLayout] == NO, nil);
	STAssertTrue([layoutManager backgroundLayoutEnabled] == NO, nil);			
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
	NSLog(@"%@", [[textContainer textView] typingAttributes]);
	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"LucidaGrande", nil);
	[[textContainer textView] setTypingAttributes:nil];	// clear typing attributes
	NSLog(@"%@", [[textContainer textView] typingAttributes]);
	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"LucidaGrande", nil);
	[[textContainer textView] setTypingAttributes:[NSDictionary dictionaryWithObjectsAndKeys:nil]];	// set explicit typing Attributes
	NSLog(@"%@", [[textContainer textView] typingAttributes]);
	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], nil, nil);
	/* conclusions
	 - it is impossible to completely clear the typing atrributes
	 - setting to nil is ignored
	 - but it is possible to set attributes without NSFontAttributeName
	 */
}

- (void) test08
{ // default layout settings
	NSSize size=[textContainer containerSize];
	NSLog(@"%@", NSStringFromSize(size));
	STAssertTrue(size.width == 1e+07 && size.height == 1e+07, nil);
}

- (void) test10
{
	STAssertTrue([layoutManager firstUnlaidGlyphIndex] == 0, nil);
	STAssertTrue([layoutManager firstUnlaidCharacterIndex] == 0, nil);			
	[layoutManager ensureGlyphsForGlyphRange:NSMakeRange(0, 5)];
	// since we still see 0 here, firstUnlaidGlyph has nothing to do with the glyph generation
	STAssertTrue([layoutManager firstUnlaidGlyphIndex] == 0, nil);
	STAssertTrue([layoutManager firstUnlaidCharacterIndex] == 0, nil);
	/* conclusions
	 - ensuring glyphRanges has nothing to do with firstUnlaid*Index
	 - it is solely for layout
	 */
}

- (void) test11
{
	STAssertTrue([layoutManager firstUnlaidGlyphIndex] == 0, nil);
	STAssertTrue([layoutManager firstUnlaidCharacterIndex] == 0, nil);
	// this shows that we may have a stale text container assignment even if we have no valid layout!
	// it is not even clear where this comes from!
	// if we check this right after setting up the layout manger it is/was nil
	// most likely there was some initial layout phase during setUp which was reset
	STAssertTrue([layoutManager textContainerForGlyphAtIndex:0 effectiveRange:NULL withoutAdditionalLayout:YES] == textContainer, nil);
	STAssertTrue([layoutManager textContainerForGlyphAtIndex:10 effectiveRange:NULL withoutAdditionalLayout:YES] == textContainer, nil);
	[layoutManager invalidateGlyphsOnLayoutInvalidationForGlyphRange:NSMakeRange(0, 30)];
	STAssertThrows([layoutManager invalidateLayoutForCharacterRange:NSMakeRange(0, 40) actualCharacterRange:NULL], nil);
	STAssertNoThrow([layoutManager invalidateLayoutForCharacterRange:NSMakeRange(0, 30) actualCharacterRange:NULL], nil);
	// here we get nil because there is no layout for this glyph
	STAssertTrue([layoutManager firstUnlaidGlyphIndex] == 0, nil);
	STAssertTrue([layoutManager firstUnlaidCharacterIndex] == 0, nil);
	STAssertTrue([layoutManager textContainerForGlyphAtIndex:0 effectiveRange:NULL withoutAdditionalLayout:YES] == textContainer, nil);
	STAssertTrue([layoutManager textContainerForGlyphAtIndex:10 effectiveRange:NULL withoutAdditionalLayout:YES] == textContainer, nil);
	/* conclusions
	 - generating glyphs does not assign text containers
	 - there may be stale text container info attached to glyphs (probably unless we enforce additionalLayout)
	 */
}

- (void) test12
{
	STAssertTrue([layoutManager firstUnlaidGlyphIndex] == 0, nil);
	STAssertTrue([layoutManager firstUnlaidCharacterIndex] == 0, nil);			
	[layoutManager ensureGlyphsForCharacterRange:NSMakeRange(0, 10)];
	// ensuring glyphs does not do any layout
	STAssertTrue([layoutManager firstUnlaidGlyphIndex] == 0, nil);
	STAssertTrue([layoutManager firstUnlaidCharacterIndex] == 0, nil);			
	/* conclusions
	 - generating glyphs does not assign text containers
	 */
}

- (void) test13
{
	STAssertTrue([layoutManager firstUnlaidGlyphIndex] == 0, nil);
	STAssertTrue([layoutManager firstUnlaidCharacterIndex] == 0, nil);			
	[layoutManager ensureLayoutForGlyphRange:NSMakeRange(0, 5)];
	// here we will see 7 because the first line (7 chars/glyphs) was laid out completely
	STAssertTrue([layoutManager firstUnlaidGlyphIndex] == 7, nil);
	STAssertTrue([layoutManager firstUnlaidCharacterIndex] == 7, nil);			
	/* conclusions
	 - generating layout works line by line
	 */
}

- (void) test14
{
	NSRange glyphRange;
	STAssertTrue([layoutManager firstUnlaidGlyphIndex] == 0, nil);
	STAssertTrue([layoutManager firstUnlaidCharacterIndex] == 0, nil);			
	[layoutManager ensureLayoutForGlyphRange:NSMakeRange(0, 5)];
	// now we have a text container for the first glyph -- which generates all glyphs that fit into the container
	STAssertTrue([layoutManager textContainerForGlyphAtIndex:0 effectiveRange:NULL withoutAdditionalLayout:YES] != nil, nil);
	STAssertTrue([layoutManager textContainerForGlyphAtIndex:7 effectiveRange:NULL withoutAdditionalLayout:YES] == nil, nil);
	STAssertTrue([layoutManager textContainerForGlyphAtIndex:20 effectiveRange:NULL withoutAdditionalLayout:YES] == nil, nil);
	glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
	// here we will see all 30 glyphs (all lines!)
	STAssertTrue(glyphRange.location == 0 && glyphRange.length == 30, nil);
	STAssertTrue([layoutManager firstUnlaidGlyphIndex] == 30, nil);
	STAssertTrue([layoutManager firstUnlaidCharacterIndex] == 30, nil);		
}

- (void) test20
{
	NSRect rect;
	STAssertTrue([layoutManager firstUnlaidGlyphIndex] == 0, nil);
	STAssertTrue([layoutManager firstUnlaidCharacterIndex] == 0, nil);
	// try to invalidate already invalid range - ignored
	[layoutManager invalidateLayoutForCharacterRange:NSMakeRange(7, 5) actualCharacterRange:NULL];
	STAssertTrue([layoutManager firstUnlaidGlyphIndex] == 0, nil);
	STAssertTrue([layoutManager firstUnlaidCharacterIndex] == 0, nil);
	// make full layout
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	STAssertTrue([layoutManager firstUnlaidGlyphIndex] == 30, nil);
	STAssertTrue([layoutManager firstUnlaidCharacterIndex] == 30, nil);	// everything done
	rect = [layoutManager usedRectForTextContainer:textContainer];
	NSLog(@"usedRectForTextContainer: %@", NSStringFromRect(rect));
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width >= 1e+07 && rect.size.height == 4*14.0, nil);
	// invalidate subrange
	[layoutManager invalidateLayoutForCharacterRange:NSMakeRange(7, 5) actualCharacterRange:NULL];
//	NSLog(@"%u", [layoutManager firstUnlaidGlyphIndex]);
	STAssertTrue([layoutManager firstUnlaidGlyphIndex] == 7, nil);
	STAssertTrue([layoutManager firstUnlaidCharacterIndex] == 7, nil);
	// should have become smaller
	rect = [layoutManager usedRectForTextContainer:textContainer];
//	NSLog(@"usedRectForTextContainer: %@", NSStringFromRect(rect));
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width >= 1e+07 && rect.size.height == 14.0, nil);
	/* conclusions
	 - invalidation of already invalid ranges is ignored
	 - invalidation reset the firstUnlaid*Index to the beginning
	 - usedRect is reduced
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
	NSRange rng;
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(7, 5)];
	rng=[layoutManager rangeOfNominallySpacedGlyphsContainingIndex:10];	// returns range {7, 7}
	STAssertTrue(rng.location == 7 && rng.length == 7, nil);
	[layoutManager locationForGlyphAtIndex:10];	// needs calculation
	// range is unchanged, i.e. locationForGlyphAtIndex appears to interpolate locations within ranges if someone asks (e.g. CircleView)!
	rng=[layoutManager rangeOfNominallySpacedGlyphsContainingIndex:10];
	STAssertTrue(rng.location == 7 && rng.length == 7, nil);
	}

- (void) test30
{
	NSRect rect;
	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"Helvetica", nil);
	// try same directly on textstorage
	[textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:@""];
	// now we should have no layout, i.e. 0
	STAssertTrue([layoutManager firstUnlaidGlyphIndex] == 0, nil);
	STAssertTrue([layoutManager firstUnlaidCharacterIndex] == 0, nil);
	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	STAssertTrue([layoutManager firstUnlaidGlyphIndex] == 0, nil);
	STAssertTrue([layoutManager firstUnlaidCharacterIndex] == 0, nil);
	rect = [layoutManager usedRectForTextContainer:textContainer];
	// there is some default font for empty strings
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width == 10.0 && rect.size.height == 14.0, nil);
	// the text container we have provided
	STAssertEqualObjects([layoutManager extraLineFragmentTextContainer], textContainer, nil);
	rect = [layoutManager extraLineFragmentRect];
	// we see an almost infinitely wide container
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width >= 1e+07 && rect.size.height == 14.0, nil);
	rect = [layoutManager extraLineFragmentUsedRect];
	// the textContainer usedRect is the extraFragmentUsedRect
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width == 10 && rect.size.height == 14.0, nil);
}

- (void) test31
{ // do the same but with setting font attribute doesn't influence empty strings
	NSRect rect;
	[textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:@""];
	[textStorage setFont:[NSFont fontWithName:@"Helvetica" size:24.0]];
	// now we should have no layout, i.e. 0
	STAssertTrue([layoutManager firstUnlaidGlyphIndex] == 0, nil);
	STAssertTrue([layoutManager firstUnlaidCharacterIndex] == 0, nil);
	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	STAssertTrue([layoutManager firstUnlaidGlyphIndex] == 0, nil);
	STAssertTrue([layoutManager firstUnlaidCharacterIndex] == 0, nil);
	rect = [layoutManager usedRectForTextContainer:textContainer];
	// there is some default font for empty strings
	// the 10 width appears to be some default margin?
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width == 10.0 && rect.size.height == 14.0, nil);
	// the text container we have provided
	STAssertEqualObjects([layoutManager extraLineFragmentTextContainer], textContainer, nil);
	rect = [layoutManager extraLineFragmentRect];
	// we see an almost infinitely wide container
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width >= 1e+07 && rect.size.height == 14.0, nil);
	rect = [layoutManager extraLineFragmentUsedRect];
	// the textContainer usedRect is the extraFragmentUsedRect
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width == 10 && rect.size.height == 14.0, nil);
}

- (void) test32
{ // do the same but with setting font attribute does influence non-empty strings
	NSRect rect;
	[textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:@"x"];
	
	// now we should have no layout, i.e. 0
	STAssertTrue([layoutManager firstUnlaidGlyphIndex] == 0, nil);
	STAssertTrue([layoutManager firstUnlaidCharacterIndex] == 0, nil);
	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	STAssertTrue([layoutManager firstUnlaidGlyphIndex] == 1, nil);
	STAssertTrue([layoutManager firstUnlaidCharacterIndex] == 1, nil);
	rect = [layoutManager usedRectForTextContainer:textContainer];
	// there is some default font for any string with line height 14.0
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width == 16.0 && rect.size.height == 14.0, nil);	
	// since we have some characters there is no extra line fragment
	STAssertEqualObjects([layoutManager extraLineFragmentTextContainer], nil, nil);
	rect = [layoutManager extraLineFragmentRect];
	// the rect is empty
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width == 0.0 && rect.size.height == 0.0, nil);
	rect = [layoutManager extraLineFragmentUsedRect];
	// the rect is empty
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width == 0.0 && rect.size.height == 0.0, nil);

	[textStorage setFont:[NSFont fontWithName:@"Helvetica" size:24.0]];

	// now we should have no layout, i.e. 0
	STAssertTrue([layoutManager firstUnlaidGlyphIndex] == 0, nil);
	STAssertTrue([layoutManager firstUnlaidCharacterIndex] == 0, nil);
	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	STAssertTrue([layoutManager firstUnlaidGlyphIndex] == 1, nil);
	STAssertTrue([layoutManager firstUnlaidCharacterIndex] == 1, nil);
	rect = [layoutManager usedRectForTextContainer:textContainer];
	// now we see the bigger font height
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width == 22.0 && rect.size.height == 29.0, nil);
	// since we have some characters there is no extra line fragment
	STAssertEqualObjects([layoutManager extraLineFragmentTextContainer], nil, nil);
	rect = [layoutManager extraLineFragmentRect];
	// the rect is empty - but where does the offset 15.0 come from?
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 15.0 && rect.size.width == 0.0 && rect.size.height == 0.0, nil);
	rect = [layoutManager extraLineFragmentUsedRect];
//	NSLog(@"%@", NSStringFromRect(rect));
	// the rect is empty
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 15.0 && rect.size.width == 0.0 && rect.size.height == 0.0, nil);
	
	// [textStorage setFont:nil];	// go back to default font -- this raises an exception
	[textStorage removeAttribute:NSFontAttributeName range:NSMakeRange(0, [textStorage length])];

	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	rect = [layoutManager usedRectForTextContainer:textContainer];
	// there is some default font for any string with line height 14.0
//	NSLog(@"%@", NSStringFromRect(rect));
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width == 16.0 && rect.size.height == 14.0, nil);	
	
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
	NSLog(@"%@", NSStringFromRect(rect));	
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width >= 1e+07 && rect.size.height == 14.0, nil);

	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"LucidaGrande", nil);

	// now wipe out the string so that there is no attribute information left over
	[textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:@""];

	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"LucidaGrande", nil);

	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	rect = [layoutManager usedRectForTextContainer:textContainer];
	// now we should see the font height from the typing attributes
	NSLog(@"%@", NSStringFromRect(rect));	
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width == 10.0 && rect.size.height == 21.0, nil);	

	// but as soon as we have a character again, the typingAttributes are ignored
	
	[textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:@"x"];

	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"Helvetica", nil);

	// now we should have no layout, i.e. 0
	STAssertTrue([layoutManager firstUnlaidGlyphIndex] == 0, nil);
	STAssertTrue([layoutManager firstUnlaidCharacterIndex] == 0, nil);
	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	STAssertTrue([layoutManager firstUnlaidGlyphIndex] == 1, nil);
	STAssertTrue([layoutManager firstUnlaidCharacterIndex] == 1, nil);
	rect = [layoutManager usedRectForTextContainer:textContainer];
	// there is some default font for any string with line height 14.0
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width == 16.0 && rect.size.height == 14.0, nil);	
	// since we have some characters there is no extra line fragment
	STAssertEqualObjects([layoutManager extraLineFragmentTextContainer], nil, nil);
	rect = [layoutManager extraLineFragmentRect];
	// the rect is empty
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width == 0.0 && rect.size.height == 0.0, nil);
	rect = [layoutManager extraLineFragmentUsedRect];
	// the rect is empty
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width == 0.0 && rect.size.height == 0.0, nil);

	// so let's remove it again and the typing attributes should re-appear
	
	[textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:@""];
	
	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"Helvetica", nil);
	
	// now we should have no layout, i.e. 0
	STAssertTrue([layoutManager firstUnlaidGlyphIndex] == 0, nil);
	STAssertTrue([layoutManager firstUnlaidCharacterIndex] == 0, nil);
	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	STAssertTrue([layoutManager firstUnlaidGlyphIndex] == 0, nil);
	STAssertTrue([layoutManager firstUnlaidCharacterIndex] == 0, nil);
	rect = [layoutManager usedRectForTextContainer:textContainer];
	// there is some default font for any string with line height 14.0
	NSLog(@"%@", NSStringFromRect(rect));	
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width == 10.0 && rect.size.height == 14.0, nil);	
	// since we have no characters there is now an extra line fragment
	STAssertEqualObjects([layoutManager extraLineFragmentTextContainer], textContainer, nil);
	rect = [layoutManager extraLineFragmentRect];
	NSLog(@"%@", NSStringFromRect(rect));	
	// the rect is not empty
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width >= 1e+07 && rect.size.height == 14.0, nil);
	rect = [layoutManager extraLineFragmentUsedRect];
	NSLog(@"%@", NSStringFromRect(rect));	
	// the rect is not empty
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width == 10.0 && rect.size.height == 14.0, nil);
	
	
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
	STAssertTrue([layoutManager firstUnlaidGlyphIndex] == 0, nil);
	STAssertTrue([layoutManager firstUnlaidCharacterIndex] == 0, nil);
	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	STAssertTrue([layoutManager firstUnlaidGlyphIndex] == 0, nil);
	STAssertTrue([layoutManager firstUnlaidCharacterIndex] == 0, nil);
	rect = [layoutManager usedRectForTextContainer:textContainer];
	NSLog(@"%@", NSStringFromRect(rect));
	// there is some default font for empty string with line height 14.0
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width == 10.0 && rect.size.height == 21.0, nil);	
	// since we have some characters there is no extra line fragment
	STAssertEqualObjects([layoutManager extraLineFragmentTextContainer], textContainer, nil);
	rect = [layoutManager extraLineFragmentRect];
	// the rect is not empty
	NSLog(@"%@", NSStringFromRect(rect));	
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width >= 1e+07 && rect.size.height == 21.0, nil);
	rect = [layoutManager extraLineFragmentUsedRect];
	// the rect is not empty - but width is always 10.0 (height is 125% * fontSize)
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width == 10.0 && rect.size.height == 21.0, nil);
	
	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"LucidaGrande", nil);
	
	[[textContainer textView] setTypingAttributes:[NSDictionary dictionaryWithObjectsAndKeys:nil]];	// remove explicit typing Attributes
	
	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], nil, nil);
	
	[layoutManager invalidateGlyphsOnLayoutInvalidationForGlyphRange:NSMakeRange(0, INT_MAX)];
	[layoutManager invalidateLayoutForCharacterRange:NSMakeRange(0, [textStorage length]) actualCharacterRange:NULL];
	// we must ensure the layout because usedRectForTextContainer does not
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	rect = [layoutManager usedRectForTextContainer:textContainer];
	// now we should see the typing attributes
	NSLog(@"%@", NSStringFromRect(rect));	
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width == 10.0 && rect.size.height == 14.0, nil);

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
	NSSize size;
	NSRect rect;

	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"Helvetica", nil);

	// no attributes
	[textStorage removeAttribute:NSFontAttributeName range:NSMakeRange(0, [textStorage length])];

	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"Helvetica", nil);

	size=[textStorage size];
	NSLog(@"%@", NSStringFromSize(size));
	STAssertTrue(size.width == 44.0 && size.height == 60.0, nil);

	// with specific font
	[textStorage addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"LucidaGrande" size:20.0] range:NSMakeRange(0, [textStorage length])];

	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"Helvetica", nil);

	size=[textStorage size];
	NSLog(@"%@ %.10f", NSStringFromSize(size), size.width);
	STAssertTrue(size.width == 79.638671875 && size.height == 96.0, nil);

	// make empty string with font
	
	[textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:@""];

	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"Helvetica", nil);

	size=[textStorage size];
	NSLog(@"%@", NSStringFromSize(size));
	// NOTE: this is different from asking our layoutManager for the usedRect which is 14.0 in this case!
	STAssertTrue(size.width == 0.0 && size.height == 15.0, nil);

	// remove font info
	
	[textStorage removeAttribute:NSFontAttributeName range:NSMakeRange(0, [textStorage length])];

	STAssertEqualObjects([[[[textContainer textView] typingAttributes] objectForKey:NSFontAttributeName] fontName], @"Helvetica", nil);

	size=[textStorage size];
	NSLog(@"%@", NSStringFromSize(size));
	STAssertTrue(size.width == 0.0 && size.height == 15.0, nil);
	
	// try the same string with our layout manager
	[layoutManager invalidateGlyphsOnLayoutInvalidationForGlyphRange:NSMakeRange(0, INT_MAX)];
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	STAssertTrue([layoutManager firstUnlaidGlyphIndex] == 0, nil);
	STAssertTrue([layoutManager firstUnlaidCharacterIndex] == 0, nil);
	rect = [layoutManager usedRectForTextContainer:textContainer];
	// there is some default font for any string with line height 14.0 [userFontOfSize.0.0]
	NSLog(@"%@", NSStringFromRect(rect));	
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width == 10.0 && rect.size.height == 14.0, nil);
	
	// and again with setting typingAttributes to some systemFont

	[[textContainer textView] setTypingAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
												   [NSFont systemFontOfSize:12.0],
												   NSFontAttributeName, nil]];	// set explicit typing Attributes

	[layoutManager invalidateGlyphsOnLayoutInvalidationForGlyphRange:NSMakeRange(0, INT_MAX)];
	[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
	STAssertTrue([layoutManager firstUnlaidGlyphIndex] == 0, nil);
	STAssertTrue([layoutManager firstUnlaidCharacterIndex] == 0, nil);
	rect = [layoutManager usedRectForTextContainer:textContainer];
	// this results in the same height as string drawing
	NSLog(@"%@", NSStringFromRect(rect));	
	STAssertTrue(rect.origin.x == 0.0 && rect.origin.y == 0.0 && rect.size.width == 10.0 && rect.size.height == 15.0, nil);
	
	/* conclusions
	 - string drawing uses a different default for empty line height (or font) than the manually set up layoutManager!
	 - typing attributes are not touched by string drawing
	 - default typing attributes are Helvetica-12
	 - most likely string drawing has its own private NSTextView with default typing attributes
	 */
	
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
