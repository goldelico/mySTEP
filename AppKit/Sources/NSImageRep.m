/* 
 NSImageRep.m
 
 Image representaions NSCachedImageRep NSCustomImageRep NSBitmapImageRep
 
 Copyright (C) 1996 Free Software Foundation, Inc.
 
 Author:  Adam Fedor <fedor@colorado.edu>
 Date: 	Feb 1996
 Author:  Felipe A. Rodriguez <farz@mindspring.com>
 Date: 	March 1999
 Author:  H. Nikolaus Schaller <hns@computer.org>
 Date: 	March 2006
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#import <tiff.h>
#import <tiffio.h>

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSException.h>
#import <Foundation/NSNotification.h>

#import <AppKit/NSColor.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSGraphicsContext.h>
#import <AppKit/NSImageRep.h>
#import <AppKit/NSBitmapImageRep.h>
#import <AppKit/NSCachedImageRep.h>
#import <AppKit/NSCustomImageRep.h>
#import <AppKit/NSPasteboard.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSView.h>
#import <AppKit/NSAffineTransform.h>

#import "NSBackendPrivate.h"

// Class variables
static NSMutableArray *__imageRepClasses;
static NSArray *__types = nil;
static NSArray *__pbTypes = nil;
static NSCountedSet *__img;
static NSCountedSet *__pb;


//*****************************************************************************
//
// 		NSImageRep 
//
//*****************************************************************************

// forward declarations
@interface GSBitmapImageRepPNG : NSBitmapImageRep; @end
@interface GSBitmapImageRepGIF : NSBitmapImageRep; @end
@interface GSBitmapImageRepJPEG : NSBitmapImageRep; @end
@interface GSBitmapImageRepICNS : NSBitmapImageRep; @end

@implementation NSImageRep

// initialize for imageRep subclasses defined in GSBitmapImageReps.m

+ (void) initialize	
{ // in practice only one of them can load in data from a given external source
	if(self == [NSImageRep class])
		{ // not if we initialize a subclass
		__imageRepClasses = [[NSMutableArray alloc] initWithCapacity: 2];
		__img = [NSCountedSet new];
		__pb = [NSCountedSet new];
		
		// make GSBitmapImageReps register themselves as additional classes (they are not initialized automatically!)
#if 0
		NSLog(@"NSImageRep initialize");
#endif
		[NSBitmapImageRep version];	// handles TIFF
		[GSBitmapImageRepICNS version];
		[GSBitmapImageRepPNG version];
		[GSBitmapImageRepGIF version];
		[GSBitmapImageRepJPEG version];
		}
}

+ (BOOL) canInitWithData:(NSData *)data			{ SUBCLASS; return NO; }
+ (BOOL) canInitWithPasteboard:(NSPasteboard*)p { SUBCLASS; return NO; }
+ (NSArray *) imageUnfilteredFileTypes			{ return [self imageFileTypes]; }
+ (NSArray *) imageUnfilteredPasteboardTypes	{  return [self imagePasteboardTypes]; }

+ (NSArray *) imageFileTypes					
{
	return (__types) ? __types : (__types = [[__img allObjects] retain]);
}

+ (NSArray *) imagePasteboardTypes
{
	return (__pbTypes) ? __pbTypes : (__pbTypes = [[__pb allObjects] retain]);
}

+ (NSArray *) registeredImageRepClasses			
{ 
	return (NSArray*)__imageRepClasses;
}

+ (void) registerImageRepClass:(Class)imageRepClass
{
#if 1
	NSLog(@" register %@", [imageRepClass description]);
#endif
	NSDebugLog(@" register %@", [imageRepClass description]);
	if (![imageRepClass respondsToSelector: @selector(imageFileTypes)])
		[NSException raise: NSInvalidArgumentException
					format: @"imageRep %@ does not respond to imageFileTypes", NSStringFromClass(imageRepClass)];
	
	[__imageRepClasses addObject: imageRepClass];
	[__img addObjectsFromArray: [imageRepClass imageUnfilteredFileTypes]];
	[__pb addObjectsFromArray: [imageRepClass imageUnfilteredPasteboardTypes]];
	ASSIGN(__types, nil);						// regenerate types on next access 
	ASSIGN(__pbTypes, nil);
}

+ (void) unregisterImageRepClass:(Class)imageRepClass
{
	[__imageRepClasses removeObject: imageRepClass];
	ASSIGN(__types, nil);						// recache types on next access 
	ASSIGN(__pbTypes, nil);
	[[NSNotificationCenter defaultCenter] postNotificationName:NSImageRepRegistryChangedNotification 
						object: self];
}

+ (id) imageRepWithContentsOfFile:(NSString *)filename
{ // Creating an NSImageRep
	NSArray *array = [self imageRepsWithContentsOfFile: filename];
	
	return ([array count]) ? [array objectAtIndex: 0] : nil;	// return first
}

// CHECKME: can we cache the image reps???
// this would only create a problem if we save an image rep to a file and then reload
// or expect that an externally changed file can be immediately seen when loading again.
// but since we don't known when the file is overwriten we should probably clear the cache by a timer

+ (NSArray *) imageRepsWithContentsOfFile:(NSString *)filename
{
	NSString *ext = [filename pathExtension];
	Class rep;
	
	if (ext && (rep = [self imageRepClassForFileType: ext]))
		{
		NSData *data = [NSData dataWithContentsOfFile: filename];
		if(!data)
			return nil;	// can't open
		if([rep respondsToSelector: @selector(imageRepsWithData:)])
			return [rep imageRepsWithData: data];
		else if ([rep respondsToSelector: @selector(imageRepWithData:)])
			return [NSArray arrayWithObject:[rep imageRepWithData:data]];
		}
	
	return nil;
}

+ (id) imageRepWithPasteboard:(NSPasteboard *)pasteboard
{
	NSArray *array = [self imageRepsWithPasteboard: pasteboard];
	
	return ([array count]) ? [array objectAtIndex: 0] : nil;
}

+ (NSArray *) imageRepsWithPasteboard:(NSPasteboard *)pasteboard
{
	NSInteger i, count = [__imageRepClasses count];
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:1];
	
	for (i = 0; i < count; i++)
		{
		NSString *t;
		Class rep = [__imageRepClasses objectAtIndex: i];
		
		if ([rep respondsToSelector: @selector(imagePasteboardTypes)] && 
			(t=[pasteboard availableTypeFromArray:[rep imagePasteboardTypes]]))
			{
			NSData *data = [pasteboard dataForType: t];
			
			if ([rep respondsToSelector: @selector(imageRepsWithData:)])
				[array addObjectsFromArray: [rep imageRepsWithData: data]];
			else 
				if ([rep respondsToSelector: @selector(imageRepWithData:)])
					[array addObject: [rep imageRepWithData: data]];
			}	}
	
	return (NSArray *)array;
}

+ (Class) imageRepClassForData:(NSData *)data
{
	NSInteger i, count = [__imageRepClasses count];
	Class rep;
	
	for (i = 0; i < count; i++)
		if([(rep = [__imageRepClasses objectAtIndex: i]) canInitWithData:data])
			return rep;
	
	return Nil;
}

+ (Class) imageRepClassForFileType:(NSString *)type
{
	NSInteger i, count = [__imageRepClasses count];
	
	for (i = 0; i < count; i++)
		{
		Class rep = [__imageRepClasses objectAtIndex: i];
		
		if ([[rep imageUnfilteredFileTypes] indexOfObject:type] != NSNotFound)
			return rep;
		}
	
	return Nil;
}

+ (Class) imageRepClassForPasteboardType:(NSString *)type
{
	NSInteger i, count = [__imageRepClasses count];
	
	for (i = 0; i < count; i++)
		{
		Class rep = [__imageRepClasses objectAtIndex: i];
		
		if ([rep respondsToSelector: @selector(imagePasteboardTypes)]
			&& [[rep imagePasteboardTypes] indexOfObject: type] != NSNotFound)
			return rep;
		}
	
	return Nil;
}

- (void) dealloc
{
	[_colorSpace release];
	[super dealloc];
}

- (NSSize) size									{ return _size; }
- (void) setSize:(NSSize)aSize					{ _size = aSize; }
- (void) setAlpha:(BOOL)flag					{ _irep.hasAlpha = flag; }
- (BOOL) hasAlpha								{ return _irep.hasAlpha; }
- (BOOL) isOpaque								{ return _irep.isOpaque; }
- (void) setOpaque:(BOOL)flag					{ _irep.isOpaque = flag; }
- (void) setPixelsWide:(NSInteger)anInt				{ _pixelsWide = anInt; }
- (void) setPixelsHigh:(NSInteger)anInt				{ _pixelsHigh = anInt; }
- (void) setBitsPerSample:(NSInteger)anInt			{ _irep.bitsPerSample = (unsigned int) anInt;}
- (NSInteger) pixelsWide								{ return _pixelsWide; }
- (NSInteger) pixelsHigh								{ return _pixelsHigh; }
- (NSInteger) bitsPerSample							{ return _irep.bitsPerSample; }
- (NSString *) colorSpaceName					{ return _colorSpace; }
- (void) setColorSpaceName:(NSString *)aString	{ ASSIGN(_colorSpace,aString);}

- (BOOL) draw { return NO; } // default

- (BOOL) drawAtPoint:(NSPoint)aPoint
{ // draw translated
	if(aPoint.x == 0.0 && aPoint.y == 0.0)
		return [self draw];
	else
		{ // translate
		BOOL r;
		NSGraphicsContext *ctx=[NSGraphicsContext currentContext];
		NSAffineTransform *atm=[NSAffineTransform transform];
		[ctx saveGraphicsState];
		[atm translateXBy:aPoint.x yBy:aPoint.y];
		[atm concat];	// modify CTM as needed
		r=[self draw];
		[ctx restoreGraphicsState];
		return r;
		}
}

- (BOOL) drawInRect:(NSRect)aRect
{ // draw translated and scaled to rect
	BOOL r;
	NSGraphicsContext *ctx=[NSGraphicsContext currentContext];
	NSAffineTransform *atm=[NSAffineTransform transform];
	[ctx saveGraphicsState];
	[atm translateXBy:aRect.origin.x yBy:aRect.origin.y];
	if(!NSEqualSizes(aRect.size, _size))
		[atm scaleXBy:aRect.size.width/_size.width yBy:aRect.size.height/_size.height];	// scale to rect
	[atm concat];	// modify CTM as needed
	r=[self draw];
	[ctx restoreGraphicsState];
	return r;
}

- (id) copyWithZone:(NSZone *) zone;
{
	NSImageRep *copy = (NSImageRep*)[[self class] allocWithZone:zone];
	if(copy)
		{
		copy->_size = _size;
		copy->_irep = _irep;
		copy->_pixelsWide = _pixelsWide;
		copy->_pixelsHigh = _pixelsHigh;
		copy->_colorSpace = [_colorSpace retain];
		}
	return copy;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{														// NSCoding protocol
	[aCoder encodeObject: _colorSpace];
	[aCoder encodeSize: _size];
	[aCoder encodeValueOfObjCType: @encode(unsigned int) at: &_irep];
	[aCoder encodeValueOfObjCType: @encode(int) at: &_pixelsWide];
	[aCoder encodeValueOfObjCType: @encode(int) at: &_pixelsHigh];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
	if([aDecoder allowsKeyedCoding])
		{
		NSData *data=[aDecoder decodeObjectForKey:@"NSTIFFRepresentation"];
		[self release];
		return [[NSBitmapImageRep alloc] initWithData:data];
		}
	_colorSpace = [[aDecoder decodeObject] retain];
	_size = [aDecoder decodeSize];
	[aDecoder decodeValueOfObjCType:@encode(unsigned int) at: &_irep];
	[aDecoder decodeValueOfObjCType: @encode(int) at: &_pixelsWide];
	[aDecoder decodeValueOfObjCType: @encode(int) at: &_pixelsHigh];
	
	return self;
}

@end /* NSImageRep */

//*****************************************************************************
//
// 		NSCachedImageRep -- maintain an image rep in an off screen window
//
//*****************************************************************************

@implementation NSCachedImageRep

- (id) initWithSize:(NSSize)aSize
			  depth:(NSWindowDepth)aDepth
		   separate:(BOOL)separate
			  alpha:(BOOL)alpha
{
	NSWindow *share=nil;
	NSRect rect={ NSZeroPoint, aSize };
	if(!separate)
		{
		// locate an empty area in the shared window that is large enough
		}
	if((self=[self initWithWindow:share rect:rect]))
		{
		_irep.hasAlpha = alpha;
		[_window setDepthLimit:aDepth];
		}
	return self;
}

- (id) initWithWindow:(NSWindow *)win rect:(NSRect)rect
{
	if((self=[super init]))
		{
		if(NSIsEmptyRect(rect))
			{
			if(!_window)
				[NSException raise: NSInvalidArgumentException
							format: @"NSCachedImageRep window and rect are both nil"];		
			_size = [_window frame].size;
			}
		else
			{
			_origin = rect.origin;
			_size = rect.size;
			}	
		if (win)
			_window = [win retain];	// use given window
		else
			_window = [[NSWindow alloc] initWithContentRect: rect
												  styleMask: NSBorderlessWindowMask | NSUnscaledWindowMask
													backing: NSBackingStoreBuffered
													  defer: YES];	// dont't draw or orderFront
#if 0	// makes problem when drawing glyphs!?!
		{ // show cache window */
			[_window setReleasedWhenClosed:NO];	// just be sure...
			[_window close];
			[_window release];
			_window = [[NSWindow alloc] initWithContentRect: rect
												  styleMask: NSTitledWindowMask
													backing: NSBackingStoreBuffered
													  defer: YES];	// dont't draw or orderFront now
			[_window setTitle:@"CachedImageRep"];
			[_window orderFront:nil];
		}
#endif
#if 0	// makes problem when drawing glyphs!?!
		[_window _allocateGraphicsContext];
		[[_window graphicsContext] _setScale:1.0];	// don't scale
#endif
		}
	return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
	self=[super initWithCoder:aDecoder];
	if([aDecoder allowsKeyedCoding])
		{
		BOOL isPlanar=[aDecoder decodeBoolForKey:@"NSCacheWindowIsPlanar"];
		int bitsPerPlane=[aDecoder decodeBoolForKey:@"NSCacheWindowBPP"];
		int bitsPerS=[aDecoder decodeBoolForKey:@"NSCacheWindowBPS"];
		id colorSpace=[aDecoder decodeObjectForKey:@"NSCacheWindowColorSpace"];
		/* create in cache window and store self (which is now an NSBitmapImageRep) */
		NSLog(@"*** should create cached image rep ***");
		return self;
		}
	return NIMP;
}

- (id) copyWithZone:(NSZone *) zone;
{
	NSCachedImageRep *copy = (NSCachedImageRep*)[super copyWithZone:zone];
	if(copy)
		{
		copy->_window = [_window retain];
		copy->_origin = _origin;
		}
	return copy;
}

- (void) dealloc
{
	[_window release];
	[super dealloc];
}

- (NSRect) rect								{ return (NSRect){_origin, _size}; }
- (NSWindow *) window						{ return _window; }

- (BOOL) draw
{
	BOOL r;
	NSGraphicsContext *ctx=[NSGraphicsContext currentContext];
	NSAffineTransform *atm=[NSAffineTransform transform];
	[ctx saveGraphicsState];
	[atm scaleXBy:_size.width yBy:_size.height];
	[atm concat];
	// [ctx _setFraction:1.0];
	r=[ctx _draw:self];
	[ctx restoreGraphicsState];
	return r;
}

@end /* NSCachedImageRep */

	//*****************************************************************************
	//
	// 		NSCustomImageRep 
	//
	//*****************************************************************************

@implementation NSCustomImageRep

- (id) initWithDrawSelector:(SEL)aSelector delegate:(id)anObject
{
	if((self=[super init]))
		{
		_delegate = [anObject retain];
		_selector = aSelector;
		}
	return self;
}

- (id) copyWithZone:(NSZone *) zone;
{
	NSCustomImageRep *copy = (NSCustomImageRep*)[super copyWithZone:zone];
	if(copy)
		{
		copy->_delegate = [_delegate retain];
		copy->_selector = _selector;
		}
	return copy;
}

- (void) dealloc
{
	[_delegate release];
	[super dealloc];
}

- (id) delegate							{ return _delegate; }
- (SEL) drawSelector					{ return _selector; }

- (BOOL) draw
{
	// FIXME: we should use the IMP mechanism to properly get the BOOL return value!!!
	return ([_delegate performSelector: _selector]) ? YES : NO;
}

@end /* NSCustomImageRep */


//*****************************************************************************
//
//		NSBitmapImageRep natively understands TIFF
// 		Private tiff functions and structures (read/write data from libtiff)
//		see e.g. http://www.squarebox.co.uk/cgi-squarebox/manServer/libtiff.3T
//
//*****************************************************************************

#define MAX_PLANES 5							// Maximum number of planes

typedef struct {								// Structure to store common 
    u_long  imageNumber;						// information about a tiff.
    u_long  subfileType;
    u_long  width;
    u_long  height;
    u_short bitsPerSample;		// number of bits per data channel
    u_short samplesPerPixel;	// number of channels per pixel
    u_short planarConfig;		// meshed or separate
    u_short photoInterp;		// photometric interpretation of bitmap data
	NSString *space;
    u_short compression;
    int     numImages;			// number of images in tiff
    int     error;
} NSTiffInfo; 

typedef struct {
    u_int size;
    u_short *red;
    u_short *green;
    u_short *blue;
} NSTiffColormap;

typedef struct {
	char *data;
	long size;
	long position;
	const char *mode;
	
} chandle_t;

static tsize_t
TiffHandleRead(thandle_t handle, tdata_t buf, tsize_t count)
{
	chandle_t *chand = (chandle_t *)handle;
	
	NSDebugLog (@"TiffHandleRead\n");
	if (chand->position >= chand->size)
		return 0;
	if (chand->position + count > chand->size)
		count = chand->size - chand->position;
	memcpy(buf, chand->data + chand->position, count);
	
	return count;
}

static tsize_t
TiffHandleWrite(thandle_t handle, tdata_t buf, tsize_t count)
{
	chandle_t *chand = (chandle_t *)handle;
	
	NSDebugLog (@"TiffHandleWrite\n");
	if (strcmp(chand->mode, "r") == 0 || (chand->position + count > chand->size))
		return 0;
	memcpy(chand->data + chand->position, buf, count);
	
	return count;
}

static toff_t
TiffHandleSeek(thandle_t handle, toff_t offset, int mode)
{
	chandle_t *chand = (chandle_t *)handle;
	
	NSDebugLog (@"TiffHandleSeek\n");
	switch(mode) 
		{
		case SEEK_SET: chand->position = offset;  break;
		case SEEK_CUR: chand->position += offset; break;
		case SEEK_END: 
			if (offset > 0 && strcmp(chand->mode, "r") == 0)
				return 0;
			chand->position += offset; 
			break;
		}
	
	return chand->position;
}

static int
TiffHandleClose(thandle_t handle)
{
	NSDebugLog (@"TiffHandleClose\n");
	free((chandle_t *)handle);
	
	return 0;
}

static toff_t
TiffHandleSize(thandle_t handle)	{ return ((chandle_t *)handle)->size; }

static void
TiffHandleUnmap(thandle_t handle, tdata_t data, toff_t size)			{}

static int
TiffHandleMap(thandle_t handle, tdata_t *data, toff_t *size)
{
	chandle_t *chand = (chandle_t *)handle;
	
	NSDebugLog (@"TiffHandleMap\n");
	*data = chand->data;
	*size = chand->size;
	
	return 1;
}

static void GSTiffWarningHandler(const char* module, const char* fmt, va_list ap)
{
	NSString *str=[[NSString alloc] initWithFormat:[NSString stringWithUTF8String:fmt] arguments:ap];
	NSLog(@"NSBitmapImageRep TIFF: %@", str);
	[str release];
}

TIFF * 
GSTiffOpenData(char *data, long size, const char *mode)
{												// Open a tiff from a stream. 
	chandle_t *handle;								// Returns NULL if can't read 
													// the tiff info.
	NSDebugLog (@"GSTiffOpenData\n");
	if (!(handle = malloc(sizeof(*handle))))
		return NULL;
	handle->data = data;
	handle->position = 0;
	handle->size = size;
	handle->mode = mode;
	
//	typedef void (*TIFFWarningHandler)(const char* module, const char* fmt, va_list ap); 

	TIFFSetWarningHandler(GSTiffWarningHandler);
	
	return TIFFClientOpen("NSBitmapImageRep", mode, (thandle_t)handle, TiffHandleRead, 
						  TiffHandleWrite, TiffHandleSeek, TiffHandleClose,
						  TiffHandleSize, TiffHandleMap, TiffHandleUnmap);
}

NSTiffInfo *      
GSTiffGetInfo(int imageNumber, TIFF *image)			// Read some information 
{													// about the image. Note 
	NSTiffInfo *info;									// that currently we don't
														// determine numImages.
	if (imageNumber >= 0 && !TIFFSetDirectory(image, imageNumber)) 
		return NULL;
	if (!(info = calloc(1, sizeof(*info))))
		return NULL;
	if (imageNumber >= 0)
		info->imageNumber = imageNumber;
	
	TIFFGetField(image, TIFFTAG_IMAGEWIDTH,  &info->width);
	TIFFGetField(image, TIFFTAG_IMAGELENGTH, &info->height);
	TIFFGetField(image, TIFFTAG_COMPRESSION, &info->compression);
	TIFFGetField(image, TIFFTAG_SUBFILETYPE, &info->subfileType);
	
	// If any tags are missing use TIFF defaults
	TIFFGetFieldDefaulted(image, TIFFTAG_BITSPERSAMPLE, &info->bitsPerSample);
	TIFFGetFieldDefaulted(image,TIFFTAG_SAMPLESPERPIXEL,&info->samplesPerPixel);	TIFFGetFieldDefaulted(image, TIFFTAG_PLANARCONFIG, &info->planarConfig);
	
	if (!TIFFGetField(image, TIFFTAG_PHOTOMETRIC, &info->photoInterp)) 
		{									// If TIFFTAG_PHOTOMETRIC is not 
		switch (info->samplesPerPixel) 		// present then assign a reasonable 
			{								// default. TIFF 5.0 spec doesn't 
			case 1:							// give a default.
				info->photoInterp = PHOTOMETRIC_MINISBLACK; break;
			case 3: 
			case 4:
				info->photoInterp = PHOTOMETRIC_RGB; break;
			default:
				TIFFError(TIFFFileName(image),
						  "Missing needed \"PhotometricInterpretation\" tag");
				return (0);
			}
		TIFFError(TIFFFileName(image),
				  "No \"PhotometricInterpretation\" tag, assuming %s\n",
				  info->photoInterp == PHOTOMETRIC_RGB ? "RGB" : "min-is-black");
		}
	// 8-bit RGB will be converted to 24-bit by 
	switch(info->photoInterp) 		// the tiff routines, so account for this.
		{
		case PHOTOMETRIC_MINISBLACK: 
			info->space = NSDeviceWhiteColorSpace; break;
		case PHOTOMETRIC_MINISWHITE: 
			info->space = NSDeviceBlackColorSpace; break;
		case PHOTOMETRIC_RGB: 		 
			info->space = NSCalibratedRGBColorSpace;   break;
		case PHOTOMETRIC_PALETTE: 
			info->space = NSCalibratedRGBColorSpace; 
			info->samplesPerPixel = 3;
		default:
			break;
		}
	
	return info;
}

NSTiffColormap *							// Gets the colormap for the image 
GSTiffGetColormap(TIFF *tif)				// if there is one. Returns a
{											// NSTiffColormap if one was found.
	register int i;
	NSTiffInfo *info = GSTiffGetInfo(-1, tif);	// Re-read the tiff info.  Pass -1
	int colorMapSize = 8;						// as the image number which means
	NSTiffColormap *map;						// just read the current image.
	
	if (info->photoInterp != PHOTOMETRIC_PALETTE)
		return NULL;
	
    if (!(map = malloc(sizeof(*map))))
		return NULL;
	map->size = 1 << info->bitsPerSample;
	
	if (!TIFFGetField(tif,TIFFTAG_COLORMAP,&map->red,&map->green,&map->blue)) 
		{
		TIFFError(TIFFFileName(tif), "Missing required \"Colormap\" tag");
		free(map);
		
		return NULL;
		}
	
	for (i = 0; i < map->size; i++)	
		if((map->red[i] > 255) ||(map->green[i] > 255) || (map->blue[i] > 255))
			{
			colorMapSize = 16;				// Many programs get TIFF colormaps 
			break;							// wrong.  They use 8-bit colormaps 
			}								// instead of 16-bit colormaps.  
											// This is a heuristic to detect 
			if (colorMapSize == 8)					// and correct this.
				{
				TIFFWarning(TIFFFileName(tif), "Assuming 8-bit colormap");
				for (i = 0; i < map->size; i++) 
					{
					map->red[i] = ((map->red[i] * 255) / ((1L << 16) - 1));
					map->green[i] = ((map->green[i] * 255) / ((1L << 16) - 1));
					map->blue[i] = ((map->blue[i] * 255) / ((1L << 16) - 1));
					}	}
			
			free(info);
	
	return map;
}

int
GSTiffRead(TIFF *tif, NSTiffInfo *info, char *data)
{
	u_char *outp = (u_char *)data;
	int i, row, col, sl_size;	// Read a tiff into a data array. The data array
	u_char *buf;				// is assumed to have been allocated to the correct
								// size.  Note that palette images are implicitly
	if (data == NULL)		// coverted to 24-bit contig direct color images.
		return -1;			// Data array should be large enough to hold this.
	
    if (!(buf = (u_char *) malloc((sl_size = (int) TIFFScanlineSize(tif)))))
		return -1;
	
	switch (info->photoInterp) 
		{
		case PHOTOMETRIC_MINISBLACK:
		case PHOTOMETRIC_MINISWHITE:
			if (info->planarConfig == PLANARCONFIG_CONTIG)
				{
				for (row = 0; row < info->height; row++) 
					{
					if (TIFFReadScanline(tif, outp, row, 0) < 0)
						{
						NSLog(@"tiff: line %d bad data\n", row);
						return 1;
						}
					outp += sl_size;
					}	}
			else 
				{
				for (i = 0; i < info->samplesPerPixel; i++)
					{
					for (row = 0; row < info->height; row++) 
						{
						if (TIFFReadScanline(tif, buf, row, i) < 0)
							{
							NSLog(@"tiff: line %d bad data\n", row);
							return 1;
							}
						
						for (col = 0; col < sl_size; col++)
							{
							*outp = *(buf + col);
							outp += info->samplesPerPixel;
							}	}
					
					outp = (u_char *)data + i + 1;
					}	}
			break;
			
		case PHOTOMETRIC_PALETTE:
			{
				NSTiffColormap *map;
				u_char *inp;
				
				if (!(map = GSTiffGetColormap(tif)))
					return -1;
				
				for (row = 0; row < info->height; ++row) 
					{
					if (TIFFReadScanline(tif, buf, row, 0) < 0)
						{
						NSLog(@"tiff: line %d bad data\n", row);
						return 1;
						}
					for (inp = buf, col = 0; col < info->width; col++) 
						{
						*outp++ = map->red[*inp] / 256;
						*outp++ = map->green[*inp] / 256;
						*outp++ = map->blue[*inp] / 256;
						inp++;
						}	}
				
				free(map->red);
				free(map->green);
				free(map->blue);
				free(map);
			}
			break;
			
		case PHOTOMETRIC_RGB:
			if (info->planarConfig == PLANARCONFIG_CONTIG) 
				{
				for (row = 0; row < info->height; row++) 
					{
					if (TIFFReadScanline(tif, outp, row, 0) < 0)
						{
						NSLog(@"tiff: line %d bad data\n", row);
						return 1;
						}
					outp += sl_size;
					}	}
			else 
				{
				for (i = 0; i < info->samplesPerPixel; i++)
					{
					for (row = 0; row < info->height; row++) 
						{
						if (TIFFReadScanline(tif, buf, row, i) < 0)
							{
							NSLog(@"tiff: line %d bad data\n", row);
							return 1;
							}
						
						for (col = 0; col < sl_size; col++)
							{
							*outp = *(buf + col);
							outp += info->samplesPerPixel;
							}	}
					
					outp = (u_char *)data + i + 1;
					}	}
			break;
			
		default:
			TIFFError(TIFFFileName(tif), "unknown photometric %d\n",
					  info->photoInterp);
			break;
		}
	
	free (buf);
	
	return 0;
}


//*****************************************************************************
//
// 		NSBitmapImageRep 
//
//*****************************************************************************

@implementation NSBitmapImageRep 

// BitmapImageRep Class variables
static NSArray *__bitmapImageReps;
static NSArray *__pbBitmapImageReps;

+ (void) initialize
{
	__bitmapImageReps = [[NSArray arrayWithObjects: @"tiff", @"tif", nil] retain];
	__pbBitmapImageReps = [[NSArray arrayWithObjects: NSTIFFPboardType, nil] retain];
	[NSImageRep registerImageRepClass: [self class]];
}

+ (BOOL) canInitWithData:(NSData *)data
{
	TIFF *tif = GSTiffOpenData((char *)[data bytes], [data length], "r");	// try to open
	if(tif)	TIFFClose(tif);
	return (tif) ? YES : NO;
}

+ (NSArray *) imageUnfilteredFileTypes			{ return __bitmapImageReps; }
+ (NSArray *) imagePasteboardTypes				{ return __pbBitmapImageReps; }
+ (NSArray *) imageUnfilteredPasteboardTypes	{ return __pbBitmapImageReps; }

+ (id) imageRepWithData:(NSData *)data
{
	return [[[self alloc] initWithData:data] autorelease];
}

+ (NSArray *) imageRepsWithData:(NSData *)data
{
	TIFF *tif;							
	int image = 0;
	NSTiffInfo *info;
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:1];
	
	if (!(tif = GSTiffOpenData((char*)[data bytes], [data length], "r")))
		[NSException raise:NSTIFFException format: @"Read invalid TIFF data"];
	
	while ((info = GSTiffGetInfo(image, tif))) 
		{
		NSBitmapImageRep *imageRep;
		
		imageRep=[[[[self class] alloc] initWithBitmapDataPlanes: NULL
								pixelsWide: info->width
								pixelsHigh: info->height
							 bitsPerSample: info->bitsPerSample
						   samplesPerPixel: info->samplesPerPixel
								  hasAlpha:(info->samplesPerPixel > 3)
								  isPlanar:(info->planarConfig == PLANARCONFIG_SEPARATE)
							colorSpaceName: info->space
								bitmapFormat:NSAlphaNonpremultipliedBitmapFormat
							   bytesPerRow: 0
							  bitsPerPixel: 0] autorelease];
		imageRep->_compression = info->compression;
	//	imageRep->_factor = info->_factor;
		// read tiff into data array
		if (GSTiffRead(tif, info, (char *) [imageRep bitmapData]))
			[NSException raise:NSTIFFException format: @"invalid TIFF image"];
		
		free(info);
		[array addObject: imageRep];
		image++;
		}
	TIFFClose(tif);
	
	return array;
}

- (id) initWithData:(NSData *)data				// Loads default (first) image
{										 		// from TIFF contained in data
	TIFF *tif = GSTiffOpenData((char*)[data bytes], [data length], "r");							
	NSTiffInfo *info = GSTiffGetInfo(-1, tif);
	
	if (!tif || !info)
		{
		// FIXME: we must also be able to load all supported formats here!
		[NSException raise:NSTIFFException format: @"Read invalid TIFF data"];
		}
	self=[self initWithBitmapDataPlanes: NULL
						pixelsWide: info->width
						pixelsHigh: info->height
					 bitsPerSample: info->bitsPerSample
				   samplesPerPixel: info->samplesPerPixel
						  hasAlpha:(info->samplesPerPixel > 3)
						  isPlanar:(info->planarConfig == PLANARCONFIG_SEPARATE)
					colorSpaceName: info->space
					   bytesPerRow: 0
					  bitsPerPixel: 0];
	if(self)
		{
		_compression = info->compression;
	//	_factor = info->compression;
		// read tiff into data array
		if (GSTiffRead(tif, info, (char *) [self bitmapData]))
			[NSException raise:NSTIFFException format:@"Read invalid TIFF image"];
	
		TIFFClose(tif);
		}
	return self;
}

- (id) initWithBitmapDataPlanes:(unsigned char **)planes
					 pixelsWide:(NSInteger)width
					 pixelsHigh:(NSInteger)height
				  bitsPerSample:(NSInteger)bitsPerSample
				samplesPerPixel:(NSInteger)samplesPerPixel
					   hasAlpha:(BOOL)alpha
					   isPlanar:(BOOL)isPlanar
				 colorSpaceName:(NSString *)colorSpaceName
					bytesPerRow:(NSInteger)rowBytes
				   bitsPerPixel:(NSInteger)pixelBits;
{
	return [self initWithBitmapDataPlanes:planes
							   pixelsWide:width
							   pixelsHigh:height
							bitsPerSample:bitsPerSample
						  samplesPerPixel:samplesPerPixel
								 hasAlpha:alpha
								 isPlanar:isPlanar
						   colorSpaceName:colorSpaceName
							 bitmapFormat:0
							  bytesPerRow:rowBytes
							 bitsPerPixel:pixelBits];
}

- (id) initWithBitmapDataPlanes:(unsigned char **)planes	// designated init
					 pixelsWide:(NSInteger)width
					 pixelsHigh:(NSInteger)height
				  bitsPerSample:(NSInteger)bitsPerSample
				samplesPerPixel:(NSInteger)samplesPerPixel
					   hasAlpha:(BOOL)alpha
					   isPlanar:(BOOL)isPlanar
				 colorSpaceName:(NSString *)colorSpaceName
					bitmapFormat:(NSBitmapFormat)bitmapFormat
					bytesPerRow:(NSInteger)rowBytes
				   bitsPerPixel:(NSInteger)pixelBits;
{
	if (bitsPerSample <= 0) [NSException raise: NSInvalidArgumentException format: @"bitsPerSample (%d) must be > 0", bitsPerSample];
	if (samplesPerPixel <= 0 || samplesPerPixel > 5) [NSException raise: NSInvalidArgumentException format: @"samplesPerPixel (%d) must be between 1 and 5", samplesPerPixel];
	if (width <= 0 || height <= 0) [NSException raise: NSInvalidArgumentException format: @"width (%d) and heigh (%d) must be > 0", width, height];
	// NOTE: GIF uses 8 spp
	/* FIXME: more consistency checks
	 if([colorSpaceName isEqual:@"RGB"])
		components=3;
	 else if([colorSpaceName isEqual:@"HSB"])
		components=3;
	 else if([colorSpaceName isEqual:@"White"])
		components=1;
	 else if([colorSpaceName isEqual:@"CMYK"])
		components=4;
	 else
		error;
	 if(alpha)
		components++;
	 if(components != samplesPerPixel)
			[NSException raise: NSInvalidArgumentException format: @"samplesPerPixel (%d) does not match color space name %@", samplesPerPixel, colorSpaceName];
	 */
	if((self=[super init]))
		{
		_pixelsWide = width;
		_pixelsHigh = height;
		_size = NSMakeSize(width, height);
		_irep.bitsPerSample = (unsigned int) bitsPerSample;
		_brep.numColors = (unsigned int) samplesPerPixel;
		_irep.hasAlpha = alpha;  
		_brep.isPlanar = isPlanar;
		_format=bitmapFormat;
		_compression=NSTIFFCompressionLZW;	// default compression
		_factor=1.0;
		_colorSpace = [colorSpaceName retain];
		if(!pixelBits)
			pixelBits = bitsPerSample * ((_brep.isPlanar) ? 1 : samplesPerPixel);
		_brep.bitsPerPixel = (unsigned int) pixelBits;
		if(!rowBytes) 
			bytesPerRow = (unsigned int)(width * _brep.bitsPerPixel + 7)/8;
		else
			bytesPerRow = (unsigned int)rowBytes;
		if(planes) 
			{
			int i, np = ((_brep.isPlanar) ? _brep.numColors : 1);
			_imagePlanes = calloc(np, sizeof(_imagePlanes[0]));
			if(!_imagePlanes)
				{ [self release]; return nil; }
			for(i = 0; i < np; i++)
				_imagePlanes[i] = planes[i];	// copy data
			}
		}
	return self;
}

- (id) copyWithZone:(NSZone *) zone;
{
	NSBitmapImageRep *copy = (NSBitmapImageRep*)[super copyWithZone:zone];
	if(copy)
		{
		/*
		 unsigned char **_imagePlanes;
		 NSMutableData *_imageData;
		 unsigned int bytesPerRow;
		 unsigned short compression;
		 NSBitmapFormat _format;
		 struct __bitmapRepFlags {
			 unsigned int bitsPerPixel:8;	
			 unsigned int isPlanar:1;
			 unsigned int numColors:4;
			 unsigned int cached:1;
			 unsigned int cachedPixel:1;
			 unsigned int reserved:17;
		 } _brep;
		 */
		}
	return NIMP;
	return copy;
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@: WxH=%ldx%ld, size=%@, bit/sample=%d, planes=%d, alpha=%d, planar=%d, colorspace=%@, bit/px=%d, byte/row=%d",
		NSStringFromClass([self class]),
		(long)_pixelsWide, (long)_pixelsHigh,
		NSStringFromSize(_size),
		_irep.bitsPerSample,
		_brep.numColors,
		_irep.hasAlpha,
		_brep.isPlanar,
		_colorSpace,
		_brep.bitsPerPixel,
		bytesPerRow
		];
}

- (int) incrementalLoadFromData:(NSData *) data complete:(BOOL) complete;
{
	if(!complete)
		return NSImageRepLoadStatusWillNeedAllData;	// we don't implement it really
	return [self initWithData:data]?NSImageRepLoadStatusCompleted:NSImageRepLoadStatusUnexpectedEOF;
}

- (NSInteger) bitsPerPixel			{ return _brep.bitsPerPixel; }
- (NSInteger) samplesPerPixel		{ return _brep.numColors; }
- (NSInteger) numberOfPlanes		{ return _brep.isPlanar ? _brep.numColors : 1;}
- (NSInteger) bytesPerPlane			{ return bytesPerRow * _pixelsHigh; }
- (NSInteger) bytesPerRow			{ return bytesPerRow; }
- (BOOL) isPlanar					{ return _brep.isPlanar; }

- (BOOL) draw
{ // draw using current CTM and operation
	return [[NSGraphicsContext currentContext] _draw:self];
}

- (unsigned char *) bitmapData
{
	if (!_imagePlanes || !_imagePlanes[0])
		{ // allocate data planes
		NSInteger i, planeSize = (bytesPerRow * _pixelsHigh);
		NSUInteger length = _brep.numColors * planeSize * sizeof(unsigned char);
		
		_imagePlanes = objc_calloc(MAX_PLANES, sizeof(_imagePlanes[0]));
		_imageData = [[NSMutableData dataWithLength: length] retain];
		_imagePlanes[0] = [_imageData mutableBytes];
		
		if (_brep.isPlanar) 
			for (i = 1; i < _brep.numColors; i++) 
				_imagePlanes[i] = _imagePlanes[0] + (i * planeSize);
		}									
	
	return _imagePlanes[0];
}

- (NSBitmapFormat) bitmapFormat;	{ return _format; }

- (void) getBitmapDataPlanes:(unsigned char **)data
{
	int i;
	
	if (!_imagePlanes || !_imagePlanes[0])
		[self bitmapData];
	
	if (data)
		for (i = 0; i < _brep.numColors; i++)
			data[i] = _imagePlanes[i];
}

- (void) getPixel:(NSUInteger[]) pixelData atX:(NSInteger) x y:(NSInteger) y;
{
	NSUInteger i;
	NSInteger offset;
	if(_brep.isPlanar)
		{ // planar
		offset=x + bytesPerRow*(_pixelsHigh-1-y);
		for(i=0; i<_brep.numColors; i++)
			pixelData[i]=_imagePlanes[i][offset];
		}
	else
		{ // meshed
		offset=_brep.numColors*x + bytesPerRow*(_pixelsHigh-1-y);
		for(i=0; i<_brep.numColors; i++)
			pixelData[i]=_imagePlanes[0][offset+i];
		}
}

- (void) setPixel:(NSUInteger[]) pixelData atX:(NSInteger) x y:(NSInteger) y;
{
	NSUInteger i;
	NSInteger offset;
	if (!_imagePlanes || !_imagePlanes[0])
		[self bitmapData];	// allocate plane memory
	if(_brep.isPlanar)
		{ // planar
		offset=x + bytesPerRow*(_pixelsHigh-1-y);
		for(i=0; i<_brep.numColors; i++)
			_imagePlanes[i][offset]=pixelData[i];
		}
	else
		{ // meshed
		offset=_brep.numColors*x + bytesPerRow*(_pixelsHigh-1-y);
		for(i=0; i<_brep.numColors; i++)
			_imagePlanes[0][offset+i]=pixelData[i];
		}
}

- (NSColor *) colorAtX:(NSInteger) x y:(NSInteger) y;
{
	NSUInteger pixelData[5];
	if(x < 0 || y < 0 || x >= _pixelsWide || y >= _pixelsHigh)
		return nil;	// outside
	[self getPixel:pixelData atX:x y:y];
	if([_colorSpace isEqualToString:NSCalibratedRGBColorSpace])
		{
		if(_irep.hasAlpha)
			return [NSColor colorWithCalibratedRed:pixelData[0]/255.0 green:pixelData[1]/255.0 blue:pixelData[2]/255.0 alpha:pixelData[3]/255.0];
		return [NSColor colorWithCalibratedRed:pixelData[0]/255.0 green:pixelData[1]/255.0 blue:pixelData[2]/255.0 alpha:1.0];
		}
	else if([_colorSpace isEqualToString:NSDeviceRGBColorSpace])
		{
		if(_irep.hasAlpha)
			return [NSColor colorWithDeviceRed:pixelData[0]/255.0 green:pixelData[1]/255.0 blue:pixelData[2]/255.0 alpha:pixelData[3]/255.0];
		return [NSColor colorWithDeviceRed:pixelData[0]/255.0 green:pixelData[1]/255.0 blue:pixelData[2]/255.0 alpha:1.0];
		}
	NSLog(@"unexpected colorspace");
	return nil;
}

- (void) setColor:(NSColor *)color atX:(NSInteger) x y:(NSInteger) y;
{
	NSUInteger pixelData[5];
	if(x < 0 || y < 0 || x >= _pixelsWide || y >= _pixelsHigh)
		return;	// outside
	if([_colorSpace isEqualToString:NSCalibratedRGBColorSpace])
		{
		CGFloat red, green, blue, alpha;
		[color getRed:&red green:&green blue:&blue alpha:&alpha];
		pixelData[0]=255*red;
		pixelData[1]=255*green;
		pixelData[2]=255*blue;
		if(_irep.hasAlpha)
			pixelData[3]=255*alpha;
		}
	else if([_colorSpace isEqualToString:NSDeviceRGBColorSpace])
		{
		CGFloat red, green, blue, alpha;
		[color getRed:&red green:&green blue:&blue alpha:&alpha];
		pixelData[0]=255*red;
		pixelData[1]=255*green;
		pixelData[2]=255*blue;
		if(_irep.hasAlpha)
			pixelData[3]=255*alpha;
		}
	else
		return;	// not implemented (e.g. NSCalibratedCMYKColorSpace)
	[self setPixel:pixelData atX:x y:y];
}

// FIXME: if we use XRender we can also copy the bitmap to offscreen memory
// and just return a reference, i.e. a NSCachedImageRep
// if we draw it again it will be done localy in the server
// we read the data only if someone wants to see the pixels.

- (id) initWithFocusedViewRect:(NSRect)rect
{
	if((self=[self initWithBitmapDataPlanes:NULL
								 pixelsWide:rect.size.width
								 pixelsHigh:rect.size.height
							  bitsPerSample:24	// get from screen depth
							samplesPerPixel:8
								   hasAlpha:NO
								   isPlanar:NO	// what is better?
							 colorSpaceName:NSDeviceRGBColorSpace
								bytesPerRow:0
							   bitsPerPixel:0]))
		{ // fill bitmap from screen
		[[NSGraphicsContext currentContext] _initBitmap:self withFocusedViewRect:rect];
		}
	return self;
}

+ (void) getTIFFCompressionTypes:(const NSTIFFCompression **)list
						   count:(NSInteger *)numTypes
{
	NIMP;
}

+ (NSData *) representationOfImageRepsInArray:(NSArray *)imageReps usingType:(NSBitmapImageFileType)storageType properties:(NSDictionary *)properties
{
	switch(storageType)
		{ // pass down to appropriate subclass - but usingType:-1 to avoid recursion if not implemented
		case NSBMPFileType:
			return nil;	// not available
		case NSGIFFileType:
			return [GSBitmapImageRepGIF representationOfImageRepsInArray:imageReps usingType:-1 properties:properties];
		case NSJPEGFileType:
		case NSJPEG2000FileType:
			return [GSBitmapImageRepJPEG representationOfImageRepsInArray:imageReps usingType:-1 properties:properties];
		case NSPNGFileType:
			return [GSBitmapImageRepPNG representationOfImageRepsInArray:imageReps usingType:-1 properties:properties];
		case NSICNSFileType:
			return [GSBitmapImageRepICNS representationOfImageRepsInArray:imageReps usingType:-1 properties:properties];
		case NSTIFFFileType:
			{
				id factor=[properties objectForKey:NSImageCompressionFactor];
				if(!factor)
					return nil;
				// fixme: get compression type
				return [self TIFFRepresentationOfImageRepsInArray:imageReps usingCompression:0 factor:[factor floatValue]];
			}
		}
	return nil;	// invalid storage type
}

- (NSData *) representationUsingType:(NSBitmapImageFileType) storageType properties:(NSDictionary *) properties
{ // single file
	return [[self class] representationOfImageRepsInArray:[NSArray arrayWithObject:self] usingType:storageType properties:properties];
}

+ (NSData *) TIFFRepresentationOfImageRepsInArray:(NSArray *)anArray
{
	// loop through all image reps and store [element TIFFRepresentation]
	return NIMP;
}

+ (NSData *) TIFFRepresentationOfImageRepsInArray:(NSArray *)anArray
								 usingCompression:(NSTIFFCompression)compressionType
										   factor:(float)factor
{
	// loop through all image reps and store [element TIFFRepresentationUsingCompression:compressionType factor:factor]
	return NIMP;
}

- (NSData *) TIFFRepresentation
{
	return [self TIFFRepresentationUsingCompression:_compression factor:_factor];
}

- (NSData *) TIFFRepresentationUsingCompression:(NSTIFFCompression)comp factor:(float)f
{ // this is the primitive method for TIFFs
	return NIMP;
}

- (BOOL) canBeCompressedUsing:(NSTIFFCompression)compression
{
	NIMP; return NO;
}

- (void) getCompression:(NSTIFFCompression *)comp factor:(float *)factor
{
	*comp=_compression;
	*factor=_factor;
}

- (void) setCompression:(NSTIFFCompression)comp factor:(float)factor
{
	_compression=comp;
	_factor=factor;
}

- (void) colorizeByMappingGray:(CGFloat) midPoint
					   toColor:(NSColor *) midPointColor
				  blackMapping:(NSColor *) shadowColor
				  whiteMapping:(NSColor *) lightColor;
{ // FIXME: very slow algorithm! Should be a CoreImage filter kernel...
	int x, y;
	NSColor *col;
	for(y=0; y<_pixelsHigh; y++)
		{
		for(x=0; x<_pixelsWide; x++)
			{
			col=[self colorAtX:x y:y];
			// get grey value
			// decide if we are above or below mid point
			// if below: interpolate between mitPointColor and shadowColor
			// if above: interpolate between mitPointColor and lightColor
			[self setColor:col atX:x y:y];
			}
		}
}

- (void) encodeWithCoder:(NSCoder*)coder		{ NIMP; }		// NSCoding Protocol

- (id) initWithCoder:(NSCoder*)coder
{
	if([coder allowsKeyedCoding])
		{
		NSData *data=[coder decodeObjectForKey:@"NSTIFFRepresentation"];
		[self release];
		return [[NSBitmapImageRep imageRepWithData:data] retain];	// should be TIFF
		}
	NSLog(@"NSBitmapImageRep: can't initWithCoder");
	return nil;
}

@end /* NSBitmapImageRep */
