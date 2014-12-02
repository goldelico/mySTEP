/*
 NSTypesetter.m
 
 Author:	H. N. Schaller <hns@computer.org>
 Date:		Jun 2006-2012
 
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

@implementation NSTypesetter	// please use NSSimpleHorizontalTypesetter and not this class!

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
	[layoutManager showsControlCharacters];
	[layoutManager showsInvisibleCharacters];
	switch([[textStorage string] characterAtIndex:location]) {
		case NSTabCharacter: return NSTypesetterHorizontalTabAction;
		case NSNewlineCharacter: return NSTypesetterParagraphBreakAction;
		case ' ': return NSTypesetterWhitespaceAction;
		// case ' ': return NSTypesetterControlCharacterAction;	// how does this relate to NSControlGlyph?
		// case ' ': return NSTypesetterContainerBreakAction;
		case NSAttachmentCharacter: return 0;
	}
	return 0;
}

- (NSAttributedString *) attributedString;
{
	return textStorage;
}

- (NSDictionary *) attributesForExtraLineFragment;
{
	NSDictionary *d=[[layoutManager firstTextView] typingAttributes];
	if(!d)
		;
	return d;
}

- (CGFloat) baselineOffsetInLayoutManager:(NSLayoutManager *) manager glyphIndex:(NSUInteger) index;
{
	// FIXME: this depends on the NSFont??
	// or is it stored/cached for each glyph in the typesetter???
	// or can we calculate that from the glyph location?
	return 0.0;
}

- (void) beginLineWithGlyphAtIndex:(NSUInteger) index;
{
	[self setLineFragmentPadding:[curContainer lineFragmentPadding]];
	return;
}

- (void) beginParagraph;
{
	curParaStyle=[textStorage attribute:NSParagraphStyleAttributeName atIndex:curParaRange.location effectiveRange:&curParaRange];
	if(!curParaStyle)
		curParaStyle=[NSParagraphStyle defaultParagraphStyle];	// none specified
	[self setParagraphGlyphRange:[layoutManager glyphRangeForCharacterRange:curParaRange actualCharacterRange:NULL] separatorGlyphRange:NSMakeRange(0, 0)];
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
	return [layoutManager characterRangeForGlyphRange:range actualGlyphRange:rangePt];
}

- (NSParagraphStyle *) currentParagraphStyle; { return curParaStyle; }
- (NSTextContainer *) currentTextContainer; { return curContainer; }

- (void) deleteGlyphsInRange:(NSRange) range;
{
	[layoutManager deleteGlyphsInRange:range];
}

- (void) endLineWithGlyphRange:(NSRange) range;
{ // do adjustments (left, right, center, justfication) and apply lfr/lfur to line range
	// center: shift used rect right by half difference
	// right: shift used rect right by full difference
	// justify: distribute difference on space characters and kerning
	[layoutManager setTextContainer:[self currentTextContainer] forGlyphRange:_paragraphGlyphRange];
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
	return [layoutManager getGlyphsInRange:range
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
	NSRect proposedRect=NSZeroRect;
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
	switch([curParaStyle baseWritingDirection]) {
		case NSWritingDirectionNatural:
		default:
		case NSWritingDirectionLeftToRight: sweep=NSLineSweepRight; break;
		case NSWritingDirectionRightToLeft: sweep=NSLineSweepLeft; break;
	}
	*lineFragmentRect=[curContainer lineFragmentRectForProposedRect:propRect sweepDirection:sweep movementDirection:NSLineMovesDown remainingRect:remRect];
	*lineFragmentUsedRect=*lineFragmentRect;
	// FIXME: how can this be smaller if we take the proposed rect???
	lineFragmentRect->size.width=MIN(NSWidth(*lineFragmentRect), NSWidth(propRect));	// reduce to what was proposed
	// handle adjustments here by shifting the lfur?
}

- (NSRange) glyphRangeForCharacterRange:(NSRange) range 
				   actualCharacterRange:(NSRangePointer) rangePt;
{
	return [layoutManager glyphRangeForCharacterRange:range actualCharacterRange:rangePt];
}

- (CGFloat) hyphenationFactor;
{
	return [layoutManager hyphenationFactor];
}

- (CGFloat) hyphenationFactorForGlyphAtIndex:(NSUInteger) index;
{ // can be overridden in subclasses
	return [self hyphenationFactor];
}

- (UTF32Char) hyphenCharacterForGlyphAtIndex:(NSUInteger) index;
{
	return '-';
}

- (void) insertGlyph:(NSGlyph) glyph atGlyphIndex:(NSUInteger) index characterIndex:(NSUInteger) charIdx;
{ // used for hyphenation and keeps some caches in sync...
	[layoutManager insertGlyphs:&glyph length:1 forStartingGlyphAtIndex:index characterIndex:charIdx];
}

/*
 * also used by simpleTypesetter
 */

- (NSRange) layoutCharactersInRange:(NSRange) range
				   forLayoutManager:(NSLayoutManager *) manager
	   maximumNumberOfLineFragments:(NSUInteger) maxLines;
{ // this is the main layout function - we assume that the Glyphs are already generated and character indexes are assigned
	NSUInteger nextGlyph=[manager glyphIndexForCharacterAtIndex:range.location];
	NSRange r=range;
	[self layoutGlyphsInLayoutManager:manager startingAtGlyphIndex:nextGlyph maxNumberOfLineFragments:maxLines nextGlyphIndex:&nextGlyph];
	r.length=[manager characterIndexForGlyphAtIndex:nextGlyph]-r.location;	// did not process all
	return r;
}

/*
 * FIXME: not implemented (but in simpleTypesetter
 */

- (void) layoutGlyphsInLayoutManager:(NSLayoutManager *) manager 
				startingAtGlyphIndex:(NSUInteger) startIndex 
			maxNumberOfLineFragments:(NSUInteger) maxLines 
					  nextGlyphIndex:(NSUInteger *) nextGlyph; 
{ // documentation says that this is the main function called by NSLayoutManager
	_maxNumberOfLineFragments=maxLines;	// set up limitation counter

//	curContainer=

	/* FIXME:
	appears to setup everything and then simply calls layoutParagraphAtPoint:

	 splitting into pragraphs is probably done here
	 
	 loop over all pragraphs:
	 [self setParagraphGlyphRange:<#(NSRange)paragRange#> separatorGlyphRange:<#(NSRange)sepRange#>];
	 [self layoutParagraphAtPoint:]
	 check if we need a new text container and continue

	*/
		
	// MOVE this to layoutParagraphAtPoint: to lay out current paragraph into current text container starting at current position...
	
	
	NSString *str=[textStorage string];
	NSUInteger options=[manager layoutOptions];	 // NSShowControlGlyphs, NSShowInvisibleGlyphs, NSWantsBidiLevels
	NSGlyph previous=0;
	NSTextContainer *container;
	NSPoint location;	// relative location within line fragment rect
	NSRect lfr;		// current line fragment rect
	layoutManager=manager;
	if(startIndex > 0)
		{ // continue previous
			container=[layoutManager textContainerForGlyphAtIndex:startIndex-1 effectiveRange:NULL];
		location=[layoutManager locationForGlyphAtIndex:startIndex-1];
		// update location!?!
		lfr=[layoutManager lineFragmentRectForGlyphAtIndex:startIndex-1 effectiveRange:NULL];
		}
	else
		{
		container=[[layoutManager textContainers] objectAtIndex:0];
		location=NSZeroPoint;
		lfr=(NSRect) { NSZeroPoint, [container containerSize] };
		}

	while(startIndex < [layoutManager numberOfGlyphs] && _maxNumberOfLineFragments > 0)
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
	// [layoutManager setExtraLineFragmentRect:lfr usedRect:ulfr textContainer:aTextContainer];
	layoutManager=nil;
}

- (NSLayoutManager *) layoutManager;
{
	return layoutManager;
}

// NOTE: there may be no glyph corresponding to the \n character!!!
// i.e. we can't find a \n character at the location defined by glyphs
// FIXME: make this useable for layout of table cells (which are sub-rects within a NSTextContainer)

- (NSUInteger) layoutParagraphAtPoint:(NSPointPointer) lfrOrigin;
{ // layout glyphs until end of paragraph; creates full line fragments
	NSString *str=[textStorage string];
	NSUInteger startIndex=_paragraphGlyphRange.location;
	NSRect proposedRect=(NSRect) { *lfrOrigin, [curContainer containerSize] };
	NSPoint location;
	NSRect lfr, lfur, rr;
	// reduce size?
	[self beginParagraph];
	while(_maxNumberOfLineFragments-- > 0)
		{ // for each line (fragment)
			CGFloat baselineOffset;
			[self beginLineWithGlyphAtIndex:startIndex];
			while(curParaRange.location < [textStorage length])
				{
				NSRect box;
				NSRect ulfr;	// used line fragment rect
				NSGlyph previous=NSNullGlyph;
				NSRange attribRange;
				NSDictionary *attribs=[textStorage attributesAtIndex:curParaRange.location effectiveRange:&attribRange];
				NSFont *font=[self substituteFontForFont:[attribs objectForKey:NSFontAttributeName]];
				if(!font) font=[[[layoutManager firstTextView] typingAttributes] objectForKey:NSFontAttributeName];		// try to get from typing attributes
				if(!font) font=[NSFont userFontOfSize:0.0];		// use default system font
				while(attribRange.length > 0)
					{ // character range with same font
						unichar c=[str characterAtIndex:attribRange.location];
						NSGlyph glyph=[layoutManager glyphAtIndex:startIndex];
						NSTypesetterControlCharacterAction a=0;
						CGFloat baseLineOffset;
						if(glyph == NSControlGlyph)
							a=[self actionForControlCharacterAtIndex:attribRange.location];
						if(a&NSTypesetterZeroAdvancementAction)
							;	// invisible and no movement
						else
							{ // normal advancement
								
								NSSize adv;
								if(glyph == NSControlGlyph)
									{
									box=[self boundingBoxForControlGlyphAtIndex:startIndex forTextContainer:curContainer proposedLineFragment:lfr glyphPosition:location characterIndex:attribRange.location];
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
								// may ask [[layoutManager delegate] layoutManager:layoutManager didCompleteLayoutForTextContainer: atEnd:]
							}
						// FIXME: update proposedRect
						ulfr=box;
						[self setNotShownAttribute:(a != 0) forGlyphRange:NSMakeRange(startIndex, 1)];
						// FIXME: handle rects
						baseLineOffset=[layoutManager defaultBaselineOffsetForFont:font];
						[self willSetLineFragmentRect:&lfr forGlyphRange:NSMakeRange(startIndex, 1) usedRect:&ulfr baselineOffset:&baseLineOffset];
						[self setLineFragmentRect:lfr forGlyphRange:NSMakeRange(startIndex, 1) usedRect:ulfr baselineOffset:baseLineOffset];
						previous=glyph;
						startIndex++;
						
						attribRange.location++;
						curParaRange.location++;
						curParaRange.length--;
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
			baselineOffset=[self baselineOffsetInLayoutManager:layoutManager glyphIndex:startIndex];
			
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

- (NSRange) paragraphCharacterRange; { return  curParaRange; }
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
	[layoutManager setAttachmentSize:size forGlyphRange:range];
}

- (void) setAttributedString:(NSAttributedString *) attrStr;
{
	textStorage=(NSTextStorage *) attrStr;	// should have the NSTextStorage interface
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
		[layoutManager setDrawsOutsideLineFragment:flag forGlyphAtIndex:range.location++];
}

- (void) setHardInvalidation:(BOOL) flag forGlyphRange:(NSRange) range;
{
	NIMP;
}

- (void) setHyphenationFactor:(CGFloat) value;
{
	[layoutManager setHyphenationFactor:value];
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
	[layoutManager setLineFragmentRect:fragRect forGlyphRange:range usedRect:rect];
	// what do we do with the offset???
}

- (void) setLocation:(NSPoint) loc 
	withAdvancements:(const CGFloat *) advancements 
forStartOfGlyphRange:(NSRange) range;
{
	[layoutManager setLocation:loc forStartOfGlyphRange:range];
	// apply advancements
}

- (void) setNotShownAttribute:(BOOL) flag forGlyphRange:(NSRange) range;
{ // can be set e.g. for TAB or other control characters that are not shown in Postscript/PDF
	while(range.length-- > 0)
		[layoutManager setNotShownAttribute:flag forGlyphAtIndex:range.location++];
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
	return [layoutManager substituteFontForFont:font];
}

- (void) substituteGlyphsInRange:(NSRange) range withGlyphs:(NSGlyph *) glyphs; 
{
	[layoutManager deleteGlyphsInRange:range];
	[layoutManager insertGlyphs:glyphs length:range.length forStartingGlyphAtIndex:range.location characterIndex:[layoutManager characterIndexForGlyphAtIndex:range.location]];
}

- (NSArray *) textContainers;
{
	return [layoutManager textContainers];
}

- (NSTextTab *) textTabForGlyphLocation:(CGFloat) glyphLoc 
					   writingDirection:(NSWritingDirection) writingDirection 
							maxLocation:(CGFloat) maxLoc; 
{
	NSTextTab *tab;
	NSEnumerator *e;
	if(writingDirection == NSWritingDirectionNatural)
		writingDirection=NSWritingDirectionLeftToRight;	// determine from system setting
	if(writingDirection == NSWritingDirectionLeftToRight)
		{
		e=[[curParaStyle tabStops] objectEnumerator];
		while((tab=[e nextObject]))
			{
			CGFloat tl=[tab location];
			if(tl > maxLoc)
				break;
			if(tl > glyphLoc)
				return tab;	// first tab beyond this glyph
			}
		}
	else
		{ // right to left
		e=[[curParaStyle tabStops] reverseObjectEnumerator];
		while((tab=[e nextObject]))
			{
			CGFloat tl=[tab location];
			if(tl <= maxLoc && tl < glyphLoc)
				return tab;	// first tab before this glyph
			}
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
		glyphs=(NSTypesetterGlyphInfo *) objc_calloc(capacityGlyphInfo, sizeof(glyphs[0]));
		}
	return self;
}

- (void) dealloc
{
	if(glyphs)
		objc_free(glyphs);
	[super dealloc];
}

//- (CGFloat) baselineOffsetInLayoutManager:(id) layoutManager glyphIndex:(NSUInteger) idx;

- (NSTypesetterGlyphInfo *) baseOfTypesetterGlyphInfo;
{
	return glyphs;
}

- (void) breakLineAtIndex:(NSUInteger) location;
{
	//	NSTypesetterGlyphInfo *glyphInfo=[self _glyphInfoAtIndex:curGlyphIndex];
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
		case NSLineBreakByCharWrapping:
		case NSLineBreakByTruncatingHead:
		case NSLineBreakByTruncatingTail:
		case NSLineBreakByTruncatingMiddle:
			// check for truncation and apply [curParagraphStyle tighteningFactorForTruncation]
			break;
	}
//	glyphInfo->extent=curMaxGlyphLocation-curGlyphOffset;	// extends to end of line
	wrapAfterCurGlyph=YES;
}

- (NSUInteger) capacityOfTypesetterGlyphInfo;
{
	return capacityGlyphInfo;
}

- (void) clearAttributesCache;
{ // release any retained objects and remove links
	attrsRange = (NSRange) { 0, 0 };
	attrs=nil;
	curParaRange = (NSRange) { 0, 0 };
	curParaStyle=nil;
	previousFont=nil;
	curFont=nil;
	return;
}

- (void) clearGlyphCache;
{
	sizeOfGlyphInfo=0;	// ???
	curGlyphIndex=0;
	curContainer=0;
	curContainerIndex=0;
	firstInvalidGlyphIndex=0;
	// shrink glpyhInfo storage to a reasonable default allocation
	// i.e. to 200 entries
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
	NSString *val;
	previousFont=curFont;
	curFont=[layoutManager substituteFontForFont:[attrs objectForKey:NSFontAttributeName]];
	if(!curFont) curFont=[[[layoutManager firstTextView] typingAttributes] objectForKey:NSFontAttributeName];		// try to get from typing attributes
	if(!curFont) curFont=[NSFont userFontOfSize:0.0];	// default
	curFontBoundingBox=[curFont boundingRectForFont];
	curFontIsFixedPitch=[curFont isFixedPitch];
	if(curFontIsFixedPitch)
		curFontAdvancement=[curFont advancementForGlyph:NSNullGlyph];	// should be the same for all ?
	curTextAlignment=[curParaStyle alignment];
	curLayoutDirection=[curParaStyle baseWritingDirection];
	curMinLineHeight=[curParaStyle minimumLineHeight];
	if(curMinLineHeight < 0.0) curMinLineHeight=0.0;
	curMaxLineHeight=[curParaStyle maximumLineHeight];
	if(curMaxLineHeight <= 0.0) curMaxLineHeight=FLT_MAX;	// infinite
	curSuperscript=[[attrs objectForKey:NSSuperscriptAttributeName] intValue];
	curSpaceAfter=(val=[attrs objectForKey:NSKernAttributeName])?[val floatValue]:0.0;
#if 0
	NSLog(@"cbl=%@", [attrs objectForKey:NSBaselineOffsetAttributeName]);
#endif
	curBaselineOffset=(val=[attrs objectForKey:NSBaselineOffsetAttributeName])?[val floatValue]:0.0;
	/* NSGlyphInfo *gi=[attrs objectForKey:NSGlyphInfoAttributeName] */
}

- (NSUInteger) firstGlyphIndexOfCurrentLineFragment;
{
	return firstIndexOfCurrentLineFragment;
}

- (void) fullJustifyLineAtGlyphIndex:(NSUInteger) glyphIndexForLineBreak;
{ // insert flexible space (kerning) between index 0 and glyphIndexForLineBreak-1
	// unless we need too much flexible space
	;
}

- (void) getAttributesForCharacterIndex:(NSUInteger) idx;
{
	attrs=[textStorage attributesAtIndex:idx effectiveRange:&attrsRange];
#if 0
	NSLog(@"getAttributesForCharacterIndex:%u", idx);
	NSLog(@"  -> range:%@", NSStringFromRange(attrsRange));
	NSLog(@"  -> %@", attrs);
#endif
}

- (NSUInteger) glyphIndexToBreakLineByHyphenatingWordAtIndex:(NSUInteger) charIndex;
{
	CGFloat factor=[curParaStyle hyphenationFactor];
	if(factor <= 0.0) factor=[layoutManager hyphenationFactor];
	if(factor <= 0.0)
		; // no hyphenation
	// hyphenate by [self inserGlyph:'-'] just before the charIndex
	if(curTextAlignment == NSJustifiedTextAlignment)
		[self fullJustifyLineAtGlyphIndex:charIndex];
	return charIndex;
}

- (NSUInteger) glyphIndexToBreakLineByWordWrappingAtIndex:(NSUInteger) charIndex;
{
	// charIndex is IMHO indexing the textStorage
	// and the return value is an index into the Glyph cache?

	// check if hyphenation is enabled
	// find a hyphen location
	return [self glyphIndexToBreakLineByHyphenatingWordAtIndex:charIndex];
}

- (NSUInteger) glyphIndexToBreakLineByClippingAtIndex:(NSUInteger) idx;
{
	// clipping means deleting glyphs to end of line
	return idx;
}

- (NSUInteger) growGlyphCaches:(NSUInteger) desiredCapacity fillGlyphInfo:(BOOL) fillGlyphInfo;
{
	NSUInteger count=0;
	if(desiredCapacity > capacityGlyphInfo)
		{ // really needs to grow the cache
			glyphs=(NSTypesetterGlyphInfo *) objc_realloc(glyphs, desiredCapacity*sizeof(glyphs[0]));
			memset(&glyphs[capacityGlyphInfo], 0, (desiredCapacity-capacityGlyphInfo)*sizeof(glyphs[0]));	// clear newly created slots
			capacityGlyphInfo=desiredCapacity;
		}
	if(fillGlyphInfo)
		{
		BOOL flag;
		NSGlyph glyph;
		[layoutManager ensureGlyphsForGlyphRange:NSMakeRange(firstInvalidGlyphIndex, desiredCapacity)];	// generate glyphs only once (or glyphAtIndex: would generate them individually)
		while(YES)
			{ // we need this loop to find out how many glyphs have been generated and make firstInvalidGlyphIndex track [layoutManager numberOfGlyphs]
			glyph=[layoutManager glyphAtIndex:firstInvalidGlyphIndex isValidIndex:&flag];
			if(!flag)
				break;	// no longer valid
			firstInvalidGlyphIndex++;
			count++;
			}
		}
	return count;
}

- (void) insertGlyph:(NSGlyph) glyph atGlyphIndex:(NSUInteger) glyphIndex characterIndex:(NSUInteger) charIndex;
{
	NIMP;
	// sync with _glyphInfo cache
	// i.e. realloc with additional slot
	// memmove
	// and fill entry
	/*
	 glyphInfo==[self _glyphInfoAtIndex:curGlyphIndex];
	glyphInfo->curLocation=(NSPoint) { curGlyphOffset, *baseline+curBaselineOffset };
	glyphInfo->font=curFont;
	glyphInfo->glyphCharacterIndex=charIndex;
	 */
	[super insertGlyph:glyph atGlyphIndex:glyphIndex characterIndex:charIndex];
}

- (NSLayoutStatus) layoutControlGlyphForLineFragment:(NSRect) lineFrag;
{
	// this is IMHO intended to be overwritten in subclasses to control e.g. display of paragraph or tab characters
	switch([textString characterAtIndex:curCharacterIndex]) {
		case NSTabCharacter:
			[self layoutTab];
			break;
		case NSLineSeparatorCharacter:	// unicode line separator
		case NSParagraphSeparatorCharacter:	// unicode line separator
		case NSNewlineCharacter:
			[self breakLineAtIndex:curGlyphIndex];		
			break;
		case NSBackspaceCharacter:
			// allow overprinting (?) by setting back curGlyphOffset to previous glyph or assigning negative extent?
			break;
		case NSCarriageReturnCharacter:
		case NSEnterCharacter:
		case NSBackTabCharacter:
		case NSDeleteCharacter:
			break;
		case NSFormFeedCharacter:	// containerBreak?
			break;
	}
	// FIXME:
	return NSLayoutOutOfGlyphs;
}

/*
NSLayoutNotDone = 0,
 // line fragment rect fully filled + more glyphs (for another fragment)
 // return if we reach the right margin and have more glyphs
 // the outer loop must continue
 // more or less means that a line within a paragraph is filled
NSLayoutDone,
 // all gyphs (of this paragraph) did fit into the rect (last fragment)
 // if we reach \n
NSLayoutCantFit,
 // first glyph is already too big to fit
 // outer loop must decide how to handle this (ignore, try with a bigger fragment etc)
NSLayoutOutOfGlyphs
 // last line was laid out (extra fragment)
 // if we reach the end of the textstorage
*/

- (NSLayoutStatus) layoutGlyphsInHorizontalLineFragment:(NSRect *) lineFragmentRect baseline:(CGFloat *) baseline;
{  /* this is the core layout method doing one line (fragment)
	* it simply fills until the given width of the lineFragmentRect is reached
	* or the paragraph range or the character storage is exhausted.
	* ending at the paragraph range may be a feature that is n/a in Cocoa but we add it to lay out table cells
	* note that glyph locations are relative to the lineFragmentRect
	*
	* on return
	*   lineFragement.size has been reduced to the usedRect (width&height)
	*   baseline is unchanged or has been determined by the maximum ascender
	*   the glyphinfo array has been filled
	*     the vertical location is either the baseline or 0.0 and must be moved externally
	*   curGlyphIndex gives the number of the glyphs
	*
	* it uses or modifies (m) these iVars:
	*   firstIndexOfCurrentLineFragment
	*   curGlyphOffset (m)
	*   curCharacterIndex (m)
	*   curGlyphIndex (m)
	*   curParaRange (m)
	*   firstInvalidGlyphIndex (m)
	*   previousGlyph (m)
	*   curGlyph (m)
	*   curBaselineOffset
	*   curFont
	*   curContainer
	*   attribute cache (m)
	*   curMinLineHeight
	*   curMaxLineHeight
	*/
	
	BOOL setBaseline=(*baseline == NSBaselineNotSet);
	NSLayoutStatus status=NSLayoutOutOfGlyphs;	// all glyphs laid out
	CGFloat lineHeight;
#if 0
	NSLog(@"layoutGlyphsInHorizontalLineFragment: %@", NSStringFromRect(*lineFragmentRect));
	NSLog(@"baseline=%f", *baseline);
#endif
	if(setBaseline)
		*baseline=0.0;
	curGlyphOffset=[curParaStyle headIndent];	// start at left indent (or 0.0)
	containerBreakAfterCurGlyph=NO;
	curMinBaselineDistance=curMaxBaselineDistance=0.0;
	curGlyphIndex=0;	// fill from the beginning
	curGlyph=NSNullGlyph;
	while(curCharacterIndex < [textString length])
		{ // we still have a character to process
			unichar curChar;
			NSTypesetterGlyphInfo *glyphInfo;
#if 0
			NSLog(@"curGlyphIndex: %u", curGlyphIndex);
			NSLog(@"curGlyphOffset: %g", curGlyphOffset);
			NSLog(@"curBaselineOffset: %g", curBaselineOffset);
			NSLog(@"curMinBaselineDistance: %g", curMinBaselineDistance);
			NSLog(@"*baseline: %g", *baseline);
			NSLog(@"setBaseline: %d", setBaseline);
			NSLog(@"curCharacterIndex: %u", curCharacterIndex);
			NSLog(@"curParaRange: %@", NSStringFromRange(curParaRange));
			NSLog(@"curMaxGlyphLocation: %g", curMaxGlyphLocation);
			NSLog(@"attrsRange: %@", NSStringFromRange(attrsRange));
			NSLog(@"firstInvalidGlyphIndex: %u", firstInvalidGlyphIndex);
			NSLog(@"containerBreakAfterCurGlyph: %d", containerBreakAfterCurGlyph);
#endif
			if(curCharacterIndex >= NSMaxRange(curParaRange))
				{ // switch to new paragraph style
					// if(curParagraphRange.location > 0)
					//	[self endParagraph];
					curParaStyle=[textStorage attribute:NSParagraphStyleAttributeName
												atIndex:curCharacterIndex
								  longestEffectiveRange:&curParaRange
												inRange:(NSRange){ 0, [textStorage length] }];
					if(!curParaStyle)
						curParaStyle=[NSParagraphStyle defaultParagraphStyle];
					curGlyphOffset=[curParaStyle firstLineHeadIndent];	// start new paragrph
					curMaxGlyphLocation=[curParaStyle tailIndent];	// positive values are absolute
					if(curMaxGlyphLocation <= 0.0)	// relative to right margin
						curMaxGlyphLocation+=lineFragmentRect->size.width;
					// set up baseline offset for fixed line height
					// check for NSTextTableBlock attribute in textStorage and if yes,
					// get table cell size and recursively layout table cells (with lineFragmenRect reduced to column)
					// [self beginParagraph];
					status=NSLayoutDone;	// end of paragraph
					break;
				}
			if(curCharacterIndex >= NSMaxRange(attrsRange))
				{ // get new attribute range
					[self getAttributesForCharacterIndex:curCharacterIndex];
					[self fillAttributesCache];			
				}
			if(curGlyphIndex >= capacityGlyphInfo)
				{ // needs more glyphs
					// could return OutOfGlyphs and call the grow method in the outer loop
					// there we can detect that no new glyphs can be allocated
					// bu how do we know the deired sizse there?
					// could we better estimate required size by line length, i.e. distance to curParaRange?
					if([self growGlyphCaches:curGlyphIndex + 100 fillGlyphInfo:YES] == 0)
						break;	// there are no more glyphs (how can this be while we still have a character to process?)
					continue;	// try again
				}
			curChar=[textString characterAtIndex:curCharacterIndex];
			/* [layoutManager temporaryAttributeAtCharacterIndex:curCharIndex effectiveRange:NULL]; */
			// FIXME: how to handle multiple glyphs for single character (and vice versa: i.e. ligatures and overprinting)
			previousGlyph=curGlyph;
			curGlyph=[layoutManager glyphAtIndex:firstIndexOfCurrentLineFragment+curGlyphIndex];	// get glyph
			glyphInfo=[self _glyphInfoAtIndex:curGlyphIndex];
#if 0
			NSLog(@"glyphInfo=%p", glyphInfo);
			NSLog(@"curGlyphOffset=%g", curGlyphOffset);
			NSLog(@"*baseline=%g", *baseline);
			NSLog(@"curBaselineOffset=%g", curBaselineOffset);
			NSLog(@"*baseline + curBaselineOffset=%g", *baseline+curBaselineOffset);
			NSLog(@"point=%@", NSStringFromPoint((NSPoint) { curGlyphOffset, *baseline+curBaselineOffset }));
#endif
			glyphInfo->curLocation=(NSPoint) { curGlyphOffset, *baseline+curBaselineOffset };
#if 0
			NSLog(@"%d[%d]: glyphInfo->curLocation=%@", curGlyphIndex, capacityGlyphInfo, NSStringFromPoint(glyphInfo->curLocation));
#endif
			glyphInfo->font=curFont;
			glyphInfo->glyphCharacterIndex=curCharacterIndex;
			*((unsigned char *) &glyphInfo->_giflags)=0;
			curGlyphIsAControlGlyph=NO;
			curGlyphExtentAboveLocation=[curFont ascender];
			curGlyphExtentBelowLocation=[curFont descender];
			wrapAfterCurGlyph=NO;
			if([[NSCharacterSet controlCharacterSet] characterIsMember:curChar])
				{
				glyphInfo->_giflags.dontShow=![layoutManager showsControlCharacters];
				glyphInfo->extent=0;	// may become width of tab or \n to end of line
				status=[self layoutControlGlyphForLineFragment:*lineFragmentRect];				
				}
			else if(curChar == NSAttachmentCharacter)
				{ // handle attachment
				NSTextAttachment *a=[attrs objectForKey:NSAttachmentAttributeName];
				id <NSTextAttachmentCell> c=[a attachmentCell];
				NSPoint off=[c cellBaselineOffset];
				NSRect frame;
				glyphInfo->_giflags.isAttachment=YES;
				glyphInfo->_giflags.defaultPositioning=(off.x == 0 && off.y == 0);
				glyphInfo->attachmentSize=[c cellSize];
				glyphInfo->curLocation.x+=off.x;	// adjust offset
				glyphInfo->curLocation.y+=off.y;
				curGlyphExtentAboveLocation=glyphInfo->attachmentSize.height;
				curGlyphExtentBelowLocation=-off.y;
				frame=[c cellFrameForTextContainer:curContainer
							  proposedLineFragment:*lineFragmentRect
									 glyphPosition:glyphInfo->curLocation
									characterIndex:curCharacterIndex];
				glyphInfo->extent=frame.size.width;
				break;				
				}
			else
				{
				NSRect box=[curFont boundingRectForGlyph:curGlyph];
				NSSize adv=[curFont advancementForGlyph:curGlyph];
				glyphInfo->extent=adv.width;
				glyphInfo->_giflags.defaultPositioning=YES;
				if(NSIsEmptyRect(box))
					glyphInfo->_giflags.dontShow=YES;
				curGlyphExtentAboveLocation=NSMaxY(box);
				curGlyphExtentBelowLocation=NSMinY(box);
				//				[attribs objectForKey:NSLigatureAttributeName];
				if(previousGlyph)
					{ // handle kerning
						// handle ligatures: check if previous = 'f' and current = 'l' => reduce to single glyph
						// not here - this is done in NSGlyphGenerator
						NSSize k=[curFont _kerningBetweenGlyph:previousGlyph andGlyph:curGlyph];
						k.width+=curSpaceAfter;
						if(k.width != 0.0 || k.height != 0.0)
							{
							glyphInfo->curLocation.x+=k.width;
							glyphInfo->curLocation.y+=k.height;
							glyphInfo->_giflags.defaultPositioning=NO;	// must set the relative position before drawing this glyph
							}
					}
				}
			curMinBaselineDistance=MAX(curMinBaselineDistance, curGlyphExtentAboveLocation);
			curMaxBaselineDistance=MAX(curMaxBaselineDistance, curGlyphExtentBelowLocation+curGlyphExtentAboveLocation);
			if(!glyphInfo->_giflags.dontShow && curGlyphOffset+glyphInfo->extent > curMaxGlyphLocation)
				{ // check if there is enough space for this glyph
					if(curGlyphIndex == 0)
						status=NSLayoutCantFit;	// not even the first glyph does fit
					else
						status=NSLayoutNotDone;	// more work to do
					break;
				}
			[self typesetterLaidOneGlyph:glyphInfo];
			[self updateCurGlyphOffset];	// advance writing position
			curCharacterIndex++;
			curGlyphIndex++;
			if(wrapAfterCurGlyph)
				{ // we did hit a \n
					status=NSLayoutNotDone;	// more work to do
					break;
				}
			if(containerBreakAfterCurGlyph)
				{
				status=NSLayoutDone;	// treat like end of paragraph
				break;
				}
		}
	curMaxBaselineDistance=ceilf(curMaxBaselineDistance);
	if(setBaseline)
		*baseline=curMinBaselineDistance; // determine here (by maximum ascender)
	if(lineFragmentRect->size.width != FLT_MAX)
		{ // can't align for infinitely large box (e.g. string drawing at given point)
			switch(curTextAlignment) {
				case NSRightTextAlignment:
					lineFragmentRect->origin.x+=curMaxGlyphLocation-curGlyphOffset;
					break;
				case NSCenterTextAlignment:
					lineFragmentRect->origin.x+=0.5*(curMaxGlyphLocation-curGlyphOffset);
					break;
				default:
					break;
			}
		}
	lineFragmentRect->size.width=curGlyphOffset;			// used width
	lineHeight=curMaxBaselineDistance;
	if([curParaStyle lineHeightMultiple] > 0.0)
		lineHeight *= [curParaStyle lineHeightMultiple];	// shouldn't we take the previous Paragraph?
	lineHeight+=[curParaStyle lineSpacing];
	// somehow add paragraphSpacing and paragraphSpacingBefore
	lineFragmentRect->size.height=MIN(MAX(curMinLineHeight, lineHeight), curMaxLineHeight);	// set line height
#if 0
	NSLog(@"   -> %d: %@", status, NSStringFromRect(*lineFragmentRect));
#endif	
	return status;
}

/* the following method splits a pure horizontal layout into fragments and multiple lines to
 * flow around forbidden areas in a (potentially non-rectangular) currentTextContainer.
 * the proposedRect should be within the text container
 * it also handles indentation, padding, line spacing, justification etc.
 *
 * CHECKME: can we call this recursively with same textContainer but small/different proposedRects to layout table cells?
 *
 * FIXME: should handle table cells
 * FIXME: should request and switch containers if needed
 */

- (void) _layoutGlyphsInLayoutManager:(NSLayoutManager *) lm
				 startingAtGlyphIndex:(NSUInteger) startGlyphIndex
			 maxNumberOfLineFragments:(NSUInteger) maxNumLines
				 currentTextContainer:(NSTextContainer **) currentTextContainer
						 proposedRect:(NSRect *) proposedRect
					   nextGlyphIndex:(NSUInteger *) nextGlyph;
{ // internal method
	NSUInteger numLines = 0;
	NSLayoutStatus status=NSLayoutNotDone;
	NSRect remainingRect = NSZeroRect;
	
	layoutManager = lm;
	textStorage = [layoutManager textStorage];
	textString = [textStorage string];
	
	firstGlyphIndex = startGlyphIndex;
	curGlyphIndex = firstGlyphIndex;
	curCharacterIndex = [layoutManager characterIndexForGlyphAtIndex:curGlyphIndex];

	containerBreakAfterCurGlyph=YES;
	while(numLines < maxNumLines)
		{ // try to fill the next line
			NSRange glyphRange;
			CGFloat baselineOffset = NSBaselineNotSet;	// we want to position the glyphs ourseleves
			NSRect lineFragmentRect;
			NSRect usedRect;
			NSUInteger i;
			// check for table layout
			// i.e. if [[textStorage attribute:NSParagraphStyleAttributeName AtIndex:curCharacterIndex] textBlocks]
			// is not empty count
			// save initial/current container index
			// if yes, get number of columns and do their layout (unlimited numberOfLines)
			// reset container and vertical start position for each table column
			if(!containerBreakAfterCurGlyph)
				{ // try current container again
#if 0
					NSLog(@"get next lfr from %@", *currentTextContainer);
#endif
					if(curContainerIsSimpleRectangular)
						lineFragmentRect=*proposedRect;	// full container rect is ok
					// FIXME: passing in the full proposedRect may lead to wrong results, for example for an hour-glass shaped container
					// we somehow should be able to adjust/redo based on the estimated or real line height
					else if(NSIsEmptyRect(remainingRect))
						lineFragmentRect=[*currentTextContainer lineFragmentRectForProposedRect:*proposedRect
																				 sweepDirection:NSLineSweepRight
																			  movementDirection:NSLineMovesDown
																				  remainingRect:&remainingRect];
					else
						lineFragmentRect=[*currentTextContainer lineFragmentRectForProposedRect:remainingRect
																				 sweepDirection:NSLineSweepRight
																			  movementDirection:NSLineMovesDown
																				  remainingRect:&remainingRect];				
				}
			if(containerBreakAfterCurGlyph || NSIsEmptyRect(lineFragmentRect))
				{ // try next container
					NSArray *containers=[lm textContainers];
#if 0
					NSLog(@"try next container");
#endif
					if(!*currentTextContainer)
						curContainerIndex=0;	// first container index
					else
						curContainerIndex=[containers indexOfObjectIdenticalTo:*currentTextContainer]+1;	// next container index
					if(curContainerIndex >= [containers count])
						{ // does not exist
							*currentTextContainer=nil;
#if 1
							NSLog(@"no next container");
#endif
							break;	// no container left over
						}
					if(*currentTextContainer)
						[[layoutManager delegate] layoutManager:layoutManager didCompleteLayoutForTextContainer:*currentTextContainer atEnd:NO];	// wasn't the end
					*currentTextContainer=[containers objectAtIndex:curContainerIndex];
					curContainerSize=[*currentTextContainer containerSize];
					*proposedRect=(NSRect) { NSZeroPoint, curContainerSize };
					curContainerIsSimpleRectangular=[*currentTextContainer isSimpleRectangularTextContainer];
					curContainerLineFragmentPadding=[*currentTextContainer lineFragmentPadding];
					containerBreakAfterCurGlyph=NO;	// found one
					continue;	// try again for new container
				}
			if(status == NSLayoutOutOfGlyphs)	// we previously have processed the last fragment
				{
				// FIXME: should we append a virtual \n glyph if there isn't any?
				if(firstGlyphIndex == 0)	// right after \n or empty text storage
					[layoutManager setExtraLineFragmentRect:lineFragmentRect usedRect:usedRect textContainer:*currentTextContainer];
				else	// CHECKME: do we need this here?
					[layoutManager setExtraLineFragmentRect:NSZeroRect usedRect:NSZeroRect textContainer:nil];	// clear extra fragment
				break;
				}
			firstIndexOfCurrentLineFragment=firstGlyphIndex;
			usedRect=lineFragmentRect;
			status=[self layoutGlyphsInHorizontalLineFragment:&usedRect 
													 baseline:&baselineOffset];	// layout into this LFR
			if(curGlyphIndex > 0)
				{ // did layout anything
					lineFragmentRect.size.height=usedRect.size.height;	// line height
					glyphRange=NSMakeRange(firstIndexOfCurrentLineFragment, 1);	// initialize range
					// FIXME: should set textContainer first
					// FIXME: should set the location for the first glyph in sequence only
					// so that we have a rangeOfNominalySpacedGlyphs
					for(i=0; i < curGlyphIndex; i++)
						{ // copy location and attributes to layout manager
							NSPoint location=NSGlyphInfoAtIndex(i)->curLocation;
#if 0
							NSLog(@"%d[%d]: location=%@ ulfr=%@ lfr=%@ blo=%f", i, capacityGlyphInfo, NSStringFromPoint(location), NSStringFromRect(usedRect), NSStringFromRect(lineFragmentRect), baselineOffset);
#endif
							location.x+=usedRect.origin.x-lineFragmentRect.origin.x;
							location.y+=baselineOffset;	// move glyph down to base line
							[layoutManager setNotShownAttribute:NSGlyphInfoAtIndex(i)->_giflags.dontShow forGlyphAtIndex:glyphRange.location];
							// if(i == 0 || !NSGlyphInfoAtIndex(i)->_giflags.defaultPositioning)
							[layoutManager setLocation:location forStartOfGlyphRange:glyphRange];
							[layoutManager setDrawsOutsideLineFragment:NSGlyphInfoAtIndex(i)->_giflags.drawsOutside forGlyphAtIndex:glyphRange.location];
							glyphRange.location++;
						}
					glyphRange=NSMakeRange(firstIndexOfCurrentLineFragment, i);
					[layoutManager setTextContainer:curContainer forGlyphRange:glyphRange];	// attach to text container
					[self willSetLineFragmentRect:&lineFragmentRect
									forGlyphRange:glyphRange
										 usedRect:&usedRect];	// last chance to modify layout (e.g. line spacing)
					[layoutManager setLineFragmentRect:lineFragmentRect forGlyphRange:glyphRange usedRect:usedRect];				
					if(curContainerIsSimpleRectangular || NSIsEmptyRect(remainingRect))
						{ // we need a new line
							numLines++;
							proposedRect->origin.y=NSMaxY(lineFragmentRect);	// where next line fragment rect can start
						}
					firstGlyphIndex+=curGlyphIndex;	// we have processed the fragment
				}
			if(status == NSLayoutCantFit)
				{ // proposedRect is not wide or high enough for next glyph, we need a new one
					// move to the next container?
					// or simply skip
					break;
				}
			if(status == NSLayoutDone)
				{
				// end of paragraph or text string
				// add paragraph spacing etc.
				// here it is called before the paragraph has been processed
				if(containerBreakAfterCurGlyph)
					{
					
					}
				}
		}
	// FIXME: handle/create the extra line fragment
	// FIXME: handle the atEnd flag correctly
	[[layoutManager delegate] layoutManager:layoutManager didCompleteLayoutForTextContainer:curContainer atEnd:curCharacterIndex == [textString length]];
	// try to switch to next one
	// if none found:
	// [[layoutManager delegate] layoutManager:layoutManager didCompleteLayoutForTextContainer:nil atEnd:NO];
	// try a different one, get a new container or give up...
	if(nextGlyph != NULL)
		*nextGlyph = firstGlyphIndex;
	layoutManager=nil;
	textStorage=nil;
}

- (void) layoutGlyphsInLayoutManager:(NSLayoutManager *) lm
				startingAtGlyphIndex:(NSUInteger) startGlyphIndex
			maxNumberOfLineFragments:(NSUInteger) maxNumLines
					  nextGlyphIndex:(NSUInteger *) nextGlyph;
{ // core layout method
	NSRect proposedRect=NSZeroRect;
	NSAssert(!busy, @"NSSimpleHorizontalTypesetter is already busy");
	busy=YES;
	if(startGlyphIndex > 0)
		curContainer=[lm textContainerForGlyphAtIndex:startGlyphIndex-1 effectiveRange:NULL];	// continue where last glyph was placed in
	else
		curContainer=nil;	// start at first
	NS_DURING
		[self _layoutGlyphsInLayoutManager:lm
					  startingAtGlyphIndex:startGlyphIndex
				  maxNumberOfLineFragments:maxNumLines
					  currentTextContainer:&curContainer
							  proposedRect:&proposedRect
							nextGlyphIndex:nextGlyph];
	NS_HANDLER
		[self clearAttributesCache];
		[self clearGlyphCache];
		busy=NO;	// cleanup
		[localException raise];
	NS_ENDHANDLER
	[self clearAttributesCache];
	[self clearGlyphCache];
	busy=NO;
}

- (void) layoutTab;
{
	NSTextTab *tab=[super textTabForGlyphLocation:curGlyphOffset writingDirection:curLayoutDirection maxLocation:curContainerSize.width];
	NSTypesetterGlyphInfo *glyphInfo=[self _glyphInfoAtIndex:curGlyphIndex];
	CGFloat interval;
	if(tab)
		glyphInfo->extent=[tab location]-glyphInfo->curLocation.x;
	else if(curParaStyle && (interval=[curParaStyle defaultTabInterval]) > 0.0)
		glyphInfo->extent=interval*ceilf(glyphInfo->curLocation.x/interval)-glyphInfo->curLocation.x;	// equally spaced
	glyphInfo->_giflags.dontShow=YES;
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
{ // calculate current glyph location if needed (if defaultPositioning == YES???)
	curGlyphOffset+=NSGlyphInfoAtIndex(curGlyphIndex)->extent;
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

- (NSTypesetterGlyphInfo *) _glyphInfoAtIndex:(int) idx;
{
	NSAssert1(idx < capacityGlyphInfo, @"no glyphInfo for index %u known", idx);
	return NSGlyphInfoAtIndex(idx);	// &glyphs[IDX]
}

- (BOOL) followsItalicAngle;
{
	return _tsFlags._useItal;
}

- (void) setFollowsItalicAngle:(BOOL) flag;
{
	_tsFlags._useItal=flag;
}

- (CGFloat) baselineOffsetInLayoutManager:(id) layoutManager glyphIndex:(unsigned int) idx;
{
	return 0.0;
}

- (void) _setupBoundsForLineFragment:(NSRect *) bounds;
{
	NIMP;
}

- (NSRect) normalizedRect:(NSRect) rect;
{
	return rect;
}

@end
