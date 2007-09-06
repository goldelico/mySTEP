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
	NSAttributedString *astr=[storage attributedString];	// get string to layout
	NSString *str=[astr string];
	unsigned int options=[storage layoutOptions];
	NSGlyph *glyphs=NULL;
	
	// FIXME: handle invisible characters, make page breaks etc. optionally visible, handle multi-character glyphs (ligatures), multi-glyph characters etc.
	// convert unicode to glyph encoding

	[storage insertGlyphs:glyphs length:num forStartingGlyphAtIndex:*glyph characterIndex:*index];
	*glyph+=num;
	*index+=num;
}

@end

@implementation NSLayoutManager

- (void) addTemporaryAttributes:(NSDictionary *)attrs forCharacterRange:(NSRange)range;
{
	NIMP;
}

- (void) addTextContainer:(NSTextContainer *)container;
{
	[textContainers addObject:container];
}

- (NSSize) attachmentSizeForGlyphAtIndex:(unsigned)index;
{
	NIMP;
	return NSZeroSize;
}

- (BOOL) backgroundLayoutEnabled; { return backgroundLayoutEnabled; }

- (NSRect) boundingRectForGlyphRange:(NSRange)glyphRange 
					 inTextContainer:(NSTextContainer *)container;
{
	// FIXME: we should ask the NSFont and glyph layout system...
	NSRange attribRange;
	NSFont *font=nil;
	NSDictionary *attrs=nil;
	NSRect r=NSZeroRect;
	unsigned int len=[textStorage length];
#if 0
	NSLog(@"boundingRectForGlyphRange %@", NSStringFromRange(glyphRange));
	NSLog(@"text storage range %@", NSStringFromRange(NSMakeRange(0, len)));
#endif
	NSAssert((glyphRange.location == 0 && glyphRange.length == len), @"can render full glyph range only");
	if(len)
		{
		attrs=[textStorage attributesAtIndex:0 longestEffectiveRange:&attribRange inRange:NSMakeRange(0, len)];
		font=[attrs objectForKey:NSFontAttributeName];
		}
	if(!font)
		font=[NSFont systemFontOfSize:12];
	r.size=[font _sizeOfString:[textStorage string]];
	return r;
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
	NIMP;
	return 0;
}

- (NSRange) characterRangeForGlyphRange:(NSRange)glyphRange actualGlyphRange:(NSRangePointer)actualGlyphRange;
{
	NIMP;
	return NSMakeRange(0, 0);
}

- (NSImageScaling) defaultAttachmentScaling; { return defaultAttachmentScaling; }

- (float) defaultLineHeightForFont:(NSFont *) font;
{
	return 12;
}

- (id) delegate; { return delegate; }

- (void) deleteGlyphsInRange:(NSRange)glyphRange;
{
	NIMP;
}

- (void) drawBackgroundForGlyphRange:(NSRange)glyphsToShow 
							 atPoint:(NSPoint)origin;
{
	// draw selection indicator
	;
}

- (void) drawGlyphsForGlyphRange:(NSRange)glyphsToShow 
						 atPoint:(NSPoint)origin;
{ // this is the core text drawing interface and all string additions are based on this call!
	NSGraphicsContext *ctxt=[NSGraphicsContext currentContext];
	NSTextContainer *container=[self textContainerForGlyphAtIndex:glyphsToShow.location effectiveRange:NULL];	// this call could fill the cache if needed...
	NSSize containerSize=[container containerSize];
	NSString *str=[textStorage string];					// raw characters
	NSRange rangeLimit=glyphsToShow;					// initial limit
	NSPoint pos;
	NSFont *font=[NSFont systemFontOfSize:12.0];		// default/current font attribute
	NSAssert(glyphsToShow.location==0 && glyphsToShow.length == [str length], @"can render ful glyph range only");
	//
	// FIXME: optimize/cache for large NSTextStorages and multiple NSTextContainers
	//
	// FIXME: use and update glyph cache if needed
	// well, we should move that to the shared NSGlyphGenerator which does the layout
	//
	// 1. split into paragraphs
	// 2. split into lines
	// 3. split into words and try to fill line and insert additional new lines if needed
	//
	// either generate (glyphs) " in PDF context or do raw drawing of the glyphs by libfreetype
	// emit positioning command(s) only if new lines and/or different containers are generated
	// i.e.
	// [ctxt _setFont:xxx]; 
	// [ctxt _beginText];
	// [ctxt _setTextPosition:origin];
	// [ctxt _setBaseline:xxx]; 
	// [ctxt _drawGlyphs:(NSGlyph *)glyphs count:(unsigned)cnt;	// -> (string) Tj
	// [ctxt _endText];
	//
	// glyphranges could be handled in string + font + position fragments
	//
	[ctxt setCompositingOperation:NSCompositeCopy];
	[ctxt _beginText];			// starts at (0,0)
	pos=origin;					// tracks current drawing position
	// we should loop over lines first
	//   then over words (for wrapping&hyphenation)
	//     then over attribute ranges (for switching modes)
	while(rangeLimit.length > 0)
		{ // parse and process white-space separated words resp. fragments with same attributes
		NSRange attribRange;	// range with constant attributes
		NSString *substr;		// substring (without attributes)
		NSDictionary *attr;		// the attributes
		id attrib;				// some individual attribute
		NSRange wordRange;		// to find word that fits into line
		NSSize size;			// size of the substr with given font
		float baseline;
		switch([str characterAtIndex:rangeLimit.location])
			{
			case NSAttachmentCharacter:
				{
				NSTextAttachment *att=[textStorage attribute:NSAttachmentAttributeName atIndex:rangeLimit.location effectiveRange:NULL];
				id <NSTextAttachmentCell> cell = [att attachmentCell];
				if(cell)
					{
					NSRect rect=[cell cellFrameForTextContainer:container
										   proposedLineFragment:NSZeroRect
												  glyphPosition:pos
												 characterIndex:rangeLimit.location];
					// FIXME: check if we need a new line
					pos.x += rect.size.width;
					// draw cell at given position
					}
				rangeLimit.location++;
				rangeLimit.length--;
				continue;
				}
			case '\t':
				{
					float tabwidth=8.0*[font _sizeOfString:@"x"].width;	// approx. 8 characters
					pos.x=(1+(int)((pos.x-origin.x)/tabwidth))*tabwidth+origin.x;
					// FIXME: check if we need a new line
					rangeLimit.location++;
					rangeLimit.length--;
					continue;
				}
			case '\n':
				{
					NSParagraphStyle *p=[textStorage attribute:NSParagraphStyleAttributeName atIndex:rangeLimit.location effectiveRange:NULL];
					float leading=1.2*[font _sizeOfString:@"X"].height+[p paragraphSpacing];
					// [ctxt _newLine];	// start new line
					if([ctxt isFlipped])
						pos.y+=leading;		// go down one line
					else
						pos.y-=leading;		// go down one line
				}
			case '\r':
				{ // start over at beginning of line but not a new line
					pos.x=origin.x;
					// [ctxt _gotohpos:pos.x];
					rangeLimit.location++;
					rangeLimit.length--;
					continue;
				}
			case ' ':
				{ // advance to next character position
					pos.x+=[font _sizeOfString:@" "].width;		// white space
					// [ctxt _gotohpos:pos.x];
					rangeLimit.location++;
					rangeLimit.length--;
					continue;
				}
			}
		attr=[textStorage attributesAtIndex:rangeLimit.location longestEffectiveRange:&attribRange inRange:rangeLimit];
		wordRange=[str rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] options:0 range:attribRange];	// embedded space in this range?
		if(wordRange.length != 0)
			{ // any whitespace found within attribute range - reduce attribute range to this word
			if(wordRange.location > attribRange.location)	
				attribRange.length=wordRange.location-attribRange.location;
			else
				attribRange.length=1;	// limit to the whitespace character itself
			}
		// FIXME: this algorithm does not really word-wrap (only) if attributes change within a word
		font=[attr objectForKey:NSFontAttributeName];
		if(!font) font=[NSFont systemFontOfSize:12.0];	// substitute default font
		substr=[str substringWithRange:attribRange];
		size=[font _sizeOfString:substr];
		if((pos.x-origin.x)+size.width > containerSize.width)
			{ // new word fragment does not fit into remaining line
			if(pos.x > origin.x)
				{ // we didn't just start on a newline, so insert a newline
//				[ctxt _newLine];
				pos.x=origin.x;
				if([ctxt isFlipped])
					pos.y+=1.2*size.height;
				else
					pos.y-=1.2*size.height;
				}
			while(size.width > containerSize.width && attribRange.length > 1)
				{ // does still not fit into box at all - we must truncate
				attribRange.length--;	// try with one character less
				substr=[str substringWithRange:attribRange];
				size=[font _sizeOfString:substr]; // get new width
				}
			}
		[[attr objectForKey:NSFontAttributeName] setInContext:ctxt];	// set font (if not nil)
		attrib=[attr objectForKey:NSForegroundColorAttributeName];
		if(attrib)
			[attrib setStroke];
		else
			[[NSColor blackColor] setStroke];	// default
		[[attr objectForKey:NSBackgroundColorAttributeName] setFill];
		baseline=0.0;
		if((attrib=[attr objectForKey:NSBaselineOffsetAttributeName]))
			baseline=[attrib floatValue];
		if((attrib=[attr objectForKey:NSSuperscriptAttributeName]))
			baseline+=3.0*[attrib intValue];
		if(pos.x != 0.0 || pos.y != 0.0)
			{ // not the first call where everything is initialized to be 0
			[ctxt _setBaseline:baseline];	// adjust baseline
			[ctxt _setTextPosition:pos];	// set where to start drawing
			}
		//
		// set kerning attributes
		//
		// FIXME: use [ctxt _drawGlyphs:(NSGlyph *)glyphs count:(unsigned)cnt;	// -> (string) Tj
		//
		[ctxt _string:substr];		// draw string
		[[attr objectForKey:NSStrokeColorAttributeName] setStroke];	// change stroke color if needed
		// 
		// FIXME: draw underlining, strike-through and Hyperlinks
		//
		rangeLimit.location=NSMaxRange(attribRange);	// handle next fragment
		rangeLimit.length-=attribRange.length;
		pos.x+=size.width;
		}
	[ctxt _endText];
}

- (BOOL) drawsOutsideLineFragmentForGlyphAtIndex:(unsigned)index;
{
	NIMP;
	return NO;
}

- (void) drawStrikethroughForGlyphRange:(NSRange)glyphRange
					  strikethroughType:(int)strikethroughVal
						 baselineOffset:(float)baselineOffset
					   lineFragmentRect:(NSRect)lineRect
				 lineFragmentGlyphRange:(NSRange)lineGlyphRange
						containerOrigin:(NSPoint)containerOrigin;
{
	NIMP;
}

- (void) drawUnderlineForGlyphRange:(NSRange)glyphRange 
					  underlineType:(int)underlineVal 
					 baselineOffset:(float)baselineOffset 
				   lineFragmentRect:(NSRect)lineRect 
			 lineFragmentGlyphRange:(NSRange)lineGlyphRange 
					containerOrigin:(NSPoint)containerOrigin;
{
	NIMP;
}

- (NSRect) extraLineFragmentRect; { return extraLineFragmentRect; }
- (NSTextContainer *) extraLineFragmentTextContainer; { return extraLineFragmentContainer; }
- (NSRect) extraLineFragmentUsedRect; { return extraLineFragmentUsedRect; }

- (NSTextView *) firstTextView;
{
	if(!firstTextView)
		{
		if([textContainers count] == 0)
			return nil;
		firstTextView=[[textContainers objectAtIndex:0] textView];
		}
	return firstTextView;
}

- (unsigned) firstUnlaidCharacterIndex;
{
	NIMP;
	return 0;
}

- (unsigned) firstUnlaidGlyphIndex;
{
	NIMP;
	return 0;
}

- (float) fractionOfDistanceThroughGlyphForPoint:(NSPoint)aPoint inTextContainer:(NSTextContainer *)aTextContainer;
{
	NIMP;
	return 0;
}

- (void) getFirstUnlaidCharacterIndex:(unsigned *)charIndex 
						   glyphIndex:(unsigned *)glyphIndex;
{
	NIMP;
}

- (unsigned) getGlyphs:(NSGlyph *)glyphArray range:(NSRange)glyphRange;
{
	NIMP;
	return 0;
}

- (unsigned) getGlyphsInRange:(NSRange)glyphsRange
					   glyphs:(NSGlyph *)glyphBuffer
			 characterIndexes:(unsigned *)charIndexBuffer
			glyphInscriptions:(NSGlyphInscription *)inscribeBuffer
				  elasticBits:(BOOL *)elasticBuffer;
{
	NIMP;
	return 0;
}

- (unsigned) getGlyphsInRange:(NSRange)glyphsRange
					   glyphs:(NSGlyph *)glyphBuffer
			 characterIndexes:(unsigned *)charIndexBuffer
			glyphInscriptions:(NSGlyphInscription *)inscribeBuffer
				  elasticBits:(BOOL *)elasticBuffer
				   bidiLevels:(unsigned char *)bidiLevelBuffer;
{
	NIMP;
	return 0;
}

- (NSGlyph) glyphAtIndex:(unsigned)glyphIndex;
{
	NIMP;
	return 0;
}

- (NSGlyph) glyphAtIndex:(unsigned)glyphIndex isValidIndex:(BOOL *)isValidIndex;
{
	NIMP;
	return 0;
}

- (NSGlyphGenerator *) glyphGenerator;
{
	if(!glyphGenerator)
		glyphGenerator=[[NSGlyphGenerator sharedGlyphGenerator] retain];
	return glyphGenerator;
}

- (unsigned) glyphIndexForPoint:(NSPoint)aPoint inTextContainer:(NSTextContainer *)aTextContainer;
{
	NIMP; return 0;
}

- (unsigned) glyphIndexForPoint:(NSPoint)aPoint
				inTextContainer:(NSTextContainer *)aTextContainer
 fractionOfDistanceThroughGlyph:(float *)partialFraction;
{
	NIMP; return 0;
}

- (NSRange) glyphRangeForBoundingRect:(NSRect)bounds 
					  inTextContainer:(NSTextContainer *)container;
{
	NSRange rng=[self glyphRangeForTextContainer:container];
	// reduce range for first and last character as needed
	return rng;
}

- (NSRange) glyphRangeForBoundingRectWithoutAdditionalLayout:(NSRect)bounds 
											 inTextContainer:(NSTextContainer *)container;
{
	NIMP;
	return NSMakeRange(0, 0);
}

- (NSRange) glyphRangeForCharacterRange:(NSRange)charRange actualCharacterRange:(NSRange *)actualCharRange;
{
	if(actualCharRange)
		*actualCharRange=charRange;
#if 0
	NSLog(@"glyphRangeForCharacterRange = %@", NSStringFromRange(charRange));
#endif
	return charRange;
}

- (NSRange) glyphRangeForTextContainer:(NSTextContainer *)container;
{
	// is this a basic or a derived method?
	return NSMakeRange(0, [textStorage length]);	// assume we have only one text container
}

- (float) hyphenationFactor; { return hyphenationFactor; }

- (id) init;
{
	if((self=[super init]))
		{
		textContainers=[NSMutableArray new];
		}
	return self;
}

- (void) dealloc;
{
	[glyphGenerator release];
	[textContainers release];
	[typesetter release];
	[super dealloc];
}

- (void) insertGlyph:(NSGlyph)glyph atGlyphIndex:(unsigned)glyphIndex characterIndex:(unsigned)charIndex;
{
	[self insertGlyphs:&glyph length:1 forStartingGlyphAtIndex:glyphIndex characterIndex:charIndex];
}

- (void) insertTextContainer:(NSTextContainer *)container atIndex:(unsigned)index;
{
	[textContainers insertObject:container atIndex:index];
	if(index == 0)
		firstTextView=nil;	// has changed
}

- (int) intAttribute:(int)attributeTag forGlyphAtIndex:(unsigned)glyphIndex;
{
	NIMP;
	return 0;
}

- (void) invalidateDisplayForCharacterRange:(NSRange)charRange;
{
	NIMP;
}

- (void) invalidateDisplayForGlyphRange:(NSRange)glyphRange;
{
	NIMP;
}

- (void) invalidateGlyphsForCharacterRange:(NSRange)charRange changeInLength:(int)delta actualCharacterRange:(NSRange *)actualCharRange;
{
	NIMP;
}

- (void) invalidateLayoutForCharacterRange:(NSRange)charRange isSoft:(BOOL)flag actualCharacterRange:(NSRange *)actualCharRange;
{
	NIMP;
}

- (BOOL) isValidGlyphIndex:(unsigned)glyphIndex;
{
	NIMP;
	return NO;
}

- (BOOL) layoutManagerOwnsFirstResponderInWindow:(NSWindow *)aWindow;
{
	NIMP;
	// check if firstResponder is a NSTextView and we are the layoutManager
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
	NIMP;
	return NSZeroRect;
}

- (NSRect) lineFragmentUsedRectForGlyphAtIndex:(unsigned)glyphIndex effectiveRange:(NSRange *)effectiveGlyphRange;
{
	NIMP;
	return NSZeroRect;
}

- (NSPoint) locationForGlyphAtIndex:(unsigned)glyphIndex;
{
	NIMP;
	return NSZeroPoint;
}

- (BOOL) notShownAttributeForGlyphAtIndex:(unsigned) glyphIndex;
{
	NIMP;
	return NO;
}

- (unsigned) numberOfGlyphs;
{
	NIMP;
	return 0;
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
		firstTextView=nil;	// might have changed
	NIMP;
}

- (void) replaceGlyphAtIndex:(unsigned)glyphIndex withGlyph:(NSGlyph)newGlyph;
{
	NIMP;
}

- (void) replaceTextStorage:(NSTextStorage *)newTextStorage;
{
	[textStorage removeLayoutManager:self];
	[newTextStorage removeLayoutManager:self];	// this calls setTextStorage
}

- (NSView *) rulerAccessoryViewForTextView:(NSTextView *)aTextView
							paragraphStyle:(NSParagraphStyle *)paraStyle
									 ruler:(NSRulerView *)aRulerView
								   enabled:(BOOL)flag;
{
	return NIMP;
}

- (NSArray*) rulerMarkersForTextView:(NSTextView *)view 
					  paragraphStyle:(NSParagraphStyle *)style 
							   ruler:(NSRulerView *)ruler;
{
	return NIMP;
}

- (void) setAttachmentSize:(NSSize)attachmentSize forGlyphRange:(NSRange)glyphRange;
{
	NIMP;
}

- (void) setBackgroundLayoutEnabled:(BOOL)flag; { backgroundLayoutEnabled=flag; }

- (void) setBoundsRect:(NSRect)rect forTextBlock:(NSTextBlock *)block glyphRange:(NSRange)glyphRange;
{
	NIMP;
}

- (void) setCharacterIndex:(unsigned)charIndex forGlyphAtIndex:(unsigned)glyphIndex;
{
	NIMP;
}

- (void) setDefaultAttachmentScaling:(NSImageScaling)scaling; { defaultAttachmentScaling=scaling; }

- (void) setDelegate:(id)obj; { delegate=obj; }

- (void) setDrawsOutsideLineFragment:(BOOL)flag forGlyphAtIndex:(unsigned)glyphIndex;
{
	NIMP;
}

- (void) setExtraLineFragmentRect:(NSRect)fragmentRect usedRect:(NSRect)usedRect textContainer:(NSTextContainer *)container;
{
	NIMP;
}

- (void) setGlyphGenerator:(NSGlyphGenerator *)gg; { ASSIGN(glyphGenerator, gg); }

- (void) setHyphenationFactor:(float)factor; { hyphenationFactor=factor; }

- (void) setIntAttribute:(int)attributeTag value:(int)val forGlyphAtIndex:(unsigned)glyphIndex;
{
	NIMP;
}

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
	NIMP;
}

- (void) setNotShownAttribute:(BOOL)flag forGlyphAtIndex:(unsigned)glyphIndex;
{
	NIMP;
}

// FIXME: does this trigger relayout?

- (void) setShowsControlCharacters:(BOOL)flag; { showsControlCharacters=flag; }

- (void) setShowsInvisibleCharacters:(BOOL)flag; { showsInvisibleCharacters=flag; }

- (void) setTemporaryAttributes:(NSDictionary *)attrs forCharacterRange:(NSRange)charRange;
{
	NIMP;
}

- (void) setTextContainer:(NSTextContainer *)container forGlyphRange:(NSRange)glyphRange;
{
	NIMP;
}

- (void) setTextStorage:(NSTextStorage *)ts; { textStorage=ts; /*ASSIGN(textStorage, ts);*/ }	// CHECKME: is this correct? the textStorage owns the layout manager(s)
- (void) setTypesetter:(NSTypesetter *)ts; { ASSIGN(typesetter, ts); }
- (void) setTypesetterBehavior:(NSTypesetterBehavior)behavior; { typesetterBehavior=behavior; }
- (void) setUsesScreenFonts:(BOOL)flag; { usesScreenFonts=flag; }

- (void) showAttachmentCell:(NSCell *)cell inRect:(NSRect)rect characterIndex:(unsigned)attachmentIndex;
{
	NIMP;
}

- (void) showPackedGlyphs:(char *)glyphs
				   length:(unsigned)glyphLen
			   glyphRange:(NSRange)glyphRange atPoint:(NSPoint)point
					 font:(NSFont *)font
					color:(NSColor *)color
	   printingAdjustment:(NSSize)adjust;
{
	NIMP;
}

- (BOOL) showsControlCharacters; { return showsControlCharacters; }
- (BOOL) showsInvisibleCharacters; { return showsInvisibleCharacters; }

- (void) strikethroughGlyphRange:(NSRange)glyphRange
			   strikethroughType:(int)strikethroughVal
				lineFragmentRect:(NSRect)lineRect
		  lineFragmentGlyphRange:(NSRange)lineGlyphRange
				 containerOrigin:(NSPoint)containerOrigin;
{
	NIMP;
}

- (NSFont *) substituteFontForFont:(NSFont *) originalFont;
{
	return NIMP;
}

- (NSDictionary *) temporaryAttributesAtCharacterIndex:(unsigned)charIndex effectiveRange:(NSRangePointer)effectiveCharRange;
{
	return NIMP;
}

- (void) textContainerChangedGeometry:(NSTextContainer *)container;
{
	NIMP;
}

- (void) textContainerChangedTextView:(NSTextContainer *)container;
{
	NIMP;
}

- (NSTextContainer *) textContainerForGlyphAtIndex:(unsigned)glyphIndex effectiveRange:(NSRange *)effectiveGlyphRange;
{
	
	// we should circle through containers touched by range
	// NOTE: the container rect might be very large if the container covers several 10-thousands lines
	// therefore, this algorithm must be very efficient
	// and there might be several thousand containers...

	return [textContainers objectAtIndex:0];	// return first one...
	return NIMP;
}

- (NSTextContainer *)textContainerForGlyphAtIndex:(unsigned)glyphIndex effectiveRange:(NSRangePointer)effectiveGlyphRange withoutAdditionalLayout:(BOOL)flag
{
	return NIMP;
}

- (NSArray *) textContainers; { return textContainers; }
- (NSTextStorage *) textStorage; { return textStorage; }

- (void) textStorage:(NSTextStorage *)str edited:(unsigned)editedMask range:(NSRange)newCharRange changeInLength:(int)delta invalidatedRange:(NSRange)invalidatedCharRange;
{
	NIMP;
}

- (NSTextView *) textViewForBeginningOfSelection;
{
	return NIMP;
}

- (NSTypesetter *) typesetter; { return typesetter; }
- (NSTypesetterBehavior) typesetterBehavior; { return typesetterBehavior; }

- (void) underlineGlyphRange:(NSRange)glyphRange 
			   underlineType:(int)underlineVal 
			lineFragmentRect:(NSRect)lineRect 
			   lineFragmentGlyphRange:(NSRange)lineGlyphRange 
			 containerOrigin:(NSPoint)containerOrigin;
{
	NIMP;
}

- (NSRect) usedRectForTextContainer:(NSTextContainer *)container;
{
	NIMP;
	return NSZeroRect;
}

- (BOOL) usesScreenFonts; { return usesScreenFonts; }

#pragma mark NSCoder

- (void) encodeWithCoder:(NSCoder *) coder;
{
//	[super encodeWithCoder:coder];
}

- (id) initWithCoder:(NSCoder *) coder;
{
//	if((self=[super initWithCoder:coder]))
		{
		int lmFlags=[coder decodeInt32ForKey:@"NSLMFlags"];
#if 0
		NSLog(@"LMFlags=%d", lmFlags);
		NSLog(@"%@ initWithCoder: %@", self, coder);
#endif
		[self setDelegate:[coder decodeObjectForKey:@"NSDelegate"]];
		textContainers=[[coder decodeObjectForKey:@"NSTextContainers"] retain];
		textStorage=[[coder decodeObjectForKey:@"NSTextStorage"] retain];
#if 0
		NSLog(@"%@ done", self);
#endif
		}
	return self;
}

#pragma NSGlyphGenerator

- (NSAttributedString *) attributedString; { return textStorage; }

- (unsigned int) layoutOptions; { return 0; }

- (void ) insertGlyphs:(const NSGlyph *) glyphs
								length:(unsigned int) length
		forStartingGlyphAtIndex:(unsigned int) glyph
				characterIndex:(unsigned int) index;
{
}

@end

