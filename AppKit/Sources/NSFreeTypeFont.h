/* 
 NSFreeTypeFont.h
 
 FreeType Wrapper
 
 Author:	H. N. Schaller <hns@computer.org>
 Date:		Jun 2007 - completely reworked

 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#ifndef _mySTEP_H_NSFreeTypeFont
#define _mySTEP_H_NSFreeTypeFont

#include <ft2build.h>
#include FT_FREETYPE_H

#import "NSAppKitPrivate.h"
#import "NSBackendPrivate.h"
#import "NSColor.h"
#import "NSFont.h"
#import "NSFontDescriptor.h"
#import "NSScreen.h"

@interface _NSX11Font (NSFreeTypeFont)

#define _faceStruct ((FT_Face) _backendPrivate)

- (void) _clear;
- (FT_Face) _face;
- (void) _finalize;
- (void) _drawAntialisedGlyphs:(NSGlyph *) glyphs count:(unsigned) cnt inContext:(NSGraphicsContext *) ctxt;

@end

#endif /* _mySTEP_H_NSFreeTypeFont */
