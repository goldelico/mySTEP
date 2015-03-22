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
	CGFloat			extent;			// width of glyph
	CGFloat			belowBaseLine;	// cumulated baseline needs
	CGFloat			aboveBaseline;	// cumulated above needs
	NSUInteger		glyphCharacterIndex;
	struct {
		unsigned int defaultPositioning:1;
		unsigned int dontShow:1;
		unsigned int isAttachment:1;
		unsigned int drawsOutside:1;	// this is our addition
	} _giflags;
} NSTypesetterGlyphInfo;

@interface NSSimpleHorizontalTypesetter : NSTypesetter
{ /* structure comes from http://lightchaos.blog10.fc2.com/blog-entry-111.html - except for upgrade to CGFloat */

	// the following iVars are defined in NSTypesetter
	// NSLayoutManager *layoutManager;	// => _layoutManager
	// NSTextStorage *textStorage;		// => _attributedString
	// NSTextContainer *curContainer;	// => _currentTextContainer
	// NSParagraphStyle *curParaStyle;	// => _currentParagraphStyle
	// NSRange curParaRange;	// current paragraph attribute range (and paragraph length)
	NSTypesetterGlyphInfo *glyphs;	// this is the shelf where Glyphs are laid out until a complete line is flushed to the LayoutManager
	NSFont *curFont;				// [attrs objectForKey:NSFontAttributeName]
	NSFont *previousFont;
	NSString *textString;			// [textStorage string]
	NSDictionary *attrs;			// current attributes
	NSRange attrsRange;				// current attribute range (character index)
	NSSize curContainerSize;		// [curContainer containerSize]; .width is used to know when to break a line
	NSRect curFontBoundingBox;
	NSSize curFontAdvancement;
	CGFloat curGlyphOffset;			// glyph layout cursor (x of next glyph)
	CGFloat curMaxGlyphLocation;		// max width of line fragment (i.e. mixed from indentation and container width)
	CGFloat curContainerLineFragmentPadding;	// [curContainer lineFragmentPadding]
	CGFloat curSpaceAfter;			// cached [attrs objectForKey:NSKernAttributeName]
	CGFloat curBaselineOffset;		// cached [attrs objectForKey:NSBaselineOffsetAttributeName]
	CGFloat curMinLineHeight;			// cached [curParaStyle minLineHeight]
	CGFloat curMaxLineHeight;			// cached [curParaStyle maxLineHeight]
	CGFloat curMinBaselineDistance;		// accumulated during layout of a single horizontal line
	CGFloat curMaxBaselineDistance;
	CGFloat curGlyphExtentAboveLocation;	// ascender/descender of current glyph
	CGFloat curGlyphExtentBelowLocation;
	NSGlyph previousGlyph;
	NSGlyph curGlyph;
	NSUInteger firstGlyphIndex;		// relative index of first glyph in glyphs array
	NSUInteger curGlyphIndex;			// current glyph being processed (relative index in glyphs[])
	NSUInteger firstInvalidGlyphIndex;	// first invalid index in glyphs[] - i.e. number of used entries
	NSUInteger capacityGlyphInfo;		// capacity of glyph[] cache
	NSUInteger sizeOfGlyphInfo;		// sizeof(NSTypesetterGlyphInfo)
	NSUInteger curCharacterIndex;		// current character index (absolute) being processed
	NSUInteger curContainerIndex;		// index into [layoutManager textContainers]
	NSUInteger firstIndexOfCurrentLineFragment;	// absolute glyph index where current line fragment starts
	NSLayoutDirection curLayoutDirection;		// [curParaStyle baseWritingDirection]
	NSTextAlignment curTextAlignment;			// [curParaStyle alignment]
	NSInteger curSuperscript;				// [attrs objectForKey:NSSuperscriptAttributeName]
	BOOL curFontIsFixedPitch;		// [curFont isFixedPitch]
	BOOL curContainerIsSimpleRectangular;	// [curContainer isSimpleRectangularTextContainer]
	BOOL curGlyphIsAControlGlyph;
	BOOL containerBreakAfterCurGlyph;	// can be set to YES in typesetterLaidOneGlyph subclass
	BOOL wrapAfterCurGlyph;			// can be set to YES in typesetterLaidOneGlyph subclass
	BOOL busy;						// busy doing layout (can detect recursions)

	/* unknown what it is good for */
	NSUInteger *glyphCache;
	NSInteger *glyphInscriptionCache;
	NSGlyphLayoutMode glyphLayoutMode;
	NSUInteger *glyphCharacterIndexCache;	// local mapping from glyph index to character index?
	char *glyphElasticCache;
	NSSize glyphLocationOffset;		// is this the accumulation of glyph location, baseline, kerning etc. before typesetterLaidOneGlyph is called?
	NSUInteger lastFixedGlyphIndex;
	NSInteger curGlyphInscription;
	NSUInteger previousBaseGlyphIndex;
	NSUInteger previousBaseGlyph;
	BOOL curGlyphOffsetOutOfDate;
	CGFloat previousSpaceAfter;
	void *curFontPositionOfGlyphMethod;
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
}

+ (id) sharedInstance;

- (NSTypesetterGlyphInfo *) baseOfTypesetterGlyphInfo;
#define NSGlyphInfoAtIndex(IDX) (&glyphs[IDX])
- (void) breakLineAtIndex:(NSUInteger) location;
- (NSUInteger) capacityOfTypesetterGlyphInfo;
- (void) clearAttributesCache;
- (void) clearGlyphCache;
- (NSTextContainer *) currentContainer;	// [super currentTextContainer]
- (NSLayoutManager *) currentLayoutManager;	// [super layoutManager]
- (NSParagraphStyle *) currentParagraphStyle;	// inherited from superclass
- (NSTextStorage *) currentTextStorage;	// [super attributedString]
- (void) fillAttributesCache;
- (NSUInteger) firstGlyphIndexOfCurrentLineFragment;
- (void) fullJustifyLineAtGlyphIndex:(NSUInteger) glyphIndexForLineBreak;
- (NSUInteger) glyphIndexToBreakLineByHyphenatingWordAtIndex:(NSUInteger) charIndex;
- (NSUInteger) glyphIndexToBreakLineByWordWrappingAtIndex:(NSUInteger) charIndex;
- (NSUInteger) growGlyphCaches:(NSUInteger) desiredCapacity fillGlyphInfo:(BOOL) fillGlyphInfo;
- (void) insertGlyph:(NSGlyph) glyph atGlyphIndex:(NSUInteger) glyphIndex characterIndex:(NSUInteger) charIndex;	// keeps _glyphInfo in sync
- (NSLayoutStatus) layoutControlGlyphForLineFragment:(NSRect) lineFrag;
- (NSLayoutStatus) layoutGlyphsInHorizontalLineFragment:(NSRect *) lineFragmentRect
											   baseline:(CGFloat *) baseline;
- (void) layoutGlyphsInLayoutManager:(NSLayoutManager *) layoutManager
				startingAtGlyphIndex:(NSUInteger) startGlyphIndex
			maxNumberOfLineFragments:(NSUInteger) maxNumLines
					  nextGlyphIndex:(NSUInteger *) nextGlyph;
- (void) layoutTab;
- (NSUInteger) sizeOfTypesetterGlyphInfo;
- (void) typesetterLaidOneGlyph:(NSTypesetterGlyphInfo *) gl;	// called after each glyph
- (void) updateCurGlyphOffset;
- (void) willSetLineFragmentRect:(NSRect *) aRect forGlyphRange:(NSRange) aRange usedRect:(NSRect *) bRect;	// inherited from superclass

/* undocumented methods */
- (NSUInteger) glyphIndexToBreakLineByClippingAtIndex:(NSUInteger) fp8;
- (void) getAttributesForCharacterIndex:(NSUInteger) fp8;
- (NSRect) normalizedRect:(NSRect) fp8;
- (void) _setupBoundsForLineFragment:(NSRect *) fp8;
- (CGFloat) baselineOffsetInLayoutManager:(id) fp8 glyphIndex:(unsigned int) fp12;
- (void) _layoutGlyphsInLayoutManager:(NSLayoutManager *) fp8
				 startingAtGlyphIndex:(NSUInteger) fp12
			 maxNumberOfLineFragments:(NSUInteger) fp16
				 currentTextContainer:(NSTextContainer **) fp20
						 proposedRect:(NSRect *) fp24
					   nextGlyphIndex:(NSUInteger *) fp28;
- (BOOL) followsItalicAngle;
- (void) setFollowsItalicAngle:(BOOL) fp8;
- (BOOL) _typesetterIsBusy;
- (NSTypesetterGlyphInfo *) _glyphInfoAtIndex:(NSUInteger) fp8;

@end

#endif /* _mySTEP_H_NSSimpleHorizontalTypesetter */
