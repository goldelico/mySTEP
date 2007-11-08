/* 
   NSImage.h

   Image container class

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:	April 1999
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Feb 2006 - aligned with 10.4
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	8. November 2007 - aligned with 10.5  
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSImage
#define _mySTEP_H_NSImage

#import <Foundation/NSBundle.h>
#import <AppKit/AppKitDefines.h>
#import <AppKit/NSBitmapImageRep.h>

typedef void *IconRef;

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

// button template images
extern NSString *const NSImageNameQuickLookTemplate;
extern NSString *const NSImageNameBluetoothTemplate;
extern NSString *const NSImageNameIChatTheaterTemplate;
extern NSString *const NSImageNameSlideshowTemplate;
extern NSString *const NSImageNameActionTemplate;
extern NSString *const NSImageNameSmartBadgeTemplate;
extern NSString *const NSImageNamePathTemplate;
extern NSString *const NSImageNameInvalidDataFreestandingTemplate;
extern NSString *const NSImageNameLockLockedTemplate;
extern NSString *const NSImageNameLockUnlockedTemplate;
extern NSString *const NSImageNameGoRightTemplate;
extern NSString *const NSImageNameGoLeftTemplate;
extern NSString *const NSImageNameRightFacingTriangleTemplate;
extern NSString *const NSImageNameLeftFacingTriangleTemplate;
extern NSString *const NSImageNameAddTemplate;
extern NSString *const NSImageNameRemoveTemplate;
extern NSString *const NSImageNameRevealFreestandingTemplate;
extern NSString *const NSImageNameFollowLinkFreestandingTemplate;
extern NSString *const NSImageNameEnterFullScreenTemplate;
extern NSString *const NSImageNameExitFullScreenTemplate;
extern NSString *const NSImageNameStopProgressTemplate;
extern NSString *const NSImageNameStopProgressFreestandingTemplate;
extern NSString *const NSImageNameRefreshTemplate;
extern NSString *const NSImageNameRefreshFreestandingTemplate;

extern NSString *const NSImageNameMultipleDocuments;

extern NSString *const NSImageNameUser;
extern NSString *const NSImageNameUserGroup;
extern NSString *const NSImageNameEveryone;

extern NSString *const NSImageNameBonjour;
extern NSString *const NSImageNameDotMac;
extern NSString *const NSImageNameComputer;
extern NSString *const NSImageNameFolderBurnable;
extern NSString *const NSImageNameFolderSmart;
extern NSString *const NSImageNameNetwork;

extern NSString *const NSImageNameUserAccounts;
extern NSString *const NSImageNamePreferencesGeneral;
extern NSString *const NSImageNameAdvanced;
extern NSString *const NSImageNameInfo;
extern NSString *const NSImageNameFontPanel;
extern NSString *const NSImageNameColorPanel;

extern NSString *const NSImageNameIconViewTemplate;
extern NSString *const NSImageNameListViewTemplate;
extern NSString *const NSImageNameColumnViewTemplate;
extern NSString *const NSImageNameFlowViewTemplate;

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

+ (BOOL) canInitWithPasteboard:(NSPasteboard *) pasteboard;
+ (NSArray *) imageFileTypes;
+ (id) imageNamed:(NSString *) name;
+ (NSArray *) imagePasteboardTypes;
+ (NSArray *) imageTypes;
+ (NSArray *) imageUnfilteredFileTypes;
+ (NSArray *) imageUnfilteredPasteboardTypes;
+ (NSArray *) imageUnfilteredTypes;

- (void) addRepresentation:(NSImageRep *) imageRep;			// Representations
- (void) addRepresentations:(NSArray *) imageRepArray;
- (NSRect) alignmentRect;
- (NSColor *) backgroundColor;
- (NSImageRep *) bestRepresentationForDevice:(NSDictionary *) deviceDescription;
- (BOOL) cacheDepthMatchesImageDepth;
- (NSImageCacheMode) cacheMode;
- (void) cancelIncrementalLoad;
- (void) compositeToPoint:(NSPoint) aPoint
				 fromRect:(NSRect) aRect
				operation:(NSCompositingOperation) op;
- (void) compositeToPoint:(NSPoint) aPoint
				 fromRect:(NSRect) aRect
				operation:(NSCompositingOperation) op
				 fraction:(CGFloat) fraction;	// most general method
- (void) compositeToPoint:(NSPoint) aPoint
				operation:(NSCompositingOperation) op;
- (void) compositeToPoint:(NSPoint) aPoint
				operation:(NSCompositingOperation) op
				 fraction:(CGFloat) fraction;
- (id) delegate;
- (void) dissolveToPoint:(NSPoint) aPoint
				fraction:(CGFloat) aFloat;
- (void) dissolveToPoint:(NSPoint) aPoint
				fromRect:(NSRect) aRect
				fraction:(CGFloat) aFloat;
- (void) drawAtPoint:(NSPoint) point
		    fromRect:(NSRect) src
		   operation:(NSCompositingOperation) op
		    fraction:(CGFloat) fraction;
- (void) drawInRect:(NSRect) rect
		   fromRect:(NSRect) src
		  operation:(NSCompositingOperation) op
		   fraction:(CGFloat) fraction;
- (BOOL) drawRepresentation:(NSImageRep *) imageRep
					 inRect:(NSRect) aRect;
- (id) initByReferencingFile:(NSString *) filename;
- (id) initByReferencingURL:(NSURL *) url;
- (id) initWithContentsOfFile:(NSString *) filename;
- (id) initWithContentsOfURL:(NSURL *) url;
- (id) initWithData:(NSData *) data;
- (id) initWithIconRef:(IconRef) ref;
- (id) initWithPasteboard:(NSPasteboard *) pasteboard;
- (id) initWithSize:(NSSize) aSize;
- (BOOL) isCachedSeparately;
- (BOOL) isDataRetained;
- (BOOL) isFlipped;
- (BOOL) isTemplate;
- (BOOL) isValid;											// Drawing details
- (void) lockFocus;
- (void) lockFocusOnRepresentation:(NSImageRep *) imageRepresentation;
- (BOOL) matchesOnMultipleResolution;
- (NSString *) name;
- (BOOL) prefersColorMatch;
- (void) recache;
- (void) removeRepresentation:(NSImageRep *) imageRep;
- (NSArray *) representations;
- (BOOL) scalesWhenResized;
- (void) setAlignmentRect:(NSRect) aRect; 
- (void) setBackgroundColor:(NSColor *) aColor;
- (void) setCacheDepthMatchesImageDepth:(BOOL) flag;
- (void) setCachedSeparately:(BOOL) flag;					// Storage details
- (void) setCacheMode:(NSImageCacheMode) mode;
- (void) setDataRetained:(BOOL) flag;
- (void) setDelegate:(id) anObject;							// Set the Delegate
- (void) setFlipped:(BOOL) flag;
- (void) setMatchesOnMultipleResolution:(BOOL) flag;
- (BOOL) setName:(NSString *) name;
- (void) setPrefersColorMatch:(BOOL) flag;
- (void) setScalesWhenResized:(BOOL) flag;
- (void) setSize:(NSSize) aSize;
- (void) setTemplate:(BOOL) flag;
- (void) setUsesEPSOnResolutionMismatch:(BOOL) flag;
- (NSSize) size;
- (NSData *) TIFFRepresentation;								// Producing a TIFF
- (NSData *) TIFFRepresentationUsingCompression:(NSTIFFCompression) comp
										 factor:(CGFloat) aFloat;
- (void) unlockFocus;
- (BOOL) usesEPSOnResolutionMismatch;

@end


@interface NSObject (NSImageDelegate)						// Implemented by
															// the delegate
- (void) image:(NSImage *) image didLoadRepresentation:(NSImageRep *)rep withStatus:(NSImageLoadStatus) status;
- (void) image:(NSImage *) image didLoadPartOfRepresentation:(NSImageRep *) rep withValidRows:(NSInteger) rows;
- (void) image:(NSImage *) image didLoadRepresentationHeader:(NSImageRep *) rep;
- (void) image:(NSImage *) image willLoadRepresentation:(NSImageRep *) rep;
- (NSImage *) imageDidNotDraw:(id) sender inRect:(NSRect) aRect;

@end


@interface NSBundle (NSImageAdditions) 

- (NSString *) pathForImageResource:(NSString *) name;

@end

#endif /* _mySTEP_H_NSImage */
