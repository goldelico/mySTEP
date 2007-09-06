/*
 NSGlyphGenerator.h
  
 Author:	H. N. Schaller <hns@computer.org>
 Date:		Jun 2006 - aligned with 10.4
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */

#import <Foundation/Foundation.h>
#import <AppKit/NSFont.h>	// define NSGlyph

enum
{
	NSShowControlGlyphs		=1,
	NSShowInvisibleGlyphs	=2,
	NSWantsBidiLevels		=4
};

@protocol NSGlyphStorage

- (NSAttributedString *) attributedString;
- (void ) insertGlyphs:(const NSGlyph *) glyphs
				length:(unsigned int) length
		forStartingGlyphAtIndex:(unsigned int) glyph
		characterIndex:(unsigned int) index;
- (unsigned int) layoutOptions;
- (void) setIntAttribute:(int) tag value:(int) value forGlyphAtIndex:(unsigned) index;

@end

@interface NSGlyphGenerator : NSObject

+ (id) sharedGlyphGenerator;
- (void) generateGlyphsForGlyphStorage:(id <NSGlyphStorage>) storage
			 desiredNumberOfCharacters:(unsigned int) num
							glyphIndex:(unsigned int *) glyph
						characterIndex:(unsigned int *) index;

@end