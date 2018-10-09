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

#import "NSAppKitPrivate.h"
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
#if 1
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
	NSInteger i, count = [array count];
	
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
				_alignmentRect = (NSRect) { NSZeroPoint, _size };
				_img.sizeWasExplicitlySet = YES;
			}
#if 1
		_img.scalable = YES;
#endif
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

- (id) initWithPasteboard:(NSPasteboard*)pasteboard		{ return NIMP; }

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
	NSImage *copy = [[self class] allocWithZone:zone];
	if(!_img.isValid)
		{
		}
	// copy instance variables
	copy->_name = [_name retain];
	copy->_imageFilePath = [_imageFilePath retain];
	copy->_reps = [_reps mutableCopy];
	copy->_backgroundColor = [_backgroundColor retain];
	copy->_size = _size;
	copy->_alignmentRect = _alignmentRect;
	copy->_delegate = [_delegate retain];
	copy->_img = _img;	// copy all image flags
	[copy recache];
	return copy;
}

- (void) lockFocus
{ // lock focus on cache
	NSGraphicsContext *ctxt;
	NSWindow *cw;
	NSAffineTransform *ctm;
#if 0
	NSLog(@"lockFocus: %@", self);
#endif
	// here we should also check the caching mode settings
	if(!_cache)
		{ // create cache
			_cache=[[NSCachedImageRep alloc] initWithSize:_size depth:[NSWindow defaultDepthLimit] separate:_img.cacheSeparately alpha:YES];
			if(!_cache)
				[NSException raise:NSImageCacheException format:@"can't create cached image representation"];
			[[_cache window] _allocateGraphicsContext];
#if 0
			NSLog(@"cache: %@", _cache);
			NSLog(@"cache window: %@", [_cache window]);
#endif
		}
	cw=[_cache window];
	ctxt=[cw graphicsContext];
	[NSGraphicsContext saveGraphicsState];
#if 0
	NSLog(@"setCurrentContext: %@", ctxt);
#endif
	[NSGraphicsContext setCurrentContext:ctxt];	// is part of graphicsState
#if 0
	NSLog(@"setGraphicsState: %d", [cw gState]);
#endif
	[NSGraphicsContext setGraphicsState:[cw gState]];	// select private state&context if possible
	ctm=[NSAffineTransform transform];
		// define CTM so that we really draw into the associated cache tile, i.e. move the origin - any maybe we need to flip
	[ctxt _setCTM:ctm];
	[ctxt _addClip:[NSBezierPath bezierPathWithRect:[_cache rect]] reset:YES];
}

- (void) lockFocusOnRepresentation:(NSImageRep *) imageRep;
{ // this method should have been called -lockFocusAndDrawRepresentation:
	[self lockFocus];
	[imageRep drawInRect:(NSRect) { NSZeroPoint, [self size]}];	// draw (if specified)
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
#if 0
	NSLog(@"NSImage setName:%@", string);
#endif
	if([string length] == 0 && [_name length] > 0)
		{ // clearing the name removes it from the dictionary
		[[self retain] autorelease];
		[__nameToImageDict removeObjectForKey:_name];	// remove from dictionary
		ASSIGN(_name, nil);
		return YES;
		}
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
	return [NSString stringWithFormat:@"NSImage: name=%@ size=%@ %@%@%@%@%@%@", 
		_name, 
		NSStringFromSize(_size),
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

- (NSImageRep *) _cachedOrBestRep;
{ // return the image rep - cached if necessary
	NSImageRep *bestRep;
	if(_cache)
		return _cache;	// we have a cached rep
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
		_cache=(NSCachedImageRep *) [bestRep retain];	// just save the reference
	else
		{ // draw into new cache
		  // CHECKME: is this ok?
		[self lockFocusOnRepresentation:bestRep];	// render into cache window
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
	if(aSize.width <= 0 || aSize.height <= 0)
		return;	// ignore
	_size = aSize;
	_alignmentRect = (NSRect) { NSZeroPoint, _size };
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
				{
					_size = [best size];
					_alignmentRect = (NSRect) { NSZeroPoint, _size };
				}
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
		    fraction:(CGFloat)fraction;
{
	if(NSIsEmptyRect(src))
		src.size=[self size];		// use image size
	[self drawInRect:(NSRect){point, src.size}	// not scaled
			fromRect:src
		   operation:op
			fraction:fraction];
}

- (void) drawInRect:(NSRect)dest
		   fromRect:(NSRect)src
		  operation:(NSCompositingOperation)op
		   fraction:(CGFloat)fraction;
{ // contrary to composite: we don't ignore rotation here!
	NSGraphicsContext *ctx;
	NSAffineTransform *atm;
	NSCompositingOperation co;
	NSImageRep *rep;
	if(!_img.isValid)
		[self isValid];		// make sure we have the image reps loaded in - if possible
	[self size];	// determine size if not yet known
	if(NSIsEmptyRect(src))
		src.size=_size;		// use image size and {0,0} origin
	if(NSIsEmptyRect(dest))
		return;	// nothing to draw
	rep=[self _cachedOrBestRep];
	ctx=[NSGraphicsContext currentContext];
	[ctx saveGraphicsState];
	co=[ctx compositingOperation];	// save
	[[NSBezierPath bezierPathWithRect:dest] addClip];	// never draw outside during scaling
	// FIXME: why do we save the compositing operation and not the fraction?
	// should either or both become part of saveGraphicsState?
	[ctx setCompositingOperation:op];
	[ctx _setFraction:fraction];
	atm=[NSAffineTransform transform];
	[atm scaleXBy:_size.width/NSWidth(src) yBy:_size.height/NSHeight(src)];	// scale by src
	[atm translateXBy:NSMinX(dest)*(NSWidth(src)/_size.width-1) - NSMinX(src)*NSWidth(dest)/_size.width
				  yBy:NSMinY(dest)*(NSHeight(src)/_size.height-1) - NSMinY(src)*NSWidth(dest)/_size.height];	// shift origin
	if(_img.flipDraw)
		{ // draw flipped
		[atm translateXBy:0.0 yBy:NSMinY(dest)+NSMaxY(dest)];	// shift origin
		[atm scaleXBy:1.0 yBy:-1.0];
		}
	[ctx _concatCTM:atm];	// add to CTM
	[self drawRepresentation:rep inRect:dest];	// draw in rect
	[ctx setCompositingOperation:co];
	[ctx restoreGraphicsState];
}

- (void) drawInRect:(NSRect) rect
{ // shortcut introduced in OSX 10.9
	[self drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

- (void) dissolveToPoint:(NSPoint)p fraction:(CGFloat)f
{
	[self compositeToPoint:p fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:f];
}

- (void) dissolveToPoint:(NSPoint)p fromRect:(NSRect)s fraction:(CGFloat)f
{
	[self compositeToPoint:p fromRect:s operation:NSCompositeSourceOver fraction:f];
}

- (void) compositeToPoint:(NSPoint)pnt					// Draw the Image
				operation:(NSCompositingOperation)op
{
	[self compositeToPoint:pnt fromRect:NSZeroRect operation:op fraction:1.0];
}

- (void) compositeToPoint:(NSPoint)pnt					// Draw the Image
				operation:(NSCompositingOperation)op
				 fraction:(CGFloat)fraction;
{
	[self compositeToPoint:pnt fromRect:NSZeroRect operation:op fraction:fraction];
}


- (void) compositeToPoint:(NSPoint)pnt
				 fromRect:(NSRect)rect
				operation:(NSCompositingOperation)op
{
	[self compositeToPoint:pnt fromRect:NSZeroRect operation:op fraction:1.0];
}

/* almost the same as drawAtPoint:fromRect:operation:fraction */

- (void) compositeToPoint:(NSPoint)pnt
				 fromRect:(NSRect)src
				operation:(NSCompositingOperation)op
				 fraction:(CGFloat)fraction
{ // this is the most generic composite/dissolve method
	// this function should ignore rotation and scaling of the CTM!
	// but not translation and [img isFlipped]
	// see e.g.: http://www.stone.com/The_Cocoa_Files/Cocoamotion.html
	NSGraphicsContext *ctx;
	NSRect dest;
	if(!_img.isValid)
		[self isValid];		// make sure we have the image reps loaded in - if possible
	if(NSIsEmptyRect(src))
		src.size=_size;	// use image size and {0,0} origin
	ctx=[NSGraphicsContext currentContext];
	dest.origin=[[ctx _getCTM] transformPoint:pnt];	// transform drawing origin through currently active CTM
	dest.size=src.size;	// draw in original size
	[ctx saveGraphicsState];
	[ctx _setCTM:[NSAffineTransform transform]];	// wipe out rotation and scaling by making 1:1 transform
	[self drawInRect:dest fromRect:src operation:op fraction:fraction];	// takes care of [img isFlipped] and scales to [img size]
#if 0
	[[NSColor orangeColor] set];
	NSRectFill(NSMakeRect(50, 50, 5, 5));	// marker for debugging
#endif
	[ctx restoreGraphicsState];
}

- (BOOL) drawRepresentation:(NSImageRep*)imageRep inRect:(NSRect)rect
{
#if 0
	NSLog(@"%@ drawRepresentation:%@ inRect:%@", self, imageRep, NSStringFromRect(rect));
#endif

#if 0
	// set current background color unless not set of fully transparent
	NSRectFill(rect);
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
		{ // substitute image provided by delegate
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
			if(_imageFilePath)
				NSLog(@"could not load representations from file %@", _imageFilePath);
			else
				NSLog(@"could not load representations from NSData");
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
			_img.isValid = YES;	// at least one valid representation has been loaded
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
	NSInteger bpp;	// bits per plane
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
	NSLog(@"representations: %@ %@", self, _reps);
#endif
	_bestRep=nil;
	highScore=-1;	// use any -1 score if no other is found
	e=[_reps reverseObjectEnumerator];
	while((r=[e nextObject]))
		{
		int newScore=[self _scoreRepresentation:r forDevice:deviceDescription];
#if 0
		NSLog(@"score %d for %@", newScore, r);
#endif
		if(newScore > highScore)
			{ // found a better one than before
			_bestRep=r;
			highScore=newScore;
			}
		}
	if(!_img.sizeWasExplicitlySet && _bestRep) 
			{
				_size = [_bestRep size];
				_alignmentRect = (NSRect) { NSZeroPoint, _size };
			}
#if 0
	NSLog(@"_bestRep: %@ size:%@", _bestRep, NSStringFromSize(_size));
#endif
	if(!_bestRep)
		NSLog(@"no best rep found for %@ in %@", deviceDescription, _reps);
	return _bestRep;
}

- (NSData *) TIFFRepresentation
{
	return [self TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:0.0];
}

- (NSData *) TIFFRepresentationUsingCompression:(NSTIFFCompression)comp
										factor:(CGFloat)aFloat
{
	// forward to best rep?
	
	// check if we have any bitmap rep
	// then, get TIFF from there
	// else get TIFF from cached rep
	return NIMP;
}

- (NSRect) alignmentRect;														{ return _alignmentRect; }
- (NSImageCacheMode) cacheMode;											{ return _img.cacheMode; }
- (BOOL) isTemplate;																{ return _img.isTemplate; }
- (BOOL) usesEPSOnResolutionMismatch;								{ return _img.usesEPSOnResolutionMismatch; }
- (void) setAlignmentRect:(NSRect) rect;						{ _alignmentRect=rect; }
- (void) setCacheMode:(NSImageCacheMode) mode;			{ _img.cacheMode=mode; }
- (void) setTemplate:(BOOL) flag;										{ _img.isTemplate=flag; }
- (void) setUsesEPSOnResolutionMismatch:(BOOL)flag;	{ _img.usesEPSOnResolutionMismatch=flag; }

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
		{
//		[self release];	--- we are always named and stored in the nameToImageDict
		return [__nameToImageDict objectForKey:_name];
		}
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
			_alignmentRect = (NSRect) { NSZeroPoint, _size };
		_backgroundColor=[[coder decodeObjectForKey:@"NSColor"] retain];
		if([coder containsValueForKey:@"NSReps"])
			{
			_reps=[[coder decodeObjectForKey:@"NSReps"] retain];	// load array of reps
				// FIXME: we should only ignore cached image reps
				// sometimes a NIB encodes a TIFFRepresentation
#if 0
			NSLog(@"NSImage initWithCoder ignores archived reps _reps=%@", _reps);
#endif
				[_reps release];
				_reps = [NSMutableArray new];
//			_img.isValid=YES;
//			[self release];
//			return nil;		// IB stores the Image Reps of Checkbox icons explicitly
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
