/*
 NSBitmapImageRep.h

 Bitmap image representations

 Copyright (C) 2000 Free Software Foundation, Inc.

 Author:  Felipe A. Rodriguez <far@pcmagic.net>
 Date:    June 2000

 Author:	H. N. Schaller <hns@computer.org>
 Date:	Jan 2006 - aligned with 10.4

 Author:	Fabian Spillner
 Date:	19. October 2007

 Author:  Fabian Spillner <fabian.spillner@gmail.com>
 Date:	6. November 2007 - aligned with 10.5

 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */

#ifndef _mySTEP_H_NSBitmapImageRep
#define _mySTEP_H_NSBitmapImageRep

#import <AppKit/NSImageRep.h>

@class CIImage;
@class NSArray;
@class NSString;
@class NSData;
@class NSMutableData;
@class NSColor;


typedef struct CGImage *CGImageRef;
@class CIImage;

typedef enum _NSTIFFCompression
{
	NSTIFFCompressionNone	   = 1,
	NSTIFFCompressionCCITTFAX3 = 3,
	NSTIFFCompressionCCITTFAX4 = 4,
	NSTIFFCompressionLZW	   = 5,
	NSTIFFCompressionJPEG	   = 6,
	NSTIFFCompressionNEXT	   = 32766,
	NSTIFFCompressionPackBits  = 32773,
	NSTIFFCompressionOldJPEG   = 32865
} NSTIFFCompression;

typedef enum _NSBitmapImageFileType
{
	NSTIFFFileType=0,
	NSBMPFileType,
	NSGIFFileType,
	NSJPEGFileType,
	NSPNGFileType,
	NSJPEG2000FileType,
	NSICNSFileType
} NSBitmapImageFileType;

typedef enum _NSBitmapFormat
{
	NSAlphaFirstBitmapFormat			=0x01,
	NSAlphaNonpremultipliedBitmapFormat	=0x02,
	NSFloatingPointSamplesBitmapFormat	=0x04
} NSBitmapFormat;

typedef enum _NSImageRepLoadStatus
{
	NSImageRepLoadStatusUnknownType		= -1,
	NSImageRepLoadStatusReadingHeader	= -2,
	NSImageRepLoadStatusWillNeedAllData	= -3,
	NSImageRepLoadStatusInvalidData		= -4,
	NSImageRepLoadStatusUnexpectedEOF	= -5,
	NSImageRepLoadStatusCompleted		= -6
} NSImageRepLoadStatus;


extern NSString *NSImageColorSyncProfileData;
extern NSString *NSImageCompressionFactor;
extern NSString *NSImageCompressionMethod;
extern NSString *NSImageCurrentFrame;
extern NSString *NSImageCurrentFrameDuration;
extern NSString *NSImageDitherTransparency;
extern NSString *NSImageEXIFData;
extern NSString *NSImageFallbackBackgroundColor;
extern NSString *NSImageFrameCount;
extern NSString *NSImageGamma;
extern NSString *NSImageInterlaced;
extern NSString *NSImageLoopCount;
extern NSString *NSImageProgressive;
extern NSString *NSImageRGBColorTable;


@interface NSBitmapImageRep : NSImageRep  <NSCopying>
{
	unsigned char **_imagePlanes;
	NSMutableData *_imageData;
	unsigned int bytesPerRow;
	NSBitmapFormat _format;
	NSTIFFCompression _compression;
	float _factor;

	struct __bitmapRepFlags {
		unsigned int bitsPerPixel:8;
		unsigned int isPlanar:1;
		unsigned int numColors:4;
		unsigned int cached:1;
		unsigned int cachedPixel:1;
		unsigned int reserved:17;
	} _brep;
}

+ (void) getTIFFCompressionTypes:(const NSTIFFCompression **) list count:(NSInteger *) count;
+ (NSArray *) imageRepsWithData:(NSData *) data;
+ (id) imageRepWithData:(NSData *) data;
+ (NSString *) localizedNameForTIFFCompressionType:(NSTIFFCompression) comp;
+ (NSData *) representationOfImageRepsInArray:(NSArray *) reps usingType:(NSBitmapImageFileType) type properties:(NSDictionary *) props;
+ (NSData *) TIFFRepresentationOfImageRepsInArray:(NSArray *) anArray;
+ (NSData *) TIFFRepresentationOfImageRepsInArray:(NSArray *) anArray usingCompression:(NSTIFFCompression) compType factor:(float) factor;

- (unsigned char *) bitmapData;	// Access image Data
- (NSBitmapFormat) bitmapFormat;
- (NSInteger) bitsPerPixel;
- (NSInteger) bytesPerPlane;
- (NSInteger) bytesPerRow;
- (BOOL) canBeCompressedUsing:(NSTIFFCompression) comp;
- (CGImageRef) CGImage;
- (NSColor *) colorAtX:(NSInteger) posX y:(NSInteger) posY;
- (void) colorizeByMappingGray:(CGFloat) midPt toColor:(NSColor *) midPtColor blackMapping:(NSColor *) blackMapping whiteMapping:(NSColor *) whiteMapping;
- (void) getBitmapDataPlanes:(unsigned char **) dataPlanes;
- (void) getCompression:(NSTIFFCompression *) comp factor:(float *) factor;
- (void) getPixel:(NSUInteger[]) pixelData atX:(NSInteger) posX y:(NSInteger) posY;
- (int) incrementalLoadFromData:(NSData *) data complete:(BOOL) flag;
- (id) initForIncrementalLoad;

- (id) initWithBitmapDataPlanes:(unsigned char **) p
					 pixelsWide:(NSInteger) w
					 pixelsHigh:(NSInteger) h
				  bitsPerSample:(NSInteger) bps
				samplesPerPixel:(NSInteger) spp
					   hasAlpha:(BOOL) alpha
					   isPlanar:(BOOL) planar
				 colorSpaceName:(NSString *) csName
				   bitmapFormat:(NSBitmapFormat) format
					bytesPerRow:(NSInteger) bpr
				   bitsPerPixel:(NSInteger) bpp;

- (id) initWithBitmapDataPlanes:(unsigned char **) p
					 pixelsWide:(NSInteger) w
					 pixelsHigh:(NSInteger) h
				  bitsPerSample:(NSInteger) bps
				samplesPerPixel:(NSInteger) spp
					   hasAlpha:(BOOL) alpha
					   isPlanar:(BOOL) planar
				 colorSpaceName:(NSString *) csName
					bytesPerRow:(NSInteger) bpr
				   bitsPerPixel:(NSInteger) bpp;

- (id) initWithCGImage:(CGImageRef) cgImgRef;
- (id) initWithCIImage:(CIImage *) ciImg;
- (id) initWithData:(NSData *) data;
- (id) initWithFocusedViewRect:(NSRect) viewRect;
- (BOOL) isPlanar;
- (NSInteger) numberOfPlanes;
- (NSData *) representationUsingType:(NSBitmapImageFileType) type properties:(NSDictionary *) props;
- (NSInteger) samplesPerPixel;
- (void) setColor:(NSColor *) color atX:(NSInteger) posX y:(NSInteger) posY;
- (void) setCompression:(NSTIFFCompression) comp factor:(float) factor;
- (void) setPixel:(NSUInteger[]) pixels atX:(NSInteger) posX y:(NSInteger) posY;
- (void) setProperty:(NSString *) prop withValue:(id) val;
- (NSData*) TIFFRepresentation;
- (NSData*) TIFFRepresentationUsingCompression:(NSTIFFCompression) compressType factor:(float) factor;
- (id) valueForProperty:(NSString *) prop;
// Compression Types
@end

#endif /* _mySTEP_H_NSBitmapImageRep */
