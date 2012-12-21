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

/*
 * for a definition see
 * https://developer.apple.com/legacy/mac/library/#documentation/Cocoa/Conceptual/FontHandling/Tasks/GettingFontMetrics.html
 */

static float scale;		// cache for screen scale
static float rscale;	// cache for 1/screen scale
static float rscale64;	// cache for 1/(64.0*screen scale)

#define Free2Pt(VAL) ((VAL)*rscale64)

- (float) ascender;
{
//	FT_Face f=_faceStruct;
	if(!FT_IS_SCALABLE(_faceStruct))
		;	// error
	return Free2Pt(_faceStruct->size->metrics.ascender);
}

- (NSRect) boundingRectForFont;
{
	FT_BBox bbox=_faceStruct->bbox;
	// FIXME: somethng apears to be wrong here
	return NSMakeRect(Free2Pt(bbox.xMin), Free2Pt(bbox.yMin), Free2Pt(bbox.xMax-bbox.xMin), Free2Pt(bbox.yMax-bbox.yMin));
}

- (float) capHeight;
{
	FT_Load_Glyph(_faceStruct, FT_Get_Char_Index(_faceStruct, 'X'), FT_LOAD_DEFAULT | FT_LOAD_IGNORE_TRANSFORM);
	return Free2Pt(_faceStruct->glyph->metrics.horiBearingY);
}

// FIXME: should this be stored in the font cache (?) as NSFontCharacterSetAttribute

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

- (float) descender; { return Free2Pt(_faceStruct->size->metrics.descender); }

- (void) getAdvancements:(NSSizeArray) advancements
			   forGlyphs:(const NSGlyph *) glyphs
				   count:(unsigned) count;
{
	while(count-- > 0)
		{
		NSSize sz;
		FT_Load_Glyph(_faceStruct, *glyphs++, FT_LOAD_DEFAULT | FT_LOAD_IGNORE_TRANSFORM);
		if(_renderingMode == NSFontAntialiasedIntegerAdvancementsRenderingMode)
			{ // a little faster but less accurate
			sz=NSMakeSize(Free2Pt(_faceStruct->glyph->advance.x), Free2Pt(_faceStruct->glyph->advance.y));
			}
		else
			{ // needs additional float operations per step
				// FIXME: delivers wrong results
//			sz=NSMakeSize(_faceStruct->glyph->linearHoriAdvance*(1.0/65536.0), 0* _faceStruct->glyph->linearVertAdvance*(1.0/65536.0));
			sz=NSMakeSize(Free2Pt(_faceStruct->glyph->advance.x), Free2Pt(_faceStruct->glyph->advance.y));
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
		FT_Load_Glyph(_faceStruct, *glyphs++, FT_LOAD_DEFAULT | FT_LOAD_IGNORE_TRANSFORM);
		rect=NSMakeRect(Free2Pt(_faceStruct->glyph->metrics.horiBearingX), Free2Pt(_faceStruct->glyph->metrics.horiBearingY-_faceStruct->glyph->metrics.height),
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

- (float) leading; { return Free2Pt(_faceStruct->size->metrics.height-(_faceStruct->size->metrics.ascender-_faceStruct->size->metrics.descender)); }

- (float) defaultLineHeightForFont; { return Free2Pt(_faceStruct->size->metrics.height); }

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
	FT_Load_Glyph(_faceStruct, FT_Get_Char_Index(_faceStruct, 'x'), FT_LOAD_DEFAULT | FT_LOAD_IGNORE_TRANSFORM);
	return Free2Pt(_faceStruct->glyph->metrics.horiBearingY);
}

- (id) _initWithDescriptor:(NSFontDescriptor *) desc
{
	if(scale == 0.0)
		{ // initialize cache
		scale=[[[[[NSScreen screens] objectAtIndex:0] deviceDescription] objectForKey:@"systemSpaceScaleFactor"] floatValue];
		rscale=1.0/scale;
		rscale64=rscale/64.0;
		}
	if((self=[super init]))
		{
		_renderingMode=NSFontAntialiasedRenderingMode;
		_descriptor=[desc retain];
		if(![self _face])
			{ // can't load backend info
#if 1
			NSLog(@"Can't find font with descriptor %@", desc);
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
				{ // scale points to screen size
				FT_Error error;
				error=FT_Set_Pixel_Sizes(_faceStruct, 0, (int) (scale*[_descriptor pointSize]));
				if(!error)
					return _faceStruct;
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
{
	return FT_Get_Char_Index(_faceStruct, c);
}

- (NSSize) _kerningBetweenGlyph:(NSGlyph) left andGlyph:(NSGlyph) right
{
	FT_Vector delta;
	FT_Get_Kerning(_faceStruct, left, right, FT_KERNING_DEFAULT, &delta);
	return NSMakeSize(Free2Pt(delta.x), Free2Pt(delta.y));
}

- (float) _widthOfAntialisedString:(NSString *) string;
{ // deprecated...
	FT_Matrix matrix = { 1<<16, 0, 0, 1<<16 };	// identity matrix
	FT_Vector delta = { 0, 0 };
	FT_GlyphSlot slot = _faceStruct->glyph;
	unsigned long i, cnt=[string length];
	// we could sum up the integer widths/heights and convert to float only once
	for(i = 0; i < cnt; i++)
		{ // load glyphs but don't transform
		FT_Error error;
		FT_Set_Transform(_faceStruct,			// handle to face object
						 &matrix,				// pointer to 2x2 matrix
						 &delta);				// pointer to 2d vector
		error = FT_Load_Char(_faceStruct, [string characterAtIndex:i], FT_LOAD_DEFAULT | FT_LOAD_IGNORE_TRANSFORM);
		if(error)
			continue;
		delta.x += slot->advance.x;
//		delta.y += slot->advance.y;	// returns bad value here and we can't handle vertical rendering anyway
		}
	return Free2Pt(delta.x);
}

// this is used for freetype with our non-XRender based drawing

- (void) _drawAntialisedGlyphs:(NSGlyph *) glyphs count:(unsigned) cnt inContext:(NSGraphicsContext *) ctxt matrix:(NSAffineTransform *) ctm;
{ // render the string
	FT_GlyphSlot slot = _faceStruct->glyph;
	NSPoint pen = [ctm transformPoint:NSZeroPoint];
	FT_Matrix matrix = { 1<<16, 0, 0, 1<<16 };	// identity matrix
	FT_Vector delta;
	NSAffineTransform *t=[_descriptor matrix];
	// catenate Font matrix (if available)
	// with text matrix
	// with CTM
	// remove scaling (i.e. make it a non-scaling transformation matrix) - scale = sqrt(m11*m11+m22*m22)
	if(t)
		{ // we have a font with an explicit text transform
		NSAffineTransformStruct m=[t transformStruct];		
		// divide by [_descriptor pointSize] so that a rotation/shearing part remains
		matrix = (FT_Matrix) { m.m11*(1<<16), m.m12*(1<<16), m.m21*(1<<16), m.m22*(1<<16) };
		delta = (FT_Vector) { m.tX*64, m.tY*64 };
		}
	else
		{ // translate only
		delta.x=(int)(64*pen.x);
		delta.y=32-(int)(64*pen.y);
		}
	while(cnt-- > 0)
		{ // render glyphs
		FT_Error error;
		FT_Set_Transform(_faceStruct,			// handle to face object
						 &matrix,				// pointer to 2x2 matrix
						 &delta);				// pointer to 2d vector
		error = FT_Load_Glyph(_faceStruct, *glyphs++, FT_LOAD_RENDER);
		if(error)
			continue;
		// x,y is the top/left position in X11 coordinates, i.e. counted from top/left of screen
		[ctxt _drawGlyphBitmap:slot->bitmap.buffer x:slot->bitmap_left y:-slot->bitmap_top width:slot->bitmap.width height:slot->bitmap.rows];
		delta.x += slot->advance.x;
		delta.y += slot->advance.y;
		}
}

// this is used when using the XRender GlyphSets

- (void) _defineGlyphs;
{ // and add to GlyphSet
	FT_ULong charcode;
	FT_UInt gindex;
	FT_GlyphSlot slot = _faceStruct->glyph;
	FT_Matrix matrix = { 1<<16, 0, 0, 1<<16 };	// identity matrix
	FT_Vector delta = { 0, 0 };
	NSAffineTransform *t=[_descriptor matrix];
#if 1
	NSLog(@"_defineGlyphs %@", self);
#endif
	if(t)
		{ // we have a font with an explicit text transform
			NSAffineTransformStruct m=[t transformStruct];		
			matrix = (FT_Matrix) { m.m11*(1<<16), m.m12*(1<<16), m.m21*(1<<16), m.m22*(1<<16) };
			delta = (FT_Vector) { m.tX*64, m.tY*64 };
		}
	FT_Set_Transform(_faceStruct,			// handle to face object
					 &matrix,				// pointer to 2x2 matrix
					 &delta);				// pointer to 2d vector
	charcode=FT_Get_First_Char(_faceStruct, &gindex);
	while(gindex != 0)
		{ // loop through all glyphs
			FT_Error error;
			NSLog(@"char=%04x glyph=%d", charcode, gindex);
			error = FT_Load_Glyph(_faceStruct, gindex, FT_LOAD_RENDER);
			if(!error && slot->bitmap.width > 0 && slot->bitmap.rows > 0)
				[self _addGlyph:(NSGlyph) gindex bitmap:(char *) slot->bitmap.buffer x:slot->bitmap_left y:slot->bitmap_top width:slot->bitmap.width height:slot->bitmap.rows];
			charcode=FT_Get_Next_Char(_faceStruct, charcode, &gindex);
		}
}

// this is used when we have our own glyph cache

- (_CachedGlyph) _defineGlyph:(NSGlyph) glyph;
{ // and add to GlyphSet
	FT_Error error;
	FT_GlyphSlot slot = _faceStruct->glyph;
	FT_Matrix matrix = { 1<<16, 0, 0, 1<<16 };	// identity matrix
	FT_Vector delta = { 0, 0 };
	NSAffineTransform *t=[_descriptor matrix];
#if 0
	NSLog(@"_defineGlyph %d %p", glyph, self);
#endif
	if(t)
			{ // we have a font with an explicit text transform
				NSAffineTransformStruct m=[t transformStruct];		
				matrix = (FT_Matrix) { m.m11*(1<<16), m.m12*(1<<16), m.m21*(1<<16), m.m22*(1<<16) };
				delta = (FT_Vector) { m.tX*64, m.tY*64 };
			}
	FT_Set_Transform(_faceStruct,			// handle to face object
									 &matrix,				// pointer to 2x2 matrix
									 &delta);				// pointer to 2d vector
	error = FT_Load_Glyph(_faceStruct, glyph, FT_LOAD_RENDER);
	if(!error && slot->bitmap.width > 0 && slot->bitmap.rows > 0)
			{
				_CachedGlyph g=(_CachedGlyph) objc_malloc(sizeof(*g));	// create new record
				[self _addGlyphToCache:g bitmap:(char *) slot->bitmap.buffer x:slot->bitmap_left y:slot->bitmap_top width:slot->bitmap.width height:slot->bitmap.rows];	// convert into Picture
			return g;
			}
	return NULL;
}

@end

@implementation NSFontDescriptor (NSFreeTypeFont)	// the NSFontDescriptor can cache a libfreetype FT_Face structure

#define USE_SQLITE 0	// has not been tested or debugged

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

+ (NSString *) _loadFontsFromFile:(NSString *) path;
{ // try to load to cache - ignore if we can't really load
	FT_Long	faceIndex;
	FT_Long numFaces=10;
	FT_Face face;
	NSString *family=nil;
#if 0
	NSLog(@"_loadFontsFromFile:%@", path);
#endif
	for(faceIndex=0; faceIndex < numFaces; faceIndex++)
		{ // loop until we can't read a given face
		FT_Error error;
		NSMutableDictionary *fontRecord;
		NSString *postscriptName;	// assuming that the name is the same for all faces...
		NSString *style;
		NSString *name;
		NSFontTraitMask traits=0;
		int cnt;
		unsigned long lweight;
		float weight=0.0;
		const char *psname;
#if 0
		NSLog(@"try face #%lu num faces=%lu", faceIndex, numFaces);
#endif
		error=FT_New_Face(_ftLibrary(), [path fileSystemRepresentation], faceIndex, &face);	// try to load first face
		if(error == FT_Err_Unknown_File_Format)
			{
			NSLog(@"Invalid font file format: %@", path);
			return nil;
			}
		if(error)
			{
			NSLog(@"Unable to load font file %@ (error=%d)", path, error);
			return nil;	// any error
			}
#if 0
		NSLog(@"  -> num faces=%lu", face->num_faces);
#endif
		numFaces=face->num_faces;
		psname=FT_Get_Postscript_Name(face);
		if(!psname)
			continue;	// we can handle fonts with postscript names only
		if(!FT_IS_SCALABLE(face))
			continue;	// must be scalable - FIXME: we could derive a NSFontSizeAttribute
		family=[NSString stringWithCString:face->family_name];
		if(!face->style_name || strcmp(face->style_name, "Regular") == 0)
			{ // style name N/A or "Regular"
			style=@"";
			name=family;
			}
		else
			{ // explicit style name available
			style=[NSString stringWithCString:face->style_name];
			name=[NSString stringWithFormat:@"%@-%@", family, style];	// build display name
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
		FT_Set_Pixel_Sizes(face, 0, 24);	// render approx. 24x24 pixels
		FT_Load_Glyph(face, FT_Get_Char_Index(face, 'x'), FT_LOAD_DEFAULT);	// draw a representative character
		cnt=face->glyph->bitmap.width*face->glyph->bitmap.rows;
		if(cnt)
			{
			lweight=0;
			while(cnt-- > 0)
				lweight+=face->glyph->bitmap.buffer[cnt];	// sum up all shaded values
			weight=(float)lweight/(255*face->glyph->bitmap.width*face->glyph->bitmap.rows);		// proportion of black and white pixels - this has to be scaled through all faces!
			}
		else
			weight=0.0;
#if 0
		NSLog(@"add font %lu [%lu] %@-%@ at %@", faceIndex, face->num_faces, family, style, path);
#endif
		postscriptName=[NSString stringWithCString:psname];
		fontRecord=[NSMutableDictionary dictionaryWithObjectsAndKeys:
			// official
			family, NSFontFamilyAttribute,
			style, NSFontFaceAttribute,
			postscriptName, NSFontNameAttribute,	// official name
			name, NSFontVisibleNameAttribute,	// display name
			[NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithUnsignedInt:traits], NSFontSymbolicTrait,
				[NSNumber numberWithFloat:weight], NSFontWeightTrait,	// -1.0 ... 1.0
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
	return family;
}

@end

@implementation NSBezierPath (Backend)

- (void) appendBezierPathWithGlyphs:(NSGlyph *)glyphs 
							  count:(int)count
							 inFont:(NSFont *)font
{
	FT_Face face=[(_NSX11Font *) font _face];
	NSFontRenderingMode renderingMode=[font renderingMode];
	FT_GlyphSlot slot = face->glyph;
	NSPoint pen = NSZeroPoint;
	NSAssert(face, @"can't convert font to Bezier Path");
	//	pen.y=[self ascender];	// one line down
	pen.y=(face->ascender+face->descender)>>6;
	while(count-- > 0)
		{ // render glyphs
		unsigned int i;
		FT_Error error = FT_Load_Glyph(face, *glyphs++, FT_LOAD_RENDER);	// CHECKME - do we really need to LOAD_RENDER?
		if(error)
			continue;
		for(i=0; i<slot->outline.n_contours; i++)
			{ // add contours to path
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
			 case 0:	// second order control point
				 break;
			 case 1:	// line to
				 [self lineTo: ];
				 break;
			 case 2: // third order control point
				 
			 case 3:	// error
				 break;
		 }
		 
		 An array of ‘n_contours’ shorts, giving the end point of each contour within the outline. For example, the first contour is defined by the points ‘0’ to ‘contours[0]’, the second one is defined by the points ‘contours[0]+1’ to ‘contours[1]’, etc.
		 
		 
		 flags	
		 A set of bit flags used to characterize the outline and give hints to the scan-converter and hinter on how to convert/grid-fit it. See FT_OUTLINE_FLAGS.
		 
		 FT_OUTLINE_EVEN_ODD_FILL
		 By default, outlines are filled using the non-zero winding rule. If set to 1, the outline will be filled using the even-odd fill rule (only works with the smooth raster).
		 
		 
		 */
			}
		
		if(renderingMode == NSFontAntialiasedIntegerAdvancementsRenderingMode)
			{ // a little faster but less accurate
			pen.x += slot->advance.x>>6;
			pen.y += slot->advance.y>>6;
			}
		else
			{ // needs 4 additional float operations per step
			pen.x += slot->linearHoriAdvance*(1.0/65536);
			// not reliable	- use FT_HAS_VERTICAL()		pen.y += slot->linearVertAdvance*(1.0/65536);
			}
		[self closePath];	// ??? and start new path for next glyph or is a moveTo: the start indicator.
		}
#if 1
	NSLog(@"path=%@", self);
#endif
}

- (void) appendBezierPathWithPackedGlyphs:(const char *)packedGlyphs
{
	NIMP;
}

@end

#endif

// EOF
