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

 Author:  Daniel B�hringer <boehring@biomed.ruhr-uni-bochum.de>
 Date: August 1998

 Author:	H. N. Schaller <hns@computer.org>
 Date:	Jun 2006 - aligned with 10.4

 Author:	Fabian Spillner <fabian.spillner@gmail.com>
 Date:	9. November 2007 - aligned with 10.5

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
@class NSView;
@class NSEvent;
@class NSTextBlock;

enum {
	NSGlyphAttributeSoft        = 0,
	NSGlyphAttributeElastic     = 1,
	NSGlyphAttributeBidiLevel   = 2,
	NSGlyphAttributeInscribe    = 5
};

enum {
	NSGlyphInscribeBase = 0,
	NSGlyphInscribeBelow = 1,
	NSGlyphInscribeAbove = 2,
	NSGlyphInscribeOverstrike = 3,
	NSGlyphInscribeOverBelow = 4
};
typedef NSUInteger NSGlyphInscription;

enum {
	NSTypesetterLatestBehavior = -1,
	NSTypesetterOriginalBehavior = 0, // should not be used
	NSTypesetterBehavior_10_2_WithCompatibility = 1,
	NSTypesetterBehavior_10_2 = 2,
	NSTypesetterBehavior_10_3 = 3,
	NSTypesetterBehavior_10_4 = 4
};
typedef NSInteger NSTypesetterBehavior;

@interface NSLayoutManager : NSObject <NSGlyphStorage>
{
	NSTextStorage /*nonretained*/ *_textStorage;	// The textStorage owns its layout manager(s)
	NSMutableArray *_textContainers;
	NSGlyphGenerator *_glyphGenerator;	// defaults to the sharedGlyphGenerator
	NSTypesetter *_typesetter;	// defaults to sharedSystemTypesetter
	NSTextContainer *_extraLineFragmentContainer;
	NSTextView *_firstTextView;		// Cache for first text view (that is text view of the first text container which has one)

	id _delegate;

	NSRect _extraLineFragmentRect;
	NSRect _extraLineFragmentUsedRect;

	float _hyphenationFactor;
	NSImageScaling _defaultAttachmentScaling;

	// NSGlyphStorage (should be able to handle sparse data)
	// the key challenge is to keep memory demand low and still allow fast search by glyph, character index, position etc.
	// it could be seen more or less as a relational database table with indexes
	struct NSGlyphStorage {
		NSRect lineFragmentRect;	// the line fragment rectangle we belong to
		NSRect usedLineFragmentRect;
		NSPoint location;	// relative to the line fragment rect
		NSGlyph glyph;		// the glyph code
		NSTextContainer *textContainer;	// the text container - if nil the glyph has invalid laid out
		struct NSGlyphStorageExtra {
			NSSize attachmentSize;
			NSDictionary *temporaryAttributes;	// FIXME: these are NOT indexed by the glyph but by the character!!!
			NSInteger softAttribute;	// integer attributes
			NSInteger elasticAttribute;
			NSInteger bidiLevelAttribute;
			NSInteger inscribeAttribute;
		} *extra;	// extra data allocated on demand (NULL otherwise)
		NSUInteger characterIndex;	// the character index
									// define some int Attribute and bit fields
		BOOL notShownAttribute;	// Bitflag in intAttribute?
		BOOL drawsOutsideLineFragment;	// Bitflag im intAttribute?
		BOOL needsDisplay;
	} *_glyphs;		// glyph storage array - it should be possible to define a sparse array!

	/* this can be used to speed up e.g. glyphRangeForTextContainer */

	struct _NSTextContainerInfo {
		NSRange glyphRange;
		NSRect usedRect;
	} *_textContainerInfo; // there is one slot for each text container

	NSRectArray _rectArray;	// rectangle array (malloc)
	NSUInteger _rectArrayCapacity;

	NSUInteger _numberOfGlyphs;	// number of currently known glyphs (in relation to the characters)
	NSUInteger _nextCharacterIndex;	// next index for glyph generation
	NSUInteger _glyphBufferCapacity;

	NSUInteger _firstUnlaidGlyphIndex;	// next glyph to be laid out
	NSUInteger _firstUnlaidCharacterIndex;

	NSUInteger _layoutOptions;

	BOOL _backgroundLayoutEnabled;
	BOOL _usesScreenFonts;
	BOOL _usesFontLeading;
	BOOL _textStorageChanged;
	BOOL _allowsNonContiguousLayout;
	BOOL _hasNonContiguousLayout;
}

- (void) addTemporaryAttribute:(NSString *) attr value:(id) val forCharacterRange:(NSRange) range;
- (void) addTemporaryAttributes:(NSDictionary *) attrs forCharacterRange:(NSRange) range;
- (void) addTextContainer:(NSTextContainer *) container;
- (BOOL) allowsNonContiguousLayout;
- (NSSize) attachmentSizeForGlyphAtIndex:(NSUInteger) index;
- (BOOL) backgroundLayoutEnabled;
- (NSRect) boundingRectForGlyphRange:(NSRange) glyphRange
					 inTextContainer:(NSTextContainer *) container;
- (NSRect) boundsRectForTextBlock:(NSTextBlock *) block atIndex:(NSUInteger) index effectiveRange:(NSRangePointer) range;
- (NSRect) boundsRectForTextBlock:(NSTextBlock *) block glyphRange:(NSRange) range;
- (NSUInteger) characterIndexForGlyphAtIndex:(NSUInteger) glyphIndex;
- (NSRange) characterRangeForGlyphRange:(NSRange) glyphRange actualGlyphRange:(NSRangePointer) actualGlyphRange;
- (NSImageScaling) defaultAttachmentScaling;
- (CGFloat) defaultBaselineOffsetForFont:(NSFont *) font;
- (CGFloat) defaultLineHeightForFont:(NSFont *) font;
- (id) delegate;
- (void) deleteGlyphsInRange:(NSRange) glyphRange;
- (void) drawBackgroundForGlyphRange:(NSRange) glyphsToShow
							 atPoint:(NSPoint) origin;
- (void) drawGlyphsForGlyphRange:(NSRange) glyphsToShow
						 atPoint:(NSPoint) origin;
- (BOOL) drawsOutsideLineFragmentForGlyphAtIndex:(NSUInteger) index;
- (void) drawStrikethroughForGlyphRange:(NSRange) glyphRange
					  strikethroughType:(NSInteger) strikethroughVal
						 baselineOffset:(CGFloat) baselineOffset
					   lineFragmentRect:(NSRect) lineRect
				 lineFragmentGlyphRange:(NSRange) lineGlyphRange
						containerOrigin:(NSPoint) containerOrigin;
- (void) drawUnderlineForGlyphRange:(NSRange) glyphRange
					  underlineType:(NSInteger) underlineVal
					 baselineOffset:(CGFloat) baselineOffset
				   lineFragmentRect:(NSRect) lineRect
			 lineFragmentGlyphRange:(NSRange) lineGlyphRange
					containerOrigin:(NSPoint) containerOrigin;
- (void) ensureGlyphsForCharacterRange:(NSRange) range;
- (void) ensureGlyphsForGlyphRange:(NSRange) range;
- (void) ensureLayoutForBoundingRect:(NSRect) rect inTextContainer:(NSTextContainer *) textContainer;
- (void) ensureLayoutForCharacterRange:(NSRange) range;
- (void) ensureLayoutForGlyphRange:(NSRange) range;
- (void) ensureLayoutForTextContainer:(NSTextContainer *) textContainer;
- (NSRect) extraLineFragmentRect;
- (NSTextContainer *) extraLineFragmentTextContainer;
- (NSRect) extraLineFragmentUsedRect;
- (void) fillBackgroundRectArray:(NSRectArray) rectArray count:(NSUInteger) rectCount forCharacterRange:(NSRange) charRange color:(NSColor *) color;
- (NSTextView *) firstTextView;
- (NSUInteger) firstUnlaidCharacterIndex;
- (NSUInteger) firstUnlaidGlyphIndex;
- (CGFloat) fractionOfDistanceThroughGlyphForPoint:(NSPoint) aPoint inTextContainer:(NSTextContainer *) aTextContainer;
- (void) getFirstUnlaidCharacterIndex:(NSUInteger *) charIndex
						   glyphIndex:(NSUInteger *) glyphIndex;
- (NSUInteger) getGlyphs:(NSGlyph *) glyphArray range:(NSRange) glyphRange;
- (NSUInteger) getGlyphsInRange:(NSRange) glyphsRange
						 glyphs:(NSGlyph *) glyphBuffer
			   characterIndexes:(NSUInteger *) charIndexBuffer
			  glyphInscriptions:(NSGlyphInscription *) inscribeBuffer
					elasticBits:(BOOL *) elasticBuffer;
- (NSUInteger) getGlyphsInRange:(NSRange) glyphsRange
						 glyphs:(NSGlyph *) glyphBuffer
			   characterIndexes:(NSUInteger *) charIndexBuffer
			  glyphInscriptions:(NSGlyphInscription *) inscribeBuffer
					elasticBits:(BOOL *) elasticBuffer
					 bidiLevels:(unsigned char *) bidiLevelBuffer;
- (NSUInteger) getLineFragmentInsertionPointsForCharacterAtIndex:(NSUInteger) index
											  alternatePositions:(BOOL) posFlag
												  inDisplayOrder:(BOOL) orderFlag
													   positions:(CGFloat *) positions
												characterIndexes:(NSUInteger *) charIds;
- (NSGlyph) glyphAtIndex:(NSUInteger) glyphIndex;
- (NSGlyph) glyphAtIndex:(NSUInteger) glyphIndex isValidIndex:(BOOL *) isValidIndex;
- (NSGlyphGenerator *) glyphGenerator;
- (NSUInteger) glyphIndexForCharacterAtIndex:(NSUInteger) index;
- (NSUInteger) glyphIndexForPoint:(NSPoint) aPoint inTextContainer:(NSTextContainer *) aTextContainer;
- (NSUInteger) glyphIndexForPoint:(NSPoint) aPoint
				  inTextContainer:(NSTextContainer *) aTextContainer
   fractionOfDistanceThroughGlyph:(CGFloat *) partialFraction;
- (NSRange) glyphRangeForBoundingRect:(NSRect) bounds
					  inTextContainer:(NSTextContainer *) container;
- (NSRange) glyphRangeForBoundingRectWithoutAdditionalLayout:(NSRect) bounds
											 inTextContainer:(NSTextContainer *) container;
- (NSRange) glyphRangeForCharacterRange:(NSRange) charRange actualCharacterRange:(NSRangePointer) actualCharRange;
- (NSRange) glyphRangeForTextContainer:(NSTextContainer *) container;
- (BOOL) hasNonContiguousLayout;
- (float) hyphenationFactor;
- (id) init;
- (void) insertGlyph:(NSGlyph) glyph atGlyphIndex:(NSUInteger) glyphIndex characterIndex:(NSUInteger) charIndex;
- (void) insertTextContainer:(NSTextContainer *) container atIndex:(NSUInteger) index;
- (NSInteger) intAttribute:(NSInteger) attributeTag forGlyphAtIndex:(NSUInteger) glyphIndex;
- (void) invalidateDisplayForCharacterRange:(NSRange) charRange;
- (void) invalidateDisplayForGlyphRange:(NSRange) glyphRange;
- (void) invalidateGlyphsForCharacterRange:(NSRange) charRange changeInLength:(NSInteger) delta actualCharacterRange:(NSRangePointer) actualCharRange;
- (void) invalidateGlyphsOnLayoutInvalidationForGlyphRange:(NSRange) range;
- (void) invalidateLayoutForCharacterRange:(NSRange) range actualCharacterRange:(NSRangePointer) charRange;
- (void) invalidateLayoutForCharacterRange:(NSRange) charRange isSoft:(BOOL) flag actualCharacterRange:(NSRangePointer) actualCharRange;
- (BOOL) isValidGlyphIndex:(NSUInteger) glyphIndex;
- (BOOL) layoutManagerOwnsFirstResponderInWindow:(NSWindow *) aWindow;
- (NSRect) layoutRectForTextBlock:(NSTextBlock *) block
						  atIndex:(NSUInteger) index
				   effectiveRange:(NSRangePointer) range;
- (NSRect) layoutRectForTextBlock:(NSTextBlock *) block
					   glyphRange:(NSRange) range;
- (NSRect) lineFragmentRectForGlyphAtIndex:(NSUInteger) index effectiveRange:(NSRangePointer) range;
- (NSRect) lineFragmentRectForGlyphAtIndex:(NSUInteger) index effectiveRange:(NSRangePointer) charRange withoutAdditionalLayout:(BOOL) layoutFlag;
- (NSRect) lineFragmentUsedRectForGlyphAtIndex:(NSUInteger) index effectiveRange:(NSRange *) range;
- (NSRect) lineFragmentUsedRectForGlyphAtIndex:(NSUInteger) index effectiveRange:(NSRangePointer) charRange withoutAdditionalLayout:(BOOL) layoutFlag;
- (NSPoint) locationForGlyphAtIndex:(NSUInteger) glyphIndex;
- (BOOL) notShownAttributeForGlyphAtIndex:(NSUInteger) glyphIndex;
- (NSUInteger) numberOfGlyphs;
- (NSRange) rangeOfNominallySpacedGlyphsContainingIndex:(NSUInteger) glyphIndex;
- (NSRectArray) rectArrayForCharacterRange:(NSRange) charRange
			  withinSelectedCharacterRange:(NSRange) selCharRange
						   inTextContainer:(NSTextContainer *) container
								 rectCount:(NSUInteger *) rectCount;
- (NSRectArray) rectArrayForGlyphRange:(NSRange) glyphRange
			  withinSelectedGlyphRange:(NSRange) selGlyphRange
					   inTextContainer:(NSTextContainer *) container
							 rectCount:(NSUInteger *) rectCount;
- (void) removeTemporaryAttribute:(NSString *) name forCharacterRange:(NSRange) charRange;
- (void) removeTextContainerAtIndex:(NSUInteger) index;
- (void) replaceGlyphAtIndex:(NSUInteger) glyphIndex withGlyph:(NSGlyph) newGlyph;
- (void) replaceTextStorage:(NSTextStorage *) newTextStorage;
- (NSView *) rulerAccessoryViewForTextView:(NSTextView *) aTextView
							paragraphStyle:(NSParagraphStyle *) paraStyle
									 ruler:(NSRulerView *) aRulerView
								   enabled:(BOOL) flag;
- (NSArray *) rulerMarkersForTextView:(NSTextView *) view
					   paragraphStyle:(NSParagraphStyle *) style
								ruler:(NSRulerView *) ruler;
- (void) setAllowsNonContiguousLayout:(BOOL) flag;
- (void) setAttachmentSize:(NSSize) attachmentSize forGlyphRange:(NSRange) glyphRange;
- (void) setBackgroundLayoutEnabled:(BOOL) flag;
- (void) setBoundsRect:(NSRect) rect forTextBlock:(NSTextBlock *) block glyphRange:(NSRange) glyphRange;
- (void) setCharacterIndex:(NSUInteger) charIndex forGlyphAtIndex:(NSUInteger) glyphIndex;
- (void) setDefaultAttachmentScaling:(NSImageScaling) scaling;
- (void) setDelegate:(id) delegate;
- (void) setDrawsOutsideLineFragment:(BOOL) flag forGlyphAtIndex:(NSUInteger) glyphIndex;
- (void) setExtraLineFragmentRect:(NSRect) fragmentRect usedRect:(NSRect) usedRect textContainer:(NSTextContainer *) container;
- (void) setGlyphGenerator:(NSGlyphGenerator *) glyphGenerator;
- (void) setHyphenationFactor:(float) factor;
- (void) setIntAttribute:(NSInteger) attributeTag value:(NSInteger) val forGlyphAtIndex:(NSUInteger) glyphIndex;
- (void) setLayoutRect:(NSRect) rect forTextBlock:(NSTextBlock *) block glyphRange:(NSRange) range;
- (void) setLineFragmentRect:(NSRect) fragmentRect forGlyphRange:(NSRange) glyphRange usedRect:(NSRect) usedRect;
- (void) setLocation:(NSPoint) location forStartOfGlyphRange:(NSRange) glyphRange;
- (void) setLocations:(NSPointArray) locs
 startingGlyphIndexes:(NSUInteger *) glyphIds
				count:(NSUInteger) number
		forGlyphRange:(NSRange) range;
- (void) setNotShownAttribute:(BOOL) flag forGlyphAtIndex:(NSUInteger) glyphIndex;
- (void) setShowsControlCharacters:(BOOL) flag;
- (void) setShowsInvisibleCharacters:(BOOL) flag;
- (void) setTemporaryAttributes:(NSDictionary *) attrs forCharacterRange:(NSRange) charRange;
- (void) setTextContainer:(NSTextContainer *) container forGlyphRange:(NSRange) glyphRange;
- (void) setTextStorage:(NSTextStorage *) textStorage;
- (void) setTypesetter:(NSTypesetter *) typesetter;
- (void) setTypesetterBehavior:(NSTypesetterBehavior) behavior;
- (void) setUsesFontLeading:(BOOL) flag;
- (void) setUsesScreenFonts:(BOOL) flag;
- (void) showAttachmentCell:(NSCell *) cell inRect:(NSRect) rect characterIndex:(NSUInteger) attachmentIndex;
- (void) showPackedGlyphs:(char *) glyphs
				   length:(NSUInteger) glyphLen
			   glyphRange:(NSRange) glyphRange
				  atPoint:(NSPoint) point
					 font:(NSFont *) font
					color:(NSColor *) color
	   printingAdjustment:(NSSize) adjust;
- (BOOL) showsControlCharacters;
- (BOOL) showsInvisibleCharacters;
- (void) strikethroughGlyphRange:(NSRange) glyphRange
			   strikethroughType:(NSInteger) strikethroughVal
				lineFragmentRect:(NSRect) lineRect
		  lineFragmentGlyphRange:(NSRange) lineGlyphRange
				 containerOrigin:(NSPoint) containerOrigin;
- (NSFont *) substituteFontForFont:(NSFont *) originalFont;
- (id) temporaryAttribute:(NSString *) name
		 atCharacterIndex:(NSUInteger) loc
		   effectiveRange:(NSRangePointer) effectiveRange;
- (id) temporaryAttribute:(NSString *) name
		 atCharacterIndex:(NSUInteger) loc
	longestEffectiveRange:(NSRangePointer) effectiveRange
				  inRange:(NSRange) limit;
- (NSDictionary *) temporaryAttributesAtCharacterIndex:(NSUInteger) index effectiveRange:(NSRangePointer) charRange;
- (NSDictionary *) temporaryAttributesAtCharacterIndex:(NSUInteger) loc
								 longestEffectiveRange:(NSRangePointer) effectiveRange
											   inRange:(NSRange) limit;
- (void) textContainerChangedGeometry:(NSTextContainer *) container;
- (void) textContainerChangedTextView:(NSTextContainer *) container;
- (NSTextContainer *) textContainerForGlyphAtIndex:(NSUInteger) glyphIndex effectiveRange:(NSRange *) effectiveGlyphRange;
- (NSTextContainer *) textContainerForGlyphAtIndex:(NSUInteger) index
									effectiveRange:(NSRangePointer) effectiveGlyphRange
						   withoutAdditionalLayout:(BOOL) layoutFlag;
- (NSArray *) textContainers;
- (NSTextStorage *) textStorage;
- (void) textStorage:(NSTextStorage *) str
/* FIXME: should use NSTextStorageEditedOptions typedef */
			  edited:(NSUInteger) editedMask
			   range:(NSRange) newCharRange
	  changeInLength:(NSInteger) delta
	invalidatedRange:(NSRange) invalidatedCharRange;
- (NSTextView *) textViewForBeginningOfSelection;
- (NSTypesetter *) typesetter;
- (NSTypesetterBehavior) typesetterBehavior;
- (void) underlineGlyphRange:(NSRange) glyphRange
			   underlineType:(NSInteger) underlineVal
			lineFragmentRect:(NSRect) lineRect
	  lineFragmentGlyphRange:(NSRange) lineGlyphRange
			 containerOrigin:(NSPoint) containerOrigin;
- (NSRect) usedRectForTextContainer:(NSTextContainer *) container;
- (BOOL) usesFontLeading;
- (BOOL) usesScreenFonts;

@end

@interface NSObject (NSLayoutManagerDelegate)

- (void) layoutManagerDidInvalidateLayout:(NSLayoutManager *) sender;
- (NSDictionary *) layoutManager:(NSLayoutManager *) sender
	shouldUseTemporaryAttributes:(NSDictionary *) tempAttrs
			  forDrawingToScreen:(BOOL) flag
				atCharacterIndex:(NSUInteger) index
				  effectiveRange:(NSRangePointer) charRange;
- (void) layoutManager:(NSLayoutManager *) layoutManager
didCompleteLayoutForTextContainer:(NSTextContainer *) textContainer
				 atEnd:(BOOL) layoutFinishedFlag;

@end
