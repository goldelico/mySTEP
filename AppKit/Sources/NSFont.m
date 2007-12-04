/* 
   NSFont.m

   NSFont Backend

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:	Scott Christley
   Author:	Ovidiu Predescu <ovidiu@bx.logicnet.ro>
   Date: 	February 1997
   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date: 	May 1998
   Author:	Michael Hanni <mhanni@sprintmail.com>
   Date: 	August 1998

   Author:	Nikolaus Schaller <hns@computer.org>
   Date: 	2003-2007

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSUserDefaults.h>

#include <AppKit/NSFontManager.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSGraphicsContext.h>

#import "NSAppKitPrivate.h"
#import "NSBackendPrivate.h"

// Class variables

NSString *NSAntialiasThresholdChangedNotification=@"NSAntialiasThresholdChangedNotification";
NSString *NSFontSetChangedNotification=@"NSFontSetChangedNotification";

static NSFont *_getNSFont(NSString *key, NSString *defaultFontName, float size, float deflt)
{ // get system font (cached)
	NSUserDefaults *u = [NSUserDefaults standardUserDefaults];
	NSString *fontName = [u objectForKey:key];	// e.g. NSBoldFont=Helvetica
	static NSMutableDictionary *fcache;	// system font cache
	NSFont *f;
#if 0
	NSLog(@"_getFont %@ %lf (%@ %lf)", key, size, defaultFontName, deflt);
#endif
	if(!fontName)
		fontName = defaultFontName;
	if(size <= 0.0 || (size = [u floatForKey:[NSString stringWithFormat:@"%@Size", key]]) <= 0.0)	// e.g. NSBoldFontSize=12
		{
		size = deflt;   // substitute default
		if(size <= 0.0)
			size=[NSFont systemFontSize];	// final fallback if we still don't know better
		}
	key=[fontName stringByAppendingFormat:@"-%.1f", size];	// build cache key
	f=[fcache objectForKey:key];	// look into cache
	if(!f)
		{ // create new entry
#if 1
		NSLog(@"add font to cache: %@", key);
#endif
		f=[NSFont fontWithName:fontName size:size];
		if(f)
			{ // store in font cache
			if(!fcache)
				fcache=[[NSMutableDictionary alloc] initWithCapacity:20];	// there was no cache yet
			[fcache setObject:f forKey:key];
			}
		}
#if 0
	NSLog(@"_gotFont size=%f", size);
#endif
	return f;
}

//*****************************************************************************
//
// 		NSFont 
//
//*****************************************************************************

@implementation NSFont

+ (NSFont *) boldSystemFontOfSize:(float)fontSize
{												
	return _getNSFont(@"NSBoldFont", @"Helvetica-Bold", fontSize, [NSFont systemFontSize]);
}

+ (NSFont *) systemFontOfSize:(float)fontSize
{
	return _getNSFont(@"NSFont", @"Helvetica", fontSize, [NSFont systemFontSize]);
}

+ (NSFont *) titleBarFontOfSize:(float)fontSize;
{
	return _getNSFont(@"NSBoldFont", @"Helvetica-Bold", fontSize, [NSFont systemFontSize]);
}

+ (NSFont *) menuFontOfSize:(float)fontSize
{
	static float size= -1.0;	// cache for default font size
	if(size < 0.0)
		size=floor([NSMenuView menuBarHeight]*0.58+0.75);	// 16 -> 10; 20 -> 12; 24 -> 14;
	return _getNSFont(@"NSMenuFont", @"Helvetica", fontSize, size);
}

+ (NSFont *) menuBarFontOfSize:(float)fontSize
{
	static float size= -1.0;	// cache for default font size
	if(size <= 0.0)
		size=floor([NSMenuView menuBarHeight]*0.625+0.25);	// 16 -> 10; 24 -> 15;
	return _getNSFont(@"NSMenuBarFont", @"Helvetica", fontSize, size);
}

+ (NSFont *) toolTipsFontOfSize:(float)fontSize
{
	return _getNSFont(@"NSToolTipsFont", @"Helvetica", fontSize, [NSFont systemFontSize]);
}

+ (NSFont *) paletteFontOfSize:(float)fontSize
{
	return _getNSFont(@"NSFont", @"Helvetica", fontSize, [NSFont systemFontSize]);
}

+ (NSFont *) messageFontOfSize:(float)fontSize
{
	return _getNSFont(@"NSFont", @"Helvetica", fontSize, [NSFont systemFontSize]);
}

+ (NSFont *) labelFontOfSize:(float)fontSize
{
	return _getNSFont(@"NSFont", @"Helvetica", fontSize, [NSFont labelFontSize]);
}

+ (NSFont *) controlContentFontOfSize:(float)fontSize
{
	return _getNSFont (@"NSFont", @"Helvetica", fontSize, [NSFont systemFontSize]);
}

+ (NSFont *) userFixedPitchFontOfSize:(float)fontSize
{
	return _getNSFont (@"NSUserFixedPitchFont", @"Courier", fontSize, [NSFont systemFontSize]);
}

+ (NSFont *) userFontOfSize:(float)fontSize
{
	return _getNSFont (@"NSUserFont", @"Helvetica", fontSize, [NSFont systemFontSize]);
}

+ (float) systemFontSize;
{ // return default size of standard system font
	return 12;
}

+ (float) smallSystemFontSize;
{
	return 10.0;
}

+ (float) systemFontSizeForControlSize:(NSControlSize) size
{
	switch(size)
		{
		case NSRegularControlSize:
		default:					return 12;
		case NSSmallControlSize:	return 10;
		case NSMiniControlSize:		return 9;
		}
}

+ (float) labelFontSize;
{ // return default size of standard system font
	return 12;
}

// Set preferred user fonts
+ (void) setUserFixedPitchFont:(NSFont*)font
{												
	[[NSUserDefaults standardUserDefaults] setObject:[font fontName] 
										   forKey:@"NSUserFixedPitchFont"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void) setUserFont:(NSFont*)font
{
	[[NSUserDefaults standardUserDefaults] setObject:[font fontName] 
										   forKey:@"NSUserFont"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSFont *) fontWithDescriptor:(NSFontDescriptor *) descriptor size:(float) size;
{
	return [self fontWithDescriptor:descriptor size:size textTransform:nil];
}

// the transform/matrix can be used to rotate/scale/shear the whole font (independently of the CTM!)

+ (NSFont *) fontWithDescriptor:(NSFontDescriptor *) descriptor size:(float) size textTransform:(NSAffineTransform *) transform;
{ // change size first
	return [self fontWithDescriptor:[descriptor fontDescriptorWithSize:size] textTransform:transform];
}

+ (NSFont *) fontWithDescriptor:(NSFontDescriptor *) descriptor textTransform:(NSAffineTransform *) transform;
{
	if(transform)
		descriptor=[descriptor fontDescriptorByAddingAttributes:[NSDictionary dictionaryWithObject:transform forKey:NSFontMatrixAttribute]];
	descriptor=[descriptor matchingFontDescriptorWithMandatoryKeys:[NSSet setWithArray:[[descriptor fontAttributes] allKeys]]];	// match all keys
	if(!descriptor)
		return [NSFont fontWithName:@"Times" size:0.0];	// substitute a system default
	return [[[NSFont alloc] _initWithDescriptor:descriptor] autorelease];
}

+ (NSFont *) fontWithName:(NSString*) name matrix:(const float *) fontMatrix
{
	NSFontDescriptor *descriptor;
	NSAffineTransform *matrix=[NSAffineTransform transform];
	[matrix setTransformStruct:*(NSAffineTransformStruct *)&fontMatrix];
	descriptor=[NSFontDescriptor fontDescriptorWithName:name matrix:matrix];
	descriptor=[descriptor matchingFontDescriptorWithMandatoryKeys:[NSSet setWithArray:[[descriptor fontAttributes] allKeys]]];	// match all keys
	if(!descriptor)
		return nil;	// no matching font found
	return [[[NSFont alloc] _initWithDescriptor:descriptor] autorelease];
}

+ (NSFont *) fontWithName:(NSString*) name size:(float) size
{ // create a font without matrix
	NSFontDescriptor *descriptor;
	if(size == 0.0)
		// FIXME: the NSUserFont entry is just the font name!
		// size=[[[NSUserDefaults standardUserDefaults] objectForKey:@"NSUserFont"] pointSize];	// default
		size=12.0;
	descriptor=[NSFontDescriptor fontDescriptorWithName:name size:size];
	descriptor=[descriptor matchingFontDescriptorWithMandatoryKeys:[NSSet setWithArray:[[descriptor fontAttributes] allKeys]]];	// match all keys
	if(!descriptor)
		return nil;	// no matching font found
	return [[[NSFont alloc] _initWithDescriptor:descriptor] autorelease];
}

- (NSString *) fontName							{ return [_descriptor objectForKey:NSFontNameAttribute]; }

- (NSString *) familyName						{ return [_descriptor objectForKey:NSFontFamilyAttribute]; }

- (NSString *) displayName						{ return [_descriptor objectForKey:NSFontVisibleNameAttribute]; }

- (float) pointSize								{ return [_descriptor pointSize]; }	// effective vertical size

- (void) encodeWithCoder:(NSCoder *)aCoder
{														// NSCoding protocol
//	[aCoder encodeObject:_fontName];
//	[aCoder encodeArrayOfObjCType:"f" count:6 at:_matrix];
	NIMP;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
	if([aDecoder allowsKeyedCoding])
		{
		NSFont *r;
		float size=[aDecoder decodeFloatForKey:@"NSSize"];
		int fFlags=[aDecoder decodeIntForKey:@"NSfFlags"];	// renderingMode? denotes if a descriptor exists or not?
#if 0
		NSLog(@"%@ NSfFlags=%08x", self, [aDecoder decodeIntForKey:@"NSfFlags"]);
#endif
		[self release];
		r=[NSFont fontWithName:[aDecoder decodeObjectForKey:@"NSName"] size:size];	// fails if we don't have this font
		if(!r)
			r=[NSFont systemFontOfSize:size];	// substitute system font
		return [r retain];
		}
//	_fontName = [[aDecoder decodeObject] retain];
//	[aDecoder decodeArrayOfObjCType:"f" count:6 at:_matrix];
//	return self;
	return NIMP;
}

- (id) _initWithDescriptor:(NSFontDescriptor *) desc
{ // can beoverwritten by freetype backend
	if((self=[super init]))
		{
		_descriptor=[desc retain];
		_renderingMode=NSFontIntegerAdvancementsRenderingMode;	// default rendering mode
		}
	return self;
}

- (id) copyWithZone:(NSZone *)z
{
	NSFont *f=[isa allocWithZone:z];
	if(f)
		{
//		f->_fontName=[_fontName copyWithZone:z];
	//	memcpy(f->_matrix, _matrix, sizeof(_matrix));
		f->_descriptor=[_descriptor retain];
		f->_renderingMode=_renderingMode;
//		f->_backendPrivate=NULL;	// will be allocated on demand
		}
	return f;
}

- (NSString *) description;
{
//	return [NSString stringWithFormat:@"NSFont: %@", _descriptor];
	NSMutableString *str=[NSMutableString stringWithFormat:@"NSFont: %@ ", _descriptor];
#if 0
		[str appendFormat:@" advancement=%@", NSStringFromSize([self advancementForGlyph:100])];
		[str appendFormat:@" ascender=%f", [self ascender]];
		[str appendFormat:@" boundingRectForFont=%@", NSStringFromRect([self boundingRectForFont])];
		[str appendFormat:@" boundingRectForGlyph=%@", NSStringFromRect([self boundingRectForGlyph:100])];
		[str appendFormat:@" capHeight=%f", [self capHeight]];
		[str appendFormat:@" coveredCharacterSet=%@", [self coveredCharacterSet]];
		[str appendFormat:@" descender=%f", [self descender]];
#endif
		[str appendFormat:@" displayName=%@", [self displayName]];
		[str appendFormat:@" familyName=%@", [self familyName]];
		[str appendFormat:@" fontName=%@", [self fontName]];
#if 0
		[str appendFormat:@" isFixedPitch=%@", [self isFixedPitch]?@"YES":@"NO"];
		[str appendFormat:@" italicAngle=%f", [self italicAngle]];
		[str appendFormat:@" leading=%f", [self leading]];
		[str appendFormat:@" maximumAdvancement=%f", [self maximumAdvancement]];
		[str appendFormat:@" numberOfGlyphs=%d", [self numberOfGlyphs]];
#endif
		[str appendFormat:@" pointSize=%f", [self pointSize]];
#if 0
		[str appendFormat:@" postscriptName=%f", [_descriptor postscriptName]];
#endif
		[str appendFormat:@" renderingMode=%d", [self renderingMode]];
#if 0
		[str appendFormat:@" textTransform=%@", [self textTransform]];
		[str appendFormat:@" underlinePosition=%f", [self underlinePosition]];
		[str appendFormat:@" xHeight=%f", [self xHeight]];
#endif
		return str;
}

- (void) set
{
	[[NSGraphicsContext currentContext] _setFont:self];
}

- (void) setInContext:(NSGraphicsContext *) context;
{
	[context _setFont:self];
}

- (NSFont *) screenFont; { return [self screenFontWithRenderingMode:NSFontDefaultRenderingMode]; }

- (NSFont *) screenFontWithRenderingMode:(NSFontRenderingMode) mode;
{ // make it a screen font
	return BACKEND;
}

- (NSFont *) printerFont;
{ // make it a printer font
	return BACKEND;
}

- (NSFontDescriptor *) fontDescriptor; { return _descriptor; }

- (NSFontRenderingMode) renderingMode; { return _renderingMode; }

- (const float *) matrix;
{
	NSAffineTransform *m=[_descriptor matrix];
	static NSAffineTransformStruct matrix;
	if(m)
		matrix=[m transformStruct];
	else
		{ // get transformation
		float size=[self pointSize];
		matrix.m11=size;
		matrix.m22=size;
		}
	return (const float *) &matrix;	// is struct with 6 float elements
}

- (NSSize) advancementForGlyph:(NSGlyph)aGlyph;
{
	NSSize sizes[1];
	[self getAdvancements:sizes forGlyphs:&aGlyph count:1];
	return sizes[0];
}

- (NSRect) boundingRectForGlyph:(NSGlyph)aGlyph;
{
	NSRect rects[1];
	[self getBoundingRects:rects forGlyphs:&aGlyph count:1];
	return rects[0];
}

#pragma mark BACKEND

- (float) ascender; { BACKEND; return 0.0; }
- (NSRect) boundingRectForFont; { BACKEND; return NSZeroRect; }
- (float) capHeight; { BACKEND; return 0.0; }
- (NSCharacterSet *) coveredCharacterSet;  { return BACKEND; }
- (float) descender; { BACKEND; return 0.0; }

- (void) getAdvancements:(NSSizeArray) advancements
			   forGlyphs:(const NSGlyph *) glyphs
				   count:(unsigned) count; { BACKEND; }

- (void) getAdvancements:(NSSizeArray) advancements
		 forPackedGlyphs:(const void *) glyphs
				   count:(unsigned) count; { BACKEND; }

- (void) getBoundingRects:(NSRectArray) bounds
				forGlyphs:(const NSGlyph *) glyphs
					count:(unsigned) count; { BACKEND; }

- (NSGlyph) glyphWithName:(NSString *) name; { BACKEND; return NSNullGlyph; }

- (BOOL) isFixedPitch;	{ BACKEND; return NO; }

- (float) italicAngle; { BACKEND; return 0.0; }

- (float) leading; { BACKEND; return 0.0; }

- (NSSize) maximumAdvancement; { BACKEND; return NSZeroSize; }

- (NSStringEncoding) mostCompatibleStringEncoding; { BACKEND; return NSASCIIStringEncoding; }

- (unsigned) numberOfGlyphs; { BACKEND; return 0; }

- (NSAffineTransform *) textTransform; { return BACKEND; }

- (float) underlinePosition; { BACKEND; return 0.0; }

- (float) underlineThickness; { BACKEND; return 0.0; }

- (float) xHeight; { BACKEND; return 0.0; }

#pragma mark DEPRECATED

+ (NSArray *) preferredFontNames;	{ DEPRECATED; return nil; }
+ (void) setPreferredFontNames:(NSArray *) names;	{ DEPRECATED; }

+ (void) useFont:(NSString *)name
{ // should include font in PDF document
	DEPRECATED;
	[[self fontWithName:name size:12] set];	// just select
}

- (NSDictionary *) afmDictionary;	{ DEPRECATED; return nil; }
- (float) defaultLineHeightForFont;	{ DEPRECATED; return [self leading]; }
- (NSString *) encodingScheme;	{ DEPRECATED; return @"FontSpecificEncoding"; }
- (BOOL) glyphIsEncoded:(NSGlyph)aGlyph;	{ DEPRECATED; return NO; }
- (NSMultibyteGlyphPacking) glyphPacking;	{ DEPRECATED; return NSNativeShortGlyphPacking; }
- (BOOL) isBaseFont;	{ DEPRECATED; return NO; }
- (NSPoint) positionOfGlyph:(NSGlyph)curGlyph forCharacter:(unichar)character struckOverRect:(NSRect)rect;	 { DEPRECATED; return NSZeroPoint; }
- (NSPoint) positionOfGlyph:(NSGlyph)curGlyph precededByGlyph:(NSGlyph)prevGlyph isNominal:(BOOL *)nominal;	 { DEPRECATED; return NSZeroPoint; }
- (NSPoint) positionOfGlyph:(NSGlyph)curGlyph struckOverGlyph:(NSGlyph)prevGlyph metricExists:(BOOL *)flag;	 { DEPRECATED; return NSZeroPoint; }
- (NSPoint) positionOfGlyph:(NSGlyph)curGlyph struckOverRect:(NSRect)rect metricExists:(BOOL *)flag;	 { DEPRECATED; return NSZeroPoint; }
- (NSPoint) positionOfGlyph:(NSGlyph)curGlyph withRelation:(NSGlyphRelation)relation toBaseGlyph:(NSGlyph)otherGlyph totalAdvancement:(NSSizePointer)offset metricExists:(BOOL *)flag;  { DEPRECATED; return NSZeroPoint; }
- (int) positionsForCompositeSequence:(NSGlyph *) glyphs numberOfGlyphs:(int) number pointArray:(NSPointArray) points; { DEPRECATED; return 0; }

- (float) widthOfString:(NSString *) string
{ // calc the size of string in this font
	DEPRECATED;
	return [self _sizeOfString:string].width;	// ask backend
}

@end /* NSFont */

NSString *NSFontFamilyAttribute=@"Family";
NSString *NSFontNameAttribute=@"Name";
NSString *NSFontFaceAttribute=@"Face";
NSString *NSFontSizeAttribute=@"Size"; 
NSString *NSFontVisibleNameAttribute=@"VisibleName"; 
NSString *NSFontColorAttribute=@"Color";
NSString *NSFontMatrixAttribute=@"Matrix";
NSString *NSFontVariationAttribute=@"Variation";
NSString *NSFontCharacterSetAttribute=@"CharacterSet";
NSString *NSFontCascadeListAttribute=@"CascadeList";
NSString *NSFontTraitsAttribute=@"Traits";
NSString *NSFontFixedAdvanceAttribute=@"FixedAdvance";

NSString *NSFontSymbolicTrait=@"SymbolicTrait";
NSString *NSFontWeightTrait=@"WeightTrait";
NSString *NSFontWidthTrait=@"WidthTrait";
NSString *NSFontSlantTrait=@"SlantTrait";

NSString *NSFontVariationAxisIdentifierKey=@"VariationAxisIdentifier";
NSString *NSFontVariationAxisMinimumValueKey=@"VariationAxisMinimumValue";
NSString *NSFontVariationAxisMaximumValueKey=@"VariationAxisMaximumValue";
NSString *NSFontVariationAxisDefaultValueKey=@"VariationAxisDefaultValue";
NSString *NSFontVariationAxisNameKey=@"VariationAxisName";

@implementation NSFontDescriptor

+ (id) fontDescriptorWithFontAttributes:(NSDictionary *) attributes;
{
	return [[[self alloc] initWithFontAttributes:attributes] autorelease];
}

+ (id) fontDescriptorWithName:(NSString *) name matrix:(NSAffineTransform *) matrix;
{
	return [self fontDescriptorWithFontAttributes:
		[NSDictionary dictionaryWithObjectsAndKeys:
			name, NSFontNameAttribute,
			matrix, NSFontMatrixAttribute,
			nil]];
}

+ (id) fontDescriptorWithName:(NSString *) name size:(float) size;
{
	return [self fontDescriptorWithFontAttributes:
		[NSDictionary dictionaryWithObjectsAndKeys:
			name, NSFontNameAttribute,
			[NSString stringWithFormat:@"%f", size], NSFontSizeAttribute,
			nil]];
}

- (NSDictionary *) fontAttributes; { return _attributes; }

- (NSFontDescriptor *) fontDescriptorByAddingAttributes:(NSDictionary *) attributes;
{
	NSFontDescriptor *fd=[super copy];	// make a copy
	if(fd)
		{
		fd->_attributes=[_attributes mutableCopy];	// current attributes
		[(NSMutableDictionary *) fd->_attributes addEntriesFromDictionary:attributes];	// change
		}
	return fd;
}

- (NSFontDescriptor *) fontDescriptorWithFace:(NSString *) face;
{
	return [self fontDescriptorByAddingAttributes:[NSDictionary dictionaryWithObject:face forKey:NSFontFaceAttribute]];
}

- (NSFontDescriptor *) fontDescriptorWithFamily:(NSString *) family;
{
	return [self fontDescriptorByAddingAttributes:[NSDictionary dictionaryWithObject:family forKey:NSFontFamilyAttribute]];
}

- (NSFontDescriptor *) fontDescriptorWithMatrix:(NSAffineTransform *) matrix;
{
	return [self fontDescriptorByAddingAttributes:[NSDictionary dictionaryWithObject:matrix forKey:NSFontMatrixAttribute]];
}

- (NSFontDescriptor *) fontDescriptorWithSize:(float) size;
{
	return [self fontDescriptorByAddingAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:size] forKey:NSFontSizeAttribute]];
}

- (NSFontDescriptor *) fontDescriptorWithSymbolicTraits:(NSFontSymbolicTraits) traits;
{
	return [self fontDescriptorByAddingAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:traits] forKey:NSFontSymbolicTrait]];
}

- (id) initWithFontAttributes:(NSDictionary *) attributes;
{
	if((self=[super init]))
		{
		if(attributes)
			_attributes=[attributes retain];
		else
			_attributes=[[NSDictionary alloc] init];	// empty dictionary
		}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
	NIMP;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
	if(![aDecoder allowsKeyedCoding])
		NIMP;
	_attributes = [[aDecoder decodeObjectForKey:@"NSAttributes"] retain];
	return self;
}
	
- (void) dealloc;
{
	[_attributes release];
	[super dealloc];
}

- (id) copyWithZone:(NSZone *)z
{
	NSFontDescriptor *f=[isa allocWithZone:z];
	if(f)
		f->_attributes=[_attributes copyWithZone:z];
	return f;
}

#define FONT_CACHE	[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/com.quantum-step.mySTEP.NSFonts.plist"]

// the font cache is a NSDictionary indexed by Font Families
// each family contains NSDictionary indexed by Font Faces
// each Face has an entry "File" and and entry "FaceNumber"
// each Face can also have and entry "NSFontDescriptor" storing the attributes dictionary

// ?? how to handle duplicate Family-Faces? If there are two files and potentially two different FaceNumbers

/* shouldn't we organize the cache differently:

NSDictionary -> NSDictionary -> NSArray -> Record
attribute    -> value        -> index

i.e. [cache valueForKeyPath:@"name.Helvetica.7"] would return the 7-th Helvetica entry

then, searching by a keyset is getting/filtering all these indexes and finding the common ones


match:
  loop through keys
  get cache.key
  get array indexed by _attributes
  if(first key)
     take as result
  else
	 remvoe from current result all entries not in our array

*/

static NSMutableDictionary *cache;
static BOOL changed;

+ (NSDictionary *) _fonts;
{
	if(!cache)
		{
#if 1
		NSLog(@"read font cache");
#endif
		cache=[[NSMutableDictionary alloc] initWithContentsOfFile:FONT_CACHE];
		if(!cache)
			{
			cache=[[NSMutableDictionary alloc] initWithCapacity:10];	// empty cache
			[self _findFonts];
			}
		}
	if(changed)
		{
		NSString *error;
#if 1
		NSLog(@"write font cache %@", cache);
#endif
		if(![[NSPropertyListSerialization dataFromPropertyList:cache format:NSPropertyListBinaryFormat_v1_0 errorDescription:&error] writeToFile:FONT_CACHE atomically:YES])
			[NSException raise:NSGenericException format:@"Can't write font cache: %@", FONT_CACHE];
		changed=NO;
		}
	return cache;
}

+ (void) _addDescriptor:(NSDictionary *) record;
{ // add a system record that helps to find the font file
	NSEnumerator *e=[record keyEnumerator];
	NSString *key;
	while((key=[e nextObject]))
		{ // add indexes for all attributes
		id val=[record objectForKey:key];
		NSMutableDictionary *index=[cache objectForKey:key];
		NSMutableArray *list=nil;
		if(!index)
			[cache setObject:(index=[NSMutableDictionary dictionaryWithCapacity:20]) forKey:key];
		else
			list=[index objectForKey:val];	// is there already an index entry?
		if(!list)
			[index setObject:[NSMutableArray arrayWithObject:record] forKey:val];	// first entry
		else
			[list addObject:record];	// add to cache
		}
	changed=YES;
}

+ (void) _findFonts;
{
	return;		// Backend override
}

- (NSArray *) matchingFontDescriptorsWithMandatoryKeys:(NSSet *) keys;
{ // this is the core font search engine that knows about font directories
	NSMutableArray *r=[NSArray array];
	NSDictionary *fonts=[isa _fonts];
	if([keys containsObject:NSFontNameAttribute])
		{ // match by name
		r=[[fonts objectForKey:NSFontNameAttribute] objectForKey:[_attributes objectForKey:NSFontNameAttribute]]; 
		}
	if([keys containsObject:@"Size"])
		{ // specific size
		}
	// search all fonts we know
	// FIXME: filter by matching attributes
	// returns array of matching font descriptors!
	return r;
}

- (NSFontDescriptor *) matchingFontDescriptorWithMandatoryKeys:(NSSet *) keys;
{
	NSArray *r=[self matchingFontDescriptorsWithMandatoryKeys:keys];
	if([r count])
		return [r objectAtIndex:0];
	return nil;
}

- (NSAffineTransform *) matrix; { return [_attributes objectForKey:NSFontMatrixAttribute]; }
- (id) objectForKey:(NSString *) attribute; { return [_attributes objectForKey:attribute]; }
- (float) pointSize; { return [[_attributes objectForKey:NSFontSizeAttribute] floatValue]; }
- (NSFontSymbolicTraits) symbolicTraits; { return [[_attributes objectForKey:NSFontSymbolicTrait] unsignedIntValue]; }

- (NSString *) postscriptName;
{
	NSMutableString *family=[[[self objectForKey:NSFontFamilyAttribute] mutableCopy] autorelease];
	NSString *face=[self objectForKey:NSFontFaceAttribute];
	[family replaceOccurrencesOfString:@" " withString:@"" options:0 range:NSMakeRange(0, [family length])];
	if([face isEqualToString:@"Regular"])
		return family;
	return [NSString stringWithFormat:@"%@-%@", family, face];
}

@end
