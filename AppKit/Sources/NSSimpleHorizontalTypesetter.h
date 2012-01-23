/*
	NSSimpleHorizontalTypesetter.h
	mySTEP

	Created by Dr. H. Nikolaus Schaller on Sun Jan 22 2012.
	Copyright (c) 2006 DSITRI.

	This file is part of the mySTEP Library and is provided
	under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSSimpleHorizontalTypesetter
#define _mySTEP_H_NSSimpleHorizontalTypesetter

#import "AppKit/NSTypesetter.h"

#define NumGlyphsToGetEachTime 20
#define NSBaselineNotSet -1.0

typedef enum _NSLayoutStatus
{
	NSLayoutNotDone = 0,
	NSLayoutDone,
	NSLayoutCantFit,
	NSLayoutOutOfGlyphs
} NSLayoutStatus;

typedef enum _NSGlyphLayoutMode { NSGlyphLayoutAtAPoint = 0, NSGlyphLayoutAgainstAPoint, NSGlyphLayoutWithPrevious
} NSGlyphLayoutMode;

typedef enum _NSLayoutDirection { NSLayoutLeftToRight = 0, NSLayoutRightToLeft
} NSLayoutDirection;

typedef struct _NSTypesetterGlyphInfo
{ // Must be identical in component names to Cocoa or subclassing and overwriting typesetterLaidOneGlyph may fail
	NSPoint			curLocation;	// location of glyph
	NSSize			attachmentSize;
	NSFont			*font;
	float			extent;			// width of glyph
	float			belowBaseLine;	// cumulated baseline needs
	float			aboveBaseline;	// cumulated above needs
	unsigned		glyphCharacterIndex;
	struct {
		unsigned int defaultPositioning:1;
		unsigned int dontShow:1;
		unsigned int isAttachment:1;
	} _giflags;
} NSTypesetterGlyphInfo;

@interface NSSimpleHorizontalTypesetter : NSTypesetter
{
	NSTypesetterGlyphInfo *_glyphInfo;	// this is the shelf where Glyphs are laid out until a complete line is flushed to the LayoutManager
//	NSLayoutManager *_currentLayoutManager;	=> _layoutManager
//	NSTextStorage *_currentTextStorage;	=> _attributedString
//	NSTextContainer *_currentContainer;	=> _currentTextContainer
//	NSParagraphStyle *_currentParagraphStyle;	=> _currentParagraphStyle
	unsigned _capacityGlyphInfo;
	unsigned _sizeGlyphInfo;
	unsigned _firstIndexOfCurrentLineFragment;
	unsigned _currentGlyphIndex;
	NSRange _currentParagraphRange;
	/* from http://lightchaos.blog10.fc2.com/blog-entry-111.html
	NSLayoutManager *layoutManager;
	NSTextStorage *textStorage;
	unsigned int firstGlyphIndex;
	unsigned int curGlyphIndex;
	unsigned int firstInvalidGlyphIndex;
	NSTypesetterGlyphInfo *glyphs;
	unsigned int *glyphCache;
	int *glyphInscriptionCache;
	unsigned int *glyphCharacterIndexCache;
	char *glyphElasticCache;
	NSSize glyphLocationOffset;
	float curMaxGlyphLocation;
	unsigned int lastFixedGlyphIndex;
	unsigned int sizeOfGlyphInfo;
	unsigned int curGlyph;
	int curGlyphInscription;
	unsigned int curCharacterIndex;
	unsigned int previousGlyph;
	unsigned int previousBaseGlyphIndex;
	unsigned int previousBaseGlyph;
	NSFont *previousFont;
	float curGlyphOffset;
	BOOL curGlyphOffsetOutOfDate;
	BOOL curGlyphIsAControlGlyph;
	BOOL containerBreakAfterCurGlyph;
	BOOL wrapAfterCurGlyph;
	float curSpaceAfter;
	float previousSpaceAfter;
	int glyphLayoutMode;
	float curGlyphExtentAboveLocation;
	float curGlyphExtentBelowLocation;
	int curLayoutDirection;
	int curTextAlignment;
	NSFont *curFont;
	NSRect curFontBoundingBox;
	BOOL curFontIsFixedPitch;
	NSPoint curFontAdvancement;
	void *curFontPositionOfGlyphMethod;
	NSDictionary *attrs;
	NSRange attrsRange;
	float curBaselineOffset;
	float curMinBaselineDistance;
	float curMaxBaselineDistance;
	int curSuperscript;
	NSParagraphStyle *curParaStyle;
	NSTextContainer *curContainer;
	unsigned int curContainerIndex;
	float curContainerLineFragmentPadding;
	BOOL curContainerIsSimpleRectangular;
	NSSize curContainerSize;
	float curMinLineHeight;
	float curMaxLineHeight;
	NSString *textString;
	unsigned int capacityOfGlyphs;
	BOOL busy;
	struct {
		unsigned int _glyphPostLay:1;
		unsigned int _fragPostLay:1;
		unsigned int _useItal:1;
		unsigned int _curFontIsDefaultFace:1;
		unsigned int _tabState:2;
		unsigned int _tabType:2;
		unsigned int _tabEOL:1;
		unsigned int reserved:23;
	} _tsFlags;
	char *glyphBidiLevelCache;
	unsigned char curBidiLevel;
	unsigned char previousBidiLevel;
	unsigned char _reservedChars[2];
	unsigned int _reserved2[6];
	*/
}

+ (id) sharedInstance;

- (NSTypesetterGlyphInfo *) baseOfTypesetterGlyphInfo;
#define NSGlyphInfoAtIndex(IDX) (_glyphInfo+(IDX)*sizeof(_glyphInfo[0]))
- (void) breakLineAtIndex:(unsigned) location;
- (unsigned) capacityOfTypesetterGlyphInfo;
- (void) clearAttributesCache;
- (void) clearGlyphCache;
- (NSTextContainer *) currentContainer;	// [super currentTextContainer]
- (NSLayoutManager *) currentLayoutManager;	// [super layoutManager]
// - (NSParagraphStyle *) currentParagraphStyle;	// inherited from superclass
- (NSTextStorage *) currentTextStorage;	// [super attributedString]
- (void) fillAttributesCache;
- (unsigned) firstGlyphIndexOfCurrentLineFragment;
- (void) fullJustifyLineAtGlyphIndex:(unsigned) glyphIndexForLineBreak;
- (unsigned) glyphIndexToBreakLineByHyphenatingWordAtIndex:(unsigned) charIndex;
- (unsigned) glyphIndexToBreakLineByWordWrappingAtIndex:(unsigned) charIndex;
- (unsigned) growGlyphCaches:(unsigned) desiredCapacity fillGlyphInfo:(BOOL) fillGlyphInfo;
- (void) insertGlyph:(NSGlyph) glyph atGlyphIndex:(unsigned) glyphIndex characterIndex:(unsigned) charIndex;	// keeps _glyphInfo in sync
- (NSLayoutStatus) layoutControlGlyphForLineFragment:(NSRect) lineFrag;
- (NSLayoutStatus) layoutGlyphsInHorizontalLineFragment:(NSRect *) lineFragmentRect
											   baseline:(float *) baseline;
- (void) layoutGlyphsInLayoutManager:(NSLayoutManager *) layoutManager
				startingAtGlyphIndex:(unsigned) startGlyphIndex
			maxNumberOfLineFragments:(unsigned) maxNumLines
					  nextGlyphIndex:(unsigned *) nextGlyph;
- (void) layoutTab;
- (unsigned) sizeOfTypesetterGlyphInfo;
- (void) typesetterLaidOneGlyph:(NSTypesetterGlyphInfo *) gl;	// called after each glyph
- (void) updateCurGlyphOffset;
// - (void) willSetLineFragmentRect:(NSRect *) aRect forGlyphRange:(NSRange) aRange usedRect:(NSRect *) bRect;	// inherited from superclass

/* undocumented methods */
- (unsigned int)glyphIndexToBreakLineByClippingAtIndex:(unsigned int)fp8;
- (void)getAttributesForCharacterIndex:(unsigned int)fp8;
- (struct _NSRect)normalizedRect:(struct _NSRect)fp8;
- (void)_setupBoundsForLineFragment:(struct _NSRect *)fp8;
- (float)baselineOffsetInLayoutManager:(id)fp8 glyphIndex:(unsigned int)fp12;
- (void)_layoutGlyphsInLayoutManager:(id)fp8 startingAtGlyphIndex:(unsigned int)fp12 maxNumberOfLineFragments:(unsigned int)fp16 currentTextContainer:(id *)fp20 proposedRect:(struct _NSRect *)fp24 nextGlyphIndex:(unsigned int *)fp28;
- (BOOL)followsItalicAngle;
- (void)setFollowsItalicAngle:(BOOL)fp8;
- (BOOL)_typesetterIsBusy;
- (struct _NSTypesetterGlyphInfo *)_glyphInfoAtIndex:(int)fp8;

@end

#endif /* _mySTEP_H_NSSimpleHorizontalTypesetter */
