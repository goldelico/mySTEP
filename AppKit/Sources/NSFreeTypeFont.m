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

@implementation NSFont (NSFreeTypeFont)

#if 0
// FIXME: add freetype rendering

- (NSSize) _sizeOfString:(NSString *) string;
{ // get size
	return size;	// return size of character box
}
#endif

- (float) ascender; { return [_descriptor _face]->ascender * (1.0/32.0); }

- (NSRect) boundingRectForFont; { return NSZeroRect; }

- (NSRect) boundingRectForGlyph:(NSGlyph)aGlyph; { return NSZeroRect; }

- (float) capHeight; { return 0.0; }

- (NSCharacterSet *) coveredCharacterSet;  { return nil; }

- (float) descender; { return [_descriptor _face]->descender * (1.0/32.0); }

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
	FT_UInt glyph=FT_Get_Name_Index([_descriptor _face], (FT_String *) [name cString]);
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

@end


@implementation NSFontDescriptor (NSBackend)	// the NSFontDescriptor can cache a libfreetype FT_Face structure

#define FONT_CACHE	[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/com.quantum-step.mySTEP.NSFonts.plist"]

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

// the font cache is a NSDictionary indexed by Font Families
// each family contains NSDictionary indexed by Font Faces
// each Face has an entry "File" and and entry "FaceNumber"
// dynamically, each Face can also have and entry "NSFontDescriptor" storing the attributes dictionary

// ?? how to handle duplicate Family-Faces? There are two files and potentially two different FaceNumbers

static NSMutableDictionary *cache;

- (void) _loadFontFromFile:(NSString *) path;
{ // try to load to cache - ignore if we can't really load
	FT_Long	faceIndex;
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
		if(_faceStruct)
			{
			FT_Done_Face(_faceStruct);
			_backendPrivate=NULL;
			}
#if 0
		NSLog(@"try face #%lu", faceIndex);
#endif
		error=FT_New_Face(_ftLibrary(), [path fileSystemRepresentation], faceIndex, (FT_Face *) &_backendPrivate);	// try to load first face
		if(error)
			return;	// any error
#if 0
		NSLog(@"num faces=%lu", _faceStruct->num_faces);
#endif
		family=[NSString stringWithCString:_faceStruct->family_name];
		if(_faceStruct->style_name)
			style=[NSString stringWithCString:_faceStruct->style_name];
		else
			style=@"Regular";	// N/A
		if([style isEqualToString:@"Regular"])
			name=family;
		else
			name=[NSString stringWithFormat:@"%@-%@", family, style];
#if 1
		NSLog(@"add #%lu[%lu] %@-%@ at %@", faceIndex, _faceStruct->num_faces, family, style, path);
#endif
		fontRecord=[NSDictionary dictionaryWithObjectsAndKeys:
			path, @"File",
			[NSNumber numberWithUnsignedLong:faceIndex], @"Face",
			nil];
		[[cache objectForKey:NSFontNameAttribute] setObject:fontRecord forKey:name];
		// add to cache
		// create { "File"=path, "Face"=NSNumber(faceIndex) }
		// save e.g. as "Helvetica-Bold" in NSFontNameAttribute
		// save in NSSet with name NSFontFamilyAttribute
		// in the Family, we should keep spaces
		// for the font name, we should remove space characters
		// remove "Regular" from style name for building postscript name
		}
}

- (void) _createCache;
{
	NSEnumerator *e=[[[NSBundle bundleForClass:isa] objectForInfoDictionaryKey:@"NSFontSearchPath"] objectEnumerator];
	NSString *dir;
	if(_faceStruct)
		{
		FT_Done_Face(_faceStruct);
		_backendPrivate=NULL;
		}
#if 1
	NSLog(@"create font cache");
#endif
	cache=[[NSMutableDictionary alloc] initWithObjectsAndKeys:
		[NSMutableDictionary dictionaryWithCapacity:20], NSFontFamilyAttribute,
		[NSMutableDictionary dictionaryWithCapacity:20], NSFontNameAttribute,
		nil];
	while((dir=[e nextObject]))
		{
		NSEnumerator *f;
		NSString *file;
		dir=[dir stringByExpandingTildeInPath];
		f=[[[NSFileManager defaultManager] directoryContentsAtPath:dir] objectEnumerator];
		while((file=[f nextObject]))
			{
			if([file hasPrefix:@"."])
				continue;	// ignore hidden files
			[self _loadFontFromFile:[dir stringByAppendingPathComponent:file]];
			}
		}
#if 1
	NSLog(@"write font cache");
#endif
	if(![cache writeToFile:FONT_CACHE atomically:YES])
		[NSException raise:NSGenericException format:@"Can't write font cache: %@", FONT_CACHE];
}

- (FT_Face) _face;
{ // get _face
	if(!_faceStruct)
		{
		FT_Error error;
		FT_Long	faceIndex;
		NSString *fontFile;
		NSString *fontName;
		NSDictionary *fontRecord;
		fontName=[_attributes objectForKey:NSFontNameAttribute];											// get our font name
//		NS_DURING
			if(!cache)
				cache=[[NSMutableDictionary alloc] initWithContentsOfFile:FONT_CACHE];			// load cache if needed
//		NS_HANDLER
//			cache=nil;
//		NS_ENDHANDLER
		fontRecord=[[cache objectForKey:NSFontNameAttribute] objectForKey:fontName];	// look up in cache
		if(!fontRecord)
			{
			[self _createCache];	// does not exist, try to rebuild cache
			fontRecord=[[cache objectForKey:NSFontNameAttribute] objectForKey:fontName];
			if(!fontFile)
				[NSException raise:NSGenericException format:@"Font not in cache: %@", fontName];
			}
		fontFile=[fontRecord objectForKey:@"File"];
		faceIndex=[[fontRecord objectForKey:@"Face"] unsignedLongValue];
		_backendPrivate=NULL;
		error=FT_New_Face(_ftLibrary(), [fontFile fileSystemRepresentation], faceIndex, (FT_Face *) &_backendPrivate);
		// fixme: should we clear the cache on errors so that it is rebuilt from scratch?
		if(error == FT_Err_Unknown_File_Format)
			[NSException raise:NSGenericException format:@"Invalid font %@ file format: %@", fontName, fontFile];
		if(error)
			[NSException raise:NSGenericException format:@"Unable to load font %@ from %@", fontName, fontFile];
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
	return _faceStruct;
}

// FIXME: should be moved to the current context where we store the current _faceStruct

- (void) _render:(NSString *) string forContext:(NSGraphicsContext *) ctxt;
{ // render the string
	FT_Error error;
	FT_GlyphSlot slot = _faceStruct->glyph;
	FT_Vector pen;
	unsigned long len=[string length];
	unsigned long i;
	
	//	error = FT_Select_CharMap(_faceStruct, FT_ENCODING_BIG5 );	// not required since we use Unicode
	
	/* the pen position in 26.6 cartesian space coordinates */
	
	pen.x = 0;
	pen.y = 0;
	
	for(i = 0; i < len; i++)
		{	// render characters
		FT_ULong c=[string characterAtIndex:i];
		error = FT_Load_Char(_faceStruct, c, FT_LOAD_RENDER);
		if(error)
			continue;
		/*
		 // draw/render into context
		 my_draw_bitmap( &slot->bitmap,
						 slot->bitmap_left,
						 slot->bitmap_top );
		 */
		pen.x += slot->advance.x;
		pen.y += slot->advance.y;
		}
}

- (NSArray *) matchingFontDescriptorsWithMandatoryKeys:(NSSet *) keys;
{ // this is the core font search engine that knows about font directories
	// search all fonts we know
	// FIXME: filter by matching attributes
	// returns array of font desriptors!
	return nil;
}

- (void) dealloc;
{
	if(_faceStruct)
		FT_Done_Face((FT_Face) _faceStruct);
	[_attributes release];
	[super dealloc];
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

// EOF