/*
 NSTypesetter.m
 
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

@implementation NSTypesetter

+ (NSTypesetterBehavior) defaultTypesetterBehavior;
{
	return NSTypesetterOriginalBehavior;	// overwritten in subclasses
}

+ (NSSize) printingAdjustmentInLayoutManager:(NSLayoutManager *) manager 
				forNominallySpacedGlyphRange:(NSRange) range 
								packedGlyphs:(const unsigned char *) glyphs
									   count:(NSUInteger) count;
{
	NIMP;
	return NSZeroSize;
}

+ (id) sharedSystemTypesetter;
{
	return [self sharedSystemTypesetterForBehavior:[self defaultTypesetterBehavior]];
}

+ (id) sharedSystemTypesetterForBehavior:(NSTypesetterBehavior) behavior;
{ // FIXME: there should be an array of singletons for all potential behaviors
	switch(behavior) {
		case NSTypesetterLatestBehavior:
		case NSTypesetterOriginalBehavior:
			return [NSSimpleHorizontalTypesetter sharedInstance];
		default: {
			static id _sharedSystemTypesetter;
			if(!_sharedSystemTypesetter)
				{
				_sharedSystemTypesetter=[[self alloc] init];
				[_sharedSystemTypesetter setTypesetterBehavior:behavior];				
				}
			return _sharedSystemTypesetter;
		}
	}
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
		// case ' ': return NSTypesetterControlCharacterAction;	// how does this relate to NSControlGlyph?
		// case ' ': return NSTypesetterContainerBreakAction;
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
	NSDictionary *d=[[_layoutManager firstTextView] typingAttributes];
	if(!d)
		;
	return d;
}

- (CGFloat) baselineOffsetInLayoutManager:(NSLayoutManager *) manager glyphIndex:(NSUInteger) index;
{
	// FIXME: this depends on the NSFont??
	// or is it stored/cached for each glyph in the typesetter???
	return 0.0;
}

- (void) beginLineWithGlyphAtIndex:(NSUInteger) index;
{
	[self setLineFragmentPadding:[_currentTextContainer lineFragmentPadding]];
	return;
}

- (void) beginParagraph;
{
	_currentParagraphStyle=[_attributedString attribute:NSParagraphStyleAttributeName atIndex:_paragraphCharacterRange.location effectiveRange:&_paragraphCharacterRange];
	if(!_currentParagraphStyle)
		_currentParagraphStyle=[NSParagraphStyle defaultParagraphStyle];	// none specified
	[self setParagraphGlyphRange:[_layoutManager glyphRangeForCharacterRange:_paragraphCharacterRange actualCharacterRange:NULL] separatorGlyphRange:NSMakeRange(0, 0)];
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
	return [_layoutManager characterRangeForGlyphRange:range actualGlyphRange:rangePt];
}

- (NSParagraphStyle *) currentParagraphStyle; { return _currentParagraphStyle; }
- (NSTextContainer *) currentTextContainer; { return _currentTextContainer; }

- (void) deleteGlyphsInRange:(NSRange) range;
{
	[_layoutManager deleteGlyphsInRange:range];
}

- (void) endLineWithGlyphRange:(NSRange) range;
{ // do adjustments (left, right, center, justfication) and apply lfr/lfur to line range
	// center: shift used rect right by half difference
	// right: shift used rect right by full difference
	// justify: distribute difference on space characters and kerning
	[_layoutManager setTextContainer:[self currentTextContainer] forGlyphRange:_paragraphGlyphRange];
}

- (void) endParagraph;
{
	NIMP;
}

- (NSUInteger) getGlyphsInRange:(NSRange) range 
						 glyphs:(NSGlyph *) glyphs 
			   characterIndexes:(NSUInteger *) idxs 
			  glyphInscriptions:(NSGlyphInscription *) inscBuffer 
					elasticBits:(BOOL *) flag 
					 bidiLevels:(unsigned char *) bidiLevels;
{
	return [_layoutManager getGlyphsInRange:range
									 glyphs:glyphs
						   characterIndexes:idxs
						  glyphInscriptions:inscBuffer
								elasticBits:flag];
}

- (void) getLineFragmentRect:(NSRectPointer) fragRect 
					usedRect:(NSRectPointer) fragUsedRect 
forParagraphSeparatorGlyphRange:(NSRange) range 
			atProposedOrigin:(NSPoint) origin;
{ // for blank lines
	NSRect rr;
	NSRect proposedRect;
	[self getLineFragmentRect:fragRect
					 usedRect:fragUsedRect
				remainingRect:&rr
	  forStartingGlyphAtIndex:range.location
				 proposedRect:proposedRect
				  lineSpacing:[self lineSpacingAfterGlyphAtIndex:_paragraphGlyphRange.location withProposedLineFragmentRect:proposedRect]
	   paragraphSpacingBefore:[self paragraphSpacingBeforeGlyphAtIndex:_paragraphGlyphRange.location withProposedLineFragmentRect:proposedRect]
		paragraphSpacingAfter:[self paragraphSpacingAfterGlyphAtIndex:_paragraphGlyphRange.location withProposedLineFragmentRect:proposedRect]];
	[self currentParagraphStyle];
	[self lineFragmentPadding];	// why again???
}

- (void) getLineFragmentRect:(NSRectPointer) lineFragmentRect 
					usedRect:(NSRectPointer) lineFragmentUsedRect 
			   remainingRect:(NSRectPointer) remRect 
	 forStartingGlyphAtIndex:(NSUInteger) startIndex 
				proposedRect:(NSRect) propRect	// remaining space needed up to the end of the paragraph
				 lineSpacing:(CGFloat) spacing 
	  paragraphSpacingBefore:(CGFloat) paragSpacBefore 
	   paragraphSpacingAfter:(CGFloat) paragSpacAfter;
{ // for lines
	int sweep;
	// FIXME: should also set up the initial position to the left or right?
	switch([_currentParagraphStyle baseWritingDirection]) {
		case NSWritingDirectionNatural:
		default:
		case NSWritingDirectionLeftToRight: sweep=NSLineSweepRight; break;
		case NSWritingDirectionRightToLeft: sweep=NSLineSweepLeft; break;
	}
	*lineFragmentRect=[_currentTextContainer lineFragmentRectForProposedRect:propRect sweepDirection:sweep movementDirection:NSLineMovesDown remainingRect:remRect];
	*lineFragmentUsedRect=*lineFragmentRect;
	// FIXME: how can this be smaller if we take the proposed rect???
	lineFragmentRect->size.width=MIN(NSWidth(*lineFragmentRect), NSWidth(propRect));	// reduce to what was proposed
	// handle adjustments here by shifting the lfur?
}

- (NSRange) glyphRangeForCharacterRange:(NSRange) range 
				   actualCharacterRange:(NSRangePointer) rangePt;
{
	return [_layoutManager glyphRangeForCharacterRange:range actualCharacterRange:rangePt];
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
{ // used for hyphenation and keeps some caches in sync...
	[_layoutManager insertGlyphs:&glyph length:1 forStartingGlyphAtIndex:index characterIndex:charIdx];
}

- (NSRange) layoutCharactersInRange:(NSRange) range
				   forLayoutManager:(NSLayoutManager *) manager
	   maximumNumberOfLineFragments:(NSUInteger) maxLines;
{ // this is the main layout function - we assume that the Glyphs are already generated and character indexes are assigned
	NSUInteger nextGlyph;
	NSRange r=range;
	[self layoutGlyphsInLayoutManager:manager startingAtGlyphIndex:[manager glyphIndexForCharacterAtIndex:range.location] maxNumberOfLineFragments:maxLines nextGlyphIndex:&nextGlyph];
	r.length=[manager characterIndexForGlyphAtIndex:nextGlyph]-r.location;
	return r;
}

- (void) layoutGlyphsInLayoutManager:(NSLayoutManager *) manager 
				startingAtGlyphIndex:(NSUInteger) startIndex 
			maxNumberOfLineFragments:(NSUInteger) maxLines 
					  nextGlyphIndex:(NSUInteger *) nextGlyph; 
{ // documentation says that this is the main function called by NSLayoutManager
	_maxNumberOfLineFragments=maxLines;	// set up limitation counter

//	_currentTextContainer=

	/* FIXME:
	appears to setup everything and then simply calls layoutParagraphAtPoint:

	 splitting into pragraphs is probably done here
	 
	 loop over all pragraphs:
	 [self setParagraphGlyphRange:<#(NSRange)paragRange#> separatorGlyphRange:<#(NSRange)sepRange#>];
	 [self layoutParagraphAtPoint:]
	 check if we need a new text container and continue

	*/
		
	// MOVE this to layoutParagraphAtPoint: to lay out current paragraph into current text container starting at current position...
	
	
	NSString *str=[_attributedString string];
	unsigned int options=[manager layoutOptions];	 // NSShowControlGlyphs, NSShowInvisibleGlyphs, NSWantsBidiLevels
	NSGlyph previous=0;
	NSTextContainer *container;
	NSPoint location;	// relative location within line fragment rect
	NSRect lfr;		// current line fragment rect
	_layoutManager=manager;
	if(startIndex > 0)
		{ // continue previous
			container=[_layoutManager textContainerForGlyphAtIndex:startIndex-1 effectiveRange:NULL];
		location=[_layoutManager locationForGlyphAtIndex:startIndex-1];
		// update location!?!
		lfr=[_layoutManager lineFragmentRectForGlyphAtIndex:startIndex-1 effectiveRange:NULL];
		}
	else
		{
		container=[[_layoutManager textContainers] objectAtIndex:0];
		location=NSZeroPoint;
		lfr=(NSRect) { NSZeroPoint, [container containerSize] };
		}

	while(startIndex < [_layoutManager numberOfGlyphs] && _maxNumberOfLineFragments > 0)
		{
		startIndex = [self layoutParagraphAtPoint:&location];
		// check for end due to end of container
		// switch to next container (if possible)
		}
	// we should fill the current TextContainer with line fragment rects
	// and ask the delegate if we need another one
	// if it can be streched, call [textView sizeToFit];	// size... - warning: this may be recursive!
	
	// handle NSTextTable and call -[NSTextTableBlock boundsRectForContentRect:inRect:textContainer:characterRange:]
	
	// FIXME: numberOfGlyphs calls layout!!!
	// FIXME: handle attribute runs like in glyph Generator!
	
	/*
	 In addition to the line fragment rectangle itself, the typesetter returns a
	 rectangle called the used rectangle. This is the portion of the line fragment
	 rectangle that actually contains glyphs or other marks to be drawn. By convention,
	 both rectangles include the line fragment padding and the interline space calculated
	 from the fontÕs line height metrics and the paragraphÕs line spacing parameters.
	 However, the paragraph spacing (before and after) and any space added around the
	 text, such as that caused by center-spaced text, are included only in the line
	 fragment rectangle and not in the used rectangle.
	 */
	
	// if the last character did not end up in a line fragment rect, define an extra line fragment
	// [self getLineFragmentRect:&lfr usedRect:&ulfr forParagraphSeparatorGlyphRange:NSMakeRange(glyph, 0) atProposedOrigin:origin];
	// [_layoutManager setExtraLineFragmentRect:lfr usedRect:ulfr textContainer:aTextContainer];
	_layoutManager=nil;
}

- (NSLayoutManager *) layoutManager;
{
	return _layoutManager;
}

// NOTE: there may be no glyph corresponding to the \n character!!!
// i.e. we can't find a \n character at the location defined by glyphs
// FIXME: make this useable for layout of table cells (which are sub-rects within a NSTextContainer)

- (NSUInteger) layoutParagraphAtPoint:(NSPointPointer) lfrOrigin;
{ // layout glyphs until end of paragraph; creates full line fragments
	NSString *str=[_attributedString string];
	NSUInteger startIndex=_paragraphGlyphRange.location;
	NSRect proposedRect=(NSRect) { *lfrOrigin, [_currentTextContainer containerSize] };
	NSPoint location;
	NSRect lfr, lfur, rr;
	// reduce size?
	[self beginParagraph];
	while(_maxNumberOfLineFragments-- > 0)
		{ // for each line (fragment)
			CGFloat baselineOffset;
			[self beginLineWithGlyphAtIndex:startIndex];
			while(_paragraphCharacterRange.location < [_attributedString length])
				{
				NSRect box;
				NSRect ulfr;	// used line fragment rect
				NSGlyph previous=NSNullGlyph;
				NSRange attribRange;
				NSDictionary *attribs=[_attributedString attributesAtIndex:_paragraphCharacterRange.location effectiveRange:&attribRange];
				NSFont *font=[self substituteFontForFont:[attribs objectForKey:NSFontAttributeName]];
				if(!font) font=[NSFont userFontOfSize:0.0];		// use default system font
				while(attribRange.length > 0)
					{ // character range with same font
						unichar c=[str characterAtIndex:attribRange.location];
						NSGlyph glyph=[_layoutManager glyphAtIndex:startIndex];
						NSTypesetterControlCharacterAction a=0;
						float baseLineOffset;
						if(glyph == NSControlGlyph)
							a=[self actionForControlCharacterAtIndex:attribRange.location];
						if(a&NSTypesetterZeroAdvancementAction)
							;	// invisible and no movement
						else
							{ // normal advancement
								
								NSSize adv;
								if(glyph == NSControlGlyph)
									{
									box=[self boundingBoxForControlGlyphAtIndex:startIndex forTextContainer:_currentTextContainer proposedLineFragment:lfr glyphPosition:location characterIndex:attribRange.location];
									adv=box.size;	
									}
								else if(c == NSAttachmentCharacter)
									{
									// ask cell for its size
									adv=box.size;	
									}
								else
									{
									box=[font boundingRectForGlyph:glyph];
									adv=[font advancementForGlyph:glyph];						
									[attribs objectForKey:NSLigatureAttributeName];
									[attribs objectForKey:NSKernAttributeName];
									if(previous)
										{ // handle kerning
											// check if previous = f and current = l => reduce to single glyph
											NSSize k=[font _kerningBetweenGlyph:previous andGlyph:glyph];
											location.x+=k.width;
											location.y+=k.height;
										}
									}
								[self setLocation:location withAdvancements:(CGFloat *) &adv forStartOfGlyphRange:NSMakeRange(startIndex, 1)];
								// round advancement depending on layout style
								box.origin=location;
								box.origin.y+=[font ascender];
								// apply:
								[attribs objectForKey:NSSuperscriptAttributeName];
								[attribs objectForKey:NSBaselineOffsetAttributeName];
								// advance
								location.x+=adv.width;
								location.y+=adv.height;
								
								// if line is full, check for hyphenation/breaks
								// ask paragraph style for type of line breaks
								// and a |= NSTypesetterLineBreakAction
								// collect fragment rect
							}
						if(a&NSTypesetterHorizontalTabAction)
							{ // advance to next tab
								// if line is full, a |= NSTypesetterLineBreakAction
							}
						if(a&NSTypesetterLineBreakAction)
							{ // advance to beginning of next line (start a new line fragment)
								// apply standard indent
								// ask current container for
								/* check with NSTextContainer:
								 - (NSRect) lineFragmentRectForProposedRect:(NSRect) proposedRect
								 sweepDirection:(NSLineSweepDirection) sweepDirection
								 movementDirection:(NSLineMovementDirection) movementDirection
								 remainingRect:(NSRect *) remainingRect;
								 */
								
								// this may return NSZeroRect if it is not possible to get a rect
								// remaining rect should also be stored
								// if container is completely full, a |= NSTypesetterContainerBreakAction
							}
						if(a&NSTypesetterParagraphBreakAction)
							{ // advance to beginning of next paragraph - apply firstLineHeadIndent
								// if container is full, a |= NSTypesetterContainerBreakAction					
							}
						if(a&NSTypesetterContainerBreakAction)
							{ // advance to beginning of next container
								// may ask [[_layoutManager delegate] layoutManager:_layoutManager didCompleteLayoutForTextContainer: atEnd:]
							}
						// FIXME: update proposedRect
						ulfr=box;
						[self setNotShownAttribute:(a != 0) forGlyphRange:NSMakeRange(startIndex, 1)];
						// FIXME: handle rects
						baseLineOffset=[_layoutManager defaultBaselineOffsetForFont:font];
						[self willSetLineFragmentRect:&lfr forGlyphRange:NSMakeRange(startIndex, 1) usedRect:&ulfr baselineOffset:&baseLineOffset];
						[self setLineFragmentRect:lfr forGlyphRange:NSMakeRange(startIndex, 1) usedRect:ulfr baselineOffset:baseLineOffset];
						previous=glyph;
						startIndex++;
						
						attribRange.location++;
						_paragraphCharacterRange.location++;
						_paragraphCharacterRange.length--;
					}
				
				
				// fill line fragment until we get to a actionForControlCharacter
				// or we fill the width of the text container
				// then
				// do word wrapping/hyphenation etc.
				// fit the fragment rects
				// and create the lfr
				// continue with next line
				}
			[self getLineFragmentRect:&lfr
							 usedRect:&lfur
						remainingRect:&rr
			  forStartingGlyphAtIndex:_paragraphGlyphRange.location
						 proposedRect:proposedRect
						  lineSpacing:[self lineSpacingAfterGlyphAtIndex:_paragraphGlyphRange.location withProposedLineFragmentRect:proposedRect]
			   paragraphSpacingBefore:[self paragraphSpacingBeforeGlyphAtIndex:_paragraphGlyphRange.location withProposedLineFragmentRect:proposedRect]
				paragraphSpacingAfter:[self paragraphSpacingAfterGlyphAtIndex:_paragraphGlyphRange.location withProposedLineFragmentRect:proposedRect]];
			/*			[self getLineFragmentRect:&lfr
			 usedRect:&lfur
			 forParagraphSeparatorGlyphRange:_separatorGlyphRange
			 atProposedOrigin:*lfrOrigin];
			 */
			baselineOffset=[self baselineOffsetInLayoutManager:_layoutManager glyphIndex:startIndex];
			
			// do alignments etc. here
			
			[self willSetLineFragmentRect:&lfr forGlyphRange:_paragraphGlyphRange usedRect:&lfur baselineOffset:&baselineOffset];
			[self setLineFragmentRect:lfr forGlyphRange:_paragraphGlyphRange usedRect:lfur baselineOffset:baselineOffset];
			// prepare next proposedRect on either remainingRect or spacings
			[self endLineWithGlyphRange:_paragraphGlyphRange];
		}
	[self endParagraph];
	return startIndex;	// first index not processed
}

- (CGFloat) lineFragmentPadding;
{
	return _lineFragmentPadding;
}

- (CGFloat) lineSpacingAfterGlyphAtIndex:(NSUInteger) index withProposedLineFragmentRect:(NSRect) fragRect;
{
	[self currentParagraphStyle];
	return 5.0;
}

- (NSRange) paragraphCharacterRange; { return  _paragraphCharacterRange; }
- (NSRange) paragraphGlyphRange; { return _paragraphGlyphRange;	 }
- (NSRange) paragraphSeparatorCharacterRange; { return _separatorCharacterRange; }
- (NSRange) paragraphSeparatorGlyphRange; { return _separatorGlyphRange; }

// CHEKME: do these methods look into the relevant NSParagraphStyle??

- (CGFloat) paragraphSpacingAfterGlyphAtIndex:(NSUInteger) index withProposedLineFragmentRect:(NSRect) fragRect;
{
	return 8.0;
}

- (CGFloat) paragraphSpacingBeforeGlyphAtIndex:(NSUInteger) index withProposedLineFragmentRect:(NSRect) fragRect; 
{
	[self currentParagraphStyle];
	return 12.0;
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
	[_layoutManager setLineFragmentRect:fragRect forGlyphRange:range usedRect:rect];
	// what do we do with the offset???
}

- (void) setLocation:(NSPoint) loc 
	withAdvancements:(const CGFloat *) advancements 
forStartOfGlyphRange:(NSRange) range;
{
	[_layoutManager setLocation:loc forStartOfGlyphRange:range];
	// apply advancements
}

- (void) setNotShownAttribute:(BOOL) flag forGlyphRange:(NSRange) range;
{ // can be set e.g. for TAB or other control characters that are not shown in Postscript/PDF
	while(range.length-- > 0)
		[_layoutManager setNotShownAttribute:flag forGlyphAtIndex:range.location++];
}

- (void) setParagraphGlyphRange:(NSRange) paragRange separatorGlyphRange:(NSRange) sepRange;
{
	_paragraphGlyphRange=paragRange;
	_separatorGlyphRange=sepRange;
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
	NSEnumerator *e;
	NSPoint loc=[_layoutManager locationForGlyphAtIndex:glyphLoc];
	if(writingDirection == NSWritingDirectionNatural)
		writingDirection=NSWritingDirectionLeftToRight;
	if(writingDirection != NSWritingDirectionLeftToRight)
		{
		e=[[_currentParagraphStyle tabStops] objectEnumerator];
		while((tab=[e nextObject]))
			{
			CGFloat tl=[tab location];
			if(tl > maxLoc)
				break;
			if(tl > loc.x)
				return tab;	// first tab beyond this glyph
			}
		}
	else
		{
		e=[[_currentParagraphStyle tabStops] reverseObjectEnumerator];
		CGFloat tl=[tab location];
		if(tl <= maxLoc && tl < loc.x)
			return tab;	// first tab before this glyph
		}
	return nil;
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
	return;	// no op - can be overridden in subclasses to implement modified layout
	// see: http://www.cocoabuilder.com/archive/cocoa/175380-creating-an-nstypesetter-subclass.html
}

@end

@implementation NSSimpleHorizontalTypesetter

+ (id) sharedInstance;
{
	static NSSimpleHorizontalTypesetter *sharedInstance;
	if(!sharedInstance)
		sharedInstance=[self new];
	return sharedInstance;
}

- (id) init
{
	if((self=[super init]))
		{
		capacityGlyphInfo=20;
		glyphs=(NSTypesetterGlyphInfo *) malloc(capacityGlyphInfo*sizeof(glyphs[0]));
		}
	return self;
}

- (void) dealloc
{
	if(glyphs)
		free(glyphs);
	[super dealloc];
}

//- (float) baselineOffsetInLayoutManager:(id) fp8 glyphIndex:(unsigned int) fp12;

- (NSTypesetterGlyphInfo *) baseOfTypesetterGlyphInfo;
{
	return glyphs;
}

- (void) breakLineAtIndex:(unsigned) location;
{
	// index appears to be a glyphInfo index!
	// this assumes that there are enough glyphs
	// I think it will remove the glyphs up to (excluding) location
	// and advances the currentl glyph/character location
	
	
	// Find an index to break the line, if inside a word try to hyphenate and 
	// add a hyphen, if not possibe wrap.
	// Do justification acording to the paragraph style.
	switch([curParaStyle lineBreakMode]) {
		case NSLineBreakByWordWrapping:
			[self glyphIndexToBreakLineByWordWrappingAtIndex:location];
			break;
		case NSLineBreakByClipping:
			[self glyphIndexToBreakLineByClippingAtIndex:location];
			break;
			// check for truncation and apply [curParagraphStyle tighteningFactorForTruncation]
	}
}

- (unsigned) capacityOfTypesetterGlyphInfo;
{
	return capacityGlyphInfo;
}

- (void) clearAttributesCache;
{
	return;
}

- (void) clearGlyphCache;
{
	// ???
	sizeOfGlyphInfo=0;
}

- (NSTextContainer *) currentContainer;
{
	return curContainer;
}

- (NSTextContainer *) currentTextContainer;
{
	return curContainer;
}

- (NSLayoutManager *) currentLayoutManager;
{
	return layoutManager;
}

- (NSLayoutManager *) layoutManager;
{
	return layoutManager;
}

- (NSParagraphStyle *) currentParagraphStyle;
{
	return curParaStyle;
}

- (NSAttributedString *) attributedString;
{
	return textStorage;
}

- (NSTextStorage *) currentTextStorage;
{
	return textStorage;
}

- (void) fillAttributesCache;
{
	previousFont=curFont;
	curFont=[layoutManager substituteFontForFont:[attrs objectForKey:NSFontAttributeName]];
	if(!curFont) curFont=[NSFont userFontOfSize:0.0];	// default
	curFontBoundingBox=[curFont boundingRectForFont];
	curFontIsFixedPitch=[curFont isFixedPitch];
	if(curFontIsFixedPitch)
		curFontAdvancement=[curFont advancementForGlyph:NSNullGlyph];	// should be the same for all ?
	curTextAlignment=[curParaStyle alignment];
	curLayoutDirection=[curParaStyle baseWritingDirection];
	curMinLineHeight=[curParaStyle minimumLineHeight];
	curMaxLineHeight=[curParaStyle maximumLineHeight];
	curSuperscript=[[attrs objectForKey:NSSuperscriptAttributeName] intValue];
	curSpaceAfter=[[attrs objectForKey:NSKernAttributeName] floatValue];
	curBaselineOffset=[[attrs objectForKey:NSBaselineOffsetAttributeName] floatValue];
	/* NSGlyphInfo *gi=[attrs objectForKey:NSGlyphInfoAttributeName] */
}

- (unsigned) firstGlyphIndexOfCurrentLineFragment;
{
	return firstIndexOfCurrentLineFragment;
}

- (void) fullJustifyLineAtGlyphIndex:(unsigned) glyphIndexForLineBreak;
{ // insert flexible space between index 0 and glyphIndexForLineBreak-1
	
}

- (void) getAttributesForCharacterIndex:(unsigned int) fp8;
{
	attrs=[textStorage attributesAtIndex:fp8 effectiveRange:&attrsRange];
}

- (unsigned) glyphIndexToBreakLineByHyphenatingWordAtIndex:(unsigned) charIndex;
{
	float factor=[curParaStyle hyphenationFactor];
	if(factor <= 0.0) factor=[layoutManager hyphenationFactor];
	if(factor <= 0.0)
		; // no hyphenation
	// hyphenate by [self inserGlyph:'-' just before the charIndex
	if(curTextAlignment == NSJustifiedTextAlignment)
		[self fullJustifyLineAtGlyphIndex:charIndex];
	return 0;
}

- (unsigned) glyphIndexToBreakLineByWordWrappingAtIndex:(unsigned) charIndex;
{
	// charIndex is IMHO indexing the textStorage
	// and the return value is an index into the Glyph cache?

	// check if hyphenation is enabled
	// find a hyphen location
	return [self glyphIndexToBreakLineByHyphenatingWordAtIndex:charIndex];
}

- (unsigned int) glyphIndexToBreakLineByClippingAtIndex:(unsigned int) fp8;
{
	return 0;
}

- (unsigned) growGlyphCaches:(unsigned) desiredCapacity fillGlyphInfo:(BOOL) fillGlyphInfo;
{
	if(capacityGlyphInfo < desiredCapacity)
		{ // really needs to grow the cache
			glyphs=(NSTypesetterGlyphInfo *) realloc(glyphs, desiredCapacity*sizeof(NSTypesetterGlyphInfo));
			capacityGlyphInfo=desiredCapacity;
		}
	if(fillGlyphInfo)
		{ // make sure we have enough glyphs from the layout manager to fill the cache
			unsigned int charIndex=curCharacterIndex;
			unsigned int glyphIndex=firstInvalidGlyphIndex;
			unsigned int count;
			[[layoutManager glyphGenerator] generateGlyphsForGlyphStorage:layoutManager
								 desiredNumberOfCharacters:desiredCapacity-glyphIndex
												glyphIndex:&glyphIndex
											characterIndex:&charIndex];	// generate Glyphs (code but not position!)
			count=glyphIndex-firstInvalidGlyphIndex;
			firstInvalidGlyphIndex=glyphIndex;
			return count;
		}
	return 0;
}

- (void) insertGlyph:(NSGlyph) glyph atGlyphIndex:(unsigned) glyphIndex characterIndex:(unsigned) charIndex;
{
	// sync with _glyphInfo cache
	// i.e. realloc with additional slot
	// memmove
	// and fill entry
	[super insertGlyph:glyph atGlyphIndex:glyphIndex characterIndex:charIndex];
}

- (NSLayoutStatus) layoutControlGlyphForLineFragment:(NSRect) lineFrag;
{
	// this is IMHO intended to be overwritten in subclasses to control e.g. display of paragraph or tab characters
	if([textString characterAtIndex:curCharacterIndex] == '\t')
		[self layoutTab];
	return NSLayoutOutOfGlyphs;
}

/*
NSLayoutNotDone = 0,
 // line fragment rect fully filled + more glyphs (for another fragment)
 // return if we reach the right margin and have more glyphs
 // the outer loop must continue
NSLayoutDone,
 // all gyphs (of this paragraph) did fit into the rect (last fragment)
 // if we reach \n
NSLayoutCantFit,
 // current glyph is too big to fit
 // outer loop must decide how to handle this (ignore, try with a bigger fragment etc)
NSLayoutOutOfGlyphs
 // last line was laid out (extra fragment)
 // if we reach the end of the textstorage
 
 call [self growGlyphCaches:curGlyphIndex + 100 fillGlyphInfo:YES];
 here in this method on demand - OutOfGlyphs 
 
*/

- (NSLayoutStatus) layoutGlyphsInHorizontalLineFragment:(NSRect *) lineFragmentRect baseline:(float *) baseline;
{ // this is the core layout method doing one line (fragment)
	BOOL setBaseline=(*baseline == NSBaselineNotSet);
	NSLayoutStatus status=NSLayoutOutOfGlyphs;	// all glyphs laid out
	if(setBaseline)
		*baseline=0.0;
	// this appears to be a parameter filled by the caller!
//	*lineFragmentRect = (NSRect) { NSZeroPoint, { curContainerSize.width, curContainerSize.height } };
	// FIXME: handle firstLineHeadIndent, headIndent and lineFragmentPadding
	curGlyphOffset = 0.0;	// start at the left
	while(curCharacterIndex < [textString length])
		{ // we still have a character to process
		unichar curChar;
		NSTypesetterGlyphInfo *glyphInfo;
		if(curCharacterIndex >= NSMaxRange(attrsRange))
			{ // get new attribute range
			[self getAttributesForCharacterIndex:curCharacterIndex];
			[self fillAttributesCache];			
			}
		if(curCharacterIndex >= NSMaxRange(curParaRange))
			{
			status=NSLayoutDone;	// end of paragraph
			break;
			}
		if(curGlyphIndex >= firstInvalidGlyphIndex)
			{ // needs more glyphs
				// could estimate required size by line length?
				if([self growGlyphCaches:curGlyphIndex + 100 fillGlyphInfo:YES] == 0)
					break;	// there are no more glyphs (how can this be while we still have a character to process?)
				continue;	// try again
			}
			//		if(curGlyphOffset >= curMaxGlyphLocation)
		curChar=[textString characterAtIndex:curCharacterIndex];
		// FIXME: how to handle multiple glyphs for single character (and vice versa: ligatures)
		previousGlyph=curGlyph;
		curGlyph=[layoutManager glyphAtIndex:firstGlyphIndex+curGlyphIndex];	// get glyph
		glyphInfo=NSGlyphInfoAtIndex(curGlyphIndex);
		glyphInfo->curLocation=(NSPoint) { curGlyphOffset, *baseline+curBaselineOffset };
		glyphInfo->font=curFont;
		glyphInfo->glyphCharacterIndex=curCharacterIndex;
		*((unsigned char *) &glyphInfo->_giflags)=0;
		switch(curChar) {
			case '\t':
				glyphInfo->_giflags.dontShow=YES;
				glyphInfo->extent=0;	// should be width of tab
				[self layoutControlGlyphForLineFragment:*lineFragmentRect];
				break;
			case '\n':
				glyphInfo->_giflags.dontShow=YES;
				glyphInfo->extent=0;
				[self breakLineAtIndex:curGlyphIndex];		
				break;
			case '\b':
				glyphInfo->_giflags.dontShow=YES;
				glyphInfo->extent=0;
				break;	// allow overprinting (?)
			case NSAttachmentCharacter: { // handle attachment
				NSTextAttachment *a=[attrs objectForKey:NSAttachmentAttributeName];
				id <NSTextAttachmentCell> c=[a attachmentCell];
				NSPoint off=[c cellBaselineOffset];
				NSRect frame;
				glyphInfo->_giflags.isAttachment=YES;
				glyphInfo->attachmentSize=[c cellSize];
				glyphInfo->curLocation.x+=off.x;	// adjust offset
				glyphInfo->curLocation.y+=off.y;
				frame=[c cellFrameForTextContainer:curContainer
							  proposedLineFragment:*lineFragmentRect
									 glyphPosition:glyphInfo->curLocation
									characterIndex:curCharacterIndex];
				glyphInfo->extent=frame.size.width;
				break;				
			}
			default: {
				NSRect box=[curFont boundingRectForGlyph:curGlyph];
				NSSize adv=[curFont advancementForGlyph:curGlyph];
				glyphInfo->extent=adv.width;
				glyphInfo->_giflags.defaultPositioning=YES;
				// adjust line height and baseline according to bounding box
//				[attribs objectForKey:NSLigatureAttributeName];
				if(previousGlyph)
					{ // handle kerning
						// check if previous = f and current = l => reduce to single glyph
						NSSize k=[curFont _kerningBetweenGlyph:previousGlyph andGlyph:curGlyph];
						glyphInfo->curLocation.x+=k.width+curSpaceAfter;
						glyphInfo->curLocation.y+=k.height;
						glyphInfo->_giflags.defaultPositioning=NO;
					}
			}
		}
		[self typesetterLaidOneGlyph:glyphInfo];
		if(curGlyphOffset == 0.0 && glyphInfo->extent > curMaxGlyphLocation)
			{
			status=NSLayoutCantFit;	// this glyph does not fit
			break;
			}
		curGlyphOffset += glyphInfo->extent;	// advance writing position
		curCharacterIndex++;
		curGlyphIndex++;
		}
	if(*baseline == NSBaselineNotSet)
		; // determine here (by maximum character height)
	return status;
}

- (void) _layoutGlyphsInLayoutManager:(NSLayoutManager *) lm
				 startingAtGlyphIndex:(unsigned int) startGlyphIndex
			 maxNumberOfLineFragments:(unsigned int) maxNumLines
				 currentTextContainer:(NSTextContainer **) currentTextContainer
						 proposedRect:(NSRect *) proposedRect
					   nextGlyphIndex:(unsigned int *) nextGlyph;
{ // internal method - CHECKME: can we call this recursively with different textContainer/proposedRect to layout table entries?
	unsigned numLines = 0;
	NSLayoutStatus status;
	
	layoutManager = lm;
	textStorage = [layoutManager textStorage];
	textString = [textStorage string];
	
	// FIXME: better handle empty strings!
	firstGlyphIndex = startGlyphIndex;
	if(startGlyphIndex > 0)
		curCharacterIndex = [layoutManager characterIndexForGlyphAtIndex: startGlyphIndex];
	else
		curCharacterIndex=0;
	curGlyphIndex = 0;
	previousGlyph = NSNullGlyph;
	attrsRange = (NSRange) { 0, 0 };
	curParaRange = (NSRange) { 0, 0 };
	
	curContainerSize=[*currentTextContainer containerSize];
	curContainerIsSimpleRectangular=[*currentTextContainer isSimpleRectangularTextContainer];
	curContainerLineFragmentPadding=[*currentTextContainer lineFragmentPadding];
	
	while(numLines < maxNumLines && curCharacterIndex < [textString length])
		{ // try to fill the next line
		NSRect lineFragmentRect;
		NSRect remainingRect;
		NSRect usedRect;
		NSRange glyphRange;
		float baselineOffset = NSBaselineNotSet;
		if(curCharacterIndex >= NSMaxRange(curParaRange))
			{ // needs to handle new paragraph style
				// handle extra fragment if end of string?
				curParaStyle = [textStorage 
								attribute: NSParagraphStyleAttributeName
								atIndex: curCharacterIndex
								longestEffectiveRange: &curParaRange
								inRange:(NSRange){ 0, [textStorage length] }];
				if(!curParaStyle)
					curParaStyle=[NSParagraphStyle defaultParagraphStyle];			
				curMaxGlyphLocation=curContainerSize.width-[curParaStyle tailIndent];
				// set up basline offset for fixed line height
			}
		firstIndexOfCurrentLineFragment = firstGlyphIndex;
		status = [self layoutGlyphsInHorizontalLineFragment: proposedRect 
												   baseline: &baselineOffset];
		if (status == NSLayoutCantFit)
			{ // container is not wide or high enough, we need a new one
				break;
			}
		while(YES)
			{
			unsigned int i;
			// fixme: handle indentation and line fragment padding
			lineFragmentRect=[*currentTextContainer lineFragmentRectForProposedRect:*proposedRect
																	 sweepDirection:NSLineSweepRight
																  movementDirection:NSLineMovesDown
																	  remainingRect:&remainingRect];
			usedRect=lineFragmentRect;
			glyphRange = NSMakeRange(firstIndexOfCurrentLineFragment, curGlyphIndex);
			for(i=0; i < curGlyphIndex; i++)
				{ // set glyph specific attributes
					NSRange rng=NSMakeRange(firstGlyphIndex+i, 1);
					NSPoint location;
					[layoutManager setNotShownAttribute:NSGlyphInfoAtIndex(i)->_giflags.dontShow forGlyphAtIndex:rng.location];
					location=NSGlyphInfoAtIndex(i)->curLocation;
					location.y+=baselineOffset;	// move glyph to base line
					[layoutManager setLocation:location forStartOfGlyphRange:rng];
				}
			[self willSetLineFragmentRect: &lineFragmentRect
							forGlyphRange: glyphRange
								 usedRect: &usedRect];	// last chance to modify layout (e.g. line spacing)
			[layoutManager setLineFragmentRect:lineFragmentRect forGlyphRange:glyphRange usedRect:usedRect];			
			if(curContainerIsSimpleRectangular || NSIsEmptyRect(remainingRect))
				break;
			}
		// reduce proposedRect by what we have consumed and apply line spacing
		numLines++;
		if(status == NSLayoutOutOfGlyphs)	// this was the last fragment
			{
			// handle extra segment here?
			break;
			}
		}
	// FIXME: handle/create the extra line fragment
	if (nextGlyph != NULL)
		*nextGlyph = firstGlyphIndex+curGlyphIndex;
	layoutManager=nil;
	textStorage=nil;
}

- (void) layoutGlyphsInLayoutManager:(NSLayoutManager *) lm
				startingAtGlyphIndex:(unsigned) startGlyphIndex
			maxNumberOfLineFragments:(unsigned) maxNumLines
					  nextGlyphIndex:(unsigned *) nextGlyph;
{ // core layout method
	NSRect proposedRect;
	NSAssert(!busy, @"NSSimpleHorizontalTypesetter is already busy");
	busy=YES;
	// FIXME: check if index out of range?
	curContainer=[[layoutManager textContainers] objectAtIndex:curContainerIndex];
	proposedRect = (NSRect) { NSZeroPoint, [curContainer containerSize] };	// initially we propose the full container but each call can reduce it
	// FIXME: do we loop here to create new containers if needed?
	[self _layoutGlyphsInLayoutManager:lm
				 startingAtGlyphIndex:startGlyphIndex
			 maxNumberOfLineFragments:maxNumLines
				  currentTextContainer:&curContainer
						 proposedRect:&proposedRect
						nextGlyphIndex:nextGlyph];
	busy=NO;
}

- (void) layoutTab;
{
	NSTextTab *tab=[super textTabForGlyphLocation:firstGlyphIndex+curGlyphIndex writingDirection:0 maxLocation:curContainerSize.width];
	// ...
	// if there is no explicit tab, check [curParagraphStyle defaultTabInterval]
	// if > 0 apply to the tab in the GlyphInfo (by modifying the extent)
}

- (unsigned) sizeOfTypesetterGlyphInfo;
{
	return sizeof(NSTypesetterGlyphInfo);
}

- (void) typesetterLaidOneGlyph:(NSTypesetterGlyphInfo *) gl;
{ // can be overwritten by subclass to modify glyph info
	return;
}

- (void) updateCurGlyphOffset;
{
	// calculate current glyph location if needed (if defaultPositioning == YES???)
}

- (void) willSetLineFragmentRect:(NSRect *) aRect forGlyphRange:(NSRange) aRange usedRect:(NSRect *) bRect;
{ // overwrite this or the superclass definition in subclasses
	[super willSetLineFragmentRect:aRect forGlyphRange:aRange usedRect:bRect baselineOffset:&curBaselineOffset];
}

/* undocumented methods */

- (BOOL) _typesetterIsBusy;
{
	return busy;
}

- (NSTypesetterGlyphInfo *) _glyphInfoAtIndex:(int) fp8;
{
	return NSGlyphInfoAtIndex(fp8);
}

- (BOOL) followsItalicAngle;
{
	return _tsFlags._useItal;
}

- (void) setFollowsItalicAngle:(BOOL) fp8;
{
	_tsFlags._useItal=fp8;
}

- (float) baselineOffsetInLayoutManager:(id) fp8 glyphIndex:(unsigned int) fp12;
{
	return 0.0;
}

- (void) _setupBoundsForLineFragment:(NSRect *) fp8;
{
	
}

- (NSRect) normalizedRect:(NSRect) fp8;
{
	return fp8;
}

@end


