/*
 NSGlyphGenerator.h
  
 Author:	H. N. Schaller <hns@computer.org>
 Date:		Jun 2006 - aligned with 10.4
 
 Author:	Fabian Spillner <fabian.spillner@gmail.com>
 Date:	8. November 2007 - aligned with 10.5 
 
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
				length:(NSUInteger) length
		forStartingGlyphAtIndex:(NSUInteger) glyph
		characterIndex:(NSUInteger) index;
- (NSUInteger) layoutOptions;
- (void) setIntAttribute:(NSInteger) tag value:(NSInteger) value forGlyphAtIndex:(NSUInteger) index;

@end


@interface NSGlyphGenerator : NSObject

+ (id) sharedGlyphGenerator;
- (void) generateGlyphsForGlyphStorage:(id <NSGlyphStorage>) storage
			 desiredNumberOfCharacters:(NSUInteger) num
							glyphIndex:(NSUInteger *) glyph
						characterIndex:(NSUInteger *) index;

@end