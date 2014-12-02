/*
 NSLayoutManager.m
 
 Author:	H. N. Schaller <hns@computer.org>
 Date:	Jun 2006
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */

#import <Foundation/Foundation.h>
#import <AppKit/NSGlyphGenerator.h>
#import <AppKit/NSLayoutManager.h>
#import <AppKit/NSTextContainer.h>
#import <AppKit/NSTextView.h>
#import <AppKit/NSTextStorage.h>
#import <AppKit/NSTypesetter.h>
#import <AppKit/NSTextList.h>
#import <AppKit/NSTextTable.h>

#import "NSBackendPrivate.h"
#import "NSSimpleHorizontalTypesetter.h"


@implementation NSGlyphGenerator

+ (id) sharedGlyphGenerator;
{ // a single shared instance
	static NSGlyphGenerator *sharedGlyphGenerator;
	if(!sharedGlyphGenerator)
		sharedGlyphGenerator=[[self alloc] init];
	return sharedGlyphGenerator;
}

- (void) generateGlyphsForGlyphStorage:(id <NSGlyphStorage>) storage
			 desiredNumberOfCharacters:(NSUInteger) num
							glyphIndex:(NSUInteger *) glyphIndex
						characterIndex:(NSUInteger *) index;
{
	if(num > 0)
		{
		NSAttributedString *astr=[storage attributedString];	// get string to layout
		NSString *str=[astr string];
		NSUInteger length=[str length];
		// could be optimized a little by getting and consuming the effective range of attributes
		while(num > 0 && *index < length)
			{
			NSRange attribRange=NSMakeRange(1,1);	// range of same attributes
			NSLog(@"attribRange = %@", NSStringFromRange(attribRange));
			NSLog(@"attribRange = %@", NSStringFromRange(NSMakeRange(3, 4)));

			NSDictionary *attribs=[astr attributesAtIndex:*index effectiveRange:&attribRange];
			NSFont *font=[attribs objectForKey:NSFontAttributeName];
			if(attribRange.length == 0)
				{
				NSLog(@"num = %d", num);
				NSLog(@"astr = %@", astr);
				NSLog(@"index = %d", *index);
				NSLog(@"attribRange = %@", NSStringFromRange(attribRange));
				NSLog(@"attribs = %@", attribs);
				NSAssert(attribRange.length > 0, @"should never be empty");
				}
			attribRange.length-=(*index)-attribRange.location;	// characters with same attributes before we start
			font=[(NSLayoutManager *) storage substituteFontForFont:font];
			if(!font) font=[[[(NSLayoutManager *) storage firstTextView] typingAttributes] objectForKey:NSFontAttributeName];		// try to get from typing attributes
			if(!font) font=[NSFont userFontOfSize:0.0];		// use default system font
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
					// if not, we need some Unicode mapping rules
					[storage insertGlyphs:glyphs length:numGlyphs forStartingGlyphAtIndex:*glyphIndex characterIndex:*index];
					(*glyphIndex)+=numGlyphs;	// inc. by number of glyphs
					(*index)++;
					num--;
				}
			}
		}
}

@end

@implementation NSLayoutManager

static BOOL _NSShowGlyphBoxes=NO;

+ (void) initialize
{
	// FIXME: should be a default and not an ENV variable
	char *flag=getenv("QSShowGlyphBoxes");
	if(flag) _NSShowGlyphBoxes=strcmp(flag, "YES") == 0;
}

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

- (NSSize) attachmentSizeForGlyphAtIndex:(NSUInteger)index;
{
	if(index >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", index];
	NIMP;
	return NSZeroSize;
}

- (BOOL) backgroundLayoutEnabled; { return _backgroundLayoutEnabled; }

// this is different from - (NSRectArray)rectArrayForGlyphRange:(NSRange)glyphRange withinSelectedGlyphRange:(NSRange)selGlyphRange inTextContainer:(NSTextContainer *)container rectCount:(NSUInteger *)rectCount
// documentation says that it includes glyph bounds outside of their lfr
// whilte rectArray may not include them (or does it?)

- (NSRect) boundingRectForGlyphRange:(NSRange) glyphRange 
					 inTextContainer:(NSTextContainer *) container;
{
	NSRect r=NSZeroRect;
	NSUInteger cnt;
	NSRectArray ra=[self rectArrayForGlyphRange:glyphRange withinSelectedGlyphRange:NSMakeRange(NSNotFound, 0) inTextContainer:container rectCount:&cnt];
	while(cnt-- > 0)
		r=NSUnionRect(r, ra[cnt]);
	return r;
}

// GETME: why do we need the index/glyphRange for the next two methods?
// A textBlock should always belong to a well specified glyphRange
// i.e. it should suffice to have a NSMapTable from blocks to effectiveRanges and boundsRect
// that is updated by setBoundsRect:forTextBlock:glyphRange:

- (NSRect) boundsRectForTextBlock:(NSTextBlock *)block atIndex:(NSUInteger)index effectiveRange:(NSRangePointer)range;
{
	[self ensureGlyphsForGlyphRange:NSMakeRange(0, index+1)];
	// if never set:
	return NSZeroRect;
}

- (NSRect) boundsRectForTextBlock:(NSTextBlock *)block glyphRange:(NSRange)range;
{
	[self ensureGlyphsForGlyphRange:range];
	return [self boundsRectForTextBlock:block atIndex:range.location effectiveRange:NULL];
}

- (NSUInteger) characterIndexForGlyphAtIndex:(NSUInteger) glyphIndex;
{
	if(!_allowsNonContiguousLayout)
		[self ensureGlyphsForGlyphRange:NSMakeRange(0, glyphIndex+1)];	// generate glyphs up to and including the given index
	if(glyphIndex >= _numberOfGlyphs)
		return _nextCharacterIndex+(glyphIndex-_numberOfGlyphs); // extrapolate
	return _glyphs[glyphIndex].characterIndex;	// we know...
}

- (NSRange) characterRangeForGlyphRange:(NSRange) glyphRange actualGlyphRange:(NSRangePointer) actualGlyphRange;
{
	NSRange r;
	if(!_allowsNonContiguousLayout)
		[self ensureGlyphsForGlyphRange:glyphRange];
	if(glyphRange.location >= _numberOfGlyphs)
		{ // starts at or beyond end of string
			glyphRange.location=_numberOfGlyphs;	// limit		
			r.location=_nextCharacterIndex;		// string length
		}
	else
		r.location=_glyphs[glyphRange.location].characterIndex;
	if(NSMaxRange(glyphRange) >= _numberOfGlyphs)
		{ // goes to or beyond end of string
			glyphRange.length=_numberOfGlyphs-glyphRange.location;	// limit
			r.length=_nextCharacterIndex-r.location;
		}
	else
		r.length=_glyphs[NSMaxRange(glyphRange)].characterIndex-r.location;
	if(actualGlyphRange && glyphRange.length == 0)
		*actualGlyphRange=glyphRange;
	else if(actualGlyphRange)
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
	if(_rectArray)
		objc_free(_rectArray);
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

- (CGFloat) defaultLineHeightForFont:(NSFont *) font;
{ // may differ from [font defaultLineHeightForFont]
	CGFloat leading=[font leading];
	CGFloat height;
	height=floorf([font ascender]+0.5)+floorf(0.5-[font descender]);
	if(leading > 0)
		height += leading + floorf(0.2*height + 0.5);
	return height;
}

- (id) delegate; { return _delegate; }

- (void) deleteGlyphsInRange:(NSRange)glyphRange;
{
	// FIXME: how does this invalidate the layout for the given glyphs???
	NSUInteger i;
	NSTextContainer *lcontainer=nil;
	if(NSMaxRange(glyphRange) > _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph range"];
	if(!_glyphs || glyphRange.length == 0)
		return;	// nothing to delete
	for(i=0; i<glyphRange.length; i++)
		{ // release extra records
			NSUInteger idx=glyphRange.location+i;
			if(_glyphs[idx].extra)
				{
				objc_free(_glyphs[idx].extra);
				_glyphs[glyphRange.location+i].extra=NULL;
				}
			if(_glyphs[idx].textContainer != lcontainer)
				{ // invalidate/reduce glyph ranges of container(s)
					NSUInteger tcidx=[_textContainers indexOfObjectIdenticalTo:(lcontainer=_glyphs[idx].textContainer)];
//					NSLog(@"reduce container glyph range %u", tcidx);
					NSAssert(idx != NSNotFound, @"");
					_textContainerInfo[tcidx].glyphRange=NSIntersectionRange(_textContainerInfo[tcidx].glyphRange, NSMakeRange(0, glyphRange.location));
#if FIXME
					_textContainerInfo[tcidx].usedRect=NSZeroRect;
					// since this partially invalidates the layout we may have to do more!
#endif
				}
		}
	_nextCharacterIndex=_glyphs[_numberOfGlyphs-glyphRange.length].characterIndex;	// reset to the first character we need to re-generate
	if(_numberOfGlyphs != NSMaxRange(glyphRange))
		memcpy(&_glyphs[glyphRange.location], &_glyphs[NSMaxRange(glyphRange)], sizeof(_glyphs[0])*(_numberOfGlyphs-NSMaxRange(glyphRange)));
	_numberOfGlyphs-=glyphRange.length;	// does not invalidate anything
	// reset layout (?)
	_firstUnlaidGlyphIndex=MIN(_firstUnlaidGlyphIndex, _numberOfGlyphs);
	_firstUnlaidCharacterIndex=MIN(_firstUnlaidCharacterIndex, _nextCharacterIndex);
}

- (void) drawBackgroundForGlyphRange:(NSRange)glyphsToShow 
							 atPoint:(NSPoint)origin;
{ // draw selection range background
	if(glyphsToShow.length > 0)
		{
		NSGraphicsContext *ctxt=[NSGraphicsContext currentContext];
		NSTextView *tv=[self firstTextView];	// hm. what is correct? +[NSView focusView], [textContainer view], or [self firstTextView]?
		NSTextContainer *textContainer;
		NSRange range=glyphsToShow;
		NSRectArray r;
		NSUInteger cnt, i;
		NSColor *color;
		// draw table cells background first, then background by attribute, then selection and finally characters boxes for debugging
		while((range.location < NSMaxRange(glyphsToShow)))
			{ // draw table cell background if specified
				NSParagraphStyle *style=[_textStorage attribute:NSParagraphStyleAttributeName atIndex:[self characterIndexForGlyphAtIndex:range.location] effectiveRange:&range];
				NSArray *blocks=[style textBlocks];
				range=NSIntersectionRange(range, glyphsToShow);	// effective range may be larger than requested..
				if([blocks count] > 0)
					{ // there are text blocks to fill
						NSRange charRange=[self characterRangeForGlyphRange:range actualGlyphRange:NULL];
						NSTextBlock *block;
						NSEnumerator *e=[blocks objectEnumerator];	// loop through all nested table blocks from outermost to innermost
						while((block=[e nextObject]))
							{
							NSRect rect=[self boundsRectForTextBlock:block glyphRange:range];	// get location where typesetter did place the table cell
							if(!NSIsEmptyRect(rect))
								[block drawBackgroundWithFrame:rect inView:tv characterRange:charRange layoutManager:self];	// make the cell draw the background according to its attributes
							}
					}
				range.location=NSMaxRange(range);	// go to next glyph run
			}		
		range=glyphsToShow;
		while((range.location < NSMaxRange(glyphsToShow)))
			{ // draw character background if specified
				color=[_textStorage attribute:NSBackgroundColorAttributeName atIndex:[self characterIndexForGlyphAtIndex:range.location] effectiveRange:&range];
				range=NSIntersectionRange(range, glyphsToShow);	// effective range may be larger than requested..
				if(color)
					{ // there is some range to fill
						textContainer=[self textContainerForGlyphAtIndex:range.location effectiveRange:NULL];	// this call could fill the cache if needed...
						r=[self rectArrayForGlyphRange:range withinSelectedGlyphRange:NSMakeRange(NSNotFound, 0) inTextContainer:textContainer rectCount:&cnt];
						for(i=0; i<cnt; i++)
							{
							r[i].origin.x+=origin.x;
							r[i].origin.y+=origin.y;	// move to drawing origin
#if 1
							NSLog(@"fill background %u: %@", i, NSStringFromRect(r[i]));
#endif
							}
						[color set];	// must be set before drawing (parameter below is only for informational purposes)
						[self fillBackgroundRectArray:r count:cnt forCharacterRange:glyphsToShow color:color];	// draw selection			
					}
				range.location=NSMaxRange(range);	// go to next glyph run
			}
		if(tv)
			{ // draw selection - if any
				color=[NSColor selectedTextBackgroundColor];
				textContainer=[self textContainerForGlyphAtIndex:glyphsToShow.location effectiveRange:NULL];	// this call could fill the cache if needed...
				r=[self rectArrayForGlyphRange:glyphsToShow withinSelectedGlyphRange:[tv selectedRange] inTextContainer:textContainer rectCount:&cnt];
				for(i=0; i<cnt; i++)
					{
					// FIXME: there can be negative width!?!
					r[i].origin.x+=origin.x;
					r[i].origin.y+=origin.y;	// move to drawing origin
#if 0
					NSLog(@"fill background %u: %@", i, NSStringFromRect(r[i]));
#endif
					}
				[color set];	// must be set before drawing (parameter below is only for informational purposes)
				[self fillBackgroundRectArray:r count:cnt forCharacterRange:glyphsToShow color:color];	// draw selection			
			}
		if(_NSShowGlyphBoxes)
			{ // draw bounding boxes of glyphs
				NSUInteger g;
				CGFloat advance=0.0;
				for(g=glyphsToShow.location; g < NSMaxRange(glyphsToShow); g++)
					{
					NSGlyph glyph=[self glyphAtIndex:g];
					NSRect lfr=[self lineFragmentRectForGlyphAtIndex:g effectiveRange:NULL withoutAdditionalLayout:YES];
					NSPoint pos=[self locationForGlyphAtIndex:g];	// location of baseline within its line fragment
					NSDictionary *attribs=[_textStorage attributesAtIndex:g effectiveRange:NULL];
					NSFont *font=[self substituteFontForFont:[attribs objectForKey:NSFontAttributeName]];
					NSRect box;
					if(!font) font=[[[self firstTextView] typingAttributes] objectForKey:NSFontAttributeName];		// try to get from typing attributes
					if(!font) font=[NSFont userFontOfSize:0.0];		// use default system font
					box=[font boundingRectForGlyph:glyph];	// origin is on baseline
					box.origin.x=lfr.origin.x+origin.x+pos.x+box.origin.x+advance;
					if([ctxt isFlipped])
						box.origin.y=lfr.origin.y+origin.y+pos.y-box.origin.y-box.size.height;	// translate container and glyphs
					else
						box.origin.y=lfr.origin.y+origin.y+pos.y-box.origin.y;	// translate container and glyphs
					if([self notShownAttributeForGlyphAtIndex:g])
						[[NSColor colorWithCalibratedRed:0.5 green:1.0 blue:1.0 alpha:0.2] set];
					else
						[[NSColor colorWithCalibratedRed:1.0 green:0.5 blue:1.0 alpha:0.2] set];
					NSRectFill(box);
#if 0 // only if we draw a sequence of characters
					NSSize adv;
					[font getAdvancements:&adv forGlyphs:&glyph count:1];
					advance+=adv.width;
#endif
					}
			}
		}
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
	NSInteger count=0;
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
		// FIXME: we should intersect with rangeOfNominallySpacedGlyphsContainingIndex to find a range drawable using backend advancements (nominal spacing)
		while(count < glyphsToShow.length)
			{ // get visible glyph range with uniform attributes and same lfr
				if(glyphsToShow.location+count >= NSMaxRange(attribRange))
					{ // update attributes
						NSUInteger cindex;
						cindex=[self characterIndexForGlyphAtIndex:glyphsToShow.location+count];
						newAttribs=[_textStorage attributesAtIndex:cindex effectiveRange:&attribRange];
						break;
					}
				if(glyphsToShow.location+count >= NSMaxRange(lfrRange))
					{ // update lfr
						newLfr=[self lineFragmentRectForGlyphAtIndex:glyphsToShow.location+count effectiveRange:&lfrRange withoutAdditionalLayout:YES];
						break;
					}
				// faster? 	_glyphs[index].notShownAttribute
				if([self notShownAttributeForGlyphAtIndex:glyphsToShow.location+count])
					{
					if(count == 0)
						{ // directly skip
							glyphsToShow.length--;
							glyphsToShow.location++;
							continue;						
						}
					break;	// break this glyph sequence
					}
				count++;	// include in this chunk
#if 0	// debug glyph advancement between NSFont and Server
				break;
#endif
			}
		if(count > 0)
			{ // there is something to draw
				// faster? 	pos=_glyphs[index].location;
				NSPoint pos=[self locationForGlyphAtIndex:glyphsToShow.location];	// location of baseline within its line fragment
				NSColor *color=[attribs objectForKey:NSForegroundColorAttributeName];
				NSFont *font=[self substituteFontForFont:[attribs objectForKey:NSFontAttributeName]];
				if(!color) color=[NSColor blackColor];	// default color is black
				if(!font) font=[[[self firstTextView] typingAttributes] objectForKey:NSFontAttributeName];		// try to get from typing attributes
				if(!font) font=[NSFont userFontOfSize:0.0];		// use default system font
				if(color != lastColor) [lastColor=color set];	// this should be tracked in the context/backend
				if(font != lastFont) [lastFont=font set];
				// handle NSStrokeWidthAttributeName
				// handle NSShadowAttributeName
				// handle NSObliquenessAttributeName
				// handle NSExpansionAttributeName
				
				// FIXME: is this relative or absolute position???
#if 0
				NSLog(@"origin=%@ pos=%@ lfr.origin=%@", NSStringFromPoint(origin),  NSStringFromPoint(pos), NSStringFromPoint(lfr.origin));
#endif
				pos.x=origin.x+pos.x+lfr.origin.x;
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

- (BOOL) drawsOutsideLineFragmentForGlyphAtIndex:(NSUInteger)index;
{ // happens if we use fixed line height
	[self ensureLayoutForGlyphRange:NSMakeRange(0, index+1)];
	if(index >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", index];
	return _glyphs[index].drawsOutsideLineFragment;
}

- (void) drawStrikethroughForGlyphRange:(NSRange)glyphRange
					  strikethroughType:(NSInteger)strikethroughVal
						 baselineOffset:(CGFloat)baselineOffset
					   lineFragmentRect:(NSRect)lineRect
				 lineFragmentGlyphRange:(NSRange)lineGlyphRange
						containerOrigin:(NSPoint)containerOrigin;
{
	// use [font xHeight]
	NIMP;
#if 0
	CGFloat posy=pos.y+[font ascender]+baselineOffset-[font xHeight]/2.0;
#if 0
	NSLog(@"strike through %x", style);
#endif
	[foreGround setStroke];
	[[attr objectForKey:NSStrikethroughColorAttributeName] setStroke];		// change stroke color if defined differently
	[NSBezierPath strokeLineFromPoint:NSMakePoint(pos.x, posy) toPoint:NSMakePoint(pos.x+width, posy)];
#endif				
}

- (void) drawUnderlineForGlyphRange:(NSRange)glyphRange 
					  underlineType:(NSInteger)underlineVal
					 baselineOffset:(CGFloat)baselineOffset
				   lineFragmentRect:(NSRect)lineRect 
			 lineFragmentGlyphRange:(NSRange)lineGlyphRange 
					containerOrigin:(NSPoint)containerOrigin;
{
	// use [font underlinePosition] and [font underlineThickness]
	NIMP;
#if 0
	// how do we get to the font? - in the same loop over attributeRanges as for drawGlyphs
	CGFloat posy=pos.y+[font defaultLineHeightForFont]+baselineOffset+[font underlinePosition];
#if 0
	NSLog(@"underline %x", style);
#endif
	[foreGround setStroke];
	[[attr objectForKey:NSUnderlineColorAttributeName] setStroke];		// change stroke color if defined differently
	[NSBezierPath strokeLineFromPoint:NSMakePoint(pos.x, posy) toPoint:NSMakePoint(pos.x+width, posy)];
#endif
}

- (void) ensureGlyphsForCharacterRange:(NSRange) range;
{ // this will also define the mapping between glyph to character indices in this range
	if(_nextCharacterIndex < NSMaxRange(range))
		{
		NSUInteger glyphIndex=_numberOfGlyphs;
		[_glyphGenerator generateGlyphsForGlyphStorage:self
							 desiredNumberOfCharacters:NSMaxRange(range)-_nextCharacterIndex	// we know exactly how much to do
											glyphIndex:&glyphIndex
										characterIndex:&_nextCharacterIndex];	// generate Glyphs (code but not layout position!)		
		}
}

- (void) ensureGlyphsForGlyphRange:(NSRange) range;
{ // this will also define the mapping from glyph to character indices
	NSUInteger cnt;
#if 0
	NSLog(@"ensureGlyphsForGlyphRange: %@ numberOfGlyphs=%u", NSStringFromRange(range), _numberOfGlyphs);
#endif
	while(_numberOfGlyphs < NSMaxRange(range) && _nextCharacterIndex < (cnt=[_textStorage length]))
		{ // do some more characters/glyphs
			NSUInteger glyphIndex=_numberOfGlyphs;
			[_glyphGenerator generateGlyphsForGlyphStorage:self
								 desiredNumberOfCharacters:MAX(cnt/20+1, NSMaxRange(range)-_numberOfGlyphs)
												glyphIndex:&glyphIndex
											characterIndex:&_nextCharacterIndex];	// generate Glyphs (code but not layout position!)		
		}
#if 0
	NSLog(@"  -> numberOfGlyphs=%u", _numberOfGlyphs);
#endif
}

- (void) ensureLayoutForBoundingRect:(NSRect) rect inTextContainer:(NSTextContainer *) textContainer;
{
	NSUInteger idx=[_textContainers indexOfObjectIdenticalTo:textContainer];
	NSAssert(idx != NSNotFound, @"Text Container unknown for NSLayoutManager");
	// FIXME: we should do layout one line after the other until 
	//    _firstUnlaidGlyphIndex is outside the container (either from usedRect or different container)
	//    or we reach end of the text storage
	// for simplicity we enforce the full layout until we can do better
	[self ensureLayoutForCharacterRange:NSMakeRange(0, [_textStorage length])];
}

- (void) ensureLayoutForCharacterRange:(NSRange) range;
{
	NSUInteger cnt=[_textStorage length];
#if 0
	NSLog(@"ensureLayoutForCharacterRange %@ strlen=%u", NSStringFromRange(range), cnt);
#endif
	while(_firstUnlaidCharacterIndex < NSMaxRange(range) && _firstUnlaidCharacterIndex < cnt)
		{ // not yet at end or range or text
			NSInteger fragments=INT_MAX;
			NSRange r;
			r=[_typesetter layoutCharactersInRange:NSMakeRange(_firstUnlaidCharacterIndex, NSMaxRange(range)-_firstUnlaidCharacterIndex) forLayoutManager:self maximumNumberOfLineFragments:fragments];
			_firstUnlaidCharacterIndex=NSMaxRange(r);
			if(r.length == 0)	// wasn't able to do any layout
				break;
		}
}

- (void) ensureLayoutForGlyphRange:(NSRange) range;
{ // layout is ensured if we know a text container for all glyphs
	NSUInteger cnt=[_textStorage length];
#if 0
	NSLog(@"ensureLayoutForGlyphRange %@ strlen=%u", NSStringFromRange(range), cnt);
#endif
	while(_firstUnlaidGlyphIndex < NSMaxRange(range) && _firstUnlaidCharacterIndex < cnt)
		{ // not yet at end or range or text
			NSInteger fragments=INT_MAX;
			NSRange r;
			r=[_typesetter layoutCharactersInRange:NSMakeRange(_firstUnlaidCharacterIndex, NSMaxRange(range)-_firstUnlaidCharacterIndex) forLayoutManager:self maximumNumberOfLineFragments:fragments];
			_firstUnlaidCharacterIndex=NSMaxRange(r);
			if(r.length == 0)	// wasn't able to do any layout
				break;
		}
}

- (void) ensureLayoutForTextContainer:(NSTextContainer *) textContainer;
{
	[self ensureLayoutForBoundingRect:NSMakeRect(FLT_MAX, FLT_MAX, FLT_MAX, FLT_MAX) inTextContainer:textContainer];
}

- (NSRect) extraLineFragmentRect; { return _extraLineFragmentRect; }
- (NSTextContainer *) extraLineFragmentTextContainer; { return _extraLineFragmentContainer; }
- (NSRect) extraLineFragmentUsedRect; { return _extraLineFragmentUsedRect; }

- (void) fillBackgroundRectArray:(NSRectArray) rectArray count:(NSUInteger) rectCount forCharacterRange:(NSRange) charRange color:(NSColor *) color;
{ // charRange and color are for informational purposes - color must already be set
	BOOL behaveAsOSX10_6orlater=NO;	// makes highlighting transparent
	NSRectFillListUsingOperation(rectArray, rectCount, behaveAsOSX10_6orlater?NSCompositeSourceOver:NSCompositeCopy);
}

- (NSTextView *) firstTextView;
{
	if(!_firstTextView && [_textContainers count] > 0)
		_firstTextView=[[_textContainers objectAtIndex:0] textView];	// get first (may be nil!)
	return _firstTextView;
}

- (NSUInteger) firstUnlaidCharacterIndex;
{ // this is how far layout has progressed (not Glyph generation!)
	return _firstUnlaidCharacterIndex;
}

- (NSUInteger) firstUnlaidGlyphIndex;
{ // this is how far layout has progressed (not Glyph generation!)
	return _firstUnlaidGlyphIndex;
}

- (CGFloat) fractionOfDistanceThroughGlyphForPoint:(NSPoint)aPoint inTextContainer:(NSTextContainer *)aTextContainer;
{
	CGFloat f;
	[self glyphIndexForPoint:aPoint inTextContainer:aTextContainer fractionOfDistanceThroughGlyph:&f];	// ignore index
	return f;
}

- (void) getFirstUnlaidCharacterIndex:(NSUInteger *)charIndex
						   glyphIndex:(NSUInteger *)glyphIndex;
{ // this is how far layout has progressed
	*charIndex=_firstUnlaidCharacterIndex;
	*glyphIndex=_firstUnlaidGlyphIndex;
}

- (NSUInteger) getGlyphs:(NSGlyph *)glyphArray range:(NSRange)glyphRange;
{
	NSUInteger idx=0;
	[self ensureGlyphsForGlyphRange:glyphRange];
	NSAssert(NSMaxRange(glyphRange) <= _numberOfGlyphs, @"invalid glyph range");
	while(glyphRange.length-- > 0)
		{
		if(_glyphs[glyphRange.location].glyph != NSNullGlyph)
			glyphArray[idx++]=_glyphs[glyphRange.location].glyph;
		glyphRange.location++;
		}
	glyphArray[idx]=NSNullGlyph;	// adds 0-termination (buffer must have enough capacity!)
	return idx;
}

- (NSUInteger) getGlyphsInRange:(NSRange)glyphsRange
					   glyphs:(NSGlyph *)glyphBuffer
			 characterIndexes:(NSUInteger *)charIndexBuffer
			glyphInscriptions:(NSGlyphInscription *)inscribeBuffer
				  elasticBits:(BOOL *)elasticBuffer;
{
	return [self getGlyphsInRange:glyphsRange glyphs:glyphBuffer
				 characterIndexes:charIndexBuffer glyphInscriptions:inscribeBuffer
					  elasticBits:elasticBuffer bidiLevels:NULL];
}

- (NSUInteger) getGlyphsInRange:(NSRange)glyphsRange
					   glyphs:(NSGlyph *)glyphBuffer
			 characterIndexes:(NSUInteger *)charIndexBuffer
			glyphInscriptions:(NSGlyphInscription *)inscribeBuffer
				  elasticBits:(BOOL *)elasticBuffer
				   bidiLevels:(unsigned char *)bidiLevelBuffer;
{
	NSUInteger cnt=glyphsRange.length;
	NSAssert(NSMaxRange(glyphsRange) <= _numberOfGlyphs, @"invalid glyph range");
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

- (NSGlyph) glyphAtIndex:(NSUInteger)glyphIndex;
{
	if(glyphIndex >= _numberOfGlyphs)
		{
		[self ensureGlyphsForGlyphRange:NSMakeRange(0, glyphIndex+1)];
		if(glyphIndex >= _numberOfGlyphs)	// still not enough glyphs for this index
			[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", glyphIndex];		
		}
	return _glyphs[glyphIndex].glyph;
}

- (NSGlyph) glyphAtIndex:(NSUInteger)glyphIndex isValidIndex:(BOOL *)isValidIndex;
{
	if(glyphIndex >= _numberOfGlyphs)
		{
		[self ensureGlyphsForGlyphRange:NSMakeRange(0, glyphIndex+1)];
		if(glyphIndex >= _numberOfGlyphs)	// still not enough glyphs for this index
			{
			if(isValidIndex) *isValidIndex=NO;
			return NSNullGlyph;
			}
		}
	if(isValidIndex) *isValidIndex=YES;
	return _glyphs[glyphIndex].glyph;
}

- (NSGlyphGenerator *) glyphGenerator; { return _glyphGenerator; }

- (NSUInteger) glyphIndexForCharacterAtIndex:(NSUInteger) index;
{
	NSUInteger i;
	NSAssert(_glyphs == NULL || _glyphs[0].notShownAttribute <= YES, @"_glyphs damaged");
	if(!_allowsNonContiguousLayout)
		[self ensureGlyphsForCharacterRange:NSMakeRange(0, index+1)];	// generate glyphs up to and including the given index
	if(index >= _nextCharacterIndex)
		return _numberOfGlyphs+(index-_nextCharacterIndex); // extrapolate
	for(i=0; i<_numberOfGlyphs; i++)	// we could do a binary search
		if(_glyphs[i].characterIndex == index)
			break;	// found
	return i;
}

- (NSUInteger) glyphIndexForPoint:(NSPoint)aPoint inTextContainer:(NSTextContainer *)aTextContainer;
{
	return [self glyphIndexForPoint:aPoint inTextContainer:aTextContainer fractionOfDistanceThroughGlyph:NULL];
}

- (NSUInteger) glyphIndexForPoint:(NSPoint)aPoint
					inTextContainer:(NSTextContainer *)textContainer
	 fractionOfDistanceThroughGlyph:(CGFloat *)partialFraction;
{
	NSRange cRange=[self glyphRangeForTextContainer:textContainer];
	NSRange lfrRange={ cRange.location, 0 };
	CGFloat fraction=0.0;
#if 1
	NSLog(@"crange %@", NSStringFromRange(cRange));
#endif
	while(lfrRange.location < NSMaxRange(cRange))
		{ // check all line fragment rects
			NSRect lfrRect;
			if(NSMaxRange(lfrRange) <= _numberOfGlyphs)
				lfrRect=[self lineFragmentUsedRectForGlyphAtIndex:lfrRange.location effectiveRange:&lfrRange];
			else
				{ // after last glyph (no need to care about extra fragments here)
				lfrRange.location=_numberOfGlyphs;
				break;
				}
#if 1
			NSLog(@"gindex %@ point %@ lfr %@", NSStringFromRange(lfrRange), NSStringFromPoint(aPoint), NSStringFromRect(lfrRect));
#endif
			if(aPoint.y < NSMinY(lfrRect))
				break;	// is above this line
			if(aPoint.x < NSMinX(lfrRect))
				break;	// is to the left of this line (e.g. at the end of a previous column)
			if(NSPointInRect(aPoint, lfrRect) )
				{ // inside this line fragment
					CGFloat prevx=0;
#if 1
					NSLog(@"inside");
#endif
					while(lfrRange.length > 0)
						{
						// faster: 	pos=_glyphs[index].location;
						NSPoint pos=[self locationForGlyphAtIndex:lfrRange.location];
						if(aPoint.x < pos.x)
							{ // was in previous glyph
								if(lfrRange.location > 0)
									{
									lfrRange.location--;
									fraction=(aPoint.x-prevx)/(pos.x-prevx);
									}
								break;
							}
						// FIXME: add some range where we report either side of \n of a paragraph
						prevx=pos.x;	// remember horizontal offset of glyph
						lfrRange.location++;
						lfrRange.length--;
						}
					break;	// in this line or at end if glyph index was not found in lfr range
				}
			lfrRange.location=NSMaxRange(lfrRange);	// try next lfr
		}
	if(*partialFraction)
		*partialFraction=fraction;
	return lfrRange.location;	
}

- (NSRange) glyphRangeForBoundingRect:(NSRect)bounds 
					  inTextContainer:(NSTextContainer *)container;
{
	[self ensureLayoutForBoundingRect:bounds inTextContainer:container]; // do any additional layout
	NSRange rng=[self glyphRangeForBoundingRectWithoutAdditionalLayout:bounds inTextContainer:container];
	return rng;
}

- (NSRange) glyphRangeForBoundingRectWithoutAdditionalLayout:(NSRect)bounds 
											 inTextContainer:(NSTextContainer *)container;
{ // does not generate glyphs or layout
	NSUInteger idx=[_textContainers indexOfObjectIdenticalTo:container];
	NSAssert(idx != NSNotFound, @"Text Container unknown for NSLayoutManager");
#if 1
	if(NSMaxRange(_textContainerInfo[idx].glyphRange) > _numberOfGlyphs)
		NSLog(@"layout not properly invalidated");
#endif
	return _textContainerInfo[idx].glyphRange;
}

- (NSRange) glyphRangeForCharacterRange:(NSRange)charRange actualCharacterRange:(NSRange *)actualCharRange;
{
	NSRange r;
	if(!_allowsNonContiguousLayout)
		[self ensureGlyphsForCharacterRange:charRange];
	if(charRange.location >= _nextCharacterIndex)
		{ // starts at or beyond end of string
			charRange.location=_nextCharacterIndex;	// limit		
			r.location=_numberOfGlyphs;
		}
	else
		{
		// FIXME: can we find a faster algorithm? E.g. by looking up the container range and searching only within containers?
		// or by a binary search?
		// we also need to encode multiple characters for a single glyphIndex
		for(r.location=0; r.location<_numberOfGlyphs; r.location++)
			{
			if(_glyphs[r.location].characterIndex == charRange.location)
				break;	// first in range found
			}		
		}
	if(NSMaxRange(charRange) >= _numberOfGlyphs)
		{ // goes to or beyond end of string
			charRange.length=_nextCharacterIndex-charRange.location;	// limit
			r.length=_numberOfGlyphs-r.location;
		}
	else
		{
		// FIXME: can we find a faster algorithm? E.g. by looking up the container range and searching only within containers?
		// or by a binary search?
		// we also need to encode multiple characters for a single glyphIndex
		for(r.length=0; NSMaxRange(r)<_numberOfGlyphs; r.length++)
			{
			if(_glyphs[NSMaxRange(r)].characterIndex == NSMaxRange(charRange))
				break;	// first no longer in range found		
			}		
		}
	if(actualCharRange && charRange.length == 0)
		*actualCharRange=charRange;
	else if(actualCharRange)
		{
		// find charRange
		// FIXME: our _glyph[idx] structure does not allow a single glyph to have more than one character (i.e. ligatures!)
		*actualCharRange=charRange;
		}
#if 0
	NSLog(@"glyphRangeForCharacterRange = %@", NSStringFromRange(r));
#endif
	return r;
}

- (NSRange) glyphRangeForTextContainer:(NSTextContainer *)textContainer;
{
	NSUInteger idx=[_textContainers indexOfObjectIdenticalTo:textContainer];
	NSAssert(idx != NSNotFound, @"Text Container unknown for NSLayoutManager");
	[self ensureLayoutForTextContainer:textContainer];
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

- (void) insertGlyph:(NSGlyph)glyph atGlyphIndex:(NSUInteger)glyphIndex characterIndex:(NSUInteger)charIndex;
{ // insert a single glyph without attributes
	[self insertGlyphs:&glyph length:1 forStartingGlyphAtIndex:glyphIndex characterIndex:charIndex];
}

- (void) insertTextContainer:(NSTextContainer *)container atIndex:(NSUInteger)index;
{
	NSUInteger cnt=[_textContainers count];	// before insertion
	[_textContainers insertObject:container atIndex:index];
	[container setLayoutManager:self];
	if(index == 0)
		_firstTextView=[container textView];	// has changed
	_textContainerInfo=(struct _NSTextContainerInfo *) objc_realloc(_textContainerInfo, sizeof(_textContainerInfo[0])*(cnt+1));	// (re)allocate memory
	if(index != cnt)
		memmove(&_textContainerInfo[index+1], &_textContainerInfo[index], sizeof(_textContainerInfo[0])*(cnt-index));	// make room for new slot
	memset(&_textContainerInfo[index], 0, sizeof(_textContainerInfo[0]));	// clear new slot
	NSAssert(_numberOfGlyphs == 0, @"we must invalidate glyphs");
	NSAssert(_firstUnlaidGlyphIndex == 0, @"we must invalidate layout");	// or the container mapping may be stale
	if([_textContainers count] > 1)
		NSLog(@"*** NSLayoutManager: more than 1 NSTextContainer not yet correctly supported ***");
}

- (NSInteger) intAttribute:(NSInteger)attributeTag forGlyphAtIndex:(NSUInteger)glyphIndex;
{
	if(!_allowsNonContiguousLayout)
		[self ensureGlyphsForGlyphRange:NSMakeRange(0, glyphIndex+1)];
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
	NSRect rect=NSZeroRect;
	NSTextContainer *lastContainer=nil;
	NSUInteger idx=0;
	if(NSMaxRange(glyphRange) > _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph range"];
	NSAssert(_glyphs == NULL || _glyphs[0].notShownAttribute <= 1, @"_glyphs damaged");
	while(glyphRange.length > 0 && glyphRange.location < _numberOfGlyphs)
		{
		NSTextContainer *container=_glyphs[glyphRange.location].textContainer;	// may be nil if this glyph isn't laid out yet
		if(container && container != lastContainer)
			{ // new container reached
				idx=[_textContainers indexOfObjectIdenticalTo:container];
				if(idx == NSNotFound)
					[NSException raise:@"NSLayoutManager" format:@"invalid container %@", container];				
				[[lastContainer textView] setNeedsDisplayInRect:rect];
				rect=NSZeroRect;
				lastContainer=container;
			}
		rect=NSUnionRect(rect, _textContainerInfo[idx].usedRect);
		_glyphs[glyphRange.location++].needsDisplay=YES;
		}
	[[lastContainer textView] setNeedsDisplayInRect:rect];	// final rect
}

- (void) invalidateGlyphsForCharacterRange:(NSRange) range changeInLength:(NSInteger) delta actualCharacterRange:(NSRange *) actual;
{
	NSRange glyphRange;
	if(range.location >= [_textStorage length])
		return;	// not valid
	glyphRange=[self glyphRangeForCharacterRange:range actualCharacterRange:actual];
	if(glyphRange.length == 0)
		return;
	if(!_allowsNonContiguousLayout)
		{ // delete all glyphs starting at range - ignore delta since we have deleted them all...
			glyphRange.length=_numberOfGlyphs-glyphRange.location;	// extend to end of glyph range
			[self deleteGlyphsInRange:glyphRange];	// delete - ensureGlyphsInRange will generate new glyphs
		}
	else
		; // cut a glyph hole and adjust character indexes
}

- (void) invalidateGlyphsOnLayoutInvalidationForGlyphRange:(NSRange) range;
{ // this should just be a flag where a typesetter can indicate that this glyph was temporarily inserted (e.g. hyphens)
	// but we can simply delete all glyphs starting at range
	if(range.location >= _numberOfGlyphs)
		return;
	range.length = _numberOfGlyphs-range.location;
	[self deleteGlyphsInRange:range];
}

- (void) invalidateLayoutForCharacterRange:(NSRange) range actualCharacterRange:(NSRangePointer) charRange;
{
	[self invalidateLayoutForCharacterRange:range isSoft:NO actualCharacterRange:charRange];
}

- (void) invalidateLayoutForCharacterRange:(NSRange)charRange isSoft:(BOOL)flag actualCharacterRange:(NSRange *)actualCharRange;
{
	BOOL wasDone=_firstUnlaidCharacterIndex == [_textStorage length];
	if(!flag)
		{ // really invalidate layout
			// FIXME: we must remove glyph[idx].textContainer
			// and reduce the glyphRange of the textContainers
			while(_firstUnlaidCharacterIndex > charRange.location)
				{
				_firstUnlaidCharacterIndex--;
				NSAssert(_firstUnlaidGlyphIndex > 0, @"_firstUnlaid* got out of sync");
				_firstUnlaidGlyphIndex--;
				if(_glyphs[_firstUnlaidGlyphIndex].textContainer)
					{
					NSUInteger idx=[_textContainers indexOfObjectIdenticalTo:_glyphs[_firstUnlaidGlyphIndex].textContainer];
					_textContainerInfo[idx].glyphRange=NSIntersectionRange(_textContainerInfo[idx].glyphRange, NSMakeRange(0, _firstUnlaidGlyphIndex));
					}
#if FIXME
				if(_glyphs[_firstUnlaidGlyphIndex].invalidateGlyphsOnLayoutInvalidation)
					[self deleteGlyphsInRange:NSMakeRange(_firstUnlaidGlyphIndex, 1)];	// remove glyphs added by some NSTypesetter
#endif
				}
			_extraLineFragmentRect=NSZeroRect;
			_extraLineFragmentUsedRect=NSZeroRect;
			_extraLineFragmentContainer=nil;
		}
	// clear caches
	if(wasDone)
		[_delegate layoutManagerDidInvalidateLayout:self];	// inform delegate
}

- (BOOL) isValidGlyphIndex:(NSUInteger)glyphIndex;
{
	BOOL flag;
	[self glyphAtIndex:glyphIndex isValidIndex:&flag];	// this implicitly generates glyphs up to including glyphIndex!
	return flag;
}

- (BOOL) layoutManagerOwnsFirstResponderInWindow:(NSWindow *)aWindow;
{ // check if firstResponder is a NSTextView and we are the layoutManager
	NSResponder *f=[aWindow firstResponder];
	if([f respondsToSelector:@selector(layoutManager)])
		return [(NSTextView *) f layoutManager] == self;
	return NO;
}

- (NSRect) layoutRectForTextBlock:(NSTextBlock *)block
						  atIndex:(NSUInteger)glyphIndex
				   effectiveRange:(NSRangePointer)effectiveGlyphRange;
{
	[self ensureGlyphsForGlyphRange:NSMakeRange(0, glyphIndex+1)];
	NIMP;
	return NSZeroRect;
}

- (NSRect) layoutRectForTextBlock:(NSTextBlock *)block
					   glyphRange:(NSRange)glyphRange;
{
	[self ensureGlyphsForGlyphRange:glyphRange];
	NIMP;
	return NSZeroRect;
}

- (NSRect) lineFragmentRectForGlyphAtIndex:(NSUInteger)glyphIndex effectiveRange:(NSRange *)effectiveGlyphRange;
{
	return [self lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange:effectiveGlyphRange withoutAdditionalLayout:NO];
}

- (NSRect) lineFragmentRectForGlyphAtIndex:(NSUInteger) index effectiveRange:(NSRangePointer) range withoutAdditionalLayout:(BOOL) layoutFlag;
{
	NSRect lfr;
	if(!layoutFlag)
		[self ensureLayoutForGlyphRange:NSMakeRange(0, index+1)];	// do additional layout
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

- (NSRect) lineFragmentUsedRectForGlyphAtIndex:(NSUInteger) index effectiveRange:(NSRange *) range;
{
	return [self lineFragmentUsedRectForGlyphAtIndex:index effectiveRange:range withoutAdditionalLayout:NO];
}

- (NSRect) lineFragmentUsedRectForGlyphAtIndex:(NSUInteger) index effectiveRange:(NSRangePointer) range withoutAdditionalLayout:(BOOL) flag;
{
	NSRect lfur;
	if(!flag)
		[self ensureGlyphsForGlyphRange:NSMakeRange(0, index+1)];
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
			while(NSMaxRange(*range) < _numberOfGlyphs)
				{
				if(!NSEqualRects(lfur, _glyphs[NSMaxRange(*range)].usedLineFragmentRect))
					break;	// next index is different
				range->length++;
				}
		}
	return lfur;
}

- (NSPoint) locationForGlyphAtIndex:(NSUInteger) index;
{
	[self ensureLayoutForGlyphRange:NSMakeRange(0, index+1)];
	if(index >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", index];
	return _glyphs[index].location;
}

- (BOOL) notShownAttributeForGlyphAtIndex:(NSUInteger) index;
{
	[self ensureLayoutForGlyphRange:NSMakeRange(0, index+1)];
	if(index >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", index];
	return _glyphs[index].notShownAttribute;
}

- (NSUInteger) numberOfGlyphs;
{
	if(!_allowsNonContiguousLayout)
		[self ensureGlyphsForCharacterRange:NSMakeRange(0, [_textStorage length])]; // generate all glyphs so that we can count them
	return _numberOfGlyphs;
}

- (NSRange) rangeOfNominallySpacedGlyphsContainingIndex:(NSUInteger)glyphIndex;
{ // return a glpyh range with no kerning
	[self ensureLayoutForGlyphRange:NSMakeRange(0, glyphIndex+1)];
	if(glyphIndex >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", index];
	//	NIMP;
	// search backwards until the first glyph with a location is found
	// then find the range up to but not including the next location
	return NSMakeRange(0, 0);
}

- (NSRect *) rectArrayForCharacterRange:(NSRange) charRange 
		   withinSelectedCharacterRange:(NSRange) selCharRange 
						inTextContainer:(NSTextContainer *) container 
							  rectCount:(NSUInteger *) rectCount;
{
	charRange=[self glyphRangeForCharacterRange:charRange actualCharacterRange:NULL];
	if(selCharRange.location != NSNotFound)
		selCharRange=[self glyphRangeForCharacterRange:selCharRange actualCharacterRange:NULL];
	return [self rectArrayForGlyphRange:charRange withinSelectedGlyphRange:selCharRange inTextContainer:container rectCount:rectCount];
}

/* selRange:
 * { NSNotFound, 0 }:	enclosing point of view - i.e. get bounds box(es)
 * otherwise:			selection boxes - trimmed to first/last character and include line wrapping
 *
 * NOTES: we may get multiple rects for the columns of (selected) tables
 * or for containers with holes
 */

- (NSRect *) rectArrayForGlyphRange:(NSRange) glyphRange 
		   withinSelectedGlyphRange:(NSRange) selGlyphRange		// { NSNotFound, 0 } defines a different algorithm!
					inTextContainer:(NSTextContainer *) container 
						  rectCount:(NSUInteger *) rectCount;
{
	NSUInteger glyphIndex;
	BOOL enclosing=selGlyphRange.location == NSNotFound;
	if(glyphRange.length > 0)
		{
		glyphRange=NSIntersectionRange(glyphRange, [self glyphRangeForTextContainer:container]);
		if(!enclosing)
			glyphRange=NSIntersectionRange(glyphRange, selGlyphRange);
		}
	[self ensureLayoutForGlyphRange:glyphRange];	// we must have valid layout information
	glyphIndex=glyphRange.location;
	*rectCount=0;
	while(glyphIndex <= NSMaxRange(glyphRange))
		{
		NSRect lfr;
		NSRange lfrRange;
		NSUInteger i;
		if(glyphIndex >= _numberOfGlyphs)
			{ // at end of glyphs
			if(!_extraLineFragmentContainer)
				{ // no extra fragment - take end of last used rect
					if(_numberOfGlyphs == 0)
						lfr=NSZeroRect;	// no glyphs, no layout, no extra fragment, nothing... how can this happen? Something not completely initialized?
					else
						{
						lfr=[self lineFragmentUsedRectForGlyphAtIndex:_numberOfGlyphs-1 effectiveRange:NULL];
						// FIXME: depends on writing direction!
						lfr.origin.x+=lfr.size.width;
						lfr.size.width=0.0;
						}
				}
			else
				lfr=_extraLineFragmentUsedRect;
			}
#if 0
		else if(*rectCount != 0 && glyphIndex == NSMaxRange(glyphRange))
			break;	// there was no extra fragment to include
#endif
		else
			{ // normal fragments
			if(!enclosing)
				lfr=[self lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange:&lfrRange withoutAdditionalLayout:YES];
			else
				lfr=[self lineFragmentUsedRectForGlyphAtIndex:glyphIndex effectiveRange:&lfrRange withoutAdditionalLayout:YES];	// take only what we have
			if(glyphIndex == glyphRange.location)
				{ // first glyph defines exact position
					NSPoint pos=[self locationForGlyphAtIndex:glyphIndex];
					lfr.size.width-=pos.x;
					lfr.origin.x+=pos.x;	// start at that glyph
				}
			if(NSMaxRange(lfrRange) > NSMaxRange(glyphRange))
				{ // not to end of LFR
					NSUInteger g=NSMaxRange(glyphRange);
					NSPoint pos=[self locationForGlyphAtIndex:g];
					lfr.size.width=pos.x-lfr.origin.x;	// end at that glyph position
				}
			}
		for(i=0; i<*rectCount; i++)
			{ // check if we can merge the new lfr with the existing one
			if(NSMinY(_rectArray[i]) == NSMinY(lfr) && NSHeight(_rectArray[i]) == NSHeight(lfr) && NSMinX(lfr) <= NSMaxX(_rectArray[i]))
			   { // overlapping or adjacent on the same line
				   _rectArray[i]=NSUnionRect(_rectArray[i], lfr);
				   break;
			   }
			if(NSMinX(_rectArray[i]) == NSMinX(lfr) && NSWidth(_rectArray[i]) == NSWidth(lfr) && NSMinY(lfr) <= NSMaxY(_rectArray[i]))
				{ // overlapping or adjacent in the same column
					_rectArray[i]=NSUnionRect(_rectArray[i], lfr);
					break;
				}
			}
		if(i == *rectCount)
			{ // could not merge: create new rect
				if(*rectCount == _rectArrayCapacity)
					_rectArray=objc_realloc(_rectArray, sizeof(_rectArray[0])*(_rectArrayCapacity=2*_rectArrayCapacity+5));	// increase with some safety margin
				_rectArray[(*rectCount)++]=lfr;	// new rectangle
			}
		if(glyphIndex >= _numberOfGlyphs)
			break;	// done with the extra fragment handling
		glyphIndex=NSMaxRange(lfrRange);	// consult next fragment
		}
	if(*rectCount+5 < _rectArrayCapacity/2)	// this time much smaller
		_rectArray=objc_realloc(_rectArray, sizeof(_rectArray[0])*(_rectArrayCapacity=*rectCount+5));	// reduce with some safety margin
	return _rectArray;
}

- (void) removeTemporaryAttribute:(NSString *)name forCharacterRange:(NSRange)charRange;
{
	NIMP;
}

- (void) removeTextContainerAtIndex:(NSUInteger)index;
{
	NSUInteger cnt=[_textContainers count];	// before removing
	if(index == 0)
		_firstTextView=nil;	// might have changed
	[[_textContainers objectAtIndex:index] setLayoutManager:nil];	// no layout manager
	[_textContainers removeObjectAtIndex:index];
	// FIXME: invalidate layout for glyph range of the text container
	if(cnt != index+1)
		memmove(&_textContainerInfo[index], &_textContainerInfo[index+1], sizeof(_textContainerInfo[0])*(cnt-index-1));	// make room for new slot
}

- (void) replaceGlyphAtIndex:(NSUInteger)glyphIndex withGlyph:(NSGlyph)newGlyph;
{
	// FIXME: locate glyph run
	if(glyphIndex >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", glyphIndex];
	_glyphs[glyphIndex].glyph=newGlyph;	// simply change but don't invalidate anything
}

- (void) replaceTextStorage:(NSTextStorage *)newTextStorage;
{
	if(_textStorage != newTextStorage)
		{
		[self retain];
		[_textStorage removeLayoutManager:self];
		[newTextStorage addLayoutManager:self];	// this calls setTextStorage
		[self release];
		}
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
#if 1
	if(flag)
		NSLog(@"*** NonContiguousLayout not implemented ***");
	flag=NO;
#endif
	_allowsNonContiguousLayout=flag;
}

- (void) setAttachmentSize:(NSSize) attachmentSize forGlyphRange:(NSRange) glyphRange;
{
	if(NSMaxRange(glyphRange) > _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph range"];
	// check if we have a NSControlGlyph
	NIMP;
}

- (void) setBackgroundLayoutEnabled:(BOOL) flag;
{
#if 1
	if(flag)
		NSLog(@"*** BackgroundLayout not implemented ***");
	flag=NO;
#endif
	_backgroundLayoutEnabled=flag;
}

- (void) setBoundsRect:(NSRect) rect forTextBlock:(NSTextBlock *) block glyphRange:(NSRange) glyphRange;
{
	[self ensureGlyphsForGlyphRange:glyphRange];
	NIMP;
}

- (void) setCharacterIndex:(NSUInteger) charIndex forGlyphAtIndex:(NSUInteger) index;
{ // character indices should be ascending with glyphIndex... so be careful what you do by calling this method!
	if(index >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", index];
	_glyphs[index].characterIndex=charIndex;
}

- (void) setDefaultAttachmentScaling:(NSImageScaling) scaling; { _defaultAttachmentScaling=scaling; }

- (void) setDelegate:(id) obj; { _delegate=obj; }

- (void) setDrawsOutsideLineFragment:(BOOL) flag forGlyphAtIndex:(NSUInteger) index;
{
	if(index >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", index];
	_glyphs[index].drawsOutsideLineFragment=flag;
}

- (void) setExtraLineFragmentRect:(NSRect) fragmentRect usedRect:(NSRect) usedRect textContainer:(NSTextContainer *) container;
{ // used to define a virtual extra line to display the insertion point if there is no content or the last character is a hard break
	NSUInteger idx;
	_extraLineFragmentRect=fragmentRect;
	_extraLineFragmentUsedRect=usedRect;
	[_extraLineFragmentContainer autorelease];
	_extraLineFragmentContainer=[container retain];
	if(container)
		{
		idx=[_textContainers indexOfObjectIdenticalTo:container];
		if(idx == NSNotFound)
			[NSException raise:@"NSLayoutManager" format:@"no text container for glyph range"];
		_textContainerInfo[idx].usedRect=NSUnionRect(_textContainerInfo[idx].usedRect, usedRect);	// enlarge used rect
		}
}

- (void) setGlyphGenerator:(NSGlyphGenerator *) gg; { ASSIGN(_glyphGenerator, gg); }

- (void) setHyphenationFactor:(float) factor; { _hyphenationFactor=factor; }

- (void) setLayoutRect:(NSRect) rect forTextBlock:(NSTextBlock *) block glyphRange:(NSRange) glyphRange;
{
	[self ensureGlyphsForGlyphRange:glyphRange];
	NIMP;
}

- (void) setLineFragmentRect:(NSRect) fragmentRect forGlyphRange:(NSRange) glyphRange usedRect:(NSRect) usedRect;
{
	NSUInteger idx;
	if(NSMaxRange(glyphRange) > _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph range"];
	idx=[_textContainers indexOfObjectIdenticalTo:_glyphs[glyphRange.location].textContainer];
	if(idx == NSNotFound)
		[NSException raise:@"NSLayoutManager" format:@"no text container for glyph range"];
	_textContainerInfo[idx].usedRect=NSUnionRect(_textContainerInfo[idx].usedRect, usedRect);	// enlarge used rect
	while(glyphRange.length-- > 0)
		{
		_glyphs[glyphRange.location].lineFragmentRect=fragmentRect;
		_glyphs[glyphRange.location].usedLineFragmentRect=usedRect;
		glyphRange.location++;
		}
}

- (void) setLocation:(NSPoint) location forStartOfGlyphRange:(NSRange) glyphRange;
{
#if 0
	NSLog(@"setLocation %@ forStartOfGlyphRange %@", NSStringFromPoint(location), NSStringFromRange(glyphRange));
#endif
	// [self setLocations:&location startingGlyphIndexes:&glyphRange.location count:1 forGlyphRange:glyphRange];
	if(NSMaxRange(glyphRange) > _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph range"];
	// other glyphs should have no location or it should be calculated here or if someone tries to ask its locationForGlyphAtIndex:
	// rangeOfNominallySpacedGlyphsContainingIndex should return this glyphRange
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

- (void) setNotShownAttribute:(BOOL) flag forGlyphAtIndex:(NSUInteger) index;
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
	if(NSMaxRange(charRange) > [_textStorage length])
		[NSException raise:@"NSLayoutManager" format:@"invalid character range"];
	// FIXME:
}

- (void) setTextContainer:(NSTextContainer *) container forGlyphRange:(NSRange) glyphRange;
{
	NSUInteger idx=[_textContainers indexOfObjectIdenticalTo:container];
	NSAssert(idx != NSNotFound, @"Text Container unknown in NSLayoutManager");
	if(NSMaxRange(glyphRange) > _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph range"];
	if(NSMaxRange(glyphRange) > _firstUnlaidGlyphIndex)
		{ // assume layout has been done for this set of glyphs
			_firstUnlaidGlyphIndex=NSMaxRange(glyphRange);
			if(_firstUnlaidGlyphIndex < _numberOfGlyphs)
				_firstUnlaidCharacterIndex=_glyphs[_firstUnlaidGlyphIndex].characterIndex;
			else
				_firstUnlaidCharacterIndex=_nextCharacterIndex;
		}
	_textContainerInfo[idx].glyphRange=NSUnionRange(_textContainerInfo[idx].glyphRange, glyphRange);
	while(glyphRange.length-- > 0)
		_glyphs[glyphRange.location++].textContainer=container;	// assign text container
}

- (void) setTextStorage:(NSTextStorage *) ts;
{
	[self invalidateGlyphsOnLayoutInvalidationForGlyphRange:NSMakeRange(0, _numberOfGlyphs)];
	[self invalidateLayoutForCharacterRange:NSMakeRange(0, [_textStorage length]) actualCharacterRange:NULL];
	_textStorage=ts;	// The textStorage owns the layout manager(s)
	[_typesetter setAttributedString:_textStorage];
}

- (void) setTypesetter:(NSTypesetter *) ts; { ASSIGN(_typesetter, ts); [_typesetter setAttributedString:_textStorage]; }
- (void) setTypesetterBehavior:(NSTypesetterBehavior) behavior; { [_typesetter setTypesetterBehavior:behavior]; }
- (void) setUsesFontLeading:(BOOL) flag; { _usesFontLeading=flag; }
- (void) setUsesScreenFonts:(BOOL) flag; { _usesScreenFonts=flag; }

- (void) showAttachmentCell:(NSCell *) cell inRect:(NSRect) rect characterIndex:(NSUInteger) attachmentIndex;
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

// FIXME: we *can* use this method since packed glyphs are now always 2-byte
// there is one exception that NSBezierPath's drawGlyphs ends at a NULL glyph
// while here we end at length and can pass NULL glyphs down to the backend

- (void) showPackedGlyphs:(char *) glyphs
				   length:(NSUInteger) glyphLen	// number of bytes = 2* number of glyphs
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
	// FIXME: could use [NSBezierPath drawGlyphs...]
	//	[ctxt _drawGlyphs:glyphs count:glyphRange.length];	// -> (string) Tj
	// printingAdjustment???
}

- (BOOL) showsControlCharacters; { return (_layoutOptions&NSShowControlGlyphs) != 0; }
- (BOOL) showsInvisibleCharacters; { return (_layoutOptions&NSShowInvisibleGlyphs) != 0; }

- (void) strikethroughGlyphRange:(NSRange)glyphRange
			   strikethroughType:(NSInteger)strikethroughVal
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
// we could define our private NSAttributedString that tracks the length
// or we do our own Array of Attribute Runs (only)

- (id) temporaryAttribute:(NSString *) name 
		 atCharacterIndex:(NSUInteger) loc 
		   effectiveRange:(NSRangePointer) effectiveRange;
{
	if(loc >= [_textStorage length])
		[NSException raise:@"NSLayoutManager" format:@"invalid character index: %u", loc];
	return NIMP;
}

- (id) temporaryAttribute:(NSString *) name 
		 atCharacterIndex:(NSUInteger) loc 
	longestEffectiveRange:(NSRangePointer) effectiveRange 
				  inRange:(NSRange) limit;
{
	if(loc >= [_textStorage length])
		[NSException raise:@"NSLayoutManager" format:@"invalid character index: %u", loc];
	return NIMP;
}

- (NSDictionary *) temporaryAttributesAtCharacterIndex:(NSUInteger) loc 
								 longestEffectiveRange:(NSRangePointer) effectiveRange 
											   inRange:(NSRange) limit;
{
	if(loc >= [_textStorage length])
		[NSException raise:@"NSLayoutManager" format:@"invalid character index: %u", loc];
	return NIMP;
}

- (NSDictionary *) temporaryAttributesAtCharacterIndex:(NSUInteger) loc
										effectiveRange:(NSRangePointer) effectiveRange;
{
	if(loc >= [_textStorage length])
		[NSException raise:@"NSLayoutManager" format:@"invalid character index: %u", loc];
	return NIMP;
}

- (void) textContainerChangedGeometry:(NSTextContainer *) container;
{
	NSAssert(_glyphs == NULL || _glyphs[0].notShownAttribute <= 1, @"_glyphs damaged");
#if 0
	NSLog(@"textContainerChangedGeometry");
#endif
	if(_textContainers)
		{
		NSRange crng, grng;
		NSUInteger idx=[_textContainers indexOfObjectIdenticalTo:container];
		NSAssert(idx != NSNotFound, @"Text Container unknown in NSLayoutManager");
		if(idx+1 < [_textContainers count])
			[self textContainerChangedGeometry:[_textContainers objectAtIndex:idx+1]];	// invalidate all further containers
		grng=_textContainerInfo[idx].glyphRange;
		crng=[self characterRangeForGlyphRange:grng actualGlyphRange:NULL];
		// this appears to be overkill...
		[self invalidateDisplayForGlyphRange:grng];	// as it was previously known
		[self invalidateLayoutForCharacterRange:crng actualCharacterRange:NULL];
		[self invalidateGlyphsForCharacterRange:crng changeInLength:0 actualCharacterRange:NULL];
		_textContainerInfo[idx].glyphRange=(NSRange) { 0, 0 };	// reset to empty/unknown
		}
}

- (void) textContainerChangedTextView:(NSTextContainer *)container;
{
	[self invalidateDisplayForGlyphRange:[self glyphRangeForTextContainer:container]];
}

- (NSTextContainer *) textContainerForGlyphAtIndex:(NSUInteger) glyphIndex effectiveRange:(NSRange *) effectiveGlyphRange;
{
	return [self textContainerForGlyphAtIndex:glyphIndex effectiveRange:effectiveGlyphRange withoutAdditionalLayout:NO];
}

- (NSTextContainer *) textContainerForGlyphAtIndex:(NSUInteger) glyphIndex effectiveRange:(NSRangePointer) effectiveGlyphRange withoutAdditionalLayout:(BOOL) flag
{
	NSTextContainer *tc;
	NSUInteger idx;
	if(!flag)
		[self ensureLayoutForGlyphRange:NSMakeRange(0, glyphIndex+1)]; // ensure layout up to and including this index
	if(glyphIndex >= _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph index: %u", glyphIndex];
	// FIXME: we could do a binary search the best matching text container's glyph range...
	// and get rid of the _glyphs[].textContainer variable (which needs some bytes per glyph)
	tc=_glyphs[glyphIndex].textContainer;
	idx=[_textContainers indexOfObjectIdenticalTo:tc];
	if(effectiveGlyphRange)
		{ // get glyph range of text container
			*effectiveGlyphRange=_textContainerInfo[idx].glyphRange;
		}
	if(!flag)
		{
		NSTextView *tv=[tc textView];
		if(tv)
			{ // grow/shrink container if needed
			NSRect used=_textContainerInfo[idx].usedRect;
			NSSize off=[tv textContainerInset];
			used.size.width+=2.0*off.width;
			used.size.height+=2.0*off.height;
			[tv setConstrainedFrameSize:used.size];
			}
		}
	return tc;
}

- (NSArray *) textContainers; { return _textContainers; }
- (NSTextStorage *) textStorage; { return _textStorage; }

/* this is called by -[NSTextStorage processEditing] if the NSTextStorage has been changed */

- (void) textStorage:(NSTextStorage *) str edited:(unsigned) editedMask range:(NSRange) newCharRange changeInLength:(NSInteger) delta invalidatedRange:(NSRange) invalidatedCharRange;
{
	// this may be used to move around glyphs and separate between glyph generation (i.e.
	// translation of character codes to glyph codes through NSFont
	// and pure layout (not changing geometry of individual glyphs but their relative position)
	// check if only drawing attributes have been changed like NSColor/underline/striketrhough/link
	//   -- then we do not even need to generate new glyphs or new layout positions
#if 0
	NSLog(@"textStorage:edited:%u range:%@ change:%d inval:%@", editedMask, NSStringFromRange(newCharRange), delta, NSStringFromRange(invalidatedCharRange));
#endif
	if(editedMask&NSTextStorageEditedCharacters)
		{ // characters have been added/removed
			NSTextView *tv=[self firstTextView];
			NSRange aRange;
			NSRange selRange=[tv selectedRange];
#if 0
			NSLog(@"  tv=%@", tv);
			if([tv frame].size.height == 0)
				NSLog(@"height became 0!");
#endif
			[self invalidateGlyphsForCharacterRange:invalidatedCharRange changeInLength:delta actualCharacterRange:&aRange];
			[self invalidateLayoutForCharacterRange:aRange actualCharacterRange:NULL];
			// FIXME: is this done here in NSLayoutManager
			// or does the NSTextView observe the NSTextStorageDidProcessEditingNotification?
			if(delta > 0)
				{
				if(newCharRange.location <= selRange.location)
					selRange.location+=delta;	// inserting before or at selection does move it to the end of the inserted range
				else if(newCharRange.location <= NSMaxRange(selRange))
					newCharRange.length+=delta;		// inserting/deleting within selection
				}
			if(delta < 0)
				{
				if(newCharRange.location < selRange.location)
					selRange.location+=delta;	// deleting before selection does move it towards beginning of text
				else if(newCharRange.location < NSMaxRange(selRange))
					selRange.length+=delta;		// deleting within selection
				}
			[tv setSelectedRange:selRange];	// adjust selection range
		}
	else if(editedMask&NSTextStorageEditedAttributes)
		{ // no need to change glyphs
			[self invalidateLayoutForCharacterRange:invalidatedCharRange actualCharacterRange:NULL];
		}
}

- (NSTextView *) textViewForBeginningOfSelection;
{
	return NIMP;
}

- (NSTypesetter *) typesetter; { return _typesetter; }
- (NSTypesetterBehavior) typesetterBehavior; { return [_typesetter typesetterBehavior]; }

- (void) underlineGlyphRange:(NSRange)glyphRange 
			   underlineType:(NSInteger)underlineVal
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
	NSAssert(idx != NSNotFound, @"Text Container unknown for NSLayoutManager");
	return _textContainerInfo[idx].usedRect;
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
	_typesetter=[[NSTypesetter sharedSystemTypesetter] retain];
	_glyphGenerator=[[NSGlyphGenerator sharedGlyphGenerator] retain];
	[self setDelegate:[coder decodeObjectForKey:@"NSDelegate"]];
	_textContainers=[[coder decodeObjectForKey:@"NSTextContainers"] retain];
	_textContainerInfo=objc_calloc([_textContainers count], sizeof(_textContainerInfo[0]));
	_textStorage=[coder decodeObjectForKey:@"NSTextStorage"];
	[_textStorage addLayoutManager:self];
	_usesScreenFonts=NO;
#if 0
	NSLog(@"%@ done", self);
#endif
	return self;
}

#pragma mark NSGlyphStorage
// methods for @protocol NSGlyphStorage

- (NSAttributedString *) attributedString; { return _textStorage; }

- (NSUInteger) layoutOptions; { return _layoutOptions; }

- (void ) insertGlyphs:(const NSGlyph *) glyphs
				length:(NSUInteger) length
forStartingGlyphAtIndex:(NSUInteger) glyph
		characterIndex:(NSUInteger) index;
{
	// FIXME: here we must be able to handle non-contiguous glyph ranges
	if(glyph > _numberOfGlyphs)
		[NSException raise:@"NSLayoutManager" format:@"invalid glyph insert position"];
	if(!_glyphs || _numberOfGlyphs+length >= _glyphBufferCapacity)
		_glyphs=(struct NSGlyphStorage *) objc_realloc(_glyphs, sizeof(_glyphs[0])*(_glyphBufferCapacity=_numberOfGlyphs+length+20));	// make more space
#if 0
	NSLog(@"insertGlyphs _glyphs=%p @ %u", _glyphs, glyph);
#endif
	if(glyph != _numberOfGlyphs)
		memmove(&_glyphs[glyph+length], &_glyphs[glyph], sizeof(_glyphs[0])*(_numberOfGlyphs-glyph));	// make room unless we append
	memset(&_glyphs[glyph], 0, sizeof(_glyphs[0])*length);	// clear all data and flags
	_numberOfGlyphs+=length;
	while(length-- > 0)
		{
		_glyphs[glyph].glyph=*glyphs++;
		// same as [self setCharacterndex:index forGlyph:glyph];
		_glyphs[glyph].characterIndex=index++;	// all glyphs belong to the same character!
		glyph++;
		}
}

- (void) setIntAttribute:(NSInteger) attributeTag value:(NSInteger) val forGlyphAtIndex:(NSUInteger) glyphIndex;
{ // subclasses must provide storage for additional attributeTag values and call this for the "old" ones
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

// default implementations unless overwritten

@implementation NSObject (NSLayoutManagerDelegate)

- (void) layoutManagerDidInvalidateLayout:(NSLayoutManager *) sender;
{
	return;
}

- (NSDictionary *) layoutManager:(NSLayoutManager *) sender 
	shouldUseTemporaryAttributes:(NSDictionary *) tempAttrs 
			  forDrawingToScreen:(BOOL) flag 
				atCharacterIndex:(NSUInteger) index 
				  effectiveRange:(NSRangePointer) charRange;
{
	return flag?tempAttrs:nil;	// use only when drawing to screen
}

- (void) layoutManager:(NSLayoutManager *) layoutManager didCompleteLayoutForTextContainer:(NSTextContainer *) textContainer atEnd:(BOOL) layoutFinishedFlag;
{
	return;
}

@end
