/*
 NSLayoutManager.m
 
 Author:	H. N. Schaller <hns@computer.org>
 Date:	Jun 2006
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */

#import <Foundation/Foundation.h>
#import <AppKit/NSLayoutManager.h>
#import <AppKit/NSTextContainer.h>
#import <AppKit/NSTextView.h>
#import <AppKit/NSTextStorage.h>
#import <AppKit/NSTypesetter.h>

#import "NSBackendPrivate.h"

#define OLD	1

@implementation NSGlyphGenerator

+ (id) sharedGlyphGenerator;
{ // a single shared instance
	static NSGlyphGenerator *sharedGlyphGenerator;
	if(!sharedGlyphGenerator)
		sharedGlyphGenerator=[[self alloc] init];
	return sharedGlyphGenerator;
}

- (void) generateGlyphsForGlyphStorage:(id <NSGlyphStorage>) storage
			 desiredNumberOfCharacters:(unsigned int) num
							glyphIndex:(unsigned int *) glyph
						characterIndex:(unsigned int *) index;
{
	BACKEND;	// overwritten by category in backend (NSFreeTypeFont.m) where we know font metrics and glyph codes
}

@end

@implementation NSTypesetter

+ (NSTypesetterBehavior) defaultTypesetterBehavior;
{
	return NSTypesetterLatestBehavior;
}

+ (NSSize) printingAdjustmentInLayoutManager:(NSLayoutManager *) manager 
				forNominallySpacedGlyphRange:(NSRange) range 
								packedGlyphs:(const unsigned char *) glyphs
									   count:(NSUInteger) count;
{
	NIMP;
	return NSZeroSize;
}

static id _sharedSystemTypesetter;

+ (id) sharedSystemTypesetter;
{
	return [self sharedSystemTypesetterForBehavior:[self defaultTypesetterBehavior]];
}

+ (id) sharedSystemTypesetterForBehavior:(NSTypesetterBehavior) behavior;
{
	if(!_sharedSystemTypesetter)
		{
		_sharedSystemTypesetter=[[self alloc] init];
		[_sharedSystemTypesetter setTypesetterBehavior:[NSTypesetter defaultTypesetterBehavior]];		
		}
	return _sharedSystemTypesetter;
}

- (NSTypesetterControlCharacterAction) actionForControlCharacterAtIndex:(NSUInteger) location;
{ // default action - can be overwritten in subclass typesetter
	// modify action based on
	[_layoutManager showsControlCharacters];
	[_layoutManager showsInvisibleCharacters];
	switch([[_attributedString string] characterAtIndex:location]) {
		case '\t': return NSTypesetterHorizontalTabAction;
		case '\n': return NSTypesetterParagraphBreakAction;
		case ' ': return NSTypesetterWhitespaceAction;
		case NSAttachmentCharacter: return 0;
	}
	return 0;
}

- (NSAttributedString *) attributedString;
{
	return _attributedString;
}

- (NSDictionary *) attributesForExtraLineFragment;
{
	return NIMP;
}

- (CGFloat) baselineOffsetInLayoutManager:(NSLayoutManager *) manager glyphIndex:(NSUInteger) index;
{
	NIMP;
	return 0.0;
}

- (void) beginLineWithGlyphAtIndex:(NSUInteger) index;
{
	NIMP;
}

- (void) beginParagraph;
{
	NIMP;
}

- (BOOL) bidiProcessingEnabled;
{
	return _bidiProcessingEnabled;
}

- (NSRect) boundingBoxForControlGlyphAtIndex:(NSUInteger) glyph 
							forTextContainer:(NSTextContainer *) container 
						proposedLineFragment:(NSRect) rect 
							   glyphPosition:(NSPoint) position 
							  characterIndex:(NSUInteger) index;
{
	return NSZeroRect;
}

- (NSRange) characterRangeForGlyphRange:(NSRange) range 
					   actualGlyphRange:(NSRangePointer) rangePt;
{
	
}

- (NSParagraphStyle *) currentParagraphStyle;
{
	return _currentParagraphStyle;
}

- (NSTextContainer *) currentTextContainer;
{
	return _currentTextContainer;
}

- (void) deleteGlyphsInRange:(NSRange) range;
{
	
}

- (void) endLineWithGlyphRange:(NSRange) range;
{
	
}

- (void) endParagraph;
{
	
}

- (NSUInteger) getGlyphsInRange:(NSRange) range 
						 glyphs:(NSGlyph *) glyphs 
			   characterIndexes:(NSUInteger *) idxs 
			  glyphInscriptions:(NSGlyphInscription *) inscBuffer 
					elasticBits:(BOOL *) flag 
					 bidiLevels:(unsigned char *) bidiLevels;
{
	
}

- (void) getLineFragmentRect:(NSRectPointer) fragRect 
					usedRect:(NSRectPointer) fragUsedRect 
forParagraphSeparatorGlyphRange:(NSRange) range 
			atProposedOrigin:(NSPoint) origin;
{
	
}

- (void) getLineFragmentRect:(NSRectPointer) lineFragmentRect 
					usedRect:(NSRectPointer) lineFragmentUsedRect 
			   remainingRect:(NSRectPointer) remRect 
	 forStartingGlyphAtIndex:(NSUInteger) startIndex 
				proposedRect:(NSRect) propRect 
				 lineSpacing:(CGFloat) spacing 
	  paragraphSpacingBefore:(CGFloat) paragSpacBefore 
	   paragraphSpacingAfter:(CGFloat) paragSpacAfter;
{
	
}

- (NSRange) glyphRangeForCharacterRange:(NSRange) range 
				   actualCharacterRange:(NSRangePointer) rangePt;
{
	
}

- (float) hyphenationFactor;
{
	return [_layoutManager hyphenationFactor];
}

- (float) hyphenationFactorForGlyphAtIndex:(NSUInteger) index;
{ // can be overridden in subclasses
	return [self hyphenationFactor];
}

- (UTF32Char) hyphenCharacterForGlyphAtIndex:(NSUInteger) index;
{
	return '-';
}

- (void) insertGlyph:(NSGlyph) glyph atGlyphIndex:(NSUInteger) index characterIndex:(NSUInteger) charIdx;
{
	// used for hyphenation and keeps some caches in sync...
}

- (NSRange) layoutCharactersInRange:(NSRange) range
				   forLayoutManager:(NSLayoutManager *) manager
	   maximumNumberOfLineFragments:(NSUInteger) maxLines;
{ // this is the main layout function
	NSRange r;
	NSUInteger nextGlyph;
	// loop???
	[self layoutGlyphsInLayoutManager:manager startingAtGlyphIndex:range.location maxNumberOfLineFragments:maxLines nextGlyphIndex:&nextGlyph];
	return r;
}

- (void) layoutGlyphsInLayoutManager:(NSLayoutManager *) manager 
				startingAtGlyphIndex:(NSUInteger) startIndex 
			maxNumberOfLineFragments:(NSUInteger) maxLines 
					  nextGlyphIndex:(NSUInteger *) nextGlyph; 
{
	NSUInteger nextChar;
	_layoutManager=manager;
	[_layoutManager getFirstUnlaidCharacterIndex:&nextChar glyphIndex:nextGlyph];
	while(YES)
		{ // loop over characters in range
			unichar c=[[_attributedString string] characterAtIndex:startIndex];
			NSTypesetterControlCharacterAction a=[self actionForControlCharacterAtIndex:startIndex];
			if((a&NSTypesetterZeroAdvancementAction))
				[self setNotShownAttribute:YES forGlyphRange:NSMakeRange(startIndex, 1)];
			else
				{
				[self setNotShownAttribute:YES forGlyphRange:NSMakeRange(startIndex, 1)];
				if(c == NSAttachmentCharacter)
					{ // layout a NSTextAttachment
						
					}
				else
					{
					// generate glyph for current font (if it prints)
					}
				// handle NSTextTable and call -[NSTextTableBlock boundsRectForContentRect:inRect:textContainer:characterRange:]
				}
			/*		if(a&NSTypesetterControlCharacterAction)
			 [self boundingBoxForControlGlyphAtIndex:range.location forTextContainer:_currentTextContainer proposedLineFragment:0 glyphPosition:[characterIndex:];
			 */
			if(a&NSTypesetterHorizontalTabAction)
				{ // advance to next tab
					
				}
			if(a&NSTypesetterLineBreakAction)
				{ // advance to beginning of next line (new line fragment)
					
				}
			if(a&NSTypesetterParagraphBreakAction)
				{ // advance to beginning of next paragraph - apply firstLineHeadIndent
					
				}
			if(a&NSTypesetterContainerBreakAction)
				{ // advance to beginning of next container
					// may ask delegate to create a new container
					
				}
			startIndex++;
		}
	_layoutManager=nil;
}

- (NSLayoutManager *) layoutManager;
{
	return _layoutManager;
}

- (NSUInteger) layoutParagraphAtPoint:(NSPointPointer) originPt;
{ // layout glyphs until end of paragraph
	// [self setParagraphGlyphRange:(NSRange) paragRange separatorGlyphRange:(NSRange) sepRange]; ???

	[self beginParagraph];
	[self beginLineWithGlyphAtIndex:1];
	// and now???
	[self endLineWithGlyphRange:NSMakeRange(1, 10)];
	[self endParagraph];
}

- (CGFloat) lineFragmentPadding;
{
	return _lineFragmentPadding;
}

- (CGFloat) lineSpacingAfterGlyphAtIndex:(NSUInteger) index withProposedLineFragmentRect:(NSRect) fragRect;
{
	
}

- (NSRange) paragraphCharacterRange;
{
	
}

- (NSRange) paragraphGlyphRange;
{
	
}

- (NSRange) paragraphSeparatorCharacterRange;
{
	
}

- (NSRange) paragraphSeparatorGlyphRange;
{
	
}

- (CGFloat) paragraphSpacingAfterGlyphAtIndex:(NSUInteger) index withProposedLineFragmentRect:(NSRect) fragRect;
{
	
}

- (CGFloat) paragraphSpacingBeforeGlyphAtIndex:(NSUInteger) index withProposedLineFragmentRect:(NSRect) fragRect; 
{
	
}

- (void) setAttachmentSize:(NSSize) size forGlyphRange:(NSRange) range; 
{
	[_layoutManager setAttachmentSize:size forGlyphRange:range];
}

- (void) setAttributedString:(NSAttributedString *) attrStr;
{
	_attributedString=attrStr;
}

- (void) setBidiLevels:(const uint8_t *) levels forGlyphRange:(NSRange) range;
{
	NIMP;
}

- (void) setBidiProcessingEnabled:(BOOL) enabled;
{
	_bidiProcessingEnabled=enabled;
}

- (void) setDrawsOutsideLineFragment:(BOOL) flag forGlyphRange:(NSRange) range;
{
	while(range.length-- > 0)
		[_layoutManager setDrawsOutsideLineFragment:flag forGlyphAtIndex:range.location++];
}

- (void) setHardInvalidation:(BOOL) flag forGlyphRange:(NSRange) range;
{
	NIMP;
}

- (void) setHyphenationFactor:(float) value;
{
	[_layoutManager setHyphenationFactor:value];
}

- (void) setLineFragmentPadding:(CGFloat) value;
{
	_lineFragmentPadding=value;
}

- (void) setLineFragmentRect:(NSRect) fragRect 
			   forGlyphRange:(NSRange) range 
					usedRect:(NSRect) rect 
			  baselineOffset:(CGFloat) offset;
{
	// offset???
	[_layoutManager setLineFragmentRect:fragRect forGlyphRange:range usedRect:rect];
}

- (void) setLocation:(NSPoint) loc 
	withAdvancements:(const CGFloat *) advancements 
forStartOfGlyphRange:(NSRange) range;
{
	// advancements???
	[_layoutManager setLocation:loc forStartOfGlyphRange:range];
}

- (void) setNotShownAttribute:(BOOL) flag forGlyphRange:(NSRange) range;
{ // can be set e.g. for TAB or other control characters that are not shown in Postscript
	while(range.length-- > 0)
		[_layoutManager setNotShownAttribute:flag forGlyphAtIndex:range.location++];
}

- (void) setParagraphGlyphRange:(NSRange) paragRange separatorGlyphRange:(NSRange) sepRange;
{
	
}

- (void) setTypesetterBehavior:(NSTypesetterBehavior) behavior; 
{
	_typesetterBehavior=behavior;
}

- (void) setUsesFontLeading:(BOOL) fontLeading; 
{
	_usesFontLeading=fontLeading;
}

- (BOOL) shouldBreakLineByHyphenatingBeforeCharacterAtIndex:(NSUInteger) index;
{
	return NO;	// we have no hyphenation at the moment
}

- (BOOL) shouldBreakLineByWordBeforeCharacterAtIndex:(NSUInteger) index;
{
	return NO;
}

- (NSFont *) substituteFontForFont:(NSFont *) font;
{
	return [_layoutManager substituteFontForFont:font];
}

- (void) substituteGlyphsInRange:(NSRange) range withGlyphs:(NSGlyph *) glyphs; 
{
	[_layoutManager deleteGlyphsInRange:range];
	[_layoutManager insertGlyphs:glyphs length:range.length forStartingGlyphAtIndex:range.location characterIndex:[_layoutManager characterIndexForGlyphAtIndex:range.location]];
}

- (NSArray *) textContainers;
{
	return [_layoutManager textContainers];
}

- (NSTextTab *) textTabForGlyphLocation:(CGFloat) glyphLoc 
					   writingDirection:(NSWritingDirection) writingDirection 
							maxLocation:(CGFloat) maxLoc; 
{
	NSTextTab *tab;
	[_currentParagraphStyle tabStops];
	// check array - forward or backwards depending on writingDirection
}

- (NSTypesetterBehavior) typesetterBehavior;
{
	return _typesetterBehavior;
}

- (BOOL) usesFontLeading;
{
	return _usesFontLeading;
}

- (void) willSetLineFragmentRect:(NSRectPointer) lineRectPt 
				   forGlyphRange:(NSRange) range 
						usedRect:(NSRectPointer) usedRectPt 
				  baselineOffset:(CGFloat *) offset; 
{
	
}

@end

#if OLD

@implementation NSLayoutManager (SimpleVersion)

/*
 * this is currently our core layout and drawing method
 * it works quite well but has 3 limitations
 *
 * 1. it reclculates the layout for each call since there is no caching
 * 2. it can't properly align vertically if font size is variable
 * 3. it can't handle horizontal alignment
 *
 * some minor limitations
 * 4. can't handle more than one text container
 * 5. recalculates for invisible ranges
 * 6. may line-break words at attribute run sections instead of hyphenation positions
 *
 * all this can be easily solved by separating the layout and the drawing phases
 * and by caching the glyph positions
 *
 * [_glyphGenerator generateGlyphsForGlyphStorage:self desiredNumberOfCharacters:attribRange.length glyphIndex:0 characterIndex:attribRange.location];
 */

//
// FIXME: optimize/cache for large NSTextStorages and multiple NSTextContainers
//
// FIXME: use and update glyph cache if needed
// well, we should move that to the shared NSGlyphGenerator which does the layout
// and make it run in the background
//
// 1. split into paragraphs
// 2. split into lines
// 3. split into words and try to fill line and hyphenate / line break
// 4. split words into attribute ranges
//
// drawing should look like
// [ctxt _setFont:xxx]; 
// [ctxt _beginText];
// [ctxt _newLine]; or [ctxt _setTextPosition:...];
// [ctxt _setBaseline:xxx]; 
// [ctxt _setHorizontalScale:xxx]; 
// [ctxt _drawGlyphs:(NSGlyph *)glyphs count:(unsigned)cnt;	// -> (string) Tj
// [ctxt _endText];
//

static NSGlyph *_oldGlyphs;
static unsigned int _oldNumberOfGlyphs;
static unsigned int _oldGlyphBufferCapacity;

- (NSGlyph *) _glyphsAtIndex:(unsigned) idx;
{
	return &_oldGlyphs[idx];
}

- (NSRect) _draw:(BOOL) draw 
						glyphsForGlyphRange:(NSRange)glyphsToShow 
						atPoint:(NSPoint)origin		// top left of the text container (in flipped coordinates)
						findPoint:(NSPoint) find
						foundAtPos:(unsigned int *) foundAtPos
{ // this is the core text drawing interface and all string additions are based on this call!
	NSGraphicsContext *ctxt=draw?[NSGraphicsContext currentContext]:(NSGraphicsContext *) [NSNull null];
	NSTextContainer *container=[self textContainerForGlyphAtIndex:glyphsToShow.location effectiveRange:NULL];	// this call could fill the cache if needed...
	NSSize containerSize=[container containerSize];
	NSString *str=[_textStorage string];								// raw characters
	NSRange rangeLimit=NSMakeRange(0, [str length]);		// all
	NSPoint pos;
	NSAffineTransform *tm;		// text matrix
#if 0
	NSFont *font=(NSFont *) [NSNull null];				// check for internal errors
#else
	NSFont *font;				// current font attribute
#endif
	NSColor *foreGround;
	BOOL flipped=draw?[ctxt isFlipped]:NO;
	NSRect box=NSZeroRect;
	NSRect clipBox;
//	BOOL outside=YES;
	if(foundAtPos)
		*foundAtPos=NSMaxRange(glyphsToShow);	// default to maximum
	if(draw)
		{
		clipBox=[ctxt _clipBox];
#if 0	// testing
		[[NSColor redColor] set];
		if(flipped)
			NSRectFill((NSRect) { origin, containerSize });
		else
			NSRectFill((NSRect) { { origin.x, origin.y-containerSize.height }, containerSize });
		[[NSColor yellowColor] set];
		if(flipped)
			NSRectFill((NSRect) { origin, { 2.0, 2.0 } });
		else
			NSRectFill((NSRect) { { origin.x, origin.y-containerSize.height }, { 2.0, 2.0 } });
#endif
		[ctxt setCompositingOperation:NSCompositeCopy];
		[ctxt _beginText];			// starts at position (0,0)
		}
	pos=origin;							// tracks current drawing position (top left of the line) - Note: PDF needs to position to the baseline

	while(rangeLimit.location < NSMaxRange(glyphsToShow))
		{ // parse and process white-space separated words resp. fragments with same attributes
		NSRange attribRange;	// range with constant attributes
		NSString *substr;		// substring (without attributes)
		unsigned int i;
		NSDictionary *attr;		// the attributes
		NSParagraphStyle *para;
		id attrib;				// some individual attribute
		unsigned style;			// underline and strike-through mask
		NSRange wordRange;		// to find word that fits into line
		float width;			// width of the substr with given font
		float baseline;
		if(foundAtPos && rangeLimit.location > 0 && pos.y > find.y)
				{ // was before current position (i.e. end of line)
					*foundAtPos=rangeLimit.location-1;
					foundAtPos=NULL;	// we have found it, so don't update again 
				}
		switch([str characterAtIndex:rangeLimit.location])
			{
			case NSAttachmentCharacter:
				{
				NSTextAttachment *att=[_textStorage attribute:NSAttachmentAttributeName atIndex:rangeLimit.location effectiveRange:NULL];
				id <NSTextAttachmentCell> cell = [att attachmentCell];
				if(cell)
					{
					NSRect rect=[cell cellFrameForTextContainer:container
										   proposedLineFragment:(NSRect) { pos, { 12.0, 12.0 } }
												  glyphPosition:pos
												 characterIndex:rangeLimit.location];
					if(flipped)
						;
					if(pos.x+rect.size.width > origin.x+containerSize.width)
						; // FIXME: needs to start on a new line
					if(draw && NSLocationInRange(rangeLimit.location, glyphsToShow))
						{
#if 0
						NSLog(@"drawing attachment (%@): %@ %@", NSStringFromRect(rect), att, cell);
#endif
						// [self showAttachmentCell:cell inRect:rect characterIndex:rangeLimit.location];
						[cell drawWithFrame:rect
									 inView:[container textView]
							 characterIndex:rangeLimit.location
							  layoutManager:self];
						}
					else if(NSLocationInRange(rangeLimit.location, glyphsToShow))
						box=NSUnionRect(box, rect);
					pos.x += rect.size.width;
					if(foundAtPos && pos.y+rect.size.height >= find.y && pos.x >= find.x)
							{ // was the attachment
								*foundAtPos=rangeLimit.location;
								foundAtPos=NULL;	// we have found it, so don't update again 
							}
					}
				rangeLimit.location++;
				rangeLimit.length--;
				continue;
				}
			case '\t':
				{
					float tabwidth;
					font=[_textStorage attribute:NSFontAttributeName atIndex:rangeLimit.location effectiveRange:NULL];
					if(!font)
						font=[NSFont userFontOfSize:0.0];		// use default system font
					tabwidth=8.0*[font widthOfString:@"x"];	// approx. 8 characters
					// draw space glyph + characterspacing
					tabwidth=origin.x+(1+(int)((pos.x-origin.x)/tabwidth))*tabwidth-pos.x;	// width of complete tab
					if(pos.x+tabwidth <= origin.x+containerSize.width)
						{ // still fits into remaining line
							if(!draw && NSLocationInRange(rangeLimit.location, glyphsToShow))
								box=NSUnionRect(box, NSMakeRect(pos.x, pos.y, tabwidth, [self defaultLineHeightForFont:font]));
							pos.x+=tabwidth;
							if(foundAtPos && pos.y+[self defaultLineHeightForFont:font] >= find.y && pos.x >= find.x)
									{ // was in last fragment
										*foundAtPos=rangeLimit.location;
										foundAtPos=NULL;	// we have found it, so don't update again 
									}
						rangeLimit.location++;
						rangeLimit.length--;
						continue;
						}
					// treat as a newline
				}
			case '\n':
				{ // go to a new line
					para=[_textStorage attribute:NSParagraphStyleAttributeName atIndex:rangeLimit.location effectiveRange:NULL];
					float advance;
					float nlwidth;	// "width" of newline
					font=[_textStorage attribute:NSFontAttributeName atIndex:rangeLimit.location effectiveRange:NULL];
					if(!font)
						font=[NSFont userFontOfSize:0.0];		// use default system font
					nlwidth=origin.x+containerSize.width-pos.x;
					advance=[self defaultLineHeightForFont:font];
					if(para)
						advance+=[para paragraphSpacing];
					if(!draw && NSLocationInRange(rangeLimit.location, glyphsToShow))
						box=NSUnionRect(box, NSMakeRect(pos.x, pos.y, nlwidth, [self defaultLineHeightForFont:font]));
					pos.x+=20.0;
					pos.y+=advance;		// go down one line
					if(foundAtPos && pos.y >= find.y && pos.x >= find.x)
							{ // was in last fragment
								*foundAtPos=rangeLimit.location;
								foundAtPos=NULL;	// we have found it, so don't update again 
							}
				}
			case '\r':
				{ // start over at beginning of line but not a new line
					pos.x=origin.x;
					rangeLimit.location++;
					rangeLimit.length--;
					continue;
				}
			case ' ':
				{ // advance to next character position but don't draw a glyph
					float spacewidth;
					font=[_textStorage attribute:NSFontAttributeName atIndex:rangeLimit.location effectiveRange:NULL];
					if(!font)
						font=[NSFont userFontOfSize:0.0];		// use default system font
					spacewidth=[font widthOfString:@" "];		// width of space
					if(!draw && NSLocationInRange(rangeLimit.location, glyphsToShow))
						box=NSUnionRect(box, NSMakeRect(pos.x, pos.y, spacewidth, [self defaultLineHeightForFont:font]));
					pos.x+=spacewidth;
					if(foundAtPos && pos.y+[self defaultLineHeightForFont:font] >= find.y && pos.x >= find.x)
							{ // was in last fragment
								*foundAtPos=rangeLimit.location;
								foundAtPos=NULL;	// we have found it, so don't update again 
							}
					rangeLimit.location++;
					rangeLimit.length--;
					continue;
				}
			}
		attr=[_textStorage attributesAtIndex:rangeLimit.location longestEffectiveRange:&attribRange inRange:rangeLimit];
		para=[attr objectForKey:NSParagraphStyleAttributeName];
		if([para textBlocks])
			{ // table layout
				// get table
				// draw border&backgrounds
				// etc...
			}
		wordRange=[str rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] options:0 range:attribRange];	// embedded space in this range?
		if(wordRange.length != 0)
			{ // any whitespace found within attribute range - reduce attribute range to this word
			if(wordRange.location > attribRange.location)	
				attribRange.length=wordRange.location-attribRange.location;
			else
				attribRange.length=1;	// limit to the whitespace character itself
			}
		if(attribRange.location < glyphsToShow.location && NSMaxRange(attribRange) > glyphsToShow.location)
			attribRange.length=glyphsToShow.location-attribRange.location;	// vountarily stop at glyphsToShow.location
		else if(NSMaxRange(attribRange) > NSMaxRange(glyphsToShow))
			attribRange.length=NSMaxRange(glyphsToShow)-attribRange.location;	// voluntarily stop at NSMaxRange(glyphsToShow)
		// FIXME: this algorithm does not really word-wrap (only) if attributes change within a word
		substr=[str substringWithRange:attribRange];
		font=[attr objectForKey:NSFontAttributeName];
		if(!font)
			font=[NSFont userFontOfSize:0.0];		// use default system font
		width=[font widthOfString:substr];			// use metrics of unsubstituted font
		if(pos.x+width > origin.x+containerSize.width)
			{ // new word fragment does not fit into remaining line
			if(pos.x > origin.x)
				{ // we didn't just start on a newline, so insert another newline
				float advance=[self defaultLineHeightForFont:font];
#if 0
				NSLog(@"more");
#endif
				if(para)
					advance+=[para paragraphSpacing];
				switch([para lineBreakMode])
					{
						case NSLineBreakByWordWrapping:
						case NSLineBreakByCharWrapping:
						case NSLineBreakByClipping:
						case NSLineBreakByTruncatingHead:
						case NSLineBreakByTruncatingMiddle:
						case NSLineBreakByTruncatingTail:
							// FIXME: we can't handle that here because it is too late
							break;
					}
				pos.x=origin.x;
				pos.y+=advance;
				}
			while(width > containerSize.width && attribRange.length > 1)
				{ // does still not fit into box at all - we must truncate
				attribRange.length--;	// try with one character less
				substr=[str substringWithRange:attribRange];
				width=[font widthOfString:substr]; // get new width
				}
			}
		if(draw && NSLocationInRange(rangeLimit.location, glyphsToShow))
			{ // we want to draw really
				float alignment;
			if([ctxt isDrawingToScreen])
				font=[self substituteFontForFont:font];
			if(!font)
				NSLog(@"no screen font available");
			[font setInContext:ctxt];	// set font
			foreGround=[attr objectForKey:NSForegroundColorAttributeName];
#if 0
			NSLog(@"text color=%@", attrib);
#endif
			if(!foreGround)
				foreGround=[NSColor blackColor];
			[foreGround setStroke];
			[[attr objectForKey:NSStrokeColorAttributeName] setStroke];			// overwrite stroke color if defined differently
			[[attr objectForKey:NSBackgroundColorAttributeName] setFill];		// overwrite fill color
			baseline=0.0;
			if((attrib=[attr objectForKey:NSBaselineOffsetAttributeName]))
				baseline=[attrib floatValue];
			if((attrib=[attr objectForKey:NSSuperscriptAttributeName]))
				baseline+=3.0*[attrib intValue];
			[ctxt _setBaseline:baseline];	// update baseline
				
				switch([para alignment])
						{
							case NSLeftTextAlignment:
							case NSNaturalTextAlignment:
								alignment=0.0;
								break;
							case NSRightTextAlignment:
							case NSCenterTextAlignment:
							case NSJustifiedTextAlignment:
								// FIXME: we can't handle that here because it is too late
								alignment=0.0;
								break;
						}
				tm=[NSAffineTransform transform];	// identity
				if(flipped)
					[tm translateXBy:pos.x+alignment yBy:pos.y+[font ascender]];
				else
					[tm translateXBy:pos.x+alignment yBy:pos.y-[font ascender]];
				[ctxt _setTM:tm];
			_oldNumberOfGlyphs=[substr length];
			if(!_oldGlyphs || _oldNumberOfGlyphs >= _oldGlyphBufferCapacity)
				_oldGlyphs=(NSGlyph *) objc_realloc(_oldGlyphs, sizeof(_oldGlyphs[0])*(_oldGlyphBufferCapacity=_oldNumberOfGlyphs+20));
			for(i=0; i<_oldNumberOfGlyphs; i++)
				_oldGlyphs[i]=[font _glyphForCharacter:[substr characterAtIndex:i]];		// translate and copy to glyph buffer
			
			[ctxt _drawGlyphs:[self _glyphsAtIndex:0] count:_oldNumberOfGlyphs];	// -> (string) Tj
			//	[self showPackedGlyphs:[self _glyphsAtIndex:0] length:sizeof(NSGlyph)*_oldNumberOfGlyphs glyphRange:_oldNumberOfGlyphs atPoint:<#(NSPoint)point#> font:<#(NSFont *)font#> color:<#(NSColor *)color#> printingAdjustment:NSZeroSize];
			
			// fixme: setLineWidth:[font underlineThickness]
			if((style=[[attr objectForKey:NSUnderlineStyleAttributeName] intValue]))
				{ // underline
				//	[self underlineGlyphRange:<#(NSRange)glyphRange#> underlineType:<#(int)underlineVal#> lineFragmentRect:<#(NSRect)lineRect#> lineFragmentGlyphRange:<#(NSRange)lineGlyphRange#> containerOrigin:<#(NSPoint)containerOrigin#>];
				float posy=pos.y+[font defaultLineHeightForFont]+baseline+[font underlinePosition];
#if 0
				NSLog(@"underline %x", style);
#endif
				[foreGround setStroke];
				[[attr objectForKey:NSUnderlineColorAttributeName] setStroke];		// change stroke color if defined differently
				[NSBezierPath strokeLineFromPoint:NSMakePoint(pos.x, posy) toPoint:NSMakePoint(pos.x+width, posy)];
				}
			if((style=[[attr objectForKey:NSStrikethroughStyleAttributeName] intValue]))
				{ // strike through
				//	[self strikethroughGlyphRange:<#(NSRange)glyphRange#> strikethroughType:<#(int)strikethroughVal#> lineFragmentRect:<#(NSRect)lineRect#> lineFragmentGlyphRange:<#(NSRange)lineGlyphRange#> containerOrigin:<#(NSPoint)containerOrigin#>];
				float posy=pos.y+[font ascender]+baseline-[font xHeight]/2.0;
#if 0
				NSLog(@"strike through %x", style);
#endif
				[foreGround setStroke];
				[[attr objectForKey:NSStrikethroughColorAttributeName] setStroke];		// change stroke color if defined differently
				[NSBezierPath strokeLineFromPoint:NSMakePoint(pos.x, posy) toPoint:NSMakePoint(pos.x+width, posy)];
				}
			if((attrib=[attr objectForKey:NSLinkAttributeName]))
				{ // link
				float posy=pos.y+[font defaultLineHeightForFont]+baseline+[font underlinePosition];
				[[NSColor blueColor] setStroke];
				[NSBezierPath strokeLineFromPoint:NSMakePoint(pos.x, posy) toPoint:NSMakePoint(pos.x+width, posy)];
				}
			}
		if(!draw && NSLocationInRange(rangeLimit.location, glyphsToShow))
			box=NSUnionRect(box, NSMakeRect(pos.x, pos.y, width, [self defaultLineHeightForFont:font])); // increase bounding box
		pos.x+=width;	// advance to next fragment
		if(foundAtPos && pos.y+[self defaultLineHeightForFont:font] >= find.y && pos.x >= find.x)
				{ // was in last fragment
					float posx=pos.x-width;
					*foundAtPos=rangeLimit.location;
					while(YES)
							{ // find exact position
								substr=[str substringWithRange:NSMakeRange(*foundAtPos, 1)];	// get character
								posx+=[font widthOfString:substr];			// use metrics of current font
								if(posx >= find.x)
									break;
								(*foundAtPos)++;	// try next
							}
					foundAtPos=NULL;	// we have found it, so don't update again 
				}
		rangeLimit.location=NSMaxRange(attribRange);	// handle next fragment
		rangeLimit.length-=attribRange.length;
		}
	if(draw)
		{
		[ctxt _endText];
#if 0		// testing
		[[NSColor redColor] set];
		if(flipped)
			NSFrameRect((NSRect) { origin, containerSize });
		else
			NSFrameRect((NSRect) { { origin.x, origin.y-containerSize.height }, containerSize });
#endif	
		}
	return box;
}

- (NSRect) boundingRectForGlyphRange:(NSRange) glyphRange 
					 inTextContainer:(NSTextContainer *) container;
{
	glyphRange=NSIntersectionRange(glyphRange, [self glyphRangeForTextContainer:container]);	// only the range drawn in this container
	return [self _draw:NO glyphsForGlyphRange:glyphRange atPoint:NSZeroPoint findPoint:NSZeroPoint foundAtPos:NULL];
}

- (unsigned) characterIndexForGlyphAtIndex:(unsigned)glyphIndex;
{
	// FIXME:
	return glyphIndex;
}

- (void) drawGlyphsForGlyphRange:(NSRange)glyphsToShow 
						 atPoint:(NSPoint)origin;		// top left of the text container (in flipped coordinates)
{
	[self _draw:YES glyphsForGlyphRange:glyphsToShow atPoint:origin findPoint:NSZeroPoint foundAtPos:NULL];
}

- (unsigned int) glyphIndexForPoint:(NSPoint)aPoint
					inTextContainer:(NSTextContainer *)textContainer
	 fractionOfDistanceThroughGlyph:(float *)partialFraction;
{
	unsigned int pos;
	[self _draw:NO glyphsForGlyphRange:[self glyphRangeForTextContainer:textContainer] atPoint:NSZeroPoint findPoint:aPoint foundAtPos:&pos];
	if(partialFraction)
		*partialFraction=0.0;
	return pos;
}

- (NSRange) glyphRangeForBoundingRectWithoutAdditionalLayout:(NSRect)bounds 
											 inTextContainer:(NSTextContainer *)container;
{
	return NSMakeRange(0, [_textStorage length]);	// assume we have only one text container and ignore the bounds
}

- (NSRange) glyphRangeForTextContainer:(NSTextContainer *)container;
{
	return NSMakeRange(0, [_textStorage length]);	// assume we have only one text container
}

@end

#endif

@implementation NSLayoutManager

static void allocateExtra(struct NSGlyphStorage *g)
{
	if(!g->extra)
		g->extra=(struct NSGlyphStorageExtra *) objc_calloc(1, sizeof(g->extra[0]));
}

- (void) addTemporaryAttribute:(NSString *) attr value:(id) val forCharacterRange:(NSRange) range;
{
	NSMutableDictionary *d=[[self temporaryAttributesAtCharacterIndex:range.location effectiveRange:NULL] mutableCopy];
	if(!d) d=[NSMutableDictionary dictionaryWithCapacity:5];
	[d setObject:val forKey:attr];
	[self addTemporaryAttributes:d forCharacterRange:range];
}

- (void) addTemporaryAttributes:(NSDictionary *)attrs forCharacterRange:(NSRange)range;
{
	//if(glyphIndex >= _numberOfGlyphs)
	//	[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", glyphIndex];
	// check for extra
	// if allocated - set
}

- (void) addTextContainer:(NSTextContainer *)container;
{
	[_textContainers addObject:container];
}

- (BOOL) allowsNonContiguousLayout; { return _allowsNonContiguousLayout; }

- (NSSize) attachmentSizeForGlyphAtIndex:(unsigned)index;
{
	if(index >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", index];
	NIMP;
	return NSZeroSize;
}

- (BOOL) backgroundLayoutEnabled; { return _backgroundLayoutEnabled; }

- (NSRect) boundingRectForGlyphRange:(NSRange) glyphRange 
					 inTextContainer:(NSTextContainer *) container;
{
}

- (NSRect) boundsRectForTextBlock:(NSTextBlock *)block atIndex:(unsigned)index effectiveRange:(NSRangePointer)range;
{
	NIMP;
	return NSZeroRect;
}

- (NSRect) boundsRectForTextBlock:(NSTextBlock *)block glyphRange:(NSRange)range;
{
	NIMP;
	return NSZeroRect;
}

- (unsigned) characterIndexForGlyphAtIndex:(unsigned)glyphIndex;
{
	if(glyphIndex >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", glyphIndex];
	return _glyphs[glyphIndex].characterIndex;
}

- (NSRange) characterRangeForGlyphRange:(NSRange)glyphRange actualGlyphRange:(NSRangePointer)actualGlyphRange;
{
	// FIXME:
	if(actualGlyphRange)
		*actualGlyphRange=glyphRange;
	return glyphRange;
}

- (void) dealloc;
{
	if(_glyphs)
		{
		[self deleteGlyphsInRange:NSMakeRange(0, _numberOfGlyphs)];
		objc_free(_glyphs);
		}
	[_glyphGenerator release];
	[_textContainers release];
	[_typesetter release];
	[super dealloc];
}

- (NSImageScaling) defaultAttachmentScaling; { return _defaultAttachmentScaling; }

- (CGFloat) defaultBaselineOffsetForFont:(NSFont *) font;
{
	// FIXME: ask typesetter behaviour???
	return -[font descender];
}

- (float) defaultLineHeightForFont:(NSFont *) font;
{
	// FIXME: ask typesetter behaviour???
	return [font defaultLineHeightForFont];
}

- (id) delegate; { return _delegate; }

- (void) deleteGlyphsInRange:(NSRange)glyphRange;
{
	unsigned int i;
	if(NSMaxRange(glyphRange) > _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph range"];
	if(glyphRange.length == 0)
		return;
	for(i=0; i<glyphRange.length; i++)
		{ // release extra records
		if(_glyphs[glyphRange.location+i].extra)
			objc_free(_glyphs[glyphRange.location+i].extra);
		}
	memcpy(&_glyphs[glyphRange.location], &_glyphs[NSMaxRange(glyphRange)], sizeof(_glyphs[0])*glyphRange.length);
	_numberOfGlyphs-=glyphRange.length;
}

- (void) drawBackgroundForGlyphRange:(NSRange)glyphsToShow 
							 atPoint:(NSPoint)origin;
{ // draw selection range background
	if(glyphsToShow.length > 0)
			{
				NSTextContainer *textContainer=[self textContainerForGlyphAtIndex:glyphsToShow.location effectiveRange:NULL];	// this call could fill the cache if needed...
			// FIXME - should be done line by line!
				NSRect r=[self boundingRectForGlyphRange:glyphsToShow inTextContainer:textContainer];
				NSColor *color=[NSColor selectedTextBackgroundColor];
				[color set];
				// FIXME: this is correct only for single lines...
				[self fillBackgroundRectArray:&r count:1 forCharacterRange:glyphsToShow color:color];
			}
	// also calls -[NSTextBlock drawBackgroundWithRange... ]
}

- (void) drawGlyphsForGlyphRange:(NSRange)glyphsToShow 
						 atPoint:(NSPoint)origin;		// top left of the text container (in flipped coordinates)
{
	// check if all glyphs belong to the same text container
	while(glyphsToShow.length > 0)
		{
		// or do something similar...
		//[self showPackedGlyphs:<#(char *)glyphs#> length:<#(unsigned int)glyphLen#> glyphRange:<#(NSRange)glyphRange#> atPoint:<#(NSPoint)point#> font:<#(NSFont *)font#> color:<#(NSColor *)color#> printingAdjustment:<#(NSSize)adjust#>:
		}
}

- (BOOL) drawsOutsideLineFragmentForGlyphAtIndex:(unsigned)index;
{
	if(index >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", index];
	return _glyphs[index].drawsOutsideLineFragment;
}

- (void) drawStrikethroughForGlyphRange:(NSRange)glyphRange
					  strikethroughType:(int)strikethroughVal
						 baselineOffset:(float)baselineOffset
					   lineFragmentRect:(NSRect)lineRect
				 lineFragmentGlyphRange:(NSRange)lineGlyphRange
						containerOrigin:(NSPoint)containerOrigin;
{
	NIMP;
#if 0
	float posy=pos.y+[font ascender]+baselineOffset-[font xHeight]/2.0;
#if 0
	NSLog(@"strike through %x", style);
#endif
	[foreGround setStroke];
	[[attr objectForKey:NSStrikethroughColorAttributeName] setStroke];		// change stroke color if defined differently
	[NSBezierPath strokeLineFromPoint:NSMakePoint(pos.x, posy) toPoint:NSMakePoint(pos.x+width, posy)];
#endif				
}

- (void) drawUnderlineForGlyphRange:(NSRange)glyphRange 
					  underlineType:(int)underlineVal 
					 baselineOffset:(float)baselineOffset 
				   lineFragmentRect:(NSRect)lineRect 
			 lineFragmentGlyphRange:(NSRange)lineGlyphRange 
					containerOrigin:(NSPoint)containerOrigin;
{
	NIMP;
#if 0
	float posy=pos.y+[font defaultLineHeightForFont]+baselineOffset+[font underlinePosition];
#if 0
	NSLog(@"underline %x", style);
#endif
	[foreGround setStroke];
	[[attr objectForKey:NSUnderlineColorAttributeName] setStroke];		// change stroke color if defined differently
	[NSBezierPath strokeLineFromPoint:NSMakePoint(pos.x, posy) toPoint:NSMakePoint(pos.x+width, posy)];
#endif
}

- (void) ensureGlyphsForCharacterRange:(NSRange) range;
{
	
}

- (void) ensureGlyphsForGlyphRange:(NSRange) range;
{
	
}

- (void) ensureLayoutForBoundingRect:(NSRect) rect inTextContainer:(NSTextContainer *) textContainer;
{
	
}

- (void) ensureLayoutForCharacterRange:(NSRange) range;
{
	
}

- (void) ensureLayoutForGlyphRange:(NSRange) range;
{
	
}

- (void) ensureLayoutForTextContainer:(NSTextContainer *) textContainer;
{
	
}

- (NSRect) extraLineFragmentRect; { return _extraLineFragmentRect; }
- (NSTextContainer *) extraLineFragmentTextContainer; { return _extraLineFragmentContainer; }
- (NSRect) extraLineFragmentUsedRect; { return _extraLineFragmentUsedRect; }

- (void) fillBackgroundRectArray:(NSRectArray) rectArray count:(NSUInteger) rectCount forCharacterRange:(NSRange) charRange color:(NSColor *) color;
{ // charRange and color are for informational purposes - color must already be set
	NSRectFillList(rectArray, rectCount);
}

- (NSTextView *) firstTextView;
{
	if(!_firstTextView)
		{
		if([_textContainers count] == 0)
			return nil;
		_firstTextView=[[_textContainers objectAtIndex:0] textView];
		}
	return _firstTextView;
}

- (unsigned) firstUnlaidCharacterIndex;
{
	return _firstUnlaidCharacterIndex;
}

- (unsigned) firstUnlaidGlyphIndex;
{
	return _firstUnlaidGlyphIndex;
}

- (float) fractionOfDistanceThroughGlyphForPoint:(NSPoint)aPoint inTextContainer:(NSTextContainer *)aTextContainer;
{
	float f;
	[self glyphIndexForPoint:aPoint inTextContainer:aTextContainer fractionOfDistanceThroughGlyph:&f];	// ignore index
	return f;
}

- (void) getFirstUnlaidCharacterIndex:(unsigned *)charIndex 
						   glyphIndex:(unsigned *)glyphIndex;
{
	*charIndex=_firstUnlaidCharacterIndex;
	*glyphIndex=_firstUnlaidGlyphIndex;
}

- (unsigned) getGlyphs:(NSGlyph *)glyphArray range:(NSRange)glyphRange;
{
	NSAssert(NSMaxRange(glyphRange) <= _numberOfGlyphs, @"invalid glyph range");
	unsigned int idx=0;
	while(glyphRange.length-- > 0)
		{
		if(_glyphs[glyphRange.location].glyph != NSNullGlyph)
			glyphArray[idx++]=_glyphs[glyphRange.location].glyph;
		glyphRange.location++;
		}
	glyphArray[idx]=NSNullGlyph;	// adds 0-termination (buffer must have enough capacity!)
	return idx;
}

- (unsigned) getGlyphsInRange:(NSRange)glyphsRange
					   glyphs:(NSGlyph *)glyphBuffer
			 characterIndexes:(unsigned *)charIndexBuffer
			glyphInscriptions:(NSGlyphInscription *)inscribeBuffer
				  elasticBits:(BOOL *)elasticBuffer;
{
	return [self getGlyphsInRange:glyphsRange glyphs:glyphBuffer
				 characterIndexes:charIndexBuffer glyphInscriptions:inscribeBuffer
					  elasticBits:elasticBuffer bidiLevels:NULL];
}

- (unsigned) getGlyphsInRange:(NSRange)glyphsRange
					   glyphs:(NSGlyph *)glyphBuffer
			 characterIndexes:(unsigned *)charIndexBuffer
			glyphInscriptions:(NSGlyphInscription *)inscribeBuffer
				  elasticBits:(BOOL *)elasticBuffer
				   bidiLevels:(unsigned char *)bidiLevelBuffer;
{
	while(glyphsRange.length-- > 0)
		{ // extract from internal data structure
		struct NSGlyphStorageExtra *extra;
		if(glyphBuffer) *glyphBuffer++=_glyphs[glyphsRange.location].glyph;
		if(charIndexBuffer) *charIndexBuffer++=_glyphs[glyphsRange.location].characterIndex;
		extra=_glyphs[glyphsRange.location].extra;
		if(inscribeBuffer) *inscribeBuffer++=extra?extra->inscribeAttribute:0;
		if(elasticBuffer) *elasticBuffer++=extra?extra->elasticAttribute:0;
		if(bidiLevelBuffer) *bidiLevelBuffer++=extra?extra->bidiLevelAttribute:0;
		glyphsRange.location++;
		}
}

- (NSUInteger) getLineFragmentInsertionPointsForCharacterAtIndex:(NSUInteger) index 
											  alternatePositions:(BOOL) posFlag 
												  inDisplayOrder:(BOOL) orderFlag 
													   positions:(CGFloat *) positions 
												characterIndexes:(NSUInteger *) charIds;
{
	NIMP;
	return 0;
}

- (NSGlyph) glyphAtIndex:(unsigned)glyphIndex;
{
	if(glyphIndex >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", glyphIndex];
	return _glyphs[glyphIndex].glyph;
}

- (NSGlyph) glyphAtIndex:(unsigned)glyphIndex isValidIndex:(BOOL *)isValidIndex;
{
	BOOL isValid=glyphIndex < _numberOfGlyphs;
	if(isValidIndex)
		*isValidIndex=isValid;
	if(isValid)
		return _glyphs[glyphIndex].glyph;
	return NSNullGlyph;
}

- (NSGlyphGenerator *) glyphGenerator;
{
	if(!_glyphGenerator)
		_glyphGenerator=[[NSGlyphGenerator sharedGlyphGenerator] retain];
	return _glyphGenerator;
}

static NSUInteger glyphSearch(struct NSGlyphStorage *g, unsigned from, unsigned to, int offset, char *val, int len)
{
	while(from < to)
		{
		if(memcmp(((char *) &g[from])+offset, val, len) == 0)
			return from;	// found
		}
	return NSNotFound;
}

- (NSUInteger) glyphIndexForCharacterAtIndex:(NSUInteger) index;
{
	return glyphSearch(_glyphs, 0, _numberOfGlyphs, (int)(&((struct NSGlyphStorage *) NULL)->characterIndex),  (char *) &index, sizeof(index));
}

- (unsigned int) glyphIndexForPoint:(NSPoint)aPoint inTextContainer:(NSTextContainer *)aTextContainer;
{
	return [self glyphIndexForPoint:aPoint inTextContainer:aTextContainer fractionOfDistanceThroughGlyph:NULL];
}

- (unsigned int) glyphIndexForPoint:(NSPoint)aPoint
				inTextContainer:(NSTextContainer *)textContainer
 fractionOfDistanceThroughGlyph:(float *)partialFraction;
{
}

- (NSRange) glyphRangeForBoundingRect:(NSRect)bounds 
					  inTextContainer:(NSTextContainer *)container;
{
	// if needed: layout...
	return [self glyphRangeForBoundingRectWithoutAdditionalLayout:bounds inTextContainer:container];
}

- (NSRange) glyphRangeForBoundingRectWithoutAdditionalLayout:(NSRect)bounds 
											 inTextContainer:(NSTextContainer *)container;
{
	NSRange r;
	for(r.location=0; r.location < _numberOfGlyphs; r.location++)
		if(_glyphs[r.location].textContainer == container && NSIntersectsRect(_glyphs[r.location].lineFragmentRect, bounds))
			break;	// first glyph in this container found that falls into the bounds
	for(r.length=1; NSMaxRange(r) < _numberOfGlyphs; r.length++)
		if(_glyphs[NSMaxRange(r)].textContainer != container)
			break;	// last glyph found because next one belongs to a different container
	// we should trim off all glyphs from the end that are outside of the bounds
	return r;
}

- (NSRange) glyphRangeForCharacterRange:(NSRange)charRange actualCharacterRange:(NSRange *)actualCharRange;
{
	// get first and last glyph for this range and extend actualCharRange if there are ligatures involved
	// FIXME:
	if(actualCharRange)
		{
		*actualCharRange=charRange;		
		}
#if 0
	NSLog(@"glyphRangeForCharacterRange = %@", NSStringFromRange(charRange));
#endif
	return charRange;
}

- (NSRange) glyphRangeForTextContainer:(NSTextContainer *)container;
{ // this can become quite slow if we have 10 Mio characters...
	// so we should have some cache indexed by the container
	NSRange r;
	for(r.location=0; r.location < _numberOfGlyphs; r.location++)
		if(_glyphs[r.location].textContainer == container)
			break;	// first glyph in this container found
	for(r.length=0; NSMaxRange(r) < _numberOfGlyphs; r.length++)
		if(_glyphs[NSMaxRange(r)].textContainer != container)
			break;	// last glyph found because next one belongs to a different container
	return r;
}

- (BOOL) hasNonContiguousLayout; { return _hasNonContiguousLayout; }
- (float) hyphenationFactor; { return _hyphenationFactor; }

- (id) init;
{
	if((self=[super init]))
		{
		_textContainers=[NSMutableArray new];
		_typesetter=[[NSTypesetter sharedSystemTypesetter] retain];
		_usesScreenFonts=NO;
		}
	return self;
}

- (void) insertGlyph:(NSGlyph)glyph atGlyphIndex:(unsigned)glyphIndex characterIndex:(unsigned)charIndex;
{ // insert a single glyph without attributes
	[self insertGlyphs:&glyph length:1 forStartingGlyphAtIndex:glyphIndex characterIndex:charIndex];
}

- (void) insertTextContainer:(NSTextContainer *)container atIndex:(unsigned)index;
{
	[_textContainers insertObject:container atIndex:index];
	if(index == 0)
		_firstTextView=[container textView];	// has changed
	// invalidate
}

- (int) intAttribute:(int)attributeTag forGlyphAtIndex:(unsigned)glyphIndex;
{
	if(glyphIndex >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", glyphIndex];
	switch(attributeTag) {
		case NSGlyphAttributeSoft:
			if(!_glyphs[glyphIndex].extra) return 0;
			return _glyphs[glyphIndex].extra->softAttribute;
		case NSGlyphAttributeElastic:
			if(!_glyphs[glyphIndex].extra) return 0;
			return _glyphs[glyphIndex].extra->elasticAttribute;
		case NSGlyphAttributeBidiLevel:
			if(!_glyphs[glyphIndex].extra) return 0;
			return _glyphs[glyphIndex].extra->bidiLevelAttribute;
		case NSGlyphAttributeInscribe:
			if(!_glyphs[glyphIndex].extra) return 0;
			return _glyphs[glyphIndex].extra->inscribeAttribute;
		default:
			[NSException raise:@"NSLayoutManager" format:@"unknown intAttribute tag: %u", attributeTag];
			return 0;
	}
}

- (void) invalidateDisplayForCharacterRange:(NSRange)charRange;
{
//	[self invalidateGlyphsForCharacterRange:charRange changeInLength:0 actualCharacterRange:NULL];
}

- (void) invalidateDisplayForGlyphRange:(NSRange)glyphRange;
{
	NIMP;
	// [textview setNeedsDisplayInRect: ]
}

- (void) invalidateGlyphsForCharacterRange:(NSRange)charRange changeInLength:(int)delta actualCharacterRange:(NSRange *)actualCharRange;
{
	NIMP;
}

- (void) invalidateGlyphsOnLayoutInvalidationForGlyphRange:(NSRange) range;
{
	
}

- (void) invalidateLayoutForCharacterRange:(NSRange) range actualCharacterRange:(NSRangePointer) charRange;
{
	[self invalidateLayoutForCharacterRange:range isSoft:NO actualCharacterRange:charRange];
}

- (void) invalidateLayoutForCharacterRange:(NSRange)charRange isSoft:(BOOL)flag actualCharacterRange:(NSRange *)actualCharRange;
{
	NIMP;
}

- (BOOL) isValidGlyphIndex:(unsigned)glyphIndex;
{
	if(glyphIndex >= _numberOfGlyphs)
		return NO;
	return _glyphs[glyphIndex].validFlag;
}

- (BOOL) layoutManagerOwnsFirstResponderInWindow:(NSWindow *)aWindow;
{ // check if firstResponder is a NSTextView and we are the layoutManager
	NSResponder *f=[aWindow firstResponder];
	if([f respondsToSelector:@selector(layoutManager)])
		return [(NSTextView *) f layoutManager] == self;
	return NO;
}

- (NSRect) layoutRectForTextBlock:(NSTextBlock *)block
						  atIndex:(unsigned)glyphIndex
				   effectiveRange:(NSRangePointer)effectiveGlyphRange;
{
	NIMP;
	return NSZeroRect;
}

- (NSRect) layoutRectForTextBlock:(NSTextBlock *)block
					   glyphRange:(NSRange)glyphRange;
{
	NIMP;
	return NSZeroRect;
}

- (NSRect) lineFragmentRectForGlyphAtIndex:(unsigned)glyphIndex effectiveRange:(NSRange *)effectiveGlyphRange;
{
	// [self ensureLayoutForGlyphRange:<#(NSRange)range#>];
	return [self lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange:effectiveGlyphRange withoutAdditionalLayout:NO];
}

- (NSRect) lineFragmentRectForGlyphAtIndex:(NSUInteger) index effectiveRange:(NSRangePointer) charRange withoutAdditionalLayout:(BOOL) layoutFlag;
{
	NSRect lfr;
	if(!layoutFlag)
		;	// do additional layout
	if(index >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", index];
	lfr=_glyphs[index].lineFragmentRect;
	if(charRange)
		{ // find the effective range by searching back and forth from the current index for glyphs with the same lft
			charRange->location=index;
			while(charRange->location > 0)
				{
				if(!NSEqualRects(lfr, _glyphs[charRange->location-1].lineFragmentRect))
					break;	// previous index is different
				charRange->location--;
				}
			charRange->length=index-charRange->location;
			while(NSMaxRange(*charRange)+1 < _numberOfGlyphs)
				{
				if(!NSEqualRects(lfr, _glyphs[NSMaxRange(*charRange)+1].lineFragmentRect))
					break;	// next index is different
				charRange->length++;
				}
		}
	return lfr;
}

- (NSRect) lineFragmentUsedRectForGlyphAtIndex:(unsigned)glyphIndex effectiveRange:(NSRange *)effectiveGlyphRange;
{
	NIMP;
	return NSZeroRect;
}

- (NSPoint) locationForGlyphAtIndex:(unsigned) index;
{
	if(index >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", index];
	return _glyphs[index].location;
}

- (BOOL) notShownAttributeForGlyphAtIndex:(unsigned) index;
{
	if(index >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", index];
	return _glyphs[index].notShownAttribute;
}

- (unsigned) numberOfGlyphs;
{
	if(!_allowsNonContiguousLayout)
		[self ensureGlyphsForCharacterRange:NSMakeRange(0, [_textStorage length])]; // generate all glyphs
	return _numberOfGlyphs;
}

- (NSRange) rangeOfNominallySpacedGlyphsContainingIndex:(unsigned)glyphIndex;
{
	NIMP;
	return NSMakeRange(0, 0);
}

- (NSRect*) rectArrayForCharacterRange:(NSRange)charRange 
		  withinSelectedCharacterRange:(NSRange)selCharRange 
					   inTextContainer:(NSTextContainer *)container 
							 rectCount:(unsigned *)rectCount;
{
	static NSRect rect;
	NIMP;
	return &rect;
}

- (NSRect*) rectArrayForGlyphRange:(NSRange)glyphRange 
		  withinSelectedGlyphRange:(NSRange)selGlyphRange 
				   inTextContainer:(NSTextContainer *)container 
						 rectCount:(unsigned *)rectCount;
{
	static NSRect rect;
	NIMP;
	return &rect;
}

- (void) removeTemporaryAttribute:(NSString *)name forCharacterRange:(NSRange)charRange;
{
	NIMP;
}

- (void) removeTextContainerAtIndex:(unsigned)index;
{
	if(index == 0)
		_firstTextView=nil;	// might have changed
	[_textContainers removeObjectAtIndex:index];
	// invalidate this and following containers
}

- (void) replaceGlyphAtIndex:(unsigned)glyphIndex withGlyph:(NSGlyph)newGlyph;
{
	if(glyphIndex >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", glyphIndex];
	_glyphs[glyphIndex].glyph=newGlyph;
	// set invalidation!?! If the glyph is bigger, we have to update the layout from here to the end
}

- (void) replaceTextStorage:(NSTextStorage *)newTextStorage;
{
	[_textStorage removeLayoutManager:self];
	[newTextStorage removeLayoutManager:self];	// this calls setTextStorage
}

- (NSView *) rulerAccessoryViewForTextView:(NSTextView *)aTextView
							paragraphStyle:(NSParagraphStyle *)paraStyle
									 ruler:(NSRulerView *)aRulerView
								   enabled:(BOOL)flag;
{
	return NIMP;
}

- (NSArray *) rulerMarkersForTextView:(NSTextView *)view 
					   paragraphStyle:(NSParagraphStyle *)style 
								ruler:(NSRulerView *)ruler;
{
	return NIMP;
}

- (void) setAllowsNonContiguousLayout:(BOOL) flag;
{
	_allowsNonContiguousLayout=flag;
}

- (void) setAttachmentSize:(NSSize)attachmentSize forGlyphRange:(NSRange)glyphRange;
{
	// DEPRECATED
	if(NSMaxRange(glyphRange) >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph range"];
	NIMP;
}

- (void) setBackgroundLayoutEnabled:(BOOL)flag; { _backgroundLayoutEnabled=flag; }

- (void) setBoundsRect:(NSRect)rect forTextBlock:(NSTextBlock *)block glyphRange:(NSRange)glyphRange;
{
	NIMP;
}

- (void) setCharacterIndex:(unsigned)charIndex forGlyphAtIndex:(unsigned) index;
{ // character indices should be ascending with glyphIndex...
	if(index >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", index];
	_glyphs[index].characterIndex=charIndex;
}

- (void) setDefaultAttachmentScaling:(NSImageScaling)scaling; { _defaultAttachmentScaling=scaling; }

- (void) setDelegate:(id)obj; { _delegate=obj; }

- (void) setDrawsOutsideLineFragment:(BOOL)flag forGlyphAtIndex:(unsigned) index;
{
	if(index >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", index];
	_glyphs[index].drawsOutsideLineFragment=flag;
}

- (void) setExtraLineFragmentRect:(NSRect)fragmentRect usedRect:(NSRect)usedRect textContainer:(NSTextContainer *)container;
{
	NIMP;
}

- (void) setGlyphGenerator:(NSGlyphGenerator *)gg; { ASSIGN(_glyphGenerator, gg); }

- (void) setHyphenationFactor:(float)factor; { _hyphenationFactor=factor; }

- (void) setLayoutRect:(NSRect)rect forTextBlock:(NSTextBlock *)block glyphRange:(NSRange)glyphRange;
{
	NIMP;
}

- (void) setLineFragmentRect:(NSRect)fragmentRect forGlyphRange:(NSRange)glyphRange usedRect:(NSRect)usedRect;
{
	NIMP;
}

- (void) setLocation:(NSPoint)location forStartOfGlyphRange:(NSRange)glyphRange;
{
	// [self setLocations:&location startingGlyphIndexes:&glyphRange.location count:1 forGlyphRange:glyphRange];
	if(NSMaxRange(glyphRange) >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph range"];
	_glyphs[glyphRange.location].location=location;
}

- (void) setLocations:(NSPointArray) locs 
 startingGlyphIndexes:(NSUInteger *) glyphIds 
				count:(NSUInteger) number 
		forGlyphRange:(NSRange) glyphRange; 
{
	if(NSMaxRange(glyphRange) >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph range"];
	while(number-- > 0)
		{
		if(*glyphIds >= NSMaxRange(glyphRange) || *glyphIds < glyphRange.location)
			[NSException raise:@"NSLayoutManager" format:@"invalid glyph index not in range"];
		_glyphs[*glyphIds++].location=*locs++;	// set location
		}
}

- (void) setNotShownAttribute:(BOOL)flag forGlyphAtIndex:(unsigned) index;
{
	if(index >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", index];
	_glyphs[index].notShownAttribute=flag;
}

// FIXME: does this trigger relayout?

- (void) setShowsControlCharacters:(BOOL)flag; { if(flag) _layoutOptions |= NSShowControlGlyphs; else _layoutOptions &= ~NSShowControlGlyphs; }

- (void) setShowsInvisibleCharacters:(BOOL)flag; { if(flag) _layoutOptions |= NSShowInvisibleGlyphs; else _layoutOptions &= ~NSShowInvisibleGlyphs; }

- (void) setTemporaryAttributes:(NSDictionary *)attrs forCharacterRange:(NSRange)charRange;
{
	// FIXME: this is for characters!!!
	if(NSMaxRange(charRange) >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", index];
//	return _glyphs[glyphIndex].extra=flag;
}

- (void) setTextContainer:(NSTextContainer *) container forGlyphRange:(NSRange) glyphRange;
{
	if(NSMaxRange(glyphRange) >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph range"];
	while(glyphRange.length-- > 0)
		_glyphs[glyphRange.location++].textContainer=container;
}

// invalidate if needed!!!

- (void) setTextStorage:(NSTextStorage *)ts; { _textStorage=ts; }	// The textStorage owns the layout manager(s)
- (void) setTypesetter:(NSTypesetter *)ts; { ASSIGN(_typesetter, ts); }
- (void) setTypesetterBehavior:(NSTypesetterBehavior)behavior; { [_typesetter setTypesetterBehavior:behavior]; }
- (void) setUsesFontLeading:(BOOL) flag; { _usesFontLeading=flag; }
- (void) setUsesScreenFonts:(BOOL)flag; { _usesScreenFonts=flag; }

- (void) showAttachmentCell:(NSCell *)cell inRect:(NSRect)rect characterIndex:(unsigned)attachmentIndex;
{
	// check for NSAttachmentCell or otherwise call without characterIndex
	[(NSTextAttachmentCell *) cell drawWithFrame:rect
				 inView:[self firstTextView]
		 characterIndex:attachmentIndex
		  layoutManager:self];
}

- (void) showPackedGlyphs:(char *) glyphs
				   length:(unsigned) glyphLen	// number of bytes = 2* number of glyphs
			   glyphRange:(NSRange) glyphRange
				  atPoint:(NSPoint) point
					 font:(NSFont *) font
					color:(NSColor *) color
	   printingAdjustment:(NSSize) adjust;
{
	NSGraphicsContext *ctxt=[NSGraphicsContext currentContext];
	[ctxt _setTextPosition:point];
	if(font) [ctxt _setFont:font];
	if(color) [ctxt _setColor:color];
	// FIXME: this is used with packed glyphs!!!
	[ctxt _drawGlyphs:glyphs count:glyphRange.length];	// -> (string) Tj
	// printingAdjustment???
}

- (BOOL) showsControlCharacters; { return (_layoutOptions&NSShowControlGlyphs) != 0; }
- (BOOL) showsInvisibleCharacters; { return (_layoutOptions&NSShowInvisibleGlyphs) != 0; }

- (void) strikethroughGlyphRange:(NSRange)glyphRange
			   strikethroughType:(int)strikethroughVal
				lineFragmentRect:(NSRect)lineRect
		  lineFragmentGlyphRange:(NSRange)lineGlyphRange
				 containerOrigin:(NSPoint)containerOrigin;
{
	[self ensureLayoutForGlyphRange:glyphRange];
	[self drawStrikethroughForGlyphRange:glyphRange strikethroughType:strikethroughVal baselineOffset:0.0 lineFragmentRect:lineRect lineFragmentGlyphRange:lineGlyphRange containerOrigin:containerOrigin];
}

- (NSFont *) substituteFontForFont:(NSFont *) originalFont;
{
	NSFont *newFont;
	if(_usesScreenFonts)
		{
		// FIXME: check if any NSTextView is scaled or rotated
		newFont=[originalFont screenFontWithRenderingMode:NSFontDefaultRenderingMode];	// use matching screen font based on defaults settings
		if(newFont)
			return newFont;
		}
	return originalFont;
}

- (id) temporaryAttribute:(NSString *) name 
		 atCharacterIndex:(NSUInteger) loc 
		   effectiveRange:(NSRangePointer) effectiveRange;
{
//	if(index >= _numberOfGlyphs)
//		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", index];
//	return _glyphs[glyphIndex].extra;	
	return NIMP;
}

- (id) temporaryAttribute:(NSString *) name 
		 atCharacterIndex:(NSUInteger) loc 
	longestEffectiveRange:(NSRangePointer) effectiveRange 
				  inRange:(NSRange) limit;
{
//	if(index >= _numberOfGlyphs)
//		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", index];
//	return _glyphs[glyphIndex].extra;	
	return NIMP;
}

- (NSDictionary *) temporaryAttributesAtCharacterIndex:(NSUInteger) loc 
								 longestEffectiveRange:(NSRangePointer) effectiveRange 
											   inRange:(NSRange) limit;
{
//	if(index >= _numberOfGlyphs)
//		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", index];
//	return _glyphs[glyphIndex].extra;
	return NIMP;
}

- (NSDictionary *) temporaryAttributesAtCharacterIndex:(NSUInteger) index effectiveRange:(NSRangePointer) charRange;
{
	return NIMP;
}

- (void) textContainerChangedGeometry:(NSTextContainer *)container;
{
	// trigger invalidation
	NIMP;
}

- (void) textContainerChangedTextView:(NSTextContainer *)container;
{
	// trigger invalidation
	NIMP;
}

// FIXME

// we should circle through containers touched by range
// NOTE: the container rect might be very large if the container covers several 10-thousands lines
// therefore, this algorithm must be very efficient
// and there might be several thousand containers...

- (NSTextContainer *) textContainerForGlyphAtIndex:(unsigned)glyphIndex effectiveRange:(NSRange *)effectiveGlyphRange;
{
	return [self textContainerForGlyphAtIndex:glyphIndex effectiveRange:effectiveGlyphRange withoutAdditionalLayout:NO];
}

- (NSTextContainer *) textContainerForGlyphAtIndex:(unsigned)glyphIndex effectiveRange:(NSRangePointer)effectiveGlyphRange withoutAdditionalLayout:(BOOL)flag
{
	/*
	if(!flag)
		; // additional layout
  */
#if OLD
	NSTextContainer *container=[_textContainers objectAtIndex:0];	// first one
	NSTextView *tv=[container textView];
	// FIXME: may call -[NSTypeSetter layoutCharactersInRange:forLayoutManager:maximumNumberOfLineFragments:]
	if(_textStorageChanged && tv)
		{
		_textStorageChanged=NO;
#if 0
		NSLog(@"sizing text view to changed textStorage");
#endif
		[tv didChangeText];	// let others know...
		[tv sizeToFit];	// size... - warning: this may be recursive!
		}
	return container;
#else
	if(index >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", glyphIndex];
	if(effectiveGlyphRange)
		{ // search back/forth for effective range
			
		}
	return _glyphs[glyphIndex].textContainer;
#endif	
}

- (NSArray *) textContainers; { return _textContainers; }
- (NSTextStorage *) textStorage; { return _textStorage; }

- (void) textStorage:(NSTextStorage *)str edited:(unsigned)editedMask range:(NSRange)newCharRange changeInLength:(int)delta invalidatedRange:(NSRange)invalidatedCharRange;
{
	if(!_textStorageChanged)
			{ // first call
//				NSRange glyphsToShow=NSMakeRange(0, [str length]);	// all...
//				NSTextContainer *container=[self textContainerForGlyphAtIndex:newCharRange.location effectiveRange:NULL];
//				NSTextView *tv=[container textView];
#if 0
				NSLog(@"textStorage edited");
#endif
				_textStorageChanged=YES;
			}
}

- (NSTextView *) textViewForBeginningOfSelection;
{
	return NIMP;
}

- (NSTypesetter *) typesetter; { return _typesetter; }
- (NSTypesetterBehavior) typesetterBehavior; { return [_typesetter typesetterBehavior]; }

- (void) underlineGlyphRange:(NSRange)glyphRange 
			   underlineType:(int)underlineVal 
			lineFragmentRect:(NSRect)lineRect 
			   lineFragmentGlyphRange:(NSRange)lineGlyphRange 
			 containerOrigin:(NSPoint)containerOrigin;
{
	[self ensureLayoutForGlyphRange:glyphRange];
	[self drawUnderlineForGlyphRange:glyphRange underlineType:underlineVal baselineOffset:0.0 lineFragmentRect:lineRect lineFragmentGlyphRange:lineGlyphRange containerOrigin:containerOrigin];
}

- (NSRect) usedRectForTextContainer:(NSTextContainer *)container;
{
	NSRange range=[self glyphRangeForTextContainer:container];
	return [self boundingRectForGlyphRange:range inTextContainer:container];
}

- (BOOL) usesFontLeading; { return _usesFontLeading; }
- (BOOL) usesScreenFonts; { return _usesScreenFonts; }

#pragma mark NSCoder

- (void) encodeWithCoder:(NSCoder *) coder;
{
//	[super encodeWithCoder:coder];
}

- (id) initWithCoder:(NSCoder *) coder;
{
	int lmFlags=[coder decodeInt32ForKey:@"NSLMFlags"];
#if 0
	NSLog(@"LMFlags=%d", lmFlags);
	NSLog(@"%@ initWithCoder: %@", self, coder);
#endif
	[self setDelegate:[coder decodeObjectForKey:@"NSDelegate"]];
	_textContainers=[[coder decodeObjectForKey:@"NSTextContainers"] retain];
	_textStorage=[[coder decodeObjectForKey:@"NSTextStorage"] retain];
	_usesScreenFonts=NO;
#if 0
	NSLog(@"%@ done", self);
#endif
	return self;
}

#pragma mark NSGlyphStorage
// methods for @protocol NSGlyphStorage

- (NSAttributedString *) attributedString; { return _textStorage; }

- (unsigned int) layoutOptions; { return _layoutOptions; }

- (void ) insertGlyphs:(const NSGlyph *) glyphs
				length:(unsigned int) length
		forStartingGlyphAtIndex:(unsigned int) glyph
		characterIndex:(unsigned int) index;
{
	if(glyph > _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph insert position"];
	if(!_glyphs || _numberOfGlyphs+length >= _glyphBufferCapacity)
		_glyphs=(struct NSGlyphStorage *) objc_realloc(_glyphs, sizeof(_glyphs[0])*(_glyphBufferCapacity=_numberOfGlyphs+length+20));	// make more space
	if(glyph != _numberOfGlyphs)
		memmove(&_glyphs[glyph+length], &_glyphs[glyph], sizeof(_glyphs[0])*(_numberOfGlyphs-glyph));	// make room unless we append
	// FIXME:
	// memset 0
//	memcpy(&_glyphs[glyph], glyphs, sizeof(_glyphs[0])*length);	// insert
	_numberOfGlyphs+=length;
}

- (void) setIntAttribute:(int)attributeTag value:(int)val forGlyphAtIndex:(unsigned)glyphIndex;
{ // subclasses must provide storatge for additional attributeTag values and call this for the "old" ones
	if(glyphIndex >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", glyphIndex];
	allocateExtra(&_glyphs[glyphIndex]);
	switch(attributeTag) {
		case NSGlyphAttributeSoft:
			_glyphs[glyphIndex].extra->softAttribute=val;
			break;
		case NSGlyphAttributeElastic:
			_glyphs[glyphIndex].extra->elasticAttribute=val;
			break;
		case NSGlyphAttributeBidiLevel:
			_glyphs[glyphIndex].extra->bidiLevelAttribute=val;
			break;
		case NSGlyphAttributeInscribe:
			_glyphs[glyphIndex].extra->inscribeAttribute=val;
			break;
		default:
			[NSException raise:@"NSLayoutManager" format:@"unknown intAttribute tag: %u", attributeTag];
	}
}

@end

