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
	NSLayoutNotDone = 0,	// line fragment rect fully filled + more glyphs (for another fragment)
	NSLayoutDone,			// all gyphs did fit into the rect (last fragment of this paragraph)
	NSLayoutCantFit,		// current glyph is too big to fit
	NSLayoutOutOfGlyphs		// last line was laid out (extra fragment)
} NSLayoutStatus;

typedef enum _NSGlyphLayoutMode
{
	NSGlyphLayoutAtAPoint = 0,
	NSGlyphLayoutAgainstAPoint,
	NSGlyphLayoutWithPrevious
} NSGlyphLayoutMode;

typedef enum _NSLayoutDirection
{
	NSLayoutLeftToRight = 0,
	NSLayoutRightToLeft
} NSLayoutDirection;

typedef struct _NSTypesetterGlyphInfo
{ // Must be identical in component names to Cocoa or subclassing and overwriting typesetterLaidOneGlyph may fail
	NSPoint			curLocation;	// location of glyph (relative to line fragment origin)
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
	NSTextContainer *curContainer;	// => _currentTextContainer
	NSFont *curFont;				// [attrs objectForKey:NSFontAttributeName]
	NSFont *previousFont;
	NSParagraphStyle *curParaStyle;	// => _currentParagraphStyle
	NSString *textString;			// [textStorage string]
	NSDictionary *attrs;			// current attributes
	NSRange attrsRange;				// current attribute range (character index)
	NSSize curContainerSize;		// [curContainer containerSize]; .width is used to know when to break a line
	NSRect curFontBoundingBox;
	NSSize curFontAdvancement;
	float curGlyphOffset;			// glyph layout cursor (x of next glyph)
	float curMaxGlyphLocation;		// max width of line fragment (i.e. mix of indent and [curContainer size].width)
	float curContainerLineFragmentPadding;	// [curContainer lineFragmentPadding]
	float curSpaceAfter;			// cached [attrs objectForKey:NSKernAttributeName]
	float curBaselineOffset;		// cached [attrs objectForKey:NSBaselineOffsetAttributeName] 
	float curMinLineHeight;			// cached [curParaStyle minLineHeight]
	float curMaxLineHeight;			// cached [curParaStyle maxLineHeight]
	NSGlyph previousGlyph;
	NSGlyph curGlyph;
	unsigned firstGlyphIndex;		// relative index of first glyph in glyphs array
	unsigned curGlyphIndex;			// current glyph being processed (relative index in glyphs[])
	unsigned firstInvalidGlyphIndex;	// first invalid index in glyphs[] - i.e. number of used entries
	unsigned capacityGlyphInfo;		// capacity of glyph[] cache
	unsigned sizeOfGlyphInfo;		// sizeof(NSTypesetterGlyphInfo)
	unsigned curCharacterIndex;		// current character index (absolute) being processed
	unsigned curContainerIndex;		// index into [layoutManager textContainers]
	unsigned firstIndexOfCurrentLineFragment;	// absolute glyph index where current line fragment starts
	NSLayoutDirection curLayoutDirection;		// [curParaStyle baseWritingDirection]
	NSTextAlignment curTextAlignment;			// [curParaStyle alignment]
	int curSuperscript;				// [attrs objectForKey:NSSuperscriptAttributeName]
	BOOL curFontIsFixedPitch;		// [curFont isFixedPitch]
	BOOL curContainerIsSimpleRectangular;	// [curContainer isSimpleRectangularTextContainer]
	BOOL busy;						// busy doing layout (can detect recursions)

	/* unknown what it is good for */
	unsigned int *glyphCache;
	int *glyphInscriptionCache;
	NSGlyphLayoutMode glyphLayoutMode;
	unsigned int *glyphCharacterIndexCache;	// local mapping from glyph index to character index?
	char *glyphElasticCache;
	struct _NSSize glyphLocationOffset;	// is this the accumulation of glyph location, baseline, kerning etc. before typesetterLaidOneGlyph is called?
	unsigned int lastFixedGlyphIndex;
	int curGlyphInscription;
	unsigned int previousBaseGlyphIndex;
	unsigned int previousBaseGlyph;
	BOOL curGlyphOffsetOutOfDate;
	BOOL curGlyphIsAControlGlyph;
	BOOL containerBreakAfterCurGlyph;	// can be set to YES in typesetterLaidOneGlyph subclass
	BOOL wrapAfterCurGlyph;
	float previousSpaceAfter;
	void *curFontPositionOfGlyphMethod;
	float curMinBaselineDistance;		// something accumulated? Used to determine required fragment height?
	float curMaxBaselineDistance;
	float curGlyphExtentAboveLocation;
	float curGlyphExtentBelowLocation;
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

	/* our extensions */
	NSRange curParaRange;	// current paragraph attribute range (and paragraph length)

}

+ (id) sharedInstance;

- (NSTypesetterGlyphInfo *) baseOfTypesetterGlyphInfo;
#define NSGlyphInfoAtIndex(IDX) (&glyphs[IDX])
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
- (void) _layoutGlyphsInLayoutManager:(NSLayoutManager *) fp8
				 startingAtGlyphIndex:(unsigned int) fp12
			 maxNumberOfLineFragments:(unsigned int) fp16
				 currentTextContainer:(NSTextContainer **) fp20
						 proposedRect:(NSRect *) fp24
					   nextGlyphIndex:(unsigned int *) fp28;
- (BOOL) followsItalicAngle;
- (void) setFollowsItalicAngle:(BOOL) fp8;
- (BOOL) _typesetterIsBusy;
- (NSTypesetterGlyphInfo *) _glyphInfoAtIndex:(int) fp8;

@end

#endif /* _mySTEP_H_NSSimpleHorizontalTypesetter */
