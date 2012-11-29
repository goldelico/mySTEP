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
#import "NSSimpleHorizontalTypesetter.h"

#define OLD	0

#if OLD

@implementation NSLayoutManager (SimpleVersion)	// defined as a category to overwrite methods of the full version

/*
 * this is our old core layout and drawing method
 * it works quite well but has 3 limitations
 *
 * 1. it recalculates the complete layout for each drawing call since there is no caching
 * 2. it can't properly align vertically if font size is variable
 * 3. it can't handle horizontal alignment
 *
 * some minor limitations
 * 4. can't handle more than one text container
 * 5. recalculates for invisible ranges
 * 6. may line-break words at attribute run sections instead of hyphenation positions
 * 7. does not use a NSTypeSetter
 *
 */

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
#if 0
	{	// FIXME: this needs to know more inforation
		NSParagraphStyle *para=[[_textStorage attributesAtIndex:0 effectiveRange:NULL] objectForKey:NSParagraphStyleAttributeName];
		switch([para alignment])
		{
			case NSLeftTextAlignment:
			case NSNaturalTextAlignment:
			break;
			case NSRightTextAlignment:
			case NSCenterTextAlignment:
			case NSJustifiedTextAlignment:
			{
			NSSize size=[_textStorage boundingRectForGlyphRange:[self glyphRangeForCharacterRange:NSMakeRange(0, [_textStorage length])
																						 actualCharacterRange:NULL]
												  inTextContainer:[_textContainers objectAtIndex:0]].size;
			if([para alignment] == NSRightTextAlignment)
				origin.x = NSMaxX(rect)-size.width-2.0;	// start at right edge
			else
				origin.x += (rect.size.width-size.width)/2-1.0;	// center
			}
		}
	}
#endif
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

- (NSTextContainer *) textContainerForGlyphAtIndex:(unsigned)glyphIndex effectiveRange:(NSRangePointer)effectiveGlyphRange withoutAdditionalLayout:(BOOL)flag
{
	NSTextContainer *container;
	NSTextView *tv;
	container=[_textContainers objectAtIndex:0];	// first one
	tv=[container textView];
	// FIXME: this is a hack
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
}

@end

#endif

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
							glyphIndex:(unsigned int *) glyphIndex
						characterIndex:(unsigned int *) index;
{
	NSAttributedString *astr=[storage attributedString];	// get string to layout
	NSString *str=[astr string];
	unsigned int length=[str length];
	// could be optimized a little by getting and consuming the effective range of attributes
	while(num > 0 && *index < length)
		{
		NSRange attribRange;	// range of same attributes
		NSDictionary *attribs=[astr attributesAtIndex:*index effectiveRange:&attribRange];
		NSFont *font=[attribs objectForKey:NSFontAttributeName];
		attribRange.length-=(*index)-attribRange.location;	// characters with same attributes before we start
		if(!font) font=[NSFont userFontOfSize:0.0];		// use default system font
		font=[(NSLayoutManager *) storage substituteFontForFont:font];
		while(num > 0 && attribRange.length-- > 0)
			{ // process this attribute range but not more than requested
				NSGlyph glyphs[2];
				unichar c=[str characterAtIndex:*index];
				int numGlyphs=1;
				// should map some unicode character ranges (Unicode General Category C* and U200B (ZERO WIDTH SPACE) to NSControlGlyph
				if(c == 0x200b)
					glyphs[0]=NSControlGlyph;
				else
					glyphs[0]=[font _glyphForCharacter:c];
				// if we need multiple glyphs for a single character (ligatures), insert more than one!
				// but how do we know that??? Does the font ever report that???
				[storage insertGlyphs:glyphs length:numGlyphs forStartingGlyphAtIndex:*glyphIndex characterIndex:*index];
				(*glyphIndex)+=numGlyphs;	// inc. by number of glyphs
				(*index)++;
				num--;
			}
		}
}

@end

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
	NIMP;
}

- (void) addTextContainer:(NSTextContainer *)container;
{
	[self insertTextContainer:container atIndex:[_textContainers count]];
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

// this is different from - (NSRectArray)rectArrayForGlyphRange:(NSRange)glyphRange withinSelectedGlyphRange:(NSRange)selGlyphRange inTextContainer:(NSTextContainer *)container rectCount:(NSUInteger *)rectCount

- (NSRect) boundingRectForGlyphRange:(NSRange) glyphRange 
					 inTextContainer:(NSTextContainer *) container;
{
	NSRect r=NSZeroRect;
	NSRange cRange;
	if(NSMaxRange(glyphRange) > _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph range"];
	[self ensureLayoutForGlyphRange:glyphRange];
	cRange=[self glyphRangeForTextContainer:container];
	glyphRange=NSIntersectionRange(glyphRange, cRange);	// take glyphs within given container
	while(glyphRange.length-- > 0)
		{
		// FIXME by looping over the effectiveRange for NSFontAttributeName and/or the same LFR
		NSDictionary *attribs=[_textStorage attributesAtIndex:glyphRange.location effectiveRange:NULL];	// could be optimized for font range
		NSFont *font=[self substituteFontForFont:[attribs objectForKey:NSFontAttributeName]];
		NSRect lfr=[self lineFragmentRectForGlyphAtIndex:glyphRange.location effectiveRange:NULL];
		NSPoint pos=[self locationForGlyphAtIndex:glyphRange.location];
		NSRect box;
		if(!font) font=[NSFont userFontOfSize:0.0];		// use default system font
		box=[font boundingRectForGlyph:[self glyphAtIndex:glyphRange.location]];	// origin is on baseline
		pos.x+=lfr.origin.x;
		pos.y+=lfr.origin.y;	// move to container coordinates
		pos.x+=box.origin.x;
		pos.y+=box.origin.y;	// container is in flipped coordinates
		r=NSUnionRect(r, box);
		glyphRange.location++;
		}
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
	if(glyphIndex == 0)
		return 0;
	if(glyphIndex >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", glyphIndex];
	return _glyphs[glyphIndex].characterIndex;
}

- (NSRange) characterRangeForGlyphRange:(NSRange)glyphRange actualGlyphRange:(NSRangePointer)actualGlyphRange;
{
	NSRange r;
	if(NSMaxRange(glyphRange) > _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph range"];
	r.location=_glyphs[glyphRange.location].characterIndex;
	r.length=_glyphs[NSMaxRange(glyphRange)].characterIndex-r.location;
	if(actualGlyphRange)
		{
			while(glyphRange.location > 0 && _glyphs[glyphRange.location-1].characterIndex==r.location)
				glyphRange.location--, glyphRange.length++;	// previous glyphs belong to the same character (ligature)
			while(NSMaxRange(glyphRange) < _numberOfGlyphs && _glyphs[NSMaxRange(glyphRange)].characterIndex==r.location)
				glyphRange.length++;	// next glyphs belong to the same character index
			*actualGlyphRange=glyphRange;	// may have been extended
		}
#if 0
	NSLog(@"characterRangeForGlyphRange = %@", NSStringFromRange(r));
#endif
	return r;
}

- (void) dealloc;
{
	if(_glyphs)
		{
		[self deleteGlyphsInRange:NSMakeRange(0, _numberOfGlyphs)];
		objc_free(_glyphs);
		}
	[_extraLineFragmentContainer release];
	[_glyphGenerator release];
	[_typesetter release];
	[_textContainers release];
	if(_textContainerInfo)
		objc_free(_textContainerInfo);
	[super dealloc];
}

- (NSImageScaling) defaultAttachmentScaling; { return _defaultAttachmentScaling; }

- (CGFloat) defaultBaselineOffsetForFont:(NSFont *) font;
{
	// FIXME: ask typesetter behaviour???
	return -[font descender];
}

- (float) defaultLineHeightForFont:(NSFont *) font;
{ // may differ from [font defaultLineHeightForFont]
	float leading=[font leading];
	float height;
	height=floor([font ascender]+0.5)+floor(0.5-[font descender]);
	if(leading > 0)
		height += leading + floor(0.2*height + 0.5);
	return height;
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
	if(_numberOfGlyphs != NSMaxRange(glyphRange))
		memcpy(&_glyphs[glyphRange.location], &_glyphs[NSMaxRange(glyphRange)], sizeof(_glyphs[0])*(_numberOfGlyphs-NSMaxRange(glyphRange)));
	_numberOfGlyphs-=glyphRange.length;
}

- (void) drawBackgroundForGlyphRange:(NSRange)glyphsToShow 
							 atPoint:(NSPoint)origin;
{ // draw selection range background
	if(glyphsToShow.length > 0)
		{
		NSTextContainer *textContainer=[self textContainerForGlyphAtIndex:glyphsToShow.location effectiveRange:NULL];	// this call could fill the cache if needed...
		NSColor *color=[NSColor selectedTextBackgroundColor];
		unsigned int cnt;
		NSRectArray r=[self rectArrayForGlyphRange:glyphsToShow withinSelectedGlyphRange:glyphsToShow inTextContainer:textContainer rectCount:&cnt];
		// FIXME: how do we handle the origin?
		[self fillBackgroundRectArray:r count:cnt forCharacterRange:glyphsToShow color:color];
		}
	// also calls -[NSTextBlock drawBackgroundWithRange... ] if needed
}

- (void) drawGlyphsForGlyphRange:(NSRange)glyphsToShow 
						 atPoint:(NSPoint)origin;		// top left of the text container (in flipped coordinates)
{ // The CircleView shows that this method knows about colors (and fonts) and also draws strikethrough and underline
	NSGraphicsContext *ctxt=[NSGraphicsContext currentContext];
	NSColor *lastColor=nil;
	NSFont *lastFont=nil;
	NSDictionary *attribs=nil;
	NSDictionary *newAttribs=nil;
	NSRange attribRange={ 0, 0 };	// range of same attributes
	NSRect lfr;
	NSRect newLfr;
	NSRange lfrRange={ 0, 0 };	// range of same lfr
	int count=0;
	[ctxt _beginText];
	while(glyphsToShow.length > 0)
		{
		NSGlyph *glyphs;
		/*
		 NSTextAttachment *attachment=[attribs objectForKey:NSAttachmentAttributeName];
		 if(attachment){
		 id <NSTextAttachmentCell> cell=[attachment attachmentCell];
		 NSRect frame;		 
		 frame.origin=point;
		 frame.size=[cell cellSize];
		 [cell drawWithFrame:frame inView:textView characterIndex:characterRange.location layoutManager:self];
		 */
		while(count < glyphsToShow.length)
			{ // get visible glyph range with uniform attributes and same lfr
				if(glyphsToShow.location+count >= NSMaxRange(attribRange))
					{ // update attributes
						unsigned int cindex;
						cindex=[self characterIndexForGlyphAtIndex:glyphsToShow.location+count];
						newAttribs=[_textStorage attributesAtIndex:cindex effectiveRange:&attribRange];
						break;
					}
				if(glyphsToShow.location+count >= NSMaxRange(lfrRange))
					{ // update lfr
						newLfr=[self lineFragmentRectForGlyphAtIndex:glyphsToShow.location+count effectiveRange:&lfrRange withoutAdditionalLayout:YES];
						break;
					}
				if([self notShownAttributeForGlyphAtIndex:glyphsToShow.location+count])
					{ // don't include in this list but skip
						glyphsToShow.length--;
						glyphsToShow.location++;			
						break;
					}
				count++;	// include in this chunk
			}
		if(count > 0)
			{ // there is something to draw
			NSPoint pos=[self locationForGlyphAtIndex:glyphsToShow.location];	// location of baseline within its line fragment
			NSColor *color=[attribs objectForKey:NSForegroundColorAttributeName];
			NSFont *font=[self substituteFontForFont:[attribs objectForKey:NSFontAttributeName]];
			if(!color) color=[NSColor blackColor];	// default color is black
			if(!font) font=[NSFont userFontOfSize:0.0];		// use default system font
			if(color != lastColor) [lastColor=color set];
			if(font != lastFont) [lastFont=font set];
			// handle NSStrokeWidthAttributeName
			// handle NSShadowAttributeName
			// handle NSObliquenessAttributeName
			// handle NSExpansionAttributeName
			
			// FIXME: is this relative or absolute position???
		
			pos.x+=lfr.origin.x+origin.x;
			pos.y=origin.y+pos.y+lfr.origin.y;	// translate container and glyphs
				{
				NSAffineTransform *tm=[NSAffineTransform transform];
				[tm translateXBy:pos.x yBy:pos.y];
				[ctxt _setTM:tm];
				// FIXME: when can we use relative PDF positioning commands?
				// [ctxt _setTextPosition:pos];	// x y Td
				// or [ctxt newLine] T*
				}
			glyphs=objc_malloc(sizeof(*glyphs)*(count+1));	// stores NSNullGlyph at end
			[self getGlyphs:glyphs range:NSMakeRange(glyphsToShow.location, count)];
			[ctxt _drawGlyphs:glyphs count:count];	// -> (string) Tj
			objc_free(glyphs);
			glyphsToShow.length-=count;
			glyphsToShow.location+=count;
			[[attribs objectForKey:NSUnderlineColorAttributeName] set];
			[[attribs objectForKey:NSUnderlineStyleAttributeName] intValue];
			/* get underline attribute value
			 [self drawUnderlineForGlyphRange:(NSRange)glyphRange 
			 underlineType:(int)underlineVal 
			 baselineOffset:[_typesetter baselineOffsetInLayoutManager:self glyphIndex:startIndex];
			 lineFragmentRect:(NSRect)lineRect 
			 lineFragmentGlyphRange:(NSRange)lineGlyphRange 
			 containerOrigin:(NSPoint)containerOrigin;
			 */
			/* get strikethrough attribute value
			 [self drawStrikethroughForGlyphRange:(NSRange)glyphRange 
			 strikethroughType:(int)strikethroughVal 
			 baselineOffset:[_typesetter baselineOffsetInLayoutManager:self glyphIndex:startIndex] 
			 lineFragmentRect:(NSRect)lineRect 
			 lineFragmentGlyphRange:(NSRange)lineGlyphRange 
			 containerOrigin:(NSPoint)containerOrigin;
			 */
				count=0;
			}
		attribs=newAttribs;
		lfr=newLfr;
		}
	[ctxt _endText];
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
	// how do we get to the font?
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
	if(_glyphsAreValid)
		return;
	[self deleteGlyphsInRange:NSMakeRange(0, _numberOfGlyphs)];	// delete all existing glyphs
	_firstUnlaidGlyphIndex=0;
	_firstUnlaidCharacterIndex=0;
	[_glyphGenerator generateGlyphsForGlyphStorage:self
						 desiredNumberOfCharacters:range.length
										glyphIndex:&_firstUnlaidGlyphIndex
									characterIndex:&_firstUnlaidCharacterIndex];	// generate Glyphs (code but not position!)
	_glyphsAreValid=YES;
}

- (void) ensureGlyphsForGlyphRange:(NSRange) range;
{
	// FIXME:
	[self ensureGlyphsForCharacterRange:range];
	// check
}

- (void) ensureLayoutForBoundingRect:(NSRect) rect inTextContainer:(NSTextContainer *) textContainer;
{
	[self ensureLayoutForTextContainer:textContainer];	
}

- (void) ensureLayoutForCharacterRange:(NSRange) range;
{	
	if(_layoutIsValid)
		return;
	_firstUnlaidCharacterIndex=0;
	[self ensureGlyphsForCharacterRange:range];
	_layoutIsValid=YES;	// avoid recursion
	[_typesetter layoutCharactersInRange:range forLayoutManager:self maximumNumberOfLineFragments:INT_MAX];
}

- (void) ensureLayoutForGlyphRange:(NSRange) range;
{
	// FIXME:
	[self ensureLayoutForCharacterRange:range];
}

- (void) ensureLayoutForTextContainer:(NSTextContainer *) textContainer;
{
	// FIXME:
	[self ensureLayoutForCharacterRange:NSMakeRange(0, [_textStorage length])];
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
	unsigned cnt=glyphsRange.length;
	while(cnt-- > 0)
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
	return glyphsRange.length;
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

- (NSGlyphGenerator *) glyphGenerator; { return _glyphGenerator; }

- (NSUInteger) glyphIndexForCharacterAtIndex:(NSUInteger) index;
{
	unsigned int i;
	if(index == 0)
		return 0;
	// generate glyphs if needed
	if(index >= [_textStorage length])
		return index-[_textStorage length]+_numberOfGlyphs;	// extrapolate
	for(i=0; i<_numberOfGlyphs; i++)
		if(_glyphs[i].characterIndex == index)
			return i;	// found
	return NSNotFound;
}

- (unsigned int) glyphIndexForPoint:(NSPoint)aPoint inTextContainer:(NSTextContainer *)aTextContainer;
{
	return [self glyphIndexForPoint:aPoint inTextContainer:aTextContainer fractionOfDistanceThroughGlyph:NULL];
}

- (unsigned int) glyphIndexForPoint:(NSPoint)aPoint
				inTextContainer:(NSTextContainer *)textContainer
 fractionOfDistanceThroughGlyph:(float *)partialFraction;
{
	unsigned int i;
	NSRange cRange=[self glyphRangeForTextContainer:textContainer];
	[self ensureLayoutForTextContainer:textContainer]; // additional layout
	while(cRange.length-- > 0)
		{
		// check if point is within glyph
		// if(partialFraction)
		// calculate from location and width
		cRange.location++;
		}
	return NSNotFound;	
}

- (NSRange) glyphRangeForBoundingRect:(NSRect)bounds 
					  inTextContainer:(NSTextContainer *)container;
{
	[self ensureLayoutForBoundingRect:bounds inTextContainer:container]; // do any additional layout
	return [self glyphRangeForBoundingRectWithoutAdditionalLayout:bounds inTextContainer:container];
}

- (NSRange) glyphRangeForBoundingRectWithoutAdditionalLayout:(NSRect)bounds 
											 inTextContainer:(NSTextContainer *)container;
{
	NSUInteger idx=[_textContainers indexOfObjectIdenticalTo:container];
	NSRange r;
	NSAssert(idx != NSNotFound, @"Text Container unknown for NSLayoutManager");
	if(_textContainerInfo[idx].valid && NSContainsRect(bounds, (NSRect) { NSZeroPoint, [container containerSize] }))
	   return _textContainerInfo[idx].glyphRange;
	for(r.location=0; r.location < _numberOfGlyphs; r.location++)
		if(_glyphs[r.location].textContainer == container && NSIntersectsRect(_glyphs[r.location].lineFragmentRect, bounds))
			break;	// first glyph in this container found that falls into the bounds
	for(r.length=0; NSMaxRange(r) < _numberOfGlyphs; r.length++)
		if(_glyphs[NSMaxRange(r)].textContainer != container)
			break;	// last glyph found because next one belongs to a different container
	// we should trim off all glyphs from the end that are outside of the bounds
	return r;
}

- (NSRange) glyphRangeForCharacterRange:(NSRange)charRange actualCharacterRange:(NSRange *)actualCharRange;
{
	NSRange r;
	if(NSMaxRange(charRange) > [_textStorage length])
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph range"];
	// FIXME: can we find a faster algorithm? E.g. by looking up the container range and searching only within containers?
	// or by a binary search?
	[self ensureGlyphsForCharacterRange:charRange];
	for(r.location=0; r.location<_numberOfGlyphs; r.location++)
		{
		if(_glyphs[r.location].characterIndex == charRange.location)
			break;	// first in range found
		}
	for(r.length=0; NSMaxRange(r)<_numberOfGlyphs; r.length++)
		{
		if(_glyphs[NSMaxRange(r)].characterIndex == NSMaxRange(charRange))
			break;	// first no longer in range found		
		}
	if(actualCharRange)
		{ // how can it be different from charRange???
		*actualCharRange=charRange;		
		}
#if 0
	NSLog(@"glyphRangeForCharacterRange = %@", NSStringFromRange(r));
#endif
	return r;
}

- (NSRange) glyphRangeForTextContainer:(NSTextContainer *)container;
{
	int idx=[_textContainers indexOfObject:container];
	NSAssert(idx != NSNotFound, @"Text Container unknown for NSLayoutManager");
	if(!_textContainerInfo[idx].valid)
		[self ensureLayoutForTextContainer:container];
	return _textContainerInfo[idx].glyphRange;
}

- (BOOL) hasNonContiguousLayout; { return _hasNonContiguousLayout; }
- (float) hyphenationFactor; { return _hyphenationFactor; }

- (id) init;
{
	if((self=[super init]))
		{
		_textContainers=[NSMutableArray new];
		_typesetter=[[NSTypesetter sharedSystemTypesetter] retain];
		_glyphGenerator=[[NSGlyphGenerator sharedGlyphGenerator] retain];
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
	NSUInteger cnt=[_textContainers count];	// before insertion
	[_textContainers insertObject:container atIndex:index];
	if(index == 0)
		_firstTextView=[container textView];	// has changed
	_textContainerInfo=(struct _NSTextContainerInfo *) objc_realloc(_textContainerInfo, sizeof(_textContainerInfo[0])*(cnt+1));	// (re)allocate memory
	if(index != cnt)
		memmove(&_textContainerInfo[index+1], &_textContainerInfo[index], sizeof(_textContainerInfo[0])*(cnt-index));	// make room for new slot
	memset(&_textContainerInfo[index], 0, sizeof(_textContainerInfo[0]));	// clear new slot
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
	[self invalidateDisplayForGlyphRange:[self glyphRangeForCharacterRange:charRange actualCharacterRange:NULL]];
}

- (void) invalidateDisplayForGlyphRange:(NSRange)glyphRange;
{
	// [textview setNeedsDisplayInRect:rect avoidAdditionalLayout:YES]
}

- (void) invalidateGlyphsForCharacterRange:(NSRange)charRange changeInLength:(int)delta actualCharacterRange:(NSRange *)actualCharRange;
{
	// FIXME:
	[self invalidateGlyphsOnLayoutInvalidationForGlyphRange:NSMakeRange(0, _numberOfGlyphs)];	// delete all we have
}

- (void) invalidateGlyphsOnLayoutInvalidationForGlyphRange:(NSRange) range;
{
	unsigned idx=range.location;
	while(idx < NSMaxRange(range))
		_glyphs[idx].validFlag=NO;
	if(_firstUnlaidGlyphIndex > range.location)
		_firstUnlaidGlyphIndex=range.location;
	if(_firstUnlaidGlyphIndex == 0)
		_glyphsAreValid=NO;
	_layoutIsValid=NO;
}

- (void) invalidateLayoutForCharacterRange:(NSRange) range actualCharacterRange:(NSRangePointer) charRange;
{
	// Invalidates the layout information for the glyphs mapped to the given range of characters.
	[self invalidateLayoutForCharacterRange:range isSoft:NO actualCharacterRange:charRange];
}

- (void) invalidateLayoutForCharacterRange:(NSRange)charRange isSoft:(BOOL)flag actualCharacterRange:(NSRange *)actualCharRange;
{
	// Invalidates the layout information for the glyphs mapped to the given range of characters
	// flag: If YES, invalidates internal caches in the layout manager; if NO, invalidates layout.
	[_delegate layoutManagerDidInvalidateLayout:self];
	_layoutIsValid=NO;
	// FIXME: invalidate the glyph range of the text container
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
	[self ensureLayoutForCharacterRange:NSMakeRange(0, [_textStorage length])];
	return [self lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange:effectiveGlyphRange withoutAdditionalLayout:NO];
}

- (NSRect) lineFragmentRectForGlyphAtIndex:(NSUInteger) index effectiveRange:(NSRangePointer) range withoutAdditionalLayout:(BOOL) layoutFlag;
{
	NSRect lfr;
	if(!layoutFlag)
		;	// do additional layout
	if(index >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", index];
	lfr=_glyphs[index].lineFragmentRect;
	if(range)
		{ // find the effective range by searching back and forth from the current index for glyphs with the same lfr
			range->location=index;
			while(range->location > 0)
				{
				if(!NSEqualRects(lfr, _glyphs[range->location-1].lineFragmentRect))
					break;	// previous index is different
				range->location--;
				}
			range->length=index-range->location;
			while(NSMaxRange(*range) < _numberOfGlyphs)
				{
				if(!NSEqualRects(lfr, _glyphs[NSMaxRange(*range)].lineFragmentRect))
					break;	// next index is different
				range->length++;
				}
		}
	return lfr;
}

- (NSRect) lineFragmentUsedRectForGlyphAtIndex:(unsigned) index effectiveRange:(NSRange *) range;
{
	NSRect lfur;
	if(index >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", index];
	lfur=_glyphs[index].usedLineFragmentRect;
	if(range)
		{ // find the effective range by searching back and forth from the current index for glyphs with the same lfr
			range->location=index;
			while(range->location > 0)
				{
				if(!NSEqualRects(lfur, _glyphs[range->location-1].usedLineFragmentRect))
					break;	// previous index is different
				range->location--;
				}
			range->length=index-range->location;
			while(NSMaxRange(*range)+1 < _numberOfGlyphs)
				{
				if(!NSEqualRects(lfur, _glyphs[NSMaxRange(*range)+1].usedLineFragmentRect))
					break;	// next index is different
				range->length++;
				}
		}
	return lfur;
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

- (NSRect *) rectArrayForCharacterRange:(NSRange) charRange 
		  withinSelectedCharacterRange:(NSRange) selCharRange 
					   inTextContainer:(NSTextContainer *) container 
							 rectCount:(unsigned *) rectCount;
{
	// CHECKME: which one is better to base on the other method?
	charRange=[self glyphRangeForCharacterRange:charRange actualCharacterRange:NULL];
	selCharRange=[self glyphRangeForCharacterRange:selCharRange actualCharacterRange:NULL];
	return [self rectArrayForGlyphRange:charRange withinSelectedGlyphRange:selCharRange inTextContainer:container rectCount:rectCount];
}

- (NSRect *) rectArrayForGlyphRange:(NSRange) glyphRange 
		  withinSelectedGlyphRange:(NSRange) selGlyphRange 
				   inTextContainer:(NSTextContainer *) container 
						 rectCount:(unsigned *) rectCount;
{
	// FIXME: this is not shared between all instances!
	static NSRect rect[3];	// owned by us and reused; also reused by boundingRectForGlyphRange:inTextContainer (???)
	// check that selGlyphRange contains glyphRange
	// or selGlyphRange.location == NSNotFound
	// find first partial line range (unless empty)
	// find middle "box"
	// find last partial line (unless empty)
	
	if(NSIsEmptyRect(rect[2]))
		{
		if(NSIsEmptyRect(rect[1]))
			*rectCount=1;
		else
			*rectCount=2;
		}
	else
		*rectCount=3;
	return rect;
}

- (void) removeTemporaryAttribute:(NSString *)name forCharacterRange:(NSRange)charRange;
{
	NIMP;
}

- (void) removeTextContainerAtIndex:(unsigned)index;
{
	NSUInteger cnt=[_textContainers count];	// before removing
	if(index == 0)
		_firstTextView=nil;	// might have changed
	[_textContainers removeObjectAtIndex:index];
	if(cnt != index+1)
		memmove(&_textContainerInfo[index], &_textContainerInfo[index+1], sizeof(_textContainerInfo[0])*(cnt-index-1));	// make room for new slot
	// invalidate?
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

- (void) setAttachmentSize:(NSSize) attachmentSize forGlyphRange:(NSRange) glyphRange;
{
	// DEPRECATED
	if(NSMaxRange(glyphRange) > _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph range"];
	NIMP;
}

- (void) setBackgroundLayoutEnabled:(BOOL) flag; { _backgroundLayoutEnabled=flag; }

- (void) setBoundsRect:(NSRect) rect forTextBlock:(NSTextBlock *) block glyphRange:(NSRange) glyphRange;
{
	NIMP;
}

- (void) setCharacterIndex:(unsigned) charIndex forGlyphAtIndex:(unsigned) index;
{ // character indices should be ascending with glyphIndex...
	if(index >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", index];
	_glyphs[index].characterIndex=charIndex;
}

- (void) setDefaultAttachmentScaling:(NSImageScaling) scaling; { _defaultAttachmentScaling=scaling; }

- (void) setDelegate:(id) obj; { _delegate=obj; }

- (void) setDrawsOutsideLineFragment:(BOOL) flag forGlyphAtIndex:(unsigned) index;
{
	if(index >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", index];
	_glyphs[index].drawsOutsideLineFragment=flag;
}

- (void) setExtraLineFragmentRect:(NSRect) fragmentRect usedRect:(NSRect) usedRect textContainer:(NSTextContainer *) container;
{ // used to define a virtual extra line to display the insertion point if there is no content or the last character is a hard break
	_extraLineFragmentRect=fragmentRect;
	_extraLineFragmentUsedRect=usedRect;
	[_extraLineFragmentContainer autorelease];
	_extraLineFragmentContainer=[container retain];
}

- (void) setGlyphGenerator:(NSGlyphGenerator *) gg; { ASSIGN(_glyphGenerator, gg); }

- (void) setHyphenationFactor:(float) factor; { _hyphenationFactor=factor; }

- (void) setLayoutRect:(NSRect) rect forTextBlock:(NSTextBlock *) block glyphRange:(NSRange) glyphRange;
{
	NIMP;
}

- (void) setLineFragmentRect:(NSRect) fragmentRect forGlyphRange:(NSRange) glyphRange usedRect:(NSRect) usedRect;
{
	if(NSMaxRange(glyphRange) > _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph range"];
	while(glyphRange.length-- > 0)
		{
		_glyphs[glyphRange.location].lineFragmentRect=fragmentRect;
		_glyphs[glyphRange.location].usedLineFragmentRect=usedRect;
		glyphRange.location++;
		}
}

- (void) setLocation:(NSPoint) location forStartOfGlyphRange:(NSRange) glyphRange;
{
	// [self setLocations:&location startingGlyphIndexes:&glyphRange.location count:1 forGlyphRange:glyphRange];
	if(NSMaxRange(glyphRange) > _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph range"];
	_glyphs[glyphRange.location].location=location;
}

- (void) setLocations:(NSPointArray) locs 
 startingGlyphIndexes:(NSUInteger *) glyphIds 
				count:(NSUInteger) number 
		forGlyphRange:(NSRange) glyphRange; 
{
	if(NSMaxRange(glyphRange) > _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph range"];
	while(number-- > 0)
		{
		if(*glyphIds >= NSMaxRange(glyphRange) || *glyphIds < glyphRange.location)
			[NSException raise:@"NSLayoutManager" format:@"invalid glyph index not in range"];
		_glyphs[*glyphIds++].location=*locs++;	// set location
		}
}

- (void) setNotShownAttribute:(BOOL) flag forGlyphAtIndex:(unsigned) index;
{
	if(index >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", index];
	_glyphs[index].notShownAttribute=flag;
}

// FIXME: does this trigger relayout?

- (void) setShowsControlCharacters:(BOOL) flag; { if(flag) _layoutOptions |= NSShowControlGlyphs; else _layoutOptions &= ~NSShowControlGlyphs; }

- (void) setShowsInvisibleCharacters:(BOOL) flag; { if(flag) _layoutOptions |= NSShowInvisibleGlyphs; else _layoutOptions &= ~NSShowInvisibleGlyphs; }

- (void) setTemporaryAttributes:(NSDictionary *) attrs forCharacterRange:(NSRange) charRange;
{
	NIMP;
	// FIXME: this is for characters!!!
	if(NSMaxRange(charRange) > [_textStorage length])
		[NSException raise:@"NSLayoutManager" format:@"invalid character range"];
//	return _glyphs[glyphIndex].extra=flag;
}

- (void) setTextContainer:(NSTextContainer *) container forGlyphRange:(NSRange) glyphRange;
{
	NSUInteger idx=[_textContainers indexOfObjectIdenticalTo:container];
	NSAssert(idx != NSNotFound, @"Text Container unknown in NSLayoutManager");
	_textContainerInfo[idx].glyphRange=NSUnionRange(_textContainerInfo[idx].glyphRange, glyphRange);
	if(NSMaxRange(glyphRange) > _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph range"];
	// FIXME: we could binary search the best matching text container...
	while(glyphRange.length-- > 0)
		_glyphs[glyphRange.location++].textContainer=container;
}

- (void) setTextStorage:(NSTextStorage *) ts; { _textStorage=ts; [_typesetter setAttributedString:_textStorage]; _layoutIsValid=_glyphsAreValid=NO; }	// The textStorage owns the layout manager(s)
- (void) setTypesetter:(NSTypesetter *) ts; { ASSIGN(_typesetter, ts); [_typesetter setAttributedString:_textStorage]; _layoutIsValid=_glyphsAreValid=NO; }
- (void) setTypesetterBehavior:(NSTypesetterBehavior) behavior; { [_typesetter setTypesetterBehavior:behavior]; }
- (void) setUsesFontLeading:(BOOL) flag; { _usesFontLeading=flag; }
- (void) setUsesScreenFonts:(BOOL) flag; { _usesScreenFonts=flag; }

- (void) showAttachmentCell:(NSCell *) cell inRect:(NSRect) rect characterIndex:(unsigned) attachmentIndex;
{
	if([cell isKindOfClass:[NSTextAttachmentCell class]])
		[(NSTextAttachmentCell *) cell drawWithFrame:rect
											  inView:[self firstTextView]
									  characterIndex:attachmentIndex
									   layoutManager:self];
	else
		[(NSTextAttachmentCell *) cell drawWithFrame:rect
											  inView:[self firstTextView]];
}

- (void) showPackedGlyphs:(char *) glyphs
				   length:(unsigned) glyphLen	// number of bytes = 2* number of glyphs
			   glyphRange:(NSRange) glyphRange
				  atPoint:(NSPoint) point
					 font:(NSFont *) font
					color:(NSColor *) color
	   printingAdjustment:(NSSize) adjust;
{
	NIMP;	// what is this method still used for?
	NSGraphicsContext *ctxt=[NSGraphicsContext currentContext];
	[ctxt _setTextPosition:point];
	if(font) [ctxt _setFont:font];
	if(color) [ctxt _setColor:color];
	// FIXME: this is used with packed glyphs!!!
//	[ctxt _drawGlyphs:glyphs count:glyphRange.length];	// -> (string) Tj
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
	[self drawStrikethroughForGlyphRange:glyphRange strikethroughType:strikethroughVal baselineOffset:[_typesetter baselineOffsetInLayoutManager:self glyphIndex:glyphRange.location] lineFragmentRect:lineRect lineFragmentGlyphRange:lineGlyphRange containerOrigin:containerOrigin];
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

// this is used for spell checking only and does only support underlining

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

- (NSDictionary *) temporaryAttributesAtCharacterIndex:(NSUInteger) index
										effectiveRange:(NSRangePointer) effectiveRange;
{
	return NIMP;
}

- (void) textContainerChangedGeometry:(NSTextContainer *) container;
{
	if(!_textContainers)
		return;	// we are not yet initialized, i.e. won't find this container
	[self invalidateDisplayForGlyphRange:[self glyphRangeForTextContainer:container]];
}

- (void) textContainerChangedTextView:(NSTextContainer *)container;
{
	[self invalidateDisplayForGlyphRange:[self glyphRangeForTextContainer:container]];
}

- (NSTextContainer *) textContainerForGlyphAtIndex:(unsigned) glyphIndex effectiveRange:(NSRange *) effectiveGlyphRange;
{
	return [self textContainerForGlyphAtIndex:glyphIndex effectiveRange:effectiveGlyphRange withoutAdditionalLayout:NO];
}

- (NSTextContainer *) textContainerForGlyphAtIndex:(unsigned) glyphIndex effectiveRange:(NSRangePointer) effectiveGlyphRange withoutAdditionalLayout:(BOOL) flag
{
	if(!flag)
		[self ensureLayoutForGlyphRange:NSMakeRange(0, glyphIndex)]; // ensure layout up to this index
	if(glyphIndex >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", glyphIndex];
	// FIXME: we could binary search the best matching text container...
	// and get rid of the _glyphs[].textContainer variable
	if(effectiveGlyphRange)
		{ // get glyph range of text container
			NSUInteger idx=[_textContainers indexOfObjectIdenticalTo:_glyphs[glyphIndex].textContainer];
			*effectiveGlyphRange=_textContainerInfo[idx].glyphRange;
		}
	return _glyphs[glyphIndex].textContainer;
}

- (NSArray *) textContainers; { return _textContainers; }
- (NSTextStorage *) textStorage; { return _textStorage; }

/* this is called by -[NSTextStorage processEditing] if the NSTextStorage has been changed */

- (void) textStorage:(NSTextStorage *) str edited:(unsigned) editedMask range:(NSRange) newCharRange changeInLength:(int) delta invalidatedRange:(NSRange) invalidatedCharRange;
{
	// this may be used to move around glyphs and separate between glyph generation (i.e.
	// translation of character codes to glyph codes through NSFont
	// and pure layout (not changing geometry of individual glyphs but their relative position)
	// check if only drawing attributes have been changed like NSColor/underline/striketrhough/link - then we do not even need to generate new glyphs or new layout positions
	if(editedMask&NSTextStorageEditedCharacters)
		{
		NSTextView *tv=[self firstTextView];
		NSRange sel=[tv selectedRange];
#if 0
		NSLog(@"textStorage:edited:%u range:%@ change:%d inval:%@", editedMask, NSStringFromRange(newCharRange), delta, NSStringFromRange(invalidatedCharRange));
		NSLog(@"  tv=%@", tv);
		if([tv frame].size.height == 0)
			NSLog(@"height became 0!");
#endif
		[self invalidateLayoutForCharacterRange:newCharRange actualCharacterRange:NULL], _glyphsAreValid=NO;
		sel=newCharRange;
		sel.location+=delta;
		[tv setSelectedRange:sel];
		}
	else if(editedMask&NSTextStorageEditedAttributes)
		[self invalidateLayoutForCharacterRange:invalidatedCharRange actualCharacterRange:NULL];
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
	// get fragments with same font???
	// use [font underlinePosition];
	[self drawUnderlineForGlyphRange:glyphRange underlineType:underlineVal baselineOffset:[_typesetter baselineOffsetInLayoutManager:self glyphIndex:glyphRange.location] lineFragmentRect:lineRect lineFragmentGlyphRange:lineGlyphRange containerOrigin:containerOrigin];
}

- (NSRect) usedRectForTextContainer:(NSTextContainer *) container;
{
	NSUInteger idx=[_textContainers indexOfObjectIdenticalTo:container];
	struct _NSTextContainerInfo *info;
	NSAssert(idx != NSNotFound, @"Text Container unknown for NSLayoutManager");
	info=&_textContainerInfo[idx];
	// FIXME: do we really have this valid flag or should the info be always up to date?
	if(!info->valid)
		{
		unsigned int idx;
		// run layout to get the glyph range
		//	 WARNING: if the layout algorithm can delete this container through a delegate, we have a problem to report...
		NSLog(@"glyph range %@", NSStringFromRange(info->glyphRange));
		for(idx=0; idx<info->glyphRange.length; idx++)
			{
			info->usedRect=NSUnionRect(info->usedRect, _glyphs[info->glyphRange.location+idx].usedLineFragmentRect);
			info->characterRange=NSUnionRange(info->characterRange, (NSRange) { _glyphs[info->glyphRange.location+idx].characterIndex, 1 });
			}
		}
	return info->usedRect;
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
	_textContainerInfo=objc_calloc(sizeof(_textContainerInfo[0]), [_textContainers count]);
	_textStorage=[[coder decodeObjectForKey:@"NSTextStorage"] retain];
	_typesetter=[[NSTypesetter sharedSystemTypesetter] retain];
	_glyphGenerator=[[NSGlyphGenerator sharedGlyphGenerator] retain];
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
	memset(&_glyphs[glyph], 0, sizeof(_glyphs[0])*length);	// clear all data and flags
	_numberOfGlyphs+=length;
	while(length-- > 0)
		{
		_glyphs[glyph].glyph=*glyphs++;
		_glyphs[glyph].characterIndex=index;	// all glyphs belong to the same character!
		_glyphs[glyph].validFlag=YES;
		glyph++;
		}
}

- (void) setIntAttribute:(int) attributeTag value:(int) val forGlyphAtIndex:(unsigned) glyphIndex;
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

