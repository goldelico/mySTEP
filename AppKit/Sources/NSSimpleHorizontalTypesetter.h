/*
	NSSimpleHorizontalTypesetter.h
	mySTEP

	Created by Dr. H. Nikolaus Schaller on Sun Jan 22 2012.
	Copyright (c) 2012 Golden Delicious Computers GmbH&Co. KG.
 
	Tries to be compatible to
	http://developer.apple.com/legacy/mac/library/documentation/Cocoa/Reference/ApplicationKit/Classes/NSSimpleHorizontalTypesetter_Class/NSSimpleHorizontalTypesetter_Class.pdf

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
{ /* from http://lightchaos.blog10.fc2.com/blog-entry-111.html */

	NSTypesetterGlyphInfo *glyphs;	// this is the shelf where Glyphs are laid out until a complete line is flushed to the LayoutManager
	NSLayoutManager *layoutManager;	// => _layoutManager
	NSTextStorage *textStorage;		// => _attributedString
	NSString *textString;
	NSTextContainer *curContainer;	// => _currentTextContainer
	NSParagraphStyle *curParaStyle;	// => _currentParagraphStyle
	NSFont *previousFont;
	NSFont *curFont;
	NSDictionary *attrs;
	NSSize curContainerSize;
	float curMinLineHeight;
	float curMaxLineHeight;
	float curGlyphExtentAboveLocation;
	float curGlyphExtentBelowLocation;
	float curMaxGlyphLocation;
	float curBaselineOffset;
	NSRange attrsRange;
	unsigned capacityGlyphInfo;
	unsigned sizeGlyphInfo;
	unsigned firstIndexOfCurrentLineFragment;
	unsigned curGlyphIndex;
	unsigned int curGlyph;
	unsigned int curCharacterIndex;
	unsigned int firstGlyphIndex;
	unsigned int firstInvalidGlyphIndex;
	unsigned int previousGlyph;
	unsigned int curContainerIndex;
	int curTextAlignment;
	int curSuperscript;
	BOOL curFontIsFixedPitch;
	BOOL busy;
	/*
	unsigned int *glyphCache;
	int *glyphInscriptionCache;
	unsigned int *glyphCharacterIndexCache;
	char *glyphElasticCache;
	NSSize glyphLocationOffset;
	unsigned int lastFixedGlyphIndex;
	unsigned int sizeOfGlyphInfo;
	int curGlyphInscription;
	unsigned int previousBaseGlyphIndex;
	unsigned int previousBaseGlyph;
	float curGlyphOffset;
	BOOL curGlyphOffsetOutOfDate;
	BOOL curGlyphIsAControlGlyph;
	BOOL containerBreakAfterCurGlyph;
	BOOL wrapAfterCurGlyph;
	float curSpaceAfter;
	float previousSpaceAfter;
	int glyphLayoutMode;
	int curLayoutDirection;
	NSRect curFontBoundingBox;
	NSPoint curFontAdvancement;
	void *curFontPositionOfGlyphMethod;
	float curMinBaselineDistance;
	float curMaxBaselineDistance;
	float curContainerLineFragmentPadding;
	BOOL curContainerIsSimpleRectangular;
	unsigned int capacityOfGlyphs;
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
#define NSGlyphInfoAtIndex(IDX) (glyphs+(IDX)*sizeof(glyphs[0]))
- (void) breakLineAtIndex:(unsigned) location;
- (unsigned) capacityOfTypesetterGlyphInfo;
- (void) clearAttributesCache;
- (void) clearGlyphCache;
- (NSTextContainer *) currentContainer;	// [super currentTextContainer]
- (NSLayoutManager *) currentLayoutManager;	// [super layoutManager]
- (NSParagraphStyle *) currentParagraphStyle;	// inherited from superclass
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
- (void) willSetLineFragmentRect:(NSRect *) aRect forGlyphRange:(NSRange) aRange usedRect:(NSRect *) bRect;	// inherited from superclass

/* undocumented methods */
- (unsigned int) glyphIndexToBreakLineByClippingAtIndex:(unsigned int) fp8;
- (void) getAttributesForCharacterIndex:(unsigned int) fp8;
- (NSRect) normalizedRect:(NSRect) fp8;
- (void) _setupBoundsForLineFragment:(NSRect *) fp8;
- (float) baselineOffsetInLayoutManager:(id) fp8 glyphIndex:(unsigned int) fp12;
- (void) _layoutGlyphsInLayoutManager:(id) fp8
				 startingAtGlyphIndex:(unsigned int) fp12
			 maxNumberOfLineFragments:(unsigned int) fp16
				 currentTextContainer:(id *) fp20
						 proposedRect:(NSRect *) fp24
					   nextGlyphIndex:(unsigned int *) fp28;
- (BOOL) followsItalicAngle;
- (void) setFollowsItalicAngle:(BOOL) fp8;
- (BOOL) _typesetterIsBusy;
- (NSTypesetterGlyphInfo *) _glyphInfoAtIndex:(int) fp8;

@end

#endif /* _mySTEP_H_NSSimpleHorizontalTypesetter */
