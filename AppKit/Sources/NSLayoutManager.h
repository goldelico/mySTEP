/*
 NSLayoutManager.h
 
 An NSLayoutManager stores glyphs, attributes, and layout information 
 generated from a NSTextStorage by a NSTextLayout.  It can map between 
 ranges of unichars in the NSTextStorage and ranges of glyphs within 
 itself.  It understands and keeps track of two types of range 
 invalidation.  A character range can need glyphs generated for it or 
 it can need its glyphs laid out.  
 
 When a NSLayoutManager is asked for information which would require 
 knowledge of glyphs or layout which is not currently available, the 
 NSLayoutManager must cause the appropriate recalculation to be done.
 
 Copyright (C) 1996 Free Software Foundation, Inc.
 
 Author:  Daniel Bðhringer <boehring@biomed.ruhr-uni-bochum.de>
 Date: August 1998
 
 Author:	H. N. Schaller <hns@computer.org>
 Date:	Jun 2006 - aligned with 10.4
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */

#import <Foundation/Foundation.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSImageCell.h>
#import <AppKit/NSGlyphGenerator.h>

@class NSTextStorage;
@class NSTypesetter;
@class NSTextContainer;
@class NSTextView;
@class NSWindow;
@class NSColor;
@class NSRulerView;
@class NSParagraphStyle;
@class NSRulerMarker;
@class NSBox;
@class NSTextField;
@class NSMatrix;
@class NSTabWell;
@class NSStorage;
@class NSRunStorage;
@class NSSortedArray;
@class NSView;
@class NSEvent;
@class NSTextBlock;

typedef enum
{
    NSGlyphInscribeBase			= 0,
    NSGlyphInscribeBelow		= 1,
    NSGlyphInscribeAbove		= 2,
    NSGlyphInscribeOverstrike	= 3,
    NSGlyphInscribeOverBelow	= 4
} NSGlyphInscription;

typedef enum
{
	NSTypesetterLatestBehavior					= -1,
	NSTypesetterOriginalBehavior				= 0,	// should not be used...
	NSTypesetterBehavior_10_2_WithCompatibility	= 1,
	NSTypesetterBehavior_10_2					= 2,
	NSTypesetterBehavior_10_3					= 3
} NSTypesetterBehavior;

@interface NSLayoutManager : NSObject <NSGlyphStorage>
{	
	NSTextStorage *textStorage;
    NSGlyphGenerator *glyphGenerator;
    NSTypesetter *typesetter;
	
    NSMutableArray *textContainers;
    NSStorage *containerUsedRects;
	
    NSStorage *glyphs;
    NSRunStorage *containerRuns;
    NSRunStorage *fragmentRuns;
    NSRunStorage *glyphLocations;
    NSRunStorage *glyphRotationRuns;
    
    NSRect extraLineFragmentRect;
    NSRect extraLineFragmentUsedRect;
    NSTextContainer *extraLineFragmentContainer;
	
    NSSortedArray *glyphHoles;
    NSSortedArray *layoutHoles;
	
    id delegate;
	
    // Enable/disable stacks
    unsigned short textViewResizeDisableStack;
    unsigned short displayInvalidationDisableStack;
    NSRange deferredDisplayCharRange;
	
	// Cache for first text view (that is text view of the first text container which has one)

    NSTextView *firstTextView;
	
	// Cache for rectangle arrays
    NSRect *cachedRectArray;
    unsigned cachedRectArrayCapacity;
	
	// Cache for glyph strings (used when drawing)
    char *glyphBuffer;
    unsigned glyphBufferSize;
	
	// Cache for faster glyph location lookup
    NSRange cachedLocationNominalGlyphRange;
    unsigned cachedLocationGlyphIndex;
    NSPoint cachedLocation;
	
	// Cache for faster glyph location lookup
    NSRange cachedFontCharRange;
    NSFont *cachedFont;
	
	// Cache for first unlaid glypha and character
    unsigned firstUnlaidGlyphIndex;
    unsigned firstUnlaidCharIndex;
	
	// Outlets for ruler accessory view.
    NSBox *rulerAccView;
    NSMatrix *rulerAccViewAlignmentButtons;
    NSTextField *rulerAccViewLeadingField;
    NSTabWell *rulerAccViewLeftTabWell;
    NSTabWell *rulerAccViewRightTabWell;
    NSTabWell *rulerAccViewCenterTabWell;
    NSTabWell *rulerAccViewDecimalTabWell;
    NSMatrix *rulerAccViewIncrementLineHeightButtons;
    NSMatrix *rulerAccViewFixedLineHeightButtons;
	
    NSRange newlyFilledGlyphRange;
	
	float hyphenationFactor;
	NSImageScaling defaultAttachmentScaling;
	NSTypesetterBehavior typesetterBehavior;
	BOOL backgroundLayoutEnabled;
	BOOL showsControlCharacters;
	BOOL showsInvisibleCharacters;
	BOOL usesScreenFonts;
}

- (void) addTemporaryAttributes:(NSDictionary *)attrs forCharacterRange:(NSRange)range;
- (void) addTextContainer:(NSTextContainer *)container;
- (NSSize) attachmentSizeForGlyphAtIndex:(unsigned)index;
- (BOOL) backgroundLayoutEnabled;
- (NSRect) boundingRectForGlyphRange:(NSRange)glyphRange 
					 inTextContainer:(NSTextContainer *)container;
- (NSRect) boundsRectForTextBlock:(NSTextBlock *)block atIndex:(unsigned)index effectiveRange:(NSRangePointer)range;
- (NSRect) boundsRectForTextBlock:(NSTextBlock *)block glyphRange:(NSRange)range;

- (unsigned) characterIndexForGlyphAtIndex:(unsigned)glyphIndex;
- (NSRange) characterRangeForGlyphRange:(NSRange)glyphRange actualGlyphRange:(NSRangePointer)actualGlyphRange;
- (NSImageScaling) defaultAttachmentScaling;
- (float) defaultLineHeightForFont:(NSFont *) font;
- (id) delegate;
- (void) deleteGlyphsInRange:(NSRange)glyphRange;
- (void) drawBackgroundForGlyphRange:(NSRange)glyphsToShow 
							 atPoint:(NSPoint)origin;
- (void) drawGlyphsForGlyphRange:(NSRange)glyphsToShow 
						 atPoint:(NSPoint)origin;
- (BOOL) drawsOutsideLineFragmentForGlyphAtIndex:(unsigned)index;
- (void) drawStrikethroughForGlyphRange:(NSRange)glyphRange
					  strikethroughType:(int)strikethroughVal
						 baselineOffset:(float)baselineOffset
					   lineFragmentRect:(NSRect)lineRect
				 lineFragmentGlyphRange:(NSRange)lineGlyphRange
						containerOrigin:(NSPoint)containerOrigin;
- (void) drawUnderlineForGlyphRange:(NSRange)glyphRange 
					  underlineType:(int)underlineVal 
					 baselineOffset:(float)baselineOffset 
				   lineFragmentRect:(NSRect)lineRect 
			 lineFragmentGlyphRange:(NSRange)lineGlyphRange 
					containerOrigin:(NSPoint)containerOrigin;
- (NSRect) extraLineFragmentRect;
- (NSTextContainer*) extraLineFragmentTextContainer;
- (NSRect) extraLineFragmentUsedRect;
- (NSTextView *) firstTextView;
- (unsigned) firstUnlaidCharacterIndex;
- (unsigned) firstUnlaidGlyphIndex;
- (float) fractionOfDistanceThroughGlyphForPoint:(NSPoint)aPoint inTextContainer:(NSTextContainer *)aTextContainer;
- (void) getFirstUnlaidCharacterIndex:(unsigned *)charIndex 
						   glyphIndex:(unsigned *)glyphIndex;
- (unsigned) getGlyphs:(NSGlyph *)glyphArray range:(NSRange)glyphRange;
- (unsigned) getGlyphsInRange:(NSRange)glyphsRange
					   glyphs:(NSGlyph *)glyphBuffer
			 characterIndexes:(unsigned *)charIndexBuffer
			glyphInscriptions:(NSGlyphInscription *)inscribeBuffer
				  elasticBits:(BOOL *)elasticBuffer;
- (unsigned) getGlyphsInRange:(NSRange)glyphsRange
					   glyphs:(NSGlyph *)glyphBuffer
			 characterIndexes:(unsigned *)charIndexBuffer
			glyphInscriptions:(NSGlyphInscription *)inscribeBuffer
				  elasticBits:(BOOL *)elasticBuffer
				   bidiLevels:(unsigned char *)bidiLevelBuffer;
- (NSGlyph) glyphAtIndex:(unsigned)glyphIndex;
- (NSGlyph) glyphAtIndex:(unsigned)glyphIndex isValidIndex:(BOOL *)isValidIndex;
- (NSGlyphGenerator *) glyphGenerator;
- (unsigned) glyphIndexForPoint:(NSPoint)aPoint inTextContainer:(NSTextContainer *)aTextContainer;
- (unsigned) glyphIndexForPoint:(NSPoint)aPoint
				inTextContainer:(NSTextContainer *)aTextContainer
 fractionOfDistanceThroughGlyph:(float *)partialFraction;
- (NSRange) glyphRangeForBoundingRect:(NSRect)bounds 
					  inTextContainer:(NSTextContainer *)container;
- (NSRange) glyphRangeForBoundingRectWithoutAdditionalLayout:(NSRect)bounds 
											 inTextContainer:(NSTextContainer *)container;
- (NSRange) glyphRangeForCharacterRange:(NSRange)charRange actualCharacterRange:(NSRange *)actualCharRange;
- (NSRange) glyphRangeForTextContainer:(NSTextContainer *)container;
- (float) hyphenationFactor;
- (id) init;
- (void) insertGlyph:(NSGlyph)glyph atGlyphIndex:(unsigned)glyphIndex characterIndex:(unsigned)charIndex;
- (void) insertTextContainer:(NSTextContainer *)container atIndex:(unsigned)index;
- (int) intAttribute:(int)attributeTag forGlyphAtIndex:(unsigned)glyphIndex;
- (void) invalidateDisplayForCharacterRange:(NSRange)charRange;
- (void) invalidateDisplayForGlyphRange:(NSRange)glyphRange;
- (void) invalidateGlyphsForCharacterRange:(NSRange)charRange changeInLength:(int)delta actualCharacterRange:(NSRange *)actualCharRange;
- (void) invalidateLayoutForCharacterRange:(NSRange)charRange isSoft:(BOOL)flag actualCharacterRange:(NSRange *)actualCharRange;
- (BOOL) isValidGlyphIndex:(unsigned)glyphIndex;
- (BOOL) layoutManagerOwnsFirstResponderInWindow:(NSWindow *)aWindow;
- (NSRect) layoutRectForTextBlock:(NSTextBlock *)block
						  atIndex:(unsigned)glyphIndex
				   effectiveRange:(NSRangePointer)effectiveGlyphRange;
- (NSRect) layoutRectForTextBlock:(NSTextBlock *)block
					   glyphRange:(NSRange)glyphRange;
- (NSRect) lineFragmentRectForGlyphAtIndex:(unsigned)glyphIndex effectiveRange:(NSRange *)effectiveGlyphRange;
- (NSRect) lineFragmentUsedRectForGlyphAtIndex:(unsigned)glyphIndex effectiveRange:(NSRange *)effectiveGlyphRange;
- (NSPoint) locationForGlyphAtIndex:(unsigned)glyphIndex;
- (BOOL) notShownAttributeForGlyphAtIndex:(unsigned) glyphIndex;
- (unsigned) numberOfGlyphs;
- (NSRange) rangeOfNominallySpacedGlyphsContainingIndex:(unsigned)glyphIndex;
- (NSRect*) rectArrayForCharacterRange:(NSRange)charRange 
		  withinSelectedCharacterRange:(NSRange)selCharRange 
					   inTextContainer:(NSTextContainer *)container 
							 rectCount:(unsigned *)rectCount;
- (NSRect*) rectArrayForGlyphRange:(NSRange)glyphRange 
		  withinSelectedGlyphRange:(NSRange)selGlyphRange 
				   inTextContainer:(NSTextContainer *)container 
						 rectCount:(unsigned *)rectCount;
- (void) removeTemporaryAttribute:(NSString *)name forCharacterRange:(NSRange)charRange;
- (void) removeTextContainerAtIndex:(unsigned)index;
- (void) replaceGlyphAtIndex:(unsigned)glyphIndex withGlyph:(NSGlyph)newGlyph;
- (void) replaceTextStorage:(NSTextStorage *)newTextStorage;
- (NSView *) rulerAccessoryViewForTextView:(NSTextView *)aTextView
							paragraphStyle:(NSParagraphStyle *)paraStyle
									 ruler:(NSRulerView *)aRulerView
								   enabled:(BOOL)flag;
- (NSArray*) rulerMarkersForTextView:(NSTextView *)view 
					  paragraphStyle:(NSParagraphStyle *)style 
							   ruler:(NSRulerView *)ruler;
- (void) setAttachmentSize:(NSSize)attachmentSize forGlyphRange:(NSRange)glyphRange;
- (void) setBackgroundLayoutEnabled:(BOOL)flag;
- (void) setBoundsRect:(NSRect)rect forTextBlock:(NSTextBlock *)block glyphRange:(NSRange)glyphRange;
- (void) setCharacterIndex:(unsigned)charIndex forGlyphAtIndex:(unsigned)glyphIndex;
- (void) setDefaultAttachmentScaling:(NSImageScaling)scaling;
- (void) setDelegate:(id)delegate;
- (void) setDrawsOutsideLineFragment:(BOOL)flag forGlyphAtIndex:(unsigned)glyphIndex;
- (void) setExtraLineFragmentRect:(NSRect)fragmentRect usedRect:(NSRect)usedRect textContainer:(NSTextContainer *)container;
- (void) setGlyphGenerator:(NSGlyphGenerator *)glyphGenerator;
- (void) setHyphenationFactor:(float)factor;
- (void) setIntAttribute:(int)attributeTag value:(int)val forGlyphAtIndex:(unsigned)glyphIndex;
- (void) setLayoutRect:(NSRect)rect forTextBlock:(NSTextBlock *)block glyphRange:(NSRange)glyphRange;
- (void) setLineFragmentRect:(NSRect)fragmentRect forGlyphRange:(NSRange)glyphRange usedRect:(NSRect)usedRect;
- (void) setLocation:(NSPoint)location forStartOfGlyphRange:(NSRange)glyphRange;
- (void) setNotShownAttribute:(BOOL)flag forGlyphAtIndex:(unsigned)glyphIndex;
- (void) setShowsControlCharacters:(BOOL)flag;
- (void) setShowsInvisibleCharacters:(BOOL)flag;
- (void) setTemporaryAttributes:(NSDictionary *)attrs forCharacterRange:(NSRange)charRange;
- (void) setTextContainer:(NSTextContainer *)container forGlyphRange:(NSRange)glyphRange;
- (void) setTextStorage:(NSTextStorage *)textStorage;
- (void) setTypesetter:(NSTypesetter *)typesetter;
- (void) setTypesetterBehavior:(NSTypesetterBehavior)behavior;
- (void) setUsesScreenFonts:(BOOL)flag;
- (void) showAttachmentCell:(NSCell *)cell inRect:(NSRect)rect characterIndex:(unsigned)attachmentIndex;
- (void) showPackedGlyphs:(char *)glyphs
				   length:(unsigned)glyphLen
			   glyphRange:(NSRange)glyphRange atPoint:(NSPoint)point
					 font:(NSFont *)font
					color:(NSColor *)color
	   printingAdjustment:(NSSize)adjust;
- (BOOL) showsControlCharacters;
- (BOOL) showsInvisibleCharacters;
- (void) strikethroughGlyphRange:(NSRange)glyphRange
			   strikethroughType:(int)strikethroughVal
				lineFragmentRect:(NSRect)lineRect
		  lineFragmentGlyphRange:(NSRange)lineGlyphRange
				 containerOrigin:(NSPoint)containerOrigin;
- (NSFont*) substituteFontForFont:(NSFont *)originalFont;
- (NSDictionary *) temporaryAttributesAtCharacterIndex:(unsigned)charIndex effectiveRange:(NSRangePointer)effectiveCharRange;
- (void) textContainerChangedGeometry:(NSTextContainer *)container;
- (void) textContainerChangedTextView:(NSTextContainer *)container;
- (NSTextContainer *) textContainerForGlyphAtIndex:(unsigned)glyphIndex effectiveRange:(NSRange *)effectiveGlyphRange;
- (NSArray *) textContainers;
- (NSTextStorage *) textStorage;
- (void) textStorage:(NSTextStorage *)str edited:(unsigned)editedMask range:(NSRange)newCharRange changeInLength:(int)delta invalidatedRange:(NSRange)invalidatedCharRange;
- (NSTextView *) textViewForBeginningOfSelection;
- (NSTypesetter *) typesetter;
- (NSTypesetterBehavior) typesetterBehavior;
- (void) underlineGlyphRange:(NSRange)glyphRange 
			   underlineType:(int)underlineVal 
			lineFragmentRect:(NSRect)lineRect 
			   lineFragmentGlyphRange:(NSRange)lineGlyphRange 
			 containerOrigin:(NSPoint)containerOrigin;
- (NSRect) usedRectForTextContainer:(NSTextContainer *)container;
- (BOOL) usesScreenFonts;

@end

@interface NSObject (NSLayoutManagerDelegate)

- (void) layoutManagerDidInvalidateLayout:(NSLayoutManager*)sender;
- (void) layoutManager:(NSLayoutManager*)layoutManager 
		 didCompleteLayoutForTextContainer:(NSTextContainer*)textContainer 
				 atEnd:(BOOL)layoutFinishedFlag;

@end
