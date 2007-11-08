/* 
   NSFont.h

   Font wrapper object

   Copyright (C) 1998 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date: 	May 1998
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Oct 2006 - aligned with 10.4
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	8. November 2007 - aligned with 10.5 
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSFont
#define _mySTEP_H_NSFont

#import <Foundation/NSCoder.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSCell.h>
#import <AppKit/NSFontDescriptor.h>

@class NSString;
@class NSDictionary;

typedef enum _NSFontRenderingMode
{
	NSFontDefaultRenderingMode = 0,
	NSFontAntialiasedRenderingMode,
	NSFontIntegerAdvancementsRenderingMode,
	NSFontAntialiasedIntegerAdvancementsRenderingMode
} NSFontRenderingMode;

extern const float *NSFontIdentityMatrix;

typedef enum _NSMultibyteGlyphPacking
{
	NSOneByteGlyphPacking = 0,	// deprecated
	NSJapaneseEUCGlyphPacking,	// deprecated
	NSAsciiWithDoubleByteEUCGlyphPacking,	// deprecated
	NSTwoByteGlyphPacking,	// deprecated
	NSFourByteGlyphPacking,	// deprecated
	NSNativeShortGlyphPacking = 5
} NSMultibyteGlyphPacking; 

enum _ReservedGlyphCodes
{
	NSControlGlyph = 0x00ffffff,
	NSNullGlyph = 0x0
};

#if 0	// deprecated
extern NSString *NSAFMFamilyName;
extern NSString *NSAFMFontName;
extern NSString *NSAFMFormatVersion;
extern NSString *NSAFMFullName;
extern NSString *NSAFMNotice;
extern NSString *NSAFMVersion;
extern NSString *NSAFMWeight;
extern NSString *NSAFMEncodingScheme;
extern NSString *NSAFMCharacterSet;
extern NSString *NSAFMCapHeight;
extern NSString *NSAFMXHeight;
extern NSString *NSAFMAscender;
extern NSString *NSAFMDescender;
extern NSString *NSAFMUnderlinePosition;
extern NSString *NSAFMUnderlineThickness;
extern NSString *NSAFMItalicAngle;
extern NSString *NSAFMMappingScheme;
#endif

typedef unsigned int NSGlyph;

typedef enum _NSGlyphRelation
{
	NSGlyphBelow = 1,
	NSGlyphAbove = 2
} NSGlyphRelation;	// deprecated

extern NSString *NSAntialiasThresholdChangedNotification;
extern NSString *NSFontSetChangedNotification;

@interface NSFont : NSObject  <NSCoding>
{
	NSFontDescriptor *_descriptor;
	NSFontRenderingMode _renderingMode;
// @public
// 	void *_backendPrivate;	// stores an XFontStruct if we are a screen font
}

+ (NSFont *) boldSystemFontOfSize:(CGFloat) fontSize;
+ (NSFont *) controlContentFontOfSize: (CGFloat) fontSize;
+ (NSFont *) fontWithDescriptor:(NSFontDescriptor *) descriptor size:(CGFloat) size;
+ (NSFont *) fontWithDescriptor:(NSFontDescriptor *) descriptor size:(CGFloat) size textTransform:(NSAffineTransform *) transform;
+ (NSFont *) fontWithDescriptor:(NSFontDescriptor *) descriptor textTransform:(NSAffineTransform *) transform;
+ (NSFont *) fontWithName:(NSString *) fontName matrix:(const CGFloat *) fontMatrix;
+ (NSFont *) fontWithName:(NSString *) fontName size:(CGFloat) fontSize;
+ (NSFont *) labelFontOfSize:(CGFloat) fontSize;
+ (CGFloat) labelFontSize;
+ (NSFont *) menuBarFontOfSize:(CGFloat) fontSize;
+ (NSFont *) menuFontOfSize:(CGFloat) fontSize;
+ (NSFont *) messageFontOfSize:(CGFloat) fontSize;
+ (NSFont *) paletteFontOfSize:(CGFloat) fontSize;
+ (NSArray *) preferredFontNames;	// deprecated
+ (void) setPreferredFontNames:(NSArray *) names;	// deprecated
+ (void) setUserFixedPitchFont:(NSFont *) aFont;				// Setting the Font
+ (void) setUserFont:(NSFont *) aFont;
+ (CGFloat) smallSystemFontSize;
+ (NSFont *) systemFontOfSize:(CGFloat) fontSize;
+ (CGFloat) systemFontSize;
+ (CGFloat) systemFontSizeForControlSize:(NSControlSize) size;
+ (NSFont *) titleBarFontOfSize:(CGFloat) fontSize;
+ (NSFont *) toolTipsFontOfSize:(CGFloat) fontSize;
+ (NSFont *) userFixedPitchFontOfSize:(CGFloat) fontSize;
+ (void) useFont:(NSString *) fontName;	// deprecated
+ (NSFont *) userFontOfSize:(CGFloat) fontSize;

- (NSSize) advancementForGlyph:(NSGlyph) aGlyph;
- (NSDictionary *) afmDictionary;	// deprecated
- (CGFloat) ascender;
- (NSRect) boundingRectForFont;
- (NSRect) boundingRectForGlyph:(NSGlyph) aGlyph;
- (CGFloat) capHeight;
- (NSCharacterSet *) coveredCharacterSet;
- (float) defaultLineHeightForFont;	// deprecated
- (CGFloat) descender;
- (NSString *) displayName;
- (NSString *) encodingScheme;	// deprecated
- (NSString *) familyName;
- (NSFontDescriptor *) fontDescriptor;
- (NSString *) fontName;
- (void) getAdvancements:(NSSizeArray) advancements
			   forGlyphs:(const NSGlyph *) glyphs
				   count:(NSUInteger) count;
- (void) getAdvancements:(NSSizeArray) advancements
			   forPackedGlyphs:(const void *) glyphs
				   count:(NSUInteger) count;
- (void) getBoundingRects:(NSRectArray) bounds
				forGlyphs:(const NSGlyph *) glyphs
					count:(NSUInteger) count;
- (BOOL) glyphIsEncoded:(NSGlyph) aGlyph;	// deprecated
- (NSMultibyteGlyphPacking) glyphPacking;	// deprecated
- (NSGlyph) glyphWithName:(NSString *) name;
- (BOOL) isBaseFont;	// deprecated
- (BOOL) isFixedPitch;
- (CGFloat) italicAngle;
- (CGFloat) leading;
- (const CGFloat *) matrix;
- (NSSize) maximumAdvancement;
// - (NSSize) minimumAdvancement;	// ??
- (NSStringEncoding) mostCompatibleStringEncoding;
- (NSUInteger) numberOfGlyphs;
- (CGFloat) pointSize;	// effective vertical point size
- (NSPoint) positionOfGlyph:(NSGlyph) curGlyph
			forCharacter:(unichar) character
				  struckOverRect:(NSRect) rect;	// deprecated
- (NSPoint) positionOfGlyph:(NSGlyph) curGlyph
			precededByGlyph:(NSGlyph) prevGlyph
				  isNominal:(BOOL *) nominal;	// deprecated
- (NSPoint) positionOfGlyph:(NSGlyph) curGlyph
			struckOverGlyph:(NSGlyph) prevGlyph
				  metricExists:(BOOL *) flag;	// deprecated
- (NSPoint) positionOfGlyph:(NSGlyph) curGlyph
			struckOverRect:(NSRect) rect
				  metricExists:(BOOL *) flag;	// deprecated
- (NSPoint) positionOfGlyph:(NSGlyph) curGlyph
			 withRelation:(NSGlyphRelation) relation
				toBaseGlyph:(NSGlyph) otherGlyph
		   totalAdvancement:(NSSizePointer) offset
			   metricExists:(BOOL *) flag;	// deprecated
- (int) positionsForCompositeSequence:(NSGlyph *) glyphs
					   numberOfGlyphs:(int) number
						   pointArray:(NSPointArray) points; // deprecated
- (NSFont *) printerFont;
- (NSFontRenderingMode) renderingMode;
- (NSFont *) screenFont;
- (NSFont *) screenFontWithRenderingMode:(NSFontRenderingMode) mode;
- (void) set;
- (void) setInContext:(NSGraphicsContext *) context;
- (NSAffineTransform *) textTransform;
- (CGFloat) underlinePosition;
- (CGFloat) underlineThickness;
- (float) widthOfString:(NSString *) string;	// deprecated
- (CGFloat) xHeight;

@end

#endif /* _mySTEP_H_NSFont */
