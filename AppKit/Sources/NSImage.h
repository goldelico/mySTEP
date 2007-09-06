/* 
   NSImage.h

   Image container class

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:	April 1999
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Feb 2006 - aligned with 10.4
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSImage
#define _mySTEP_H_NSImage

#import <Foundation/NSBundle.h>
#import <AppKit/AppKitDefines.h>
#import <AppKit/NSBitmapImageRep.h>

@class NSString;
@class NSURL;
@class NSData;
@class NSPasteboard;
@class NSImageRep;
@class NSColor;
@class NSView;
@class NSMutableArray;

typedef enum _NSCompositingOperation
{
	NSCompositeClear	   = 0,
	NSCompositeCopy		   = 1,
	NSCompositeSourceOver  = 2,
	NSCompositeSourceIn	   = 3,
	NSCompositeSourceOut   = 4,
	NSCompositeSourceAtop  = 5,
	NSCompositeDestinationOver	   = 6,
	NSCompositeDestinationIn	   = 7,
	NSCompositeDestinationOut	   = 8,
	NSCompositeDestinationAtop	   = 9,
	NSCompositeXOR		   = 10,
	NSCompositePlusDarker  = 11,
	NSCompositeHighlight   = 12,
	NSCompositePlusLighter = 13
} NSCompositingOperation;

typedef enum _NSImageLoadStatus
{
	NSImageLoadStatusCompleted=0,
	NSImageLoadStatusCancelled,
	NSImageLoadStatusInvalidData,
	NSImageLoadStatusUnexpectedEOF,
	NSImageLoadStatusReadError
} NSImageLoadStatus;

typedef enum _NSImageCacheMode
{
	NSImageCacheDefault,
	NSImageCacheAlways,
	NSImageCacheBySize,
	NSImageCacheNever
} NSImageCacheMode;

@interface NSImage : NSObject  <NSCoding, NSCopying>
{
	NSString *_name;			// image name (if named)
	NSString *_imageFilePath;	// file path (if named)
	NSMutableArray *_reps;		// representations
	NSMutableArray *_cache;		// cached representations
	NSImageRep *_bestRep;		// best representation of all
	NSColor *_backgroundColor;	// used when caching
	NSSize _size;
	id _delegate;

	struct __imageFlags {
		UIBITFIELD(unsigned int, scalable, 1);
		UIBITFIELD(unsigned int, dataRetained, 1);
		UIBITFIELD(unsigned int, flipDraw, 1);
		UIBITFIELD(unsigned int, uniqueWindow, 1);				// ?
		UIBITFIELD(unsigned int, uniqueWasExplicitlySet, 1);	// ?
		UIBITFIELD(unsigned int, sizeWasExplicitlySet, 1);
		UIBITFIELD(unsigned int, builtIn, 1);				// ?
		UIBITFIELD(unsigned int, needsToExpand, 1);			// ?
		UIBITFIELD(unsigned int, prefersColorMatch, 1);
		UIBITFIELD(unsigned int, multipleResolutionMatching, 1);
		UIBITFIELD(unsigned int, subImage, 1);				// ?
		UIBITFIELD(unsigned int, aSynch, 1);				// ?
		UIBITFIELD(unsigned int, archiveByName, 1);			// ?
		UIBITFIELD(unsigned int, cacheSeparately, 1);
		UIBITFIELD(NSImageCacheMode, cacheMode, 2);
		UIBITFIELD(unsigned int, unboundedCacheDepth, 1);
		UIBITFIELD(unsigned int, isValid, 1);
		UIBITFIELD(unsigned int, usesEPSOnResolutionMismatch, 1);
		} _img;
}

+ (BOOL) canInitWithPasteboard:(NSPasteboard*)pasteboard;
+ (NSArray*) imageFileTypes;
+ (id) imageNamed:(NSString*)name;
+ (NSArray*) imagePasteboardTypes;
+ (NSArray*) imageUnfilteredFileTypes;
+ (NSArray*) imageUnfilteredPasteboardTypes;

- (void) addRepresentation:(NSImageRep*)imageRep;			// Representations
- (void) addRepresentations:(NSArray*)imageRepArray;
- (NSColor*) backgroundColor;
- (NSImageRep*) bestRepresentationForDevice:(NSDictionary*)deviceDescription;
- (BOOL) cacheDepthMatchesImageDepth;
- (NSImageCacheMode) cacheMode;
- (void) cancelIncrementalLoad;
- (void) compositeToPoint:(NSPoint)aPoint
				 fromRect:(NSRect)aRect
				operation:(NSCompositingOperation)op;
- (void) compositeToPoint:(NSPoint)aPoint
				 fromRect:(NSRect)aRect
				operation:(NSCompositingOperation)op
				 fraction:(float)fraction;	// most general method
- (void) compositeToPoint:(NSPoint)aPoint
				operation:(NSCompositingOperation)op;
- (void) compositeToPoint:(NSPoint)aPoint
				operation:(NSCompositingOperation)op
				 fraction:(float)fraction;
- (id) delegate;
- (void) dissolveToPoint:(NSPoint)aPoint
				fraction:(float)aFloat;
- (void) dissolveToPoint:(NSPoint)aPoint
				fromRect:(NSRect)aRect
				fraction:(float)aFloat;
- (void) drawAtPoint:(NSPoint)point
		    fromRect:(NSRect)src
		   operation:(NSCompositingOperation)op
		    fraction:(float)fraction;
- (void) drawInRect:(NSRect)rect
		   fromRect:(NSRect)src
		  operation:(NSCompositingOperation)op
		   fraction:(float)fraction;
- (BOOL) drawRepresentation:(NSImageRep *)imageRep
					 inRect:(NSRect)aRect;
- (id) initByReferencingFile:(NSString*)filename;
- (id) initByReferencingURL:(NSURL*)url;
- (id) initWithContentsOfFile:(NSString*)filename;
- (id) initWithContentsOfURL:(NSURL*)url;
- (id) initWithData:(NSData*)data;
- (id) initWithPasteboard:(NSPasteboard*)pasteboard;
- (id) initWithSize:(NSSize)aSize;
- (BOOL) isCachedSeparately;
- (BOOL) isDataRetained;
- (BOOL) isFlipped;
- (BOOL) isValid;											// Drawing details
- (void) lockFocus;
- (void) lockFocusOnRepresentation:(NSImageRep *)imageRepresentation;
- (BOOL) matchesOnMultipleResolution;
- (NSString*) name;
- (BOOL) prefersColorMatch;
- (void) recache;
- (void) removeRepresentation:(NSImageRep*)imageRep;
- (NSArray*) representations;
- (BOOL) scalesWhenResized;
- (void) setBackgroundColor:(NSColor*)aColor;
- (void) setCacheDepthMatchesImageDepth:(BOOL)flag;
- (void) setCachedSeparately:(BOOL)flag;					// Storage details
- (void) setCacheMode:(NSImageCacheMode) mode;
- (void) setDataRetained:(BOOL)flag;
- (void) setDelegate:(id)anObject;							// Set the Delegate
- (void) setFlipped:(BOOL)flag;
- (void) setMatchesOnMultipleResolution:(BOOL)flag;
- (BOOL) setName:(NSString*)name;
- (void) setPrefersColorMatch:(BOOL)flag;
- (void) setScalesWhenResized:(BOOL)flag;
- (void) setSize:(NSSize)aSize;
- (void) setUsesEPSOnResolutionMismatch:(BOOL)flag;
- (NSSize) size;
- (NSData*) TIFFRepresentation;								// Producing a TIFF
- (NSData*) TIFFRepresentationUsingCompression:(NSTIFFCompression)comp
										factor:(float)aFloat;
- (void) unlockFocus;
- (BOOL) usesEPSOnResolutionMismatch;

@end


@interface NSObject (NSImageDelegate)						// Implemented by
															// the delegate
- (void) image:(NSImage *)image didLoadRepresentation:(NSImageRep *)rep withStatus:(NSImageLoadStatus)status;
- (void) image:(NSImage *)image didLoadPartOfRepresentation:(NSImageRep *)rep withValidRows:(int)rows;
- (void) image:(NSImage *)image didLoadRepresentationHeader:(NSImageRep *)rep;
- (void) image:(NSImage *)image willLoadRepresentation:(NSImageRep *)rep;
- (NSImage *) imageDidNotDraw:(id)sender inRect:(NSRect)aRect;

@end


@interface NSBundle (NSImageAdditions) 

- (NSString*) pathForImageResource:(NSString*)name;

@end

#endif /* _mySTEP_H_NSImage */
