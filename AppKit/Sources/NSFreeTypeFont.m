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

@implementation _NSX11Font (NSFreeTypeFont)

#if 0
// FIXME: add freetype rendering

- (NSSize) _sizeOfString:(NSString *) string;
{ // get size of string (fragment)
	return size;	// return size of character box
}
#endif

- (float) ascender; { return _faceStruct->ascender * (1.0/32.0); }

- (NSRect) boundingRectForFont; { return NSZeroRect; }

- (NSRect) boundingRectForGlyph:(NSGlyph)aGlyph; { return NSZeroRect; }

- (float) capHeight; { return 0.0; }

- (NSCharacterSet *) coveredCharacterSet;  { return nil; }

- (float) descender; { return _faceStruct->descender * (1.0/32.0); }

- (void) getAdvancements:(NSSizeArray) advancements
							 forGlyphs:(const NSGlyph *) glyphs
									 count:(unsigned) count; { return; }

- (void) getAdvancements:(NSSizeArray) advancements
				 forPackedGlyphs:(const void *) glyphs
									 count:(unsigned) count; { return; }

- (void) getBoundingRects:(NSRectArray) bounds
								forGlyphs:(const NSGlyph *) glyphs
										count:(unsigned) count; { return; }

- (NSGlyph) glyphWithName:(NSString *) name;
{
	FT_UInt glyph=FT_Get_Name_Index(_faceStruct, (FT_String *) [name cString]);
	if(glyph == 0)
		return NSNullGlyph;
	return glyph;
}

- (BOOL) isFixedPitch;	{ return NO; }

- (float) italicAngle; { return 0.0; }

- (float) leading; { return 0.0; }

- (NSSize) maximumAdvancement; { return NSZeroSize; }

- (NSStringEncoding) mostCompatibleStringEncoding; { return NSASCIIStringEncoding; }

- (unsigned) numberOfGlyphs; { return 0; }

- (float) underlinePosition; { return 0.0; }

- (float) underlineThickness; { return 0.0; }

- (float) xHeight; { return 0.0; }

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
		{
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
				// get transform/size
				// if we don't have a transform we must have a pointSize
				// else get point size from matrix, and scale matrix by inverse size
				/*
				 error = FT_Set_Char_Size((FT_Face *) &_faceStruct,			// handle to face object
										  0,														// char_width in 1/64th of points
										  [self pointSize]*64,					// char_height in 1/64th of points
										  72,     // horizontal device resolution
										  72 );   // vertical device resolution
				 */
				/*
				 NSAffineTransformStruct m;
				 FT_Matrix matrix = { m.m11*0x10000, m.m12*0x10000, m.m21*0x10000, m.m22*0x10000 };
				 FT_Vector delta = { m.tX*64, m.tY*64 };
				 error = FT_Set_Transform((FT_Face *) &_faceStruct,			// handle to face object
										  &matrix,    // pointer to 2x2 matrix
										  &delta );   // pointer to 2d vector
				 */
				}
			}
		}
	return _faceStruct;
}

- (void) _finalize
{ // called when deallocating the X11Font
	if(_faceStruct)
		FT_Done_Face((FT_Face) _faceStruct);
}

- (void) _drawAntialisedGlyphs:(NSGlyph *) glyphs count:(unsigned) cnt inContext:(NSGraphicsContext *) ctxt;
{ // render the string
	FT_Error error;
	FT_GlyphSlot slot = _faceStruct->glyph;
	FT_Vector pen;
	unsigned long i;
	
	//	error = FT_Select_CharMap(_faceStruct, FT_ENCODING_BIG5 );	// not required since we use Unicode
	
	/* the pen position in 26.6 cartesian space coordinates */
	
	pen.x = 0;
	pen.y = 0;
	
	for(i = 0; i < cnt; i++)
		{	// render characters
		error = FT_Load_Char(_faceStruct, glyphs[i], FT_LOAD_RENDER);
		if(error)
			continue;
		/*
		 my_draw_bitmap( context, &slot->bitmap,
						 slot->bitmap_left,
						 slot->bitmap_top,
						 pen
						 );
		 */
		pen.x += slot->advance.x;
		pen.y += slot->advance.y;
		}
}

@end


@implementation NSFontDescriptor (NSFreeTypeFont)	// the NSFontDescriptor can cache a libfreetype FT_Face structure

+ (void) _loadFontFromFile:(NSString *) path;
{ // try to load to cache - ignore if we can't really load
	FT_Long	faceIndex;
	FT_Face face;
#if 1
	NSLog(@"_loadFontFromFile:%@", path);
#endif
	for(faceIndex=0; faceIndex < 10; faceIndex++)
		{ // loop until we can't read a given face
		FT_Error error;
		NSDictionary *fontRecord;
		NSString *family;
		NSString *style;
		NSString *name;
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
#if 0
		NSLog(@"num faces=%lu", face.num_faces);
#endif
		family=[NSString stringWithCString:face->family_name];
		if(face->style_name)
			style=[NSString stringWithCString:face->style_name];
		else
			style=@"Regular";	// N/A
		if([style isEqualToString:@"Regular"])
			name=family;
		else
			name=[NSString stringWithFormat:@"%@-%@", family, style];
#if 1
		NSLog(@"add #%lu[%lu] %@-%@ at %@", faceIndex, face->num_faces, family, style, path);
#endif
		fontRecord=[NSDictionary dictionaryWithObjectsAndKeys:
			family, NSFontFamilyAttribute,
			style, NSFontFaceAttribute,
			name, NSFontNameAttribute,
			// add other attributes if we can get them...
			path, @"FilePath",
			[NSNumber numberWithUnsignedLong:faceIndex], @"FaceNumber",
			nil];
		[NSFontDescriptor _addDescriptor:fontRecord];
		FT_Done_Face(face);
		}
}

+ (void) _findFonts;
{
	NSEnumerator *e=[[[NSBundle bundleForClass:self] objectForInfoDictionaryKey:@"NSFontSearchPath"] objectEnumerator];
	NSString *dir;
#if 1
	NSLog(@"scan for fonts");
#endif
	while((dir=[e nextObject]))
		{
		NSEnumerator *f;
		NSString *file;
#if 1
		NSLog(@"scan %@", dir);
#endif
		dir=[dir stringByExpandingTildeInPath];
		f=[[[NSFileManager defaultManager] directoryContentsAtPath:dir] objectEnumerator];
		while((file=[f nextObject]))
			{
			if([file hasPrefix:@"."])
				continue;	// ignore hidden files
			[self _loadFontFromFile:[dir stringByAppendingPathComponent:file]];
			}
		}
}


@end

@implementation NSBezierPath (Backend)

- (void) appendBezierPathWithGlyphs:(NSGlyph *)glyphs 
							  count:(int)count
							 inFont:(NSFont *)font
{
	NIMP;
}

- (void) appendBezierPathWithPackedGlyphs:(const char *)packedGlyphs
{
	NIMP;
}

@end

#endif

// EOF