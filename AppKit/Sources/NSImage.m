/*
   NSImage.m

   Load, manipulate and display images

   Copyright (C) 1996 Free Software Foundation, Inc.

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSString.h>
#import <Foundation/NSEnumerator.h>

#import <AppKit/NSImage.h>
#import <AppKit/NSBitmapImageRep.h>
#import <AppKit/NSCachedImageRep.h>
#import <AppKit/NSAffineTransform.h>
#import <AppKit/NSBezierPath.h>
#import <AppKit/NSView.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSGraphicsContext.h>
#import <AppKit/NSApplication.h>

#import "NSBackendPrivate.h"

// Class variables 
static NSMutableDictionary *__nameToImageDict = nil;

@implementation NSImage

+ (void) initialize
{
	__nameToImageDict = [[NSMutableDictionary alloc] initWithCapacity: 10];
	[NSBitmapImageRep class]; // initialize NSBitmapImageRep class now
}

+ (id) imageNamed:(NSString*)aName
{ // locate by name or load from main bundle
	NSImage *image;
	if([aName length] == 0)
		return nil;	// there is no unnamed image...
	if([aName isEqualToString:NSApplicationIcon])
		{ // try to load application icon
		NSString *subst=[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIconFile"];	// replace from Info.plist
		if([subst length] > 0)
			aName=subst;			// try to load
		}
	if((image = [__nameToImageDict objectForKey:aName]))
		{ // found a record in cache
		if([image isKindOfClass:[NSNull class]])
			return nil; // we know that we don't know...
		return image;
		}
	image=[self _imageNamed:aName inBundle:[NSBundle mainBundle]];
	if(!image)
		{
#if 0
		NSLog(@"could not find NSImage -imageNamed:%@", aName);
#endif
		[__nameToImageDict setObject:[NSNull null] forKey:aName];	// save a tag that we don't know the image
		}
	return image;
}

+ (id) _imageNamed:(NSString*)aName inBundle:(NSBundle *) bundle;
{ // locate in specific bundle (e.g. a loaded bundle) and then in AppKit.framework
	NSString *name;
	NSString *path;
	NSEnumerator *e;
	NSString *ext;
	NSArray *fileTypes;
	NSImage *image;
#if 0
	NSLog(@"load imageNamed %@ inBundle %@", aName, bundle);
#endif
	ext = [aName pathExtension];		// dict search for it
	fileTypes = [NSImageRep imageFileTypes];
#if 0
	NSLog(@"ext = %@ imageFileTypes = %@", ext, fileTypes);
#endif
	if([fileTypes containsObject:ext])
		{ // known extension
		name = [aName stringByDeletingPathExtension];		// has a supported extension
		path = [bundle pathForResource:name ofType:ext];	// look up
#if 0
		NSLog(@"name = %@", name);
		NSLog(@"ext = %@", ext);
		NSLog(@"path = %@", path);
#endif
		}
	else
		{ // keep full name
		name = aName;
		path = nil;
		}
	if(!path)
		{ // name does not have a supported ext: search for the image locally (mainBundle)
		id o;
		ext=nil;	// ignore extension
		e = [fileTypes objectEnumerator];
		while((o = [e nextObject]))
			{
#if 0
			NSLog(@"try %@: %@.%@", [bundle bundlePath], name, o);
#endif
			if((path = [bundle pathForResource:name ofType:o]))
				break;
			}
		}
	if(!path)
		{ // If not found in app bundle search for image in system
		bundle=[NSBundle bundleForClass:[self class]];	// look up in AppKit.framework
		if(ext)
			path = [bundle pathForResource:name ofType:ext];
		else 
			{ // try all extensions we know
			id o;
			e = [fileTypes objectEnumerator];
			while((o = [e nextObject]))
				{
#if 0
				NSLog(@"try %@: %@.%@", [bundle bundlePath], name, o);
#endif
				if((path = [bundle pathForResource:name ofType:o]))
					break;
				}
			}
		}
#if 0
	NSLog(@"found %@ at path=%@ in bundle %@", aName, path, bundle);
#endif
	image=nil;
	if(path && (image = [[NSImage alloc] initByReferencingFile:path]))
		{ // file really exists
		[image setName:aName];	// will save in __nameToImageDict - and increment retain count
#if 0
		NSLog(@"NSImage: -imageNamed:%@ -> %@", aName, image);
#endif
		[image autorelease];	// don't leak if everything is released - unfortunately we are never deleted from the image cache
		}
	return image;
}

+ (BOOL) canInitWithPasteboard:(NSPasteboard*)pasteboard
{														// FIX ME: Implement
	NSArray *array = [NSImageRep registeredImageRepClasses];
	int i, count = [array count];
	
	for (i = 0; i < count; i++)
		if ([[array objectAtIndex: i] canInitWithPasteboard: pasteboard])
			return YES;
	
	return NO;
}

+ (NSArray*) imageFileTypes
{
	return [NSImageRep imageFileTypes];
}

+ (NSArray*) imageUnfilteredFileTypes
{
	return [NSImageRep imageUnfilteredFileTypes];
}

+ (NSArray*) imagePasteboardTypes
{
	return [NSImageRep imagePasteboardTypes];
}

+ (NSArray*) imageUnfilteredPasteboardTypes
{
	return [NSImageRep imageUnfilteredPasteboardTypes];
}

- (id) init
{
	return [self initWithSize: NSZeroSize];
}

- (id) initWithSize:(NSSize)aSize							// Designated init
{
	if((self=[super init]))
		{
		_reps = [NSMutableArray new];
		if(aSize.width && aSize.height)
			{
			_size = aSize;
			_img.sizeWasExplicitlySet = YES;
			}
		_img.prefersColorMatch = YES;
		_img.multipleResolutionMatching = YES;
#if 0
		NSLog(@"NSImage initWithSize");
#endif
		_backgroundColor=[[NSColor clearColor] retain];	// default background is transparent
#if 0
		NSLog(@"NSImage initWithSize color=%@", _backgroundColor);
#endif
		}
	return self;
}

- (id) initByReferencingFile:(NSString*)fileName
{ // must have explicitly an extension
	NSString *e = [fileName pathExtension];	
#if 0
	NSLog(@"NSImage initByReferencingFile:%@", fileName);
#endif
	if (!e || ([[NSImageRep imageFileTypes] indexOfObject:e] == NSNotFound))
		{ // no extension or is not recognized by type
		[self release];
		return nil;
		}
	if((self=[self initWithSize:NSZeroSize]))
		{
		_img.dataRetained = YES;
		_imageFilePath = [fileName retain];
		}
#if 0
	NSLog(@"NSImage initByReferencingFile -> %@", self);
#endif
	return self;
}

- (id) initWithContentsOfFile:(NSString*)fileName
{
	if((self=[self initByReferencingFile:fileName]))
		{
		if(![self isValid])
			{ // wasn't able to load
			[self release];
			return nil;
			}
		}
	return self;
}

- (id) initWithData:(NSData*)data
{
	if((self=[self initWithSize: NSZeroSize]))
		{
		_data=[data retain];
		if(![self isValid])
			{ // wasn't able to load
			[self release];
			return nil;
			}
		}
	return self;
}

- (id) initWithPasteboard:(NSPasteboard*)pasteboard		{ return NIMP }

- (void) dealloc
{
	[_data release];
	[_reps release]; 
	[_cache release]; 
	if(_name && self == [__nameToImageDict objectForKey: _name]) 
		[__nameToImageDict removeObjectForKey:_name];	// only if we are not a copy with the same name
	[_name release];
	[_backgroundColor release];
	[super dealloc];
}

- (id) copyWithZone:(NSZone *) zone
{
	NSImage *copy = [isa allocWithZone:zone];
	if(!_img.isValid)
		{
		}
	// copy instance variables
	copy->_name = [_name retain];
	copy->_imageFilePath = [_imageFilePath retain];
	copy->_reps = [_reps mutableCopy];
	copy->_cache = [_cache mutableCopy];
	copy->_backgroundColor = [_backgroundColor retain];
	copy->_size = _size;
	copy->_delegate = [_delegate retain];
	copy->_img = _img;	// copy all image flags
	[copy recache];
	return copy;
}

- (void) lockFocus
{ // draw into cache
	[self lockFocusOnRepresentation:nil];
}

- (void) lockFocusOnRepresentation:(NSImageRep *) imageRep;
{
	NSCachedImageRep *irep=[self _cachedImageRep];
	[self isValid];	// load or create cached image rep if needed
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithWindow:[irep window]]];
	// define CTM so that we really draw into the irep
}

- (void) unlockFocus
{
	[NSGraphicsContext restoreGraphicsState];
}

- (void) setMatchesOnMultipleResolution:(BOOL)flag
{
	_img.multipleResolutionMatching = flag;
}

- (BOOL) matchesOnMultipleResolution	
{ 
	return _img.multipleResolutionMatching;
}

- (BOOL) setName:(NSString*)string
{
	if(!string || [__nameToImageDict objectForKey: string])
		return NO;	// if already in dictionary
	ASSIGN(_name, string);
	[__nameToImageDict setObject:self forKey:_name];	// save in dictionary
	return YES;
}

- (NSString*) name							{ return _name; }
- (void) setPrefersColorMatch:(BOOL)flag	{ _img.prefersColorMatch = flag; }
- (void) setCachedSeparately:(BOOL)flag		{ _img.cacheSeparately = flag; }
- (void) setDataRetained:(BOOL)flag			{ _img.dataRetained = flag; }
- (void) setFlipped:(BOOL)flag				{ _img.flipDraw = flag; }
- (BOOL) prefersColorMatch					{ return _img.prefersColorMatch; }
- (BOOL) isCachedSeparately					{ return _img.cacheSeparately; }
- (BOOL) isDataRetained						{ return _img.dataRetained; }
- (BOOL) isFlipped							{ return _img.flipDraw; }
- (BOOL) cacheDepthMatchesImageDepth		{ return _img.unboundedCacheDepth;}
- (BOOL) scalesWhenResized					{ return _img.scalable; }
- (void) setScalesWhenResized:(BOOL)flag	{ _img.scalable = flag; }

- (NSString *) description;
{
	return [NSString stringWithFormat:@"NSImage: name=%@ size=%@ %@%@%@", 
		_name, 
		NSStringFromSize([self size]),
		_img.scalable?@" scalable":@"",
		_img.isValid?@" valid":@"",
		_img.flipDraw?@" flipped":@"",
		_img.scalable?@" scalesWhenResized":@"",
		_img.cacheSeparately?@" cachedSeparately":@"",
		_img.dataRetained?@" dataRetained":@"",
		nil
		];
}
	
- (void) setCacheDepthMatchesImageDepth:(BOOL)flag
{
	_img.unboundedCacheDepth = flag;
}

- (void) recache
{
	[_cache release];
	_cache=nil;
}

// CHECKME: shouldn't we return NSImageRep *

- (NSCachedImageRep *) _cachedImageRep;
{ // return cached image rep - create one if there is none yet
	NSImageRep *bestRep;
	if(_cache)
		return _cache;	// found
	bestRep=[self bestRepresentationForDevice:nil];
	if(!bestRep)
		return nil;	// can't cache
	switch(_img.cacheMode)
		{
		case NSImageCacheDefault:
		case NSImageCacheNever:
			return (NSCachedImageRep *) bestRep;	// use the original
		case NSImageCacheBySize:
			// check size:
//		case NSImageCacheDefault:
		case NSImageCacheAlways:
		default:
			break;
		}
	if([bestRep isKindOfClass:[NSCachedImageRep class]])
		_cache=[bestRep retain];
	else
		{ // draw into new cache
		_cache=[[NSCachedImageRep alloc] initWithSize:_size depth:0 separate:_img.cacheSeparately alpha:YES];
		[self lockFocusOnRepresentation:_cache];
		[self drawRepresentation:bestRep inRect:[_cache rect]];	// render into cache window
		[self unlockFocus];
		}
	return _cache;
}

- (void) setBackgroundColor:(NSColor*)color	{ ASSIGN(_backgroundColor, color); }
- (NSColor*) backgroundColor				{ return _backgroundColor; }
- (NSArray*) representations				{ return _reps; }
- (void) setDelegate:(id)anObject			{ ASSIGN(_delegate, anObject); }
- (id) delegate								{ return _delegate; }

- (void) setSize:(NSSize)aSize
{
#if 0
	NSLog(@"setSize:%@", NSStringFromSize(aSize));
#endif
	if(NSEqualSizes(_size, aSize))
		return;	// effectively unchanged
	_size = aSize;
	_img.sizeWasExplicitlySet = YES;
	if(_data)
		_img.isValid=NO;	// reload from data since it is still available
	[self recache];		// recache
}

- (NSSize) size
{
	if(!_img.sizeWasExplicitlySet && _size.width == 0) 
		{ // determine from best representation if possible
		NSImageRep *best;
		if(!_img.isValid)
			[self isValid];	// try to load reps first
		// FIXME: we should determine from all reps not only the best for an unknown device
		best=[self bestRepresentationForDevice: nil];
		if(best)
			_size = [best size];
		else
			NSLog(@"there is no best representation");
#if 0
		NSLog(@"image %@ best %@: size=%@", _name, best, NSStringFromSize(_size));
#endif
		}
	return _size;
}

- (void) drawAtPoint:(NSPoint)point
		    fromRect:(NSRect)src
		   operation:(NSCompositingOperation)op
		    fraction:(float)fraction;
{
	[self drawInRect:(NSRect){point, src.size}	// not scaled
			fromRect:src
		   operation:op
			fraction:fraction];
}

- (void) drawInRect:(NSRect)dest
		   fromRect:(NSRect)src
		  operation:(NSCompositingOperation)op
		   fraction:(float)fraction;
{ // contrary to composite: we don't ignore rotation here!
	NSGraphicsContext *ctx=[NSGraphicsContext currentContext];
	NSAffineTransform *atm=[NSAffineTransform transform];
	static NSBezierPath *unitSquare=nil;
	NSCompositingOperation co;
	if(!_img.isValid)
		[self isValid];		// Make sure we have the image reps loaded in - if possible
	if(src.size.width <= 0.0 || src.size.height <= 0.0)
		src.size=_size;	// use image size
	if(dest.size.width <= 0.0 || dest.size.height <= 0.0)
		dest.size=_size;	// use image size
	[ctx saveGraphicsState];
	co=[ctx compositingOperation];	// save
	[ctx setCompositingOperation:op];
	[ctx _setFraction:fraction];
	if(_img.flipDraw)
		{ // scaleXBy:1.0 yBy:-1.0
		NSLog(@"should flip drawInRect: %@", self);
		}
	[atm translateXBy:dest.origin.x-src.origin.x yBy:dest.origin.y-src.origin.y];
	[atm scaleXBy:dest.size.width yBy:dest.size.height];	// will draw to unit square
	if(!NSEqualSizes(src.size, _size))
		[atm scaleXBy:_size.width/src.size.width yBy:_size.height/src.size.height];	// additional scaling
	[ctx _concatCTM:atm];	// add to CTM as needed
	if(!unitSquare)
		unitSquare=[[NSBezierPath bezierPathWithRect:NSMakeRect(0.0, 0.0, 1.0, 1.0)] retain];
	[ctx _addClip:unitSquare reset:NO];	// set CTM as needed
//	[ctx _draw:[self bestRepresentationForDevice:nil]];
	[ctx _draw:[self _cachedImageRep]];
	[ctx setCompositingOperation:co];
	[ctx restoreGraphicsState];
}

- (void) dissolveToPoint:(NSPoint)p fraction:(float)f
{
	[self compositeToPoint:p fromRect:(NSRect){{0,0},_size} operation:NSCompositeSourceOver fraction:f];
}

- (void) dissolveToPoint:(NSPoint)p fromRect:(NSRect)s fraction:(float)f
{
	[self compositeToPoint:p fromRect:s operation:NSCompositeSourceOver fraction:f];
}

- (void) compositeToPoint:(NSPoint)pnt					// Draw the Image
				operation:(NSCompositingOperation)op
{
	[self compositeToPoint:pnt fromRect:(NSRect){{0,0},_size} operation:op fraction:1.0];
}

- (void) compositeToPoint:(NSPoint)pnt					// Draw the Image
				operation:(NSCompositingOperation)op
				 fraction:(float)fraction;
{
	[self compositeToPoint:pnt fromRect:(NSRect){{0,0},_size} operation:op fraction:fraction];
}


- (void) compositeToPoint:(NSPoint)pnt 
				 fromRect:(NSRect)rect
				operation:(NSCompositingOperation)op
{
	[self compositeToPoint:pnt fromRect:(NSRect){{0,0},_size} operation:op fraction:1.0];
}

- (void) compositeToPoint:(NSPoint)pnt 
				 fromRect:(NSRect)src
				operation:(NSCompositingOperation)op
				 fraction:(float)fraction
{ // this is the most generic composite/dissolve method - modify CTM before calling this method to translate to point
	// for maximum compatibility, this function has to ignore rotation and scaling of the CTM!
	// see e.g.: http://www.stone.com/The_Cocoa_Files/Cocoamotion.html
	static NSBezierPath *unitSquare=nil;
	NSGraphicsContext *ctx=[NSGraphicsContext currentContext];
	NSAffineTransform *atm=[NSAffineTransform transform];
	NSCompositingOperation co;
	if(!_img.isValid)
		[self isValid];		// Make sure we have the image reps loaded in - if possible
	if(src.size.width <= 0.0 || src.size.height <= 0.0)
		src.size=_size;	// use image size
	[ctx saveGraphicsState];
	co=[ctx compositingOperation];	// save
	[ctx setCompositingOperation:op];
	[ctx _setFraction:fraction];
	if(_img.flipDraw)
		NSLog(@"should flip compositeToPoint: %@", self);
		;	// FIXME: scaleXBy:1.0 yBy:-1.0
	// FIXME: do we have to scale src.origin?
	[atm translateXBy:pnt.x-src.origin.x yBy:pnt.y-src.origin.y];
	[atm scaleXBy:src.size.width yBy:src.size.height];	// will draw the src rect to unit square
	[ctx _concatCTM:atm];	// add to CTM as needed
	// FIXME: somehow remove any rotation
	if(!unitSquare)
		unitSquare=[[NSBezierPath bezierPathWithRect:NSMakeRect(0.0, 0.0, 1.0, 1.0)] retain];
	[ctx _addClip:unitSquare reset:NO];	// set CTM as needed
//	[ctx _draw:[self bestRepresentationForDevice:nil]];
	[ctx _draw:[self _cachedImageRep]];
	[ctx setCompositingOperation:co];	// restore
	[ctx restoreGraphicsState];
}

- (BOOL) drawRepresentation:(NSImageRep*)imageRep inRect:(NSRect)rect
{
#if 0
	NSLog(@"%@ drawRepresentation:%@ inRect:%@", self, imageRep, NSStringFromRect(rect));
#endif
	if(!_img.scalable)
		{
		if([imageRep drawAtPoint:rect.origin])
			return YES;		
		rect.size = _size;
		}
	else if([imageRep drawInRect:rect])
		return YES;
	if(_delegate && [_delegate respondsToSelector:@selector(imageDidNotDraw:inRect:)])
		{
		NSImage *a;		
		if ((a = [_delegate imageDidNotDraw:self inRect:rect]))
			{
			NSImageRep *rp = [a bestRepresentationForDevice:nil];	// FIXME
			return [a drawRepresentation:rp inRect:rect];
			}
		}
	return NO;
}

- (void) addRepresentation:(NSImageRep *)imageRep
{
	[_reps addObject:imageRep];
}

- (void) addRepresentations:(NSArray *)imageRepArray
{
	if (imageRepArray)
		[_reps addObjectsFromArray:imageRepArray];
}

- (void) removeRepresentation:(NSImageRep *)imageRep
{
	[_reps removeObjectIdenticalTo:imageRep];
}

- (BOOL) isValid
{														 
	if(!_img.isValid)
		{
		NSArray *reps=nil;
#if 0
		NSLog(@"load image representation(s) (at path: %@)", _imageFilePath);
#endif
		if(_imageFilePath)
			{ // (re)load from path if possible
			reps = [NSImageRep imageRepsWithContentsOfFile:_imageFilePath];
			if(!reps)
				NSLog(@"could not load image at path: %@", _imageFilePath);
			}
		else if(_data)
			{ // (re)load from data
			Class rep = [NSImageRep imageRepClassForData:_data];	// find appropriate handler class
			if(rep)
				{
				if([rep respondsToSelector: @selector(imageRepsWithData:)])
					reps = [rep imageRepsWithData:_data];	// returns multiple reps
				else
					{ // single rep
					NSImageRep *image;
					if((image = [rep imageRepWithData:_data]))
						reps=[NSArray arrayWithObject:image];
					}
				}
			if(!_img.dataRetained)
				{ // free
				[_data release];
				_data=nil;
				}
			}
		else	// we have been created by -initWithSize: - create a cached image to draw into
			reps=[NSArray arrayWithObject:[[[NSCachedImageRep alloc] initWithSize:_size depth:0 separate:_img.cacheSeparately alpha:YES] autorelease]];
		if(!reps)
			{
			NSLog(@"could not load representations");
			return NO;
			}
		[self addRepresentations:reps];
		if(_img.sizeWasExplicitlySet)
			{
				NSEnumerator *e=[reps objectEnumerator];
				NSImageRep *r;
				while((r=[e nextObject]))
					[r setSize:_size];	// resize representation(s)
			}
		if([_reps count])
			_img.isValid = YES;	// any valid representation have been loaded
		}
#if 0
	NSLog(@"image valid %d", _img.isValid);
#endif
	return _img.isValid;
}

- (int) _scoreRepresentation:(NSImageRep *) r forDevice:(NSDictionary *) deviceDescription;
{
	int score=0;
	int imageResolution, deviceResolution;
	int bpp;	// bits per plane
	if([r isKindOfClass:[NSCachedImageRep class]])
		return -1;	// ignore in scoring process
	if(!_img.prefersColorMatch)
		; // reverse rule 1 and 2 by reversing the high scores
#if 0
	NSLog(@"score %@: %@", NSStringFromClass([r class]), r);
#endif
	// Rule 1:
	if(![r respondsToSelector:@selector(numberOfPlanes)])
		{ // not a bitmap rep - assume we are an EPS
		if(!_img.usesEPSOnResolutionMismatch)
			return -1;	// never use EPS as best one
		score=1;	// use EPS if nothing else works
		}
	if([(NSBitmapImageRep *) r numberOfPlanes] < 3)
		{ // b&w image rep
		score += 0;
		}
	else
		{ // prefer color image rep over b&w unless we know that we have a b&w display
		score += 100;	// we assume to have a color display...
		}
	// Rule 2:
	// FIXME: imageResolution is MIN([r pixelsWide]/size.width, [r pixelsHigh]/size.height) 
	imageResolution=300;	// how to get that from ImageRep???
	deviceResolution=72;	// get from deviceDescription
	if(imageResolution%deviceResolution == 0 && _img.multipleResolutionMatching)
		score += 500000;	// Jackpot
	else if(imageResolution == deviceResolution)
		score += 500000;	// exact match
	score += 10*imageResolution;	// score better resolution higher
	// Rule 3:
	bpp=[(NSBitmapImageRep *) r bitsPerPixel];
	if(bpp == 8)
		score += 50;	// depth match
	else
		score += bpp;	// score higher depth better
	return score;
}

- (NSImageRep *) bestRepresentationForDevice:(NSDictionary *) deviceDescription
{
	int highScore;
	NSEnumerator *e;
	NSImageRep *r;
	NSImageRep *_bestRep;		// best representation of all
	if(!_img.isValid && ![self isValid])
		return nil;		// Make sure we have the image reps loaded in - if possible
#if 0
	NSLog(@"representations: %@", _reps);
#endif
	_bestRep=nil;
	highScore=-1;
	e=[_reps reverseObjectEnumerator];
	while((r=[e nextObject]))
		{
		int newScore=[self _scoreRepresentation:r forDevice:deviceDescription];
		if(newScore > highScore)
			{ // found a better one than before
			_bestRep=r;
			highScore=newScore;
			}
		}
	if (!_img.sizeWasExplicitlySet && _bestRep) 
		_size = [_bestRep size];
#if 0
	NSLog(@"_bestRep: %@ size:%@", _bestRep, NSStringFromSize(_size));
#endif
	if(!_bestRep)
		NSLog(@"no best rep found for %@ in %@", deviceDescription, _reps);
	return _bestRep;
}

- (NSData *) TIFFRepresentation
{
	// simply forward to best rep?

	return [self TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:0.0];
}

- (NSData *) TIFFRepresentationUsingCompression:(NSTIFFCompression)comp
										factor:(float)aFloat
{
	// forward to best rep?
	
	// check if we have a bitmap rep
	// then, get TIFF from there
	// else get TIFF from cached rep
	return NIMP;
}

- (NSImageCacheMode) cacheMode;						{ return _img.cacheMode; }
- (BOOL) usesEPSOnResolutionMismatch;				{ return _img.usesEPSOnResolutionMismatch; }
- (void) setUsesEPSOnResolutionMismatch:(BOOL)flag;	{ _img.usesEPSOnResolutionMismatch=flag; }
- (void) setCacheMode:(NSImageCacheMode) mode;		{ _img.cacheMode=mode; }

- (id) initByReferencingURL:(NSURL*)url;
{
	return NIMP;
}

- (id) initWithContentsOfURL:(NSURL*)url;
{
	return NIMP;
}

- (void) cancelIncrementalLoad;
{
	return;	// ignored
}

- (id) awakeAfterUsingCoder:(NSCoder*)aDecoder
{
	if(_name && [__nameToImageDict objectForKey:_name]) 
		return [__nameToImageDict objectForKey:_name];
    
	return self;
}

- (void) encodeWithCoder:(NSCoder*)coder		{ NIMP; }		// NSCoding Protocol

- (id) initWithCoder:(NSCoder*)coder
{
	if([coder allowsKeyedCoding])
		{
		unsigned int iflags=[coder decodeIntForKey:@"NSImageFlags"];
#define SCALABLE ((iflags&0x8000000) != 0)
		_img.scalable=SCALABLE;
#define SIZESET ((iflags&0x2000000) != 0)
		_img.sizeWasExplicitlySet=SIZESET;
#define USEEPS ((iflags&0x0200000) != 0)
		_img.usesEPSOnResolutionMismatch=USEEPS;
#define COLORMATCHPREFERRED ((iflags&0x0100000) != 0)
		_img.prefersColorMatch=COLORMATCHPREFERRED;
#define MULTIRESMATCH ((iflags&0x0080000) != 0)
		_img.multipleResolutionMatching=MULTIRESMATCH;
#define FLIPPED ((iflags&0x0008000) != 0)
		_img.flipDraw=FLIPPED;
#define ALIASED ((iflags&0x0004000) != 0)
#define CACHEMODE ((iflags&0x0001800) >> 11)
		_img.cacheMode=CACHEMODE;
		_size=[coder decodeSizeForKey:@"NSSize"];
		_backgroundColor=[[coder decodeObjectForKey:@"NSColor"] retain];
		if([coder containsValueForKey:@"NSReps"])
			{
			_reps=[[coder decodeObjectForKey:@"NSReps"] retain];	// load array of reps
#if 1
			NSLog(@"NSImage initWithCoder igores archived reps _reps=%@", _reps);
#endif
			_img.isValid=YES;
			[self release];
			return nil;		// IB stores the Image Reps of Checkbox icons explicitly
			}
		else
			_reps = [NSMutableArray new];
		return self;
		}
	NSLog(@"NSImage: can't initWithCoder");
	[self release];
	return nil;
}

@end
