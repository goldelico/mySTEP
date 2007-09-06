/* 
   NSBitmapImageRep.h

   Bitmap image representations

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    June 2000
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Jan 2006 - aligned with 10.4

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSBitmapImageRep
#define _mySTEP_H_NSBitmapImageRep

#import <AppKit/NSImageRep.h>

@class NSArray;
@class NSString;
@class NSData;
@class NSMutableData;
@class NSColor;

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

+ (void) getTIFFCompressionTypes:(const NSTIFFCompression **)list
						   count:(int *)numTypes;
+ (NSArray *) imageRepsWithData:(NSData *)tiffData;
+ (id) imageRepWithData:(NSData *)tiffData;
+ (NSString *) localizedNameForTIFFCompressionType:(NSTIFFCompression)compression;
+ (NSData *) representationOfImageRepsInArray:(NSArray *)imageReps
									usingType:(NSBitmapImageFileType)storageType
								   properties:(NSDictionary *)properties;
+ (NSData *) TIFFRepresentationOfImageRepsInArray:(NSArray *)anArray;
+ (NSData *) TIFFRepresentationOfImageRepsInArray:(NSArray *)anArray
								 usingCompression:(NSTIFFCompression)compressionType
										   factor:(float)factor;

- (unsigned char *) bitmapData;	// Access image Data
- (NSBitmapFormat) bitmapFormat;
- (int) bitsPerPixel;
- (int) bytesPerPlane;
- (int) bytesPerRow;
- (BOOL) canBeCompressedUsing:(NSTIFFCompression) compression;
- (NSColor *) colorAtX:(int) x y:(int) y;
- (void) colorizeByMappingGray:(float) midPoint
					   toColor:(NSColor *) midPointColor
				  blackMapping:(NSColor *) shadowColor
				  whiteMapping:(NSColor *) lightColor;
- (void) getBitmapDataPlanes:(unsigned char **)data;
- (void) getCompression:(NSTIFFCompression *)compression 
				 factor:(float *)factor;
- (void) getPixel:(unsigned int[]) pixelData atX:(int) x y:(int) y;
- (int) incrementalLoadFromData:(NSData *) data complete:(BOOL) complete;
- (id) initForIncrementalLoad;
- (id) initWithBitmapDataPlanes:(unsigned char **)planes
					 pixelsWide:(int)width
					 pixelsHigh:(int)height
				  bitsPerSample:(int)bps
				samplesPerPixel:(int)spp
					   hasAlpha:(BOOL)alpha
					   isPlanar:(BOOL)config
				 colorSpaceName:(NSString *)colorSpaceName
				   bitmapFormat:(NSBitmapFormat)bitmapFormat 
					bytesPerRow:(int)rowBytes
				   bitsPerPixel:(int)pixelBits;
- (id) initWithBitmapDataPlanes:(unsigned char **)planes
					 pixelsWide:(int)width
					 pixelsHigh:(int)height
				  bitsPerSample:(int)bps
				samplesPerPixel:(int)spp
					   hasAlpha:(BOOL)alpha
					   isPlanar:(BOOL)config
				 colorSpaceName:(NSString *)colorSpaceName
					bytesPerRow:(int)rowBytes
				   bitsPerPixel:(int)pixelBits;
- (id) initWithData:(NSData *)tiffData;
- (id) initWithFocusedViewRect:(NSRect)rect;
- (BOOL) isPlanar;
- (int) numberOfPlanes;
- (NSData *) representationUsingType:(NSBitmapImageFileType) storageType
						  properties:(NSDictionary *) properties;
- (int) samplesPerPixel;
- (void) setColor:(NSColor *) color
			  atX:(int) x y:(int) y;
- (void) setCompression:(NSTIFFCompression)compression
				 factor:(float)factor;
- (void) setPixel:(unsigned int[]) pixelData
			  atX:(int) x y:(int) y;
- (void) setProperty:(NSString *)property withValue:(id)value;
- (NSData*) TIFFRepresentation;
- (NSData*) TIFFRepresentationUsingCompression:(NSTIFFCompression)compressType 
										factor:(float)factor;
- (id) valueForProperty:(NSString *)property;
														// Compression Types 
@end

#endif /* _mySTEP_H_NSBitmapImageRep */
