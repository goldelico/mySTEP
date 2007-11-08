/* 
   NSImageRep.h

   Abstract representation of an image.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:	Adam Fedor <fedor@colorado.edu>
   Date:	Feb 1996
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSImageRep
#define _mySTEP_H_NSImageRep

#import <Foundation/NSCoder.h>
#import <Foundation/NSGeometry.h>

@class NSString;
@class NSArray;
@class NSData;
@class NSPasteboard;

enum {
	NSImageRepMatchesDevice
};

@interface NSImageRep : NSObject  <NSCopying, NSCoding>
{
	NSString *_colorSpace;
	NSSize _size;
	int _pixelsWide;
	int _pixelsHigh;
    struct __repFlags {
		unsigned int hasAlpha:1;
		unsigned int isOpaque:1;
        unsigned int bitsPerSample:8;
        unsigned int reserved:6;
    } _irep;
}

+ (Class) imageRepClassForData:(NSData *) data;				// Manage subclass
+ (Class) imageRepClassForFileType:(NSString *) type;
+ (Class) imageRepClassForPasteboardType:(NSString *) type;
+ (Class) imageRepClassForType:(NSString *) type;

+ (NSArray *) registeredImageRepClasses;
+ (void) registerImageRepClass:(Class) imageRepClass;
+ (void) unregisterImageRepClass:(Class) imageRepClass;

+ (BOOL) canInitWithData:(NSData *) data;					// Check Data Types
+ (BOOL) canInitWithPasteboard:(NSPasteboard *) pasteboard;
+ (NSArray *) imageFileTypes;
+ (NSArray *) imagePasteboardTypes;
+ (NSArray *) imageTypes;
+ (NSArray *) imageUnfilteredFileTypes;
+ (NSArray *) imageUnfilteredPasteboardTypes;
+ (NSArray *) imageUnfilteredTypes;

+ (NSArray *) imageRepsWithContentsOfFile:(NSString *) filename;
+ (NSArray *) imageRepsWithContentsOfURL:(NSURL *) url; 
+ (NSArray *) imageRepsWithPasteboard:(NSPasteboard *) pasteboard;
+ (id) imageRepWithPasteboard:(NSPasteboard *) pasteboard;
+ (id) imageRepWithContentsOfFile:(NSString *) filename;
+ (id) imageRepWithContentsOfURL:(NSURL *) url; 

- (NSInteger) bitsPerSample;										// Image info
- (NSString *) colorSpaceName;
- (BOOL) draw;												// Draw the Image
- (BOOL) drawAtPoint:(NSPoint) aPoint;
- (BOOL) drawInRect:(NSRect) aRect;
- (BOOL) hasAlpha;
- (BOOL) isOpaque;
- (NSInteger) pixelsHigh;
- (NSInteger) pixelsWide;
- (void) setAlpha:(BOOL) flag;
- (void) setBitsPerSample:(NSInteger) anInt;
- (void) setColorSpaceName:(NSString *) aString;
- (void) setOpaque:(BOOL) flag;
- (void) setPixelsHigh:(NSInteger) anInt;
- (void) setPixelsWide:(NSInteger) anInt;
- (void) setSize:(NSSize) aSize;								// Size of Image 
- (NSSize) size;

@end

extern NSString *NSImageRepRegistryChangedNotification;
extern NSString *NSImageCacheException;
extern NSString *NSTIFFException;

#endif /* _mySTEP_H_NSImageRep */
