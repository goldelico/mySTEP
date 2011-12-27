/*
	NSTypesetter.h
	mySTEP

	Created by Dr. H. Nikolaus Schaller on Fri Jun 29 2006.
	Copyright (c) 2006 DSITRI.

	Author:	Fabian Spillner <fabian.spillner@gmail.com>
	Date:	19. December 2007 - aligned with 10.5 

	This file is part of the mySTEP Library and is provided
	under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSTypesetter
#define _mySTEP_H_NSTypesetter

#import "AppKit/NSResponder.h"

enum
{
	NSTypesetterZeroAdvancementAction,
	NSTypesetterWhitespaceAction,
	NSTypesetterHorizontalTabAction,
	NSTypesetterLineBreakAction,
	NSTypesetterParagraphBreakAction,
	NSTypesetterContainerBreakAction,
};
typedef NSUInteger NSTypesetterControlCharacterAction;

@interface NSTypesetter : NSObject
{
	NSAttributedString */* nonretained */_attributedString;
	NSLayoutManager *_layoutManager;	// only valid within layoutGlyphsInLayoutManager:startingAtGlyphIndex:maxNumberOfLineFragments:nextGlyphIndex:
	NSParagraphStyle *_currentParagraphStyle;
	NSTextContainer *_currentTextContainer;
	NSTypesetterBehavior _typesetterBehavior;
	CGFloat _lineFragmentPadding;
	BOOL _bidiProcessingEnabled;
	BOOL _usesFontLeading;
}

+ (NSTypesetterBehavior) defaultTypesetterBehavior;
+ (NSSize) printingAdjustmentInLayoutManager:(NSLayoutManager *) manager 
				forNominallySpacedGlyphRange:(NSRange) range 
								packedGlyphs:(const unsigned char *) glyphs
									   count:(NSUInteger) count;
+ (id) sharedSystemTypesetter;
+ (id) sharedSystemTypesetterForBehavior:(NSTypesetterBehavior) behavior;

- (NSTypesetterControlCharacterAction) actionForControlCharacterAtIndex:(NSUInteger) location; 
- (NSAttributedString *) attributedString; 
- (NSDictionary *) attributesForExtraLineFragment; 
- (CGFloat) baselineOffsetInLayoutManager:(NSLayoutManager *) manager glyphIndex:(NSUInteger) index; 
- (void) beginLineWithGlyphAtIndex:(NSUInteger) index; 
- (void) beginParagraph; 
- (BOOL) bidiProcessingEnabled; 
- (NSRect) boundingBoxForControlGlyphAtIndex:(NSUInteger) glyph 
							forTextContainer:(NSTextContainer *) container 
						proposedLineFragment:(NSRect) rect 
							   glyphPosition:(NSPoint) position 
							  characterIndex:(NSUInteger) index; 
- (NSRange) characterRangeForGlyphRange:(NSRange) range 
					   actualGlyphRange:(NSRangePointer) rangePt; 
- (NSParagraphStyle *) currentParagraphStyle; 
- (NSTextContainer *) currentTextContainer; 
- (void) deleteGlyphsInRange:(NSRange) range; 
- (void) endLineWithGlyphRange:(NSRange) range; 
- (void) endParagraph; 
- (NSUInteger) getGlyphsInRange:(NSRange) range 
						 glyphs:(NSGlyph *) glyphs 
			   characterIndexes:(NSUInteger *) idxs 
			  glyphInscriptions:(NSGlyphInscription *) inscBuffer 
					elasticBits:(BOOL *) flag 
					 bidiLevels:(unsigned char *) bidiLevels; 
- (void) getLineFragmentRect:(NSRectPointer) fragRect 
					usedRect:(NSRectPointer) fragUsedRect 
					forParagraphSeparatorGlyphRange:(NSRange) range 
			atProposedOrigin:(NSPoint) origin; 
- (void) getLineFragmentRect:(NSRectPointer) lineFragmentRect 
					usedRect:(NSRectPointer) lineFragmentUsedRect 
			   remainingRect:(NSRectPointer) remRect 
	 forStartingGlyphAtIndex:(NSUInteger) startIndex 
				proposedRect:(NSRect) propRect 
				 lineSpacing:(CGFloat) spacing 
	  paragraphSpacingBefore:(CGFloat) paragSpacBefore 
	   paragraphSpacingAfter:(CGFloat) paragSpacAfter; 
- (NSRange) glyphRangeForCharacterRange:(NSRange) range 
				   actualCharacterRange:(NSRangePointer) rangePt; 
- (float) hyphenationFactor; 
- (float) hyphenationFactorForGlyphAtIndex:(NSUInteger) index; 
- (UTF32Char) hyphenCharacterForGlyphAtIndex:(NSUInteger) index; 
- (void) insertGlyph:(NSGlyph) glyph atGlyphIndex:(NSUInteger) index characterIndex:(NSUInteger) charIdx; 
- (NSRange) layoutCharactersInRange:(NSRange) range
				   forLayoutManager:(NSLayoutManager *) manager
	   maximumNumberOfLineFragments:(NSUInteger) maxLines;
- (void) layoutGlyphsInLayoutManager:(NSLayoutManager *) manager 
				startingAtGlyphIndex:(NSUInteger) startIndex 
			maxNumberOfLineFragments:(NSUInteger) maxLines 
					  nextGlyphIndex:(NSUInteger *) nextGlyph; 
- (NSLayoutManager *) layoutManager; 
- (NSUInteger) layoutParagraphAtPoint:(NSPointPointer) originPt; 
- (CGFloat) lineFragmentPadding; 
- (CGFloat) lineSpacingAfterGlyphAtIndex:(NSUInteger) index withProposedLineFragmentRect:(NSRect) fragRect; 
- (NSRange) paragraphCharacterRange; 
- (NSRange) paragraphGlyphRange; 
- (NSRange) paragraphSeparatorCharacterRange; 
- (NSRange) paragraphSeparatorGlyphRange; 
- (CGFloat) paragraphSpacingAfterGlyphAtIndex:(NSUInteger) index withProposedLineFragmentRect:(NSRect) fragRect; 
- (CGFloat) paragraphSpacingBeforeGlyphAtIndex:(NSUInteger) index withProposedLineFragmentRect:(NSRect) fragRect; 
- (void) setAttachmentSize:(NSSize) size forGlyphRange:(NSRange) range; 
- (void) setAttributedString:(NSAttributedString *) attrStr; 
- (void) setBidiLevels:(const uint8_t *) levels forGlyphRange:(NSRange) range; 
- (void) setBidiProcessingEnabled:(BOOL) enabled; 
- (void) setDrawsOutsideLineFragment:(BOOL) flag forGlyphRange:(NSRange) range; 
- (void) setHardInvalidation:(BOOL) flag forGlyphRange:(NSRange) range; 
- (void) setHyphenationFactor:(float) value; 
- (void) setLineFragmentPadding:(CGFloat) value; 
- (void) setLineFragmentRect:(NSRect) fragRect 
			   forGlyphRange:(NSRange) range 
					usedRect:(NSRect) rect 
			  baselineOffset:(CGFloat) offset; 
- (void) setLocation:(NSPoint) loc 
	withAdvancements:(const CGFloat *) advancements 
forStartOfGlyphRange:(NSRange) range; 
- (void) setNotShownAttribute:(BOOL) flag forGlyphRange:(NSRange) range; 
- (void) setParagraphGlyphRange:(NSRange) paragRange separatorGlyphRange:(NSRange) sepRange; 
- (void) setTypesetterBehavior:(NSTypesetterBehavior) behavior; 
- (void) setUsesFontLeading:(BOOL) fontLeading; 
- (BOOL) shouldBreakLineByHyphenatingBeforeCharacterAtIndex:(NSUInteger) index; 
- (BOOL) shouldBreakLineByWordBeforeCharacterAtIndex:(NSUInteger) index; 
- (NSFont *) substituteFontForFont:(NSFont *) font; 
- (void) substituteGlyphsInRange:(NSRange) range withGlyphs:(NSGlyph *) glyphs; 
- (NSArray *) textContainers; 
- (NSTextTab *) textTabForGlyphLocation:(CGFloat) glyphLoc 
					   writingDirection:(NSWritingDirection) writingDirection 
							maxLocation:(CGFloat) maxLoc; 
- (NSTypesetterBehavior) typesetterBehavior; 
- (BOOL) usesFontLeading; 
- (void) willSetLineFragmentRect:(NSRectPointer) lineRectPt 
				   forGlyphRange:(NSRange) range 
						usedRect:(NSRectPointer) usedRectPt 
				  baselineOffset:(CGFloat *) offset; 

@end

#endif /* _mySTEP_H_NSTypesetter */
