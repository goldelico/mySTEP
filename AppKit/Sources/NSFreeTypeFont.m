/* 
 NSFreeTypeFont.m
 
 FreeType Wrapper
 
 Copyright (C) 1998 Free Software Foundation, Inc.
 
 Author:	H. N. Schaller <hns@computer.org>
 Date:		Jun 2007 - completely reworked

 Useful Manuals:
	http://tronche.com/gui/x/xlib											Xlib - basic X11 calls
    http://freetype.sourceforge.net/freetype2/docs/reference/ft2-toc.html	libFreetype2 - API
	http://freetype.sourceforge.net/freetype2/docs/tutorial/step1.html		a tutorial
	http://netmirror.org/mirror/xfree86.org/4.4.0/doc/HTML/Xft.3.html		Xft - freetype glue
	http://netmirror.org/mirror/xfree86.org/4.4.0/doc/HTML/Xrandr.3.html	XResize - rotate extension
	http://netmirror.org/mirror/xfree86.org/4.4.0/doc/HTML/Xrender.3.html	XRender - antialiased, alpha, subpixel rendering
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#if 1	// set to 0 to disable libfreetype references

#import "NSX11GraphicsContext.h"
#import "NSFreeTypeFont.h"

// load full headers (to expand @class forward references)

#import "NSAppKitPrivate.h"
#import "NSApplication.h"
#import "NSAttributedString.h"
#import "NSBezierPath.h"
#import "NSColor.h"
#import "NSCursor.h"
#import "NSFont.h"
#import "NSGraphics.h"
#import "NSGraphicsContext.h"
#import "NSImage.h"
#import "NSScreen.h"
#import "NSWindow.h"
#import "NSPasteboard.h"
#import "NSGlyphGenerator.h"

@interface NSGraphicsContext (NSFreeTypeFont)
- (void) _drawGlyphBitmap:(unsigned char *) buffer x:(int) x y:(int) y width:(unsigned) width height:(unsigned) height;
@end

@implementation _NSX11Font (NSFreeTypeFont)

#define Free2Pt(VAL) (VAL*(1.0/64.0))

- (float) ascender; { return Free2Pt(_faceStruct->ascender); }

- (NSRect) boundingRectForFont;
{
	return NSMakeRect(Free2Pt(_faceStruct->bbox.xMin), Free2Pt(_faceStruct->bbox.yMin), Free2Pt(_faceStruct->bbox.xMax-_faceStruct->bbox.xMin), Free2Pt(_faceStruct->bbox.yMax-_faceStruct->bbox.yMin));
}

- (float) capHeight; { return Free2Pt(_faceStruct->height); }

- (NSCharacterSet *) coveredCharacterSet;
{
	NSMutableCharacterSet *cs=[[NSMutableCharacterSet new] autorelease];
	FT_ULong charcode;                                              
	FT_UInt gindex;                                                	
	charcode = FT_Get_First_Char(_faceStruct, &gindex);                   
	while(gindex != 0)                                            
		{
		[cs addCharactersInRange:NSMakeRange(charcode, 1)];
		charcode = FT_Get_Next_Char(_faceStruct, charcode, &gindex);        
		}
	return cs;
}

- (float) descender; { return Free2Pt(_faceStruct->descender); }

- (void) getAdvancements:(NSSizeArray) advancements
			   forGlyphs:(const NSGlyph *) glyphs
				   count:(unsigned) count;
{
	while(count-- > 0)
		{
		NSSize sz;
		FT_Load_Glyph(_faceStruct, *glyphs++, FT_LOAD_DEFAULT);
		if(_renderingMode == NSFontAntialiasedIntegerAdvancementsRenderingMode)
			{ // a little faster but less accurate
			sz=NSMakeSize(_faceStruct->glyph->advance.x>>6, _faceStruct->glyph->advance.y>>6);
			}
		else
			{ // needs additional float operations per step
			sz=NSMakeSize(_faceStruct->glyph->linearHoriAdvance*(1.0/65536.0), _faceStruct->glyph->linearVertAdvance*(1.0/65536.0));
			}
		*advancements++=sz;
		}
}

- (void) getAdvancements:(NSSizeArray) advancements
				 forPackedGlyphs:(const void *) glyphs
									 count:(unsigned) count; { NIMP; }

- (void) getBoundingRects:(NSRectArray) bounds
								forGlyphs:(const NSGlyph *) glyphs
										count:(unsigned) count;
{
	while(count-- > 0)
		{
		NSRect rect;
		FT_Load_Glyph(_faceStruct, *glyphs++, FT_LOAD_DEFAULT);
		rect=NSMakeRect(Free2Pt(_faceStruct->glyph->metrics.horiBearingX), Free2Pt(_faceStruct->glyph->metrics.height-_faceStruct->glyph->metrics.horiBearingY),
						Free2Pt(_faceStruct->glyph->metrics.width), Free2Pt(_faceStruct->glyph->metrics.height));
		*bounds++=rect;
		}
}


- (NSGlyph) glyphWithName:(NSString *) name;
{
	FT_UInt glyph=FT_Get_Name_Index(_faceStruct, (FT_String *) [name cString]);
	if(glyph == 0)
		return NSNullGlyph;
	return glyph;
}

- (BOOL) isFixedPitch;	{ return FT_IS_FIXED_WIDTH(_faceStruct) != 0; }

- (float) italicAngle; { return 0.0; }	// FIXME

- (float) leading; { return Free2Pt(_faceStruct->height); }

- (NSSize) maximumAdvancement; { return NSMakeSize(Free2Pt(_faceStruct->max_advance_width), Free2Pt(_faceStruct->max_advance_height)); }

- (NSStringEncoding) mostCompatibleStringEncoding;
{
	NSStringEncoding enc=NSASCIIStringEncoding;
	int i;
	for(i=0; i<_faceStruct->num_charmaps; i++)
		{
		switch(_faceStruct->charmaps[i]->encoding)
			{
			case FT_ENCODING_UNICODE:
				enc=NSUnicodeStringEncoding;
				break;
			case FT_ENCODING_APPLE_ROMAN:
				enc=NSMacOSRomanStringEncoding;
				break;
			default:
				break;
			}
		}
	return enc;
}

- (unsigned) numberOfGlyphs; { return _faceStruct->num_glyphs; }

- (float) underlinePosition; { return Free2Pt(_faceStruct->underline_position); }

- (float) underlineThickness; { return Free2Pt(_faceStruct->underline_thickness); }

- (float) xHeight;
{
	FT_Load_Glyph(_faceStruct, FT_Get_Char_Index(_faceStruct, 'x'), FT_LOAD_DEFAULT);
	return Free2Pt(_faceStruct->size->metrics.ascender);
}

- (id) _initWithDescriptor:(NSFontDescriptor *) desc
{
	if((self=[super init]))
		{
		_renderingMode=NSFontAntialiasedRenderingMode;
		_descriptor=[desc retain];
		if(![self _face])
			{ // can't load backend info
#if 1
			NSLog(@"Can't find font %@", [desc fontAttributes]);
#endif
			[self release];
			return nil;
			}
		}
	return self;
}

FT_Library _ftLibrary(void)
{
	FT_Error error;
	static FT_Library _freetypeLibrary;	// For multi-threaded applications each thread should have its own FT_Library object!
	if(!_freetypeLibrary)
		{
		if((error=FT_Init_FreeType(&_freetypeLibrary)))
			[NSException raise:NSGenericException format:@"Unable to initialize libFreetype"];
		}
	return _freetypeLibrary;
}

- (void) _clear;
{
	if(_faceStruct)
		{
		FT_Done_Face(_faceStruct);
		_backendPrivate=NULL;
		}
}

- (FT_Face) _face;
{ // get _face
	if(!_faceStruct)
		{ // not yet initialized
		NSDictionary *attribs=[_descriptor fontAttributes];
		if(attribs)
			{
			FT_Error error;
			FT_Long	faceIndex=[[attribs objectForKey:@"FaceNumber"] unsignedLongValue];
			NSString *fontFile=[attribs objectForKey:@"FilePath"];
			_backendPrivate=NULL;
			error=FT_New_Face(_ftLibrary(), [fontFile fileSystemRepresentation], faceIndex, (FT_Face *) &_backendPrivate);
			if(!error)
				{
				NSAffineTransform *t=[_descriptor matrix];
//				FT_Select_Charmap(_faceStruct, FT_ENCODING_UNICODE);
				if(t)
					{ // we have a text transform
					NSAffineTransformStruct m=[t transformStruct];
					FT_Matrix matrix = { m.m11*0x10000, m.m12*0x10000, m.m21*0x10000, m.m22*0x10000 };
					FT_Vector delta = { m.tX*64, m.tY*64 };
					FT_Set_Transform(_faceStruct,			// handle to face object
									 &matrix,				// pointer to 2x2 matrix
									 &delta);				// pointer to 2d vector
					return _faceStruct;
					}
				else
					{ // use pointSize
					// well, this should be screen independent!!
					float scale=[[[[[NSScreen screens] objectAtIndex:0] deviceDescription] objectForKey:@"systemSpaceScaleFactor"] floatValue];
					error=FT_Set_Pixel_Sizes(_faceStruct, 0, (int) (scale*[_descriptor pointSize]));
#if OLD
					// FIXME: here we must handle the user and system space scale factors or the bitmaps will not be scaled to DPI!
					// we should cache and reload only if we draw to a different context!
					int hdpi=120;
					int vdpi=120;
					FT_F26Dot6 size=64*[_descriptor pointSize];
					error = FT_Set_Char_Size(_faceStruct,					// handle to face object
											  size,							// char_width in 1/64th of points
											  size,							// char_height in 1/64th of points
											  hdpi,							// horizontal device resolution
											  vdpi);						// vertical device resolution
#endif
					if(!error)
						return _faceStruct;
					}
				}
			NSLog(@"*** Internal font loading error: %@", fontFile);
			}
		}
	return _faceStruct;
}

- (void) _finalize
{ // called when deallocating the X11Font
	if(_faceStruct)
		FT_Done_Face(_faceStruct);
}

- (NSGlyph) _glyphForCharacter:(unichar) c;
	// FIXME - this should be moved to NSGlyphGenerator!
{
	return FT_Get_Char_Index(_faceStruct, c);
}

- (NSSize) _sizeOfAntialisedString:(NSString *) string;
{ // deprecated...
	NSSize sz=NSZeroSize;
	unsigned long i, cnt=[string length];
	// we could sum up the integer widths/heights and convert to float only once
	for(i = 0; i < cnt; i++)
		{ // load glyphs
		FT_Error error = FT_Load_Char(_faceStruct, [string characterAtIndex:i], FT_LOAD_DEFAULT);
		float h;
		if(error)
			continue;
		if(_renderingMode == NSFontAntialiasedIntegerAdvancementsRenderingMode)
			{ // a little faster but less accurate
			sz.width += _faceStruct->glyph->advance.x>>6;
			}
		else
			{
			sz.width += _faceStruct->glyph->linearHoriAdvance*(1.0/65536);
			}
		h=Free2Pt(_faceStruct->glyph->metrics.height);
		if(h > sz.height)
			sz.height=h;
		}
	return sz;
}

- (void) _drawAntialisedGlyphs:(NSGlyph *) glyphs count:(unsigned) cnt inContext:(NSGraphicsContext *) ctxt;
{ // render the string
	FT_GlyphSlot slot = _faceStruct->glyph;
	NSPoint pen = NSZeroPoint;
	unsigned long i;
//	pen.y=[self ascender];	// one line down
	pen.y=(_faceStruct->ascender+_faceStruct->descender)>>6;
	for(i = 0; i < cnt; i++)
		{ // render glyphs
		FT_Error error = FT_Load_Glyph(_faceStruct, glyphs[i], FT_LOAD_RENDER);
		if(error)
			continue;
		// x,y is the top/left position in X11 coordinates, i.e. counted from top/left of screen
		[ctxt _drawGlyphBitmap:slot->bitmap.buffer x:pen.x+slot->bitmap_left y:pen.y-slot->bitmap_top width:slot->bitmap.width height:slot->bitmap.rows];
		if(_renderingMode == NSFontAntialiasedIntegerAdvancementsRenderingMode)
			{ // a little faster but less accurate
			pen.x += slot->advance.x>>6;
			pen.y += slot->advance.y>>6;
			}
		else
			{ // needs 4 additional float operations per step
			pen.x += slot->linearHoriAdvance*(1.0/65536);
// not reliable	- use FT_HAS_VERTICAL()		pen.y += slot->linearVertAdvance*(1.0/65536);
			}
		}
}

@end

@implementation NSGlyphGenerator (NSFreeTypeFont)

- (void) generateGlyphsForGlyphStorage:(id <NSGlyphStorage>) storage
			 desiredNumberOfCharacters:(unsigned int) num
							glyphIndex:(unsigned int *) gidx
						characterIndex:(unsigned int *) cidx
{
	NSAttributedString *astr=[storage attributedString];	// get string to layout
	NSString *str=[astr string];
	unsigned int options=[storage layoutOptions];	 // NSShowControlGlyphs, NSShowInvisibleGlyphs, NSWantsBidiLevels
	NSGlyph previous=0;
	BOOL usekerning=YES;	// ask storage?
	while(num > 0)
		{
		
		// FIXME: handle invisible characters, make page breaks etc. optionally visible, handle multi-character glyphs (ligatures), multi-glyph characters etc.
		// convert unicode to glyph encoding
		
		// loop through characters
		// switch fonts as necessary
		// add line breaks (?)
		// convert character to glyph encoding

		NSGlyph glyph;
		int gnum=1;
		unichar c=[str characterAtIndex:*cidx];
		NSDictionary *attribs=[astr attributesAtIndex:*cidx effectiveRange:NULL];
		NSFont *font=[attribs objectForKey:@"Font"];
		FT_Face face=[(_NSX11Font *) font _face];
		switch(c)
			{
			// handle special characters like \n \t and textattachments depending on options
			default:
				glyph=FT_Get_Char_Index(face, c);
			}

		// generate position information
		if(usekerning && previous && glyph)
			{ // handle kerning
			FT_Vector delta;
			FT_Get_Kerning(face, previous, glyph, FT_KERNING_DEFAULT, &delta);
//			pen_x += Free2Pt(delta.x);
//			pen_y += Free2Pt(delta.y);
			previous=glyph;
			}
		[storage insertGlyphs:&glyph length:gnum forStartingGlyphAtIndex:*gidx characterIndex:*cidx];
//		[storage setIntAttribute:124 value:4321 forGlyphAtIndex:*gidx];
//		store glyph positions
		*gidx+=gnum;
		*cidx++;
		num--;
		}
}

@end

@implementation NSFontDescriptor (NSFreeTypeFont)	// the NSFontDescriptor can cache a libfreetype FT_Face structure

#define USE_SQLITE 0

#if USE_SQLITE	// sqlite based font cache - overwrites default implementation

#define FONT_CACHE	[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/com.quantum-step.mySTEP.NSFonts.sqlite"]

+ (NSArray *) _matchingFontDescriptorsWithAttributes:(NSDictionary *) attributes mandatoryKeys:(NSSet *) keys limit:(unsigned) limit;
{ // this is the core font search engine that knows about font directories
	NSString *query=@"SELECT * FROM fonts";
	NSString *delim=@"WHERE";
	NSArray *keylist=nil;	// nur die die gespeichert werden!
	NSEnumerator *e=[keys objectEnumerator];
	NSString *key;
	while((key=[e nextObject]) && [keylist containsObject:key])
		query=[NSString stringWithFormat:@"%@ %@ %@='%@'", query, delim, key, [_attributes objectForKey:key]], delim=@"AND";
	if(limit < 99999)
		query=[NSString stringWithFormat:@"%@ LIMIT %u", query, limit];
	NSLog(@"query=%@", query);
	abort();
	return nil;
}

+ (NSDictionary *) _fonts;
{
	return NIMP;
}

+ (void) _writeFonts;
{
	return;
}

+ (void) _addFontWithAttributes:(NSDictionary *) record;
{ // add a system record that helps to find the font file
	NSEnumerator *e=[record keyEnumerator];
	NSString *key;
	// create table fonts (Name text,Family text,Face text,PostscriptName text, Traits integer, FaceNumber integer,FilePath text);
	const char *path=[FONT_CACHE fileSystemRepresentation];
	FILE *f=fopen(path, "a");
	char c;
	fprintf(f, "insert into fonts ");
	c='(';
	while((key=[e nextObject]))
		fprintf(f, "%c%s", c, [key cString]), c=',';
	fprintf(f, ") values ");
	c='(';
	e=[record keyEnumerator];
	while((key=[e nextObject]))
		fprintf(f, "%c'%s'", c, [[[record objectForKey:key] description] UTF8String]), c=',';
	fprintf(f, ");\n");
	fclose(f);
}
#endif

+ (void) _loadFontsFromFile:(NSString *) path;
{ // try to load to cache - ignore if we can't really load
	FT_Long	faceIndex;
	FT_Face face;
#if 1
	NSLog(@"_loadFontsFromFile:%@", path);
#endif
	for(faceIndex=0; faceIndex < 10; faceIndex++)
		{ // loop until we can't read a given face
		FT_Error error;
		NSMutableDictionary *fontRecord;
		NSString *family;
		NSString *style;
		NSString *name;
		NSFontTraitMask traits=0;
		const char *psname;
#if 0
		NSLog(@"try face #%lu", faceIndex);
#endif
		error=FT_New_Face(_ftLibrary(), [path fileSystemRepresentation], faceIndex, &face);	// try to load first face
		if(error == FT_Err_Unknown_File_Format)
			{
			NSLog(@"Invalid font file format: %@", path);
			return;
			}
		if(error)
			{
			NSLog(@"Unable to load font file %@ (error=%d)", path, error);
			return;	// any error
			}
		if(!FT_IS_SCALABLE(face))
			continue;	// must be scalable - FIXME: we could derive a NSFontSizeAttribute
#if 0
		NSLog(@"num faces=%lu", face.num_faces);
#endif
		family=[NSString stringWithCString:face->family_name];
		if(face->style_name && strcmp(face->style_name, "Regular") != 0)
			{
			style=[NSString stringWithCString:face->style_name];
			name=[NSString stringWithFormat:@"%@-%@", family, style];	// build display name
			}
		else
			{
			style=@"";	// N/A
			name=family;
			}
		if(face->style_flags&FT_STYLE_FLAG_ITALIC)
			traits |= NSItalicFontMask;
//		else
//			traits |= NSUnitalicFontMask;
		if(face->style_flags&FT_STYLE_FLAG_BOLD)
			traits |= NSBoldFontMask;
//		else
//			traits |= NSUnboldFontMask;
		// nonstandardcharset traits
		// narrowfont
		// expanded
		// condensed
		// smallcaps
		// posterfont
		// compressed
		if(FT_IS_FIXED_WIDTH(face))
			traits |= NSFixedPitchFontMask;
#if 1
		NSLog(@"add #%lu[%lu] %@-%@ at %@", faceIndex, face->num_faces, family, style, path);
#endif
		psname=FT_Get_Postscript_Name(face);
		if(!psname)
			continue;	// we can handle fonts with postscript name only
		fontRecord=[NSMutableDictionary dictionaryWithObjectsAndKeys:
			// official
			family, NSFontFamilyAttribute,
			style, NSFontFaceAttribute,
			[NSString stringWithCString:psname], NSFontNameAttribute,	// official name
			name, NSFontVisibleNameAttribute,	// display name
			[NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithUnsignedInt:traits], NSFontSymbolicTrait,
				[NSNumber numberWithFloat:0.0], NSFontWeightTrait,
				// NSFontSlantTrait
				// NSFontWidthTrait
				nil], NSFontTraitsAttribute,
			// internal
			path, @"FilePath",
			[NSNumber numberWithUnsignedLong:faceIndex], @"FaceNumber",
			nil];
		[NSFontDescriptor _addFontWithAttributes:fontRecord];
		FT_Done_Face(face);
		}
}

@end

@implementation NSBezierPath (Backend)

- (void) appendBezierPathWithGlyphs:(NSGlyph *)glyphs 
							  count:(int)count
							 inFont:(NSFont *)font
{
	FT_Face face=[(_NSX11Font *) font _face];
	// do similar loop as in - (void) _drawAntialisedGlyphs:(NSGlyph *) glyphs count:(unsigned) cnt inContext:(NSGraphicsContext *) ctxt;
	// but collect contents of slot->outline
	/*
	 n_contours	
	 The number of contours in the outline.
	 
	 this is an inner loop!
	 
	 n_points	
	 The number of points in the outline.
	 
	 points	
	 A pointer to an array of ‘n_points’ FT_Vector elements, giving the outline's point coordinates.
	 
	 tags	
	 A pointer to an array of ‘n_points’ chars, giving each outline point's type. If bit 0 is unset, the point is ‘off’ the curve, i.e., a Bézier control point, while it is ‘on’ when set.
	 
	 Bit 1 is meaningful for ‘off’ points only. If set, it indicates a third-order Bézier arc control point; and a second-order control point if unset.
	 
	 switch(slot->outline->tags[i]&3)
		{
		case 0:
			// second order control point
			break;
		case 1:
			[self lineTo: ];
			break;
		case 2:
			// third order control point
		case 3:
			// error
		}
	 contours	
	 An array of ‘n_contours’ shorts, giving the end point of each contour within the outline. For example, the first contour is defined by the points ‘0’ to ‘contours[0]’, the second one is defined by the points ‘contours[0]+1’ to ‘contours[1]’, etc.
	 
	 => [self close]
	 
	 flags	
	 A set of bit flags used to characterize the outline and give hints to the scan-converter and hinter on how to convert/grid-fit it. See FT_OUTLINE_FLAGS.
	 
	 FT_OUTLINE_EVEN_ODD_FILL
	 By default, outlines are filled using the non-zero winding rule. If set to 1, the outline will be filled using the even-odd fill rule (only works with the smooth raster).
	 
	 
	 */
	
	NIMP;
}

- (void) appendBezierPathWithPackedGlyphs:(const char *)packedGlyphs
{
	NIMP;
}

@end

#endif

// EOF