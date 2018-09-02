/* 
   GSBitmapImageReps.m

   Image viewer

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date: 	March 1999
   
   Author:  H. Nikolaus Schaller <hns@computer.org>
   Date: 	July 2004 - GSBitmapImageRepICNS
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

/* on a Mac, use MacPorts to install the following libraries to /opt/local/:
libjpeg
libz
libtiff
libungif
libpng
*/

#include <png.h>	// must come first before Foundation headers (issue with setjmp macros)
#include <jpeglib.h>
#define DrawText GIFDrawText	// conflict between gif_lib and QD
#include <gif_lib.h>
#undef DrawText
#define DrawText QDDrawText

#import <Foundation/NSArray.h>
#import <Foundation/NSByteOrder.h>
#import <AppKit/AppKit.h>
#import "NSAppKitPrivate.h"


//*****************************************************************************
//
// 		GSBitmapImageRepPNG 
//
//*****************************************************************************

@interface GSBitmapImageRepPNG : NSBitmapImageRep
@end

@implementation GSBitmapImageRepPNG 

static NSArray *__bitmapImageRepsPNG;

+ (void) initialize
{
#if 0
	NSLog(@"GSBitmapImageRepPNG initialize");
#endif
	if (self == [GSBitmapImageRepPNG class])
		{
		__bitmapImageRepsPNG = [[NSArray arrayWithObjects: @"png", nil] retain];
		[NSImageRep registerImageRepClass: [GSBitmapImageRepPNG class]];
		}
}

#define PNG_HEADER_LENGTH 8

+ (BOOL) canInitWithData:(NSData *)data
{
	return data && [data length] > PNG_HEADER_LENGTH && !png_sig_cmp((png_bytep) [data bytes], 0, PNG_HEADER_LENGTH);
}

+ (NSArray *) imageFileTypes				{ return __bitmapImageRepsPNG; }
+ (NSArray *) imageUnfilteredFileTypes		{ return __bitmapImageRepsPNG; }

// we follow the description at http://santosdev.blogspot.de/2012/08/loading-png-image-with-libpng-1512-or.html
// and https://github.com/xerpi/libvita2d/blob/master/libvita2d/source/vita2d_image_png.c

static void png_read(png_structp png_ptr, png_bytep data, png_size_t length)
{
	const char **png_data=png_get_io_ptr(png_ptr);
#if 0
	NSLog(@"png_read %p png_data=%p %p %lu", png_ptr, png_data, data, length);
#endif
	if(png_data == NULL || *png_data == NULL)
		return;
#if 0
	NSLog(@"*png_data=%p", *png_data);
#endif
	if(!memcpy((void *)data, *png_data, (size_t)length))
		png_error(png_ptr, "Read Error");
	(*png_data)+=length;	// advance pointer
}

static void png_read_NSInputStream(png_structp png_ptr, png_bytep data, png_size_t length)
{
	NSInputStream *png_data=png_get_io_ptr(png_ptr);
#if 1
	NSLog(@"png_read_NSInputStream %p png_data=%p %p %lu", png_ptr, png_data, data, length);
#endif
	if(png_data == nil)
		return;
	[png_data read:data maxLength:length];
}

static void png_error_handler(png_structp png_ptr, png_const_charp error_message)
{
	// we should somehow store the error for later processing
	NSLog(@"PNG error: %s", error_message);
	//	longjmp(png_ptr->jmpbuf, 1);	// png_structp is opaque :(
}

/* NOTE: as a special trick we can pass an NSInputStream object as data to directly read from a file */

+ (NSArray *) imageRepsWithData:(NSData *)data
{
	GSBitmapImageRepPNG *imageRep;
	png_structp read_ptr;
	png_infop read_info_ptr, end_info_ptr;
	png_uint_32 y, width, height;
	int unit;
	png_uint_32 res_x, res_y;
	NSSize size;
	int num_pass, pass;
	int bit_depth, color_type, intent;
	unsigned long row_bytes;
	int interlace_type, compression_type, filter_type;
	const char *png_data;
	char *buffer;
	BOOL alpha;
	BOOL fromStream=[data isKindOfClass:[NSInputStream class]];
	// png_color_16p background;
	double screen_gamma = 2.2;				// A good guess for a PC monitor
	NSAssert(data, @"PNG imageRep data is nil");
	if(fromStream)
		{ // check header
		const unsigned char header[PNG_HEADER_LENGTH];
		[(NSInputStream *) data read:(uint8_t *) header maxLength:PNG_HEADER_LENGTH];
		if(png_sig_cmp((png_bytep) header, 0, PNG_HEADER_LENGTH))
			return nil;	/* not a PNG */
		}
	else
		{
		png_data = [data bytes];
#if 0
		NSLog(@"PNG data %p", png_data);
#endif

		if(png_sig_cmp((png_bytep) png_data, 0, PNG_HEADER_LENGTH))
			return nil;	/* not a PNG */
		}

	read_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING,NULL,NULL,NULL);
	if(!read_ptr)
		return nil;
	png_set_error_fn(read_ptr, (png_voidp)NULL, png_error_handler, NULL);	// use default implementation for warnings
	read_info_ptr = png_create_info_struct(read_ptr);
	if (!read_info_ptr)
		{
		png_destroy_read_struct(&read_ptr, NULL, NULL);
		return nil;
		}
	end_info_ptr = png_create_info_struct(read_ptr);
	if (!end_info_ptr)
		{
		png_destroy_read_struct(&read_ptr, &read_info_ptr, NULL);
		return nil;
		}
	// Establish the setjmp return context
	// for my_error_exit to use.
	if (setjmp(png_jmpbuf(read_ptr)))
		{
		png_destroy_read_struct(&read_ptr, &read_info_ptr, &end_info_ptr);
		NSLog(@"error while decompressing PNG");
//		[NSException raise:NSTIFFException format: @"invalid PNG image"];
		abort();
		return nil;
		}
	//	NSLog(@"png 1");
	png_set_read_status_fn(read_ptr, NULL);
	// NSLog(@"png 2");
	if(fromStream)
		{
		png_set_read_fn(read_ptr, (png_voidp)data, png_read_NSInputStream);
		png_set_sig_bytes(read_ptr, PNG_HEADER_LENGTH);	// header already read
		}
	else
		{
		png_set_read_fn(read_ptr, (png_voidp)&png_data, png_read);
		// NSLog(@"png 3");
		png_set_sig_bytes(read_ptr, 0);
		}
	// NSLog(@"png 4");
	png_read_info(read_ptr, read_info_ptr);
	// NSLog(@"png 5");

	if (!png_get_IHDR(read_ptr, read_info_ptr, &width, &height, &bit_depth,
			&color_type, &interlace_type, &compression_type, &filter_type))
		NSLog(@"error reading PNG IHDR");
#if 0
	NSLog(@"png: width=%d height=%d", width, height);
#endif
	if (png_get_valid(read_ptr, read_info_ptr, PNG_INFO_tRNS))
		{									// Expand paletted or RGB images
		png_set_tRNS_to_alpha(read_ptr);	// with transparency to full alpha
		alpha = YES;						// channels so the data will be
		}									// available as RGBA quartets.
	else
		alpha = (color_type & PNG_COLOR_MASK_ALPHA) != 0;
	// expand palette images to RGB, low-bit-depth grayscale, images to 8 bits, transparency chunks to full alpha channel.
	if (color_type == PNG_COLOR_TYPE_PALETTE || (color_type == PNG_COLOR_TYPE_GRAY && bit_depth < 8))
		png_set_expand(read_ptr);
	if (png_get_valid(read_ptr, read_info_ptr, PNG_INFO_tRNS))
		png_set_expand(read_ptr);
	if (bit_depth == 16)					// strip 16-bit-per-sample
		png_set_strip_16(read_ptr);			// images to 8 bits per sample
	if (color_type == PNG_COLOR_TYPE_GRAY
			|| color_type == PNG_COLOR_TYPE_GRAY_ALPHA)
		png_set_gray_to_rgb(read_ptr);		// convert grayscale to RGB[A]

	if (png_get_sRGB(read_ptr, read_info_ptr, &intent))
		png_set_gamma(read_ptr, screen_gamma, 0.45455);
	else
		{ // Tell libpng to handle gamma conversion
		double image_gamma;	
		if (png_get_gAMA(read_ptr, read_info_ptr, &image_gamma))
			png_set_gamma(read_ptr, screen_gamma, image_gamma);
		else
			png_set_gamma(read_ptr, screen_gamma, 0.45455);
		}
	// NSLog(@"png 6");

	num_pass = png_set_interlace_handling(read_ptr);
	png_read_update_info(read_ptr, read_info_ptr);
	row_bytes = png_get_rowbytes(read_ptr, read_info_ptr);

	imageRep = [[[self alloc] initWithBitmapDataPlanes: NULL
						 pixelsWide: width
						 pixelsHigh: height
						 bitsPerSample: 8
						 samplesPerPixel: (alpha ? 4 : 3)
						 hasAlpha: alpha
						 isPlanar: NO
						 colorSpaceName: NSDeviceRGBColorSpace
						 bitmapFormat:NSAlphaNonpremultipliedBitmapFormat
						 bytesPerRow: row_bytes
						 bitsPerPixel: png_get_bit_depth(read_ptr, read_info_ptr)] autorelease];

#if 0	// this header may not exist...
	if(png_get_sCAL(read_ptr, read_info_ptr, &unit, &size.width, &size.height))
		{ // PNG defines physical size
	  // skalieren?
		NSLog(@"PNG default size: %@", NSStringFromSize([imageRep size]));
		NSLog(@"PNG calibrated size: %@", NSStringFromSize(size));
	  //		[imageRep setSize:size];
		}
#endif

	if(png_get_pHYs(read_ptr, read_info_ptr, &res_x, &res_y, &unit))
		{
		if(unit == PNG_RESOLUTION_METER)
			{ // scale by dots per meter
#if 0
			NSLog(@"png: width=%d height=%d", width, height);	// in pixels
			NSLog(@"PNG png_get_pHYs: %u %u", res_x, res_y);
#endif
			res_x = rint(0.0254*res_x);	// convert and round to DPI
			res_y = rint(0.0254*res_y);
#if 0
			NSLog(@"PNG png_get_pHYs as DPI: %u %u", res_x, res_y);
#endif
			if(res_x > 0 && res_y > 0)	// protect against data leading to DIV0
				{
				size = NSMakeSize((72*width)/res_x, (72*height)/res_y);	// convert to point
#if 0
				NSLog(@"PNG default size: %@", NSStringFromSize([imageRep size]));
				NSLog(@"PNG calibrated size: %@", NSStringFromSize(size));
#endif
				[imageRep setSize:size];
				}
			}
		}

	buffer = (char *) [imageRep bitmapData];

	for (pass = 0; pass < num_pass; pass++)
		{
		for (y = 0; y < height; y++)
			{
			png_bytep ptr = (unsigned char *)buffer + y * row_bytes;
			png_read_row(read_ptr, ptr, NULL);
			}
		// here we could display an interlaced image
		}

	png_read_end(read_ptr, end_info_ptr);
	png_destroy_read_struct(&read_ptr, &read_info_ptr, &end_info_ptr);

#if 0
	NSLog(@"PNG image rep size %@", NSStringFromSize([imageRep size]));
#endif
#if 0
	NSLog(@"PNG image rep %@", imageRep);
#endif
	return [NSArray arrayWithObject:imageRep];
}
												// Loads only the default image
- (id) initWithData:(NSData *)data				// (first) from TIFF contained
{												// in data.
	return self;
}

static void png_write(png_structp png_ptr, png_bytep row, int pass)
{
	NSMutableData *png_data=png_get_io_ptr(png_ptr);
	/* put your code here */
}

+ (NSData *) representationOfImageRepsInArray:(NSArray *)imageReps usingType:(NSBitmapImageFileType)storageType properties:(NSDictionary *)properties
{ // create PNG file (ignore storageType)
	NSBitmapImageRep *irep=[imageReps objectAtIndex:0];	// save first only
	NSMutableData *data;
	id val;	// property values
	if([imageReps count] != 1)
		return nil;	// FIXME: raise exception
	if(storageType != NSPNGFileType)
		return nil;
	data=[NSMutableData dataWithCapacity:([irep bytesPerPlane]*[irep numberOfPlanes]+1000)];	// should be enough for uncompressed data
#if BITMAP_WRITING
	png_structp png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, (png_voidp)user_error_ptr, user_error_fn, user_warning_fn);
	png_infop info_ptr;
	if(!png_ptr)
		return nil;
	info_ptr = png_create_info_struct(png_ptr);
	if (!info_ptr)
	{
		png_destroy_write_struct(&png_ptr, (png_infopp)NULL);
		return nil;
	}
	if (setjmp(png_jmpbuf(png_ptr)))
	{
		png_destroy_write_struct(&png_ptr, &info_ptr);
		return nil;
	}
	// set png_ptr->ip_ptr to data object
	val=[properties objectForKey:@"xxx"];	// get values for the following calls from properties
	png_set_write_status_fn(png_ptr, png_write);
	png_set_compression_level(png_ptr, Z_BEST_COMPRESSION);
	png_set_compression_mem_level(png_ptr, 8);
	png_set_compression_strategy(png_ptr, Z_DEFAULT_STRATEGY);
	png_set_compression_window_bits(png_ptr, 15);
	png_set_compression_method(png_ptr, 8);
	png_set_compression_buffer_size(png_ptr, 8192);

	png_set_IHDR(png_ptr, info_ptr, [irep width], [irep height],
				 bit_depth, color_type, interlace_type,
				 PNG_COMPRESSION_TYPE_DEFAULT, PNG_FILTER_TYPE_DEFAULT);
/*
	bit_depth	  - holds the bit depth of one of the
					 image channels.
					 (valid values are 1, 2, 4, 8, 16
					 and depend also on the
					 color_type.  See also significant
					 bits (sBIT) below).
	color_type	 - describes which color/alpha
					 channels are present.
					 PNG_COLOR_TYPE_GRAY
						(bit depths 1, 2, 4, 8, 16)
					 PNG_COLOR_TYPE_GRAY_ALPHA
						(bit depths 8, 16)
					 PNG_COLOR_TYPE_PALETTE
						(bit depths 1, 2, 4, 8)
					 PNG_COLOR_TYPE_RGB
						(bit_depths 8, 16)
					 PNG_COLOR_TYPE_RGB_ALPHA
						(bit_depths 8, 16)

					 PNG_COLOR_MASK_PALETTE
					 PNG_COLOR_MASK_COLOR
					 PNG_COLOR_MASK_ALPHA

	interlace_type - PNG_INTERLACE_NONE or
					 PNG_INTERLACE_ADAM7
	*/
	png_set_PLTE(png_ptr, info_ptr, palette, 0);
	png_set_gAMA(png_ptr, info_ptr, 2.2);
/*
	png_set_sRGB(png_ptr, info_ptr, srgb_intent);
	srgb_intent	- the rendering intent
					 (PNG_INFO_sRGB) The presence of
					 the sRGB chunk means that the pixel
					 data is in the sRGB color space.
					 This chunk also implies specific
					 values of gAMA and cHRM.  Rendering
					 intent is the CSS-1 property that
					 has been defined by the International
					 Color Consortium
					 (http://www.color.org).
					 It can be one of
					 PNG_sRGB_INTENT_SATURATION,
					 PNG_sRGB_INTENT_PERCEPTUAL,
					 PNG_sRGB_INTENT_ABSOLUTE, or
					 PNG_sRGB_INTENT_RELATIVE.

	png_set_sRGB_gAMA_and_cHRM(png_ptr, info_ptr,
	   srgb_intent);
	srgb_intent	- the rendering intent
					 (PNG_INFO_sRGB) The presence of the
					 sRGB chunk means that the pixel
					 data is in the sRGB color space.
					 This function also causes gAMA and
					 cHRM chunks with the specific values
					 that are consistent with sRGB to be
					 written.
					  */
	/* get iCCP from [irep colorSpace];
	png_set_iCCP(png_ptr, info_ptr, name, NULL,
					  profile, proflen);
	name			- The profile name.
	compression	 - The compression type; always
					  PNG_COMPRESSION_TYPE_BASE for PNG 1.0.
					  You may give NULL to this argument to
					  ignore it.
	profile		 - International Color Consortium color
					  profile data. May contain NULs.
	proflen		 - length of profile data in bytes.
		*/

	png_set_sBIT(png_ptr, info_ptr, 8);
	png_set_tRNS(png_ptr, info_ptr, trans, num_trans, trans_values);
	png_set_hIST(png_ptr, info_ptr, hist);
	png_set_tIME(png_ptr, info_ptr, mod_time);
	png_set_bKGD(png_ptr, info_ptr, background);
/*
 text_ptr[i].compression - type of compression used
		on "text" PNG_TEXT_COMPRESSION_NONE
		PNG_TEXT_COMPRESSION_zTXt
		PNG_ITXT_COMPRESSION_NONE
		PNG_ITXT_COMPRESSION_zTXt
		text_ptr[i].key   - keyword for comment.  Must contain
			1-79 characters.
			text_ptr[i].text  - text comments for current
				keyword.  Can be NULL or empty.
				text_ptr[i].text_length - length of text string,
					after decompression, 0 for iTXt
						text_ptr[i].itxt_length - length of itxt string,
							after decompression, 0 for tEXt/zTXt
								text_ptr[i].lang  - language of comment (NULL or
																		 empty for unknown).
									text_ptr[i].translated_keyword  - keyword in UTF-8 (NULL
																						or empty for unknown).
									num_text	   - number of comments
									png_set_text(png_ptr, info_ptr, text_ptr, num_text);
*/
	
	png_set_pHYs(png_ptr, info_ptr, res_x, res_y, PNG_RESOLUTION_METER);	// here we may store size.width&size.height
	png_set_sCAL(png_ptr, info_ptr, unit, width, height);	// ditto
	png_set_sCAL_s(png_ptr, info_ptr, unit, "2.54", "2.54");
/*
 
	Title			Short (one line) title or caption for image
	Author		   Name of image's creator
	Description	  Description of image (possibly long)
	Copyright		Copyright notice
	Creation Time	Time of original image creation (usually RFC 1123 format, see below)
	Software		 "mySTEP"
	Disclaimer	   Legal disclaimer
	Warning		  Warning of nature of content
	Source		   Device used to create the image
	Comment		  Miscellaneous comment; conversion from other image format
*/
	
//	png_set_invert_alpha(png_ptr);
	png_write_info(png_ptr, info_ptr);
	// setup row pointers png_byte *row_pointers[height]; -> malloc() them!
	png_write_image(png_ptr, row_pointers);
	png_write_end(png_ptr, info_ptr);
	png_destroy_write_struct(&png_ptr, &info_ptr);
#endif
	return data;
}

@end /* GSBitmapImageRepPNG */

//*****************************************************************************
//
// 		GSBitmapImageRepGIF 
//
//*****************************************************************************

@interface GSBitmapImageRepGIF : NSBitmapImageRep
@end

@implementation GSBitmapImageRepGIF 

static NSArray *__bitmapImageRepsGIF;

+ (void) initialize
{
	if (self == [GSBitmapImageRepGIF class])
		{
		__bitmapImageRepsGIF = [[NSArray arrayWithObjects: @"gif", nil] retain];
		[NSImageRep registerImageRepClass: [GSBitmapImageRepGIF class]];
		}
}

+ (BOOL) canInitWithData:(NSData *)data
{
	return [data length] > 6 && memcmp([data bytes], "GIF89a", 6) == 0;
}

+ (NSArray *) imageFileTypes				{ return __bitmapImageRepsGIF; }
+ (NSArray *) imageUnfilteredFileTypes		{ return __bitmapImageRepsGIF; }

typedef struct {
	char *data;
	long size;
	long position;
} GIF;

static GIF * 
GIFOpenData(char *data, long size)
{												// Open a tiff from a stream. 
GIF *handle;									// Returns NULL if can't read 
												// the tiff info.
	NSDebugLog (@"GIFOpenData\n");
	handle = objc_malloc (sizeof(GIF));
	handle->data = data;
	handle->position = 0;
	handle->size = size;

	return handle;
}

static int
ReadGIF(GifFileType *handle, GifByteType *buf, int count)
{
	GIF *chand = (GIF *)handle->UserData;

	NSDebugLog (@"ReadGIF\n");
	if (chand->position >= chand->size)
		return 0;
	if (chand->position + count > chand->size)
		count = chand->size - chand->position;
	memcpy(buf, chand->data + chand->position, count);
	chand->position += count;

	return count;
}

static int
ReadGIFToBuf(GifFileType *GifFile, GIF *handle, char *data)
{
	int	i, j, k, Width, Height, ExtCode;
	GifRecordType RecordType = UNDEFINED_RECORD_TYPE;
	GifByteType *Extension;
	unsigned char *buffer=NULL;
	static ColorMapObject *ColorMap;
	static GifColorType *ColorMapEntry;
	
	NSDebugLog (@"ReadGIFToBuf\n");
	
	while (RecordType != TERMINATE_RECORD_TYPE)
		{
		if (DGifGetRecordType(GifFile, &RecordType) == GIF_ERROR)
			return 6;
		
		switch (RecordType)					// Scan the content of the GIF file
			{
			case IMAGE_DESC_RECORD_TYPE:
				if (DGifGetImageDesc(GifFile) == GIF_ERROR)
					return 1;
				
				Width = GifFile->Image.Width;
				Height = GifFile->Image.Height;
				ColorMap = (GifFile->Image.ColorMap
							? GifFile->Image.ColorMap : GifFile->SColorMap);
				
				buffer = objc_malloc(Width * sizeof(GifColorType));
				[NSData dataWithBytesNoCopy:buffer length:Width * sizeof(GifColorType) freeWhenDone:YES];	// free on autorelease
				
				if (GifFile->Image.Interlace) 
					{ // Need to perform 4 passes on interlaced images
					unsigned char *GifRow = buffer;
					int offset[] = { 0, 4, 2, 1 };
					int jump[] = { 8, 8, 4, 2 };
					
					NSLog (@"(GifFile->Image.Interlace)\n");
					
					for (i = 0; i < 4; i++)
						{
						for (k = offset[i]; k < Height; k += jump[i])
							{
							unsigned char *p;
							
							if (DGifGetLine(GifFile, buffer, Width) == GIF_ERROR)
								return 2;
							
							p = (unsigned char *)data + (k * Width * 4);		// assume RGBA
							for (j = 0; j < Width; j++)
								{
									if(GifRow[j] == GifFile->SBackGroundColor)
											{ // transparent
												*p++ = 0;
												*p++ = 0;
												*p++ = 0;
												*p++ = 0;
											}
									else
											{	// opaque
												ColorMapEntry = &ColorMap->Colors[GifRow[j]];
												*p++ = ColorMapEntry->Red;
												*p++ = ColorMapEntry->Green;
												*p++ = ColorMapEntry->Blue;
												*p++ = 255;
											}
								}
							}
						}
					}
					else
						{
						for (i = 0; i < Height; i++)
							{
							unsigned char *GifRow = buffer;
							unsigned char *p;
							
							if (DGifGetLine(GifFile, buffer, Width) == GIF_ERROR)
								return 3;
							
							p = (unsigned char *)data + (i * Width * 4);		// assume RGBA
							for (j = 0; j < Width; j++)
								{
									if(GifRow[j] == GifFile->SBackGroundColor)
											{ // transparent color
												*p++ = 0;
												*p++ = 0;
												*p++ = 0;
												*p++ = 0;
											}
									else
											{	// opaque
												ColorMapEntry = &ColorMap->Colors[GifRow[j]];
												*p++ = ColorMapEntry->Red;
												*p++ = ColorMapEntry->Green;
												*p++ = ColorMapEntry->Blue;
												*p++ = 255;
											}
								}
							}
						}
					break;
				
			case EXTENSION_RECORD_TYPE:	   // Skip any extension blocks in file
				
				if (DGifGetExtension(GifFile,&ExtCode,&Extension) == GIF_ERROR)
					return 4;
				
				while (Extension != NULL)
					if (DGifGetExtensionNext(GifFile, &Extension) == GIF_ERROR)
						return 5;
				break;
				
			case TERMINATE_RECORD_TYPE:
			default:				// Should be trapped by DGifGetRecordType
				break;
			}
		}
	
	return 0;
}

+ (NSArray *) imageRepsWithData:(NSData *)data
{
	GSBitmapImageRepGIF *imageRep;
	GIF *handle;
	GifFileType *GifFile;
	NSAssert(data, @"GIF imageRep data is nil");		

	handle = GIFOpenData((char *)[data bytes], [data length]);
	GifFile = DGifOpen(handle, ReadGIF);
	
#if 0
	NSLog(@"GifFile->SWidth=%d", GifFile->SWidth);
	NSLog(@"GifFile->SHeight=%d", GifFile->SHeight);
	NSLog(@"GifFile->SBackGroundColor=%d", GifFile->SBackGroundColor);	// should define the transparent one... (which one if we have none?)
	NSLog(@"GifFile->SColorResolution=%d", GifFile->SColorResolution);	// number of colors per primary color in original -> this is the number of bits per pixel and has nothing to do with the number of planes!
	NSLog(@"GifFile->SColorMap->BitsPerPixel=%d", GifFile->SColorMap->BitsPerPixel);	// should be the same as GifFile->SColorResolution
#endif
	
	imageRep = [[[self alloc] initWithBitmapDataPlanes: NULL
						 pixelsWide: GifFile->SWidth
						 pixelsHigh: GifFile->SHeight
						 bitsPerSample: 8		// we always convert into 8 bit per pixel
						 samplesPerPixel: 4	// we always have RGBA
						 hasAlpha: YES	
						 isPlanar: NO
						 colorSpaceName: NSCalibratedRGBColorSpace
						 bytesPerRow: 0
						 bitsPerPixel: 0] autorelease];
												// read gif into data array
	if(ReadGIFToBuf(GifFile, handle, (char *) [imageRep bitmapData]))
		{
		NSLog(@"error while decompressing GIF");
//		[NSException raise:NSTIFFException format: @"invalid GIF image"];
		return nil;
		}
	// FIXME: expand background color to alpha
	return [NSArray arrayWithObject:imageRep];
}

- (id) initWithData:(NSData *)data
{
	return self;
}

@end /* GSBitmapImageRepGIF */

//*****************************************************************************
//
// 		GSBitmapImageRepJPEG 
//
//*****************************************************************************

@interface GSBitmapImageRepJPEG : NSBitmapImageRep
@end

@implementation GSBitmapImageRepJPEG 

static NSArray *__bitmapImageRepsJPG;

+ (void) initialize				// in practice, only two of them can load in	 
{								// data from an external source.
	if (self == [GSBitmapImageRepJPEG class])
		{
		__bitmapImageRepsJPG = [[NSArray arrayWithObjects: @"jpeg", @"jpg",nil] retain];
//		_pbBitmapImageReps = [NSArray arrayWithObjects: NSTIFFPboardType, nil];
		[NSImageRep registerImageRepClass: [GSBitmapImageRepJPEG class]];
		}
}

+ (BOOL) canInitWithData:(NSData *)data
{
	return [data length] > 10 && memcmp([data bytes], "\xff\xd8\xff\xe0\x00\x10JFIF", 10) == 0;
}

+ (NSArray *) imageFileTypes				{ return __bitmapImageRepsJPG; }
+ (NSArray *) imageUnfilteredFileTypes		{ return __bitmapImageRepsJPG; }

struct my_error_mgr {
	struct jpeg_error_mgr pub;		// "public" fields
	jmp_buf setjmp_buffer;			// setjmp for error recovery
};

typedef struct my_error_mgr *my_error_ptr;

 									// Here's the routine that will replace the 
METHODDEF(void)						// standard error_exit method:
jpg_error_exit (j_common_ptr cinfo)
{									// cinfo->err really points to a 
									// my_error_mgr struct, so coerce pointer
	my_error_ptr myerr = (my_error_ptr) cinfo->err;
									// Display the message.  could postpone
									// this til after return, if we choose.
	(*cinfo->err->output_message) (cinfo);

	longjmp(myerr->setjmp_buffer, 1);	// Return control to the setjmp point
}

								// Expanded data source object for stdio input
typedef struct {
	struct jpeg_source_mgr pub;		// public fields
	FILE *infile;					// source stream
	JOCTET *buffer;					// start of buffer
	boolean start_of_file;			// have we gotten any data yet?
} my_source_mgr;

typedef my_source_mgr * my_src_ptr;


METHODDEF(boolean)								// Fill input buffer, called 
gs_fill_input_buffer (j_decompress_ptr cinfo)	// whenever buffer is emptied.
{
my_src_ptr src = (my_src_ptr) cinfo->src;

	src->start_of_file = FALSE;
	
	return TRUE;
}
						// Skip data --- used to skip over a potentially large 
METHODDEF(void)			// amount of uninteresting data such as an APPn marker
gs_skip_input_data (j_decompress_ptr cinfo, long num_bytes)
{
my_src_ptr src = (my_src_ptr) cinfo->src;
				// Just a dumb implementation for now.  Could use fseek() 
				// except it doesn't work on pipes.  Not clear that being smart 
				// is worth any trouble anyway --- large skips are infrequent.
	if (num_bytes > 0) 
		{
		while (num_bytes > (long) src->pub.bytes_in_buffer) 
			{
			num_bytes -= (long) src->pub.bytes_in_buffer;
			(void) gs_fill_input_buffer(cinfo);
				// note we assume that gs_fill_input_buffer will never return 
				// FALSE, so suspension need not be handled.
			}
		src->pub.next_input_byte += (size_t) num_bytes;
		src->pub.bytes_in_buffer -= (size_t) num_bytes;
		}
}

+ (NSArray *) imageRepsWithData:(NSData *)data
{				// struct containing the JPEG decompression parameters and 
				// pointers to working space (which is allocated as needed by 
				// the JPEG library).
	struct jpeg_decompress_struct cinfo;
				// We use our private extension JPEG error handler.  Note that 
				// this struct must live as long as the main JPEG parameter
				// struct, to avoid dangling-pointer problems.
	struct my_error_mgr jerr;
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:1];
	GSBitmapImageRepJPEG *imageRep;
	JSAMPROW buffer[1];						// Set up normal JPEG error routines, 
											// then override error_exit.
	NSAssert(data, @"JPEG imageRep data is nil");		
	cinfo.err = jpeg_std_error(&jerr.pub);
	jerr.pub.error_exit = jpg_error_exit;
										// Establish the setjmp return context 
	if (setjmp(jerr.setjmp_buffer)) 	// for jpg_error_exit to use.
		{		// If we get here, the JPEG code has signaled an error. Need to
				// clean up the JPEG object, close the input file, and return.
		jpeg_destroy_decompress(&cinfo);
		NSLog(@"error while decompressing JPEG");
//		[NSException raise:NSTIFFException format: @"invalid JPEG image"];
		return nil;
		}

	jpeg_create_decompress(&cinfo);				// init JPEG decompression obj
	jpeg_stdio_src(&cinfo, (FILE *)NULL);		// specify the JPEG data source

	cinfo.src->fill_input_buffer = &gs_fill_input_buffer;
	cinfo.src->skip_input_data = &gs_skip_input_data;
	cinfo.src->next_input_byte = [data bytes];
	cinfo.src->bytes_in_buffer = [data length];

	jpeg_read_header(&cinfo, TRUE);

	if(cinfo.jpeg_color_space == JCS_GRAYSCALE)
		cinfo.out_color_space = JCS_GRAYSCALE;
	else
		cinfo.out_color_space = JCS_RGB;
	cinfo.quantize_colors = FALSE;
	cinfo.do_fancy_upsampling = FALSE;
	cinfo.do_block_smoothing = FALSE;

	jpeg_calc_output_dimensions(&cinfo);
	jpeg_start_decompress(&cinfo);

	imageRep = [[[self alloc] initWithBitmapDataPlanes: NULL
									  pixelsWide: cinfo.image_width
									  pixelsHigh: cinfo.image_height
									  bitsPerSample: 8
									  samplesPerPixel: cinfo.num_components
									  hasAlpha: (cinfo.num_components > 3)
									  isPlanar: NO
									  colorSpaceName: NSDeviceRGBColorSpace
									  bytesPerRow: 0
									  bitsPerPixel: 0] autorelease];
//	imageRep->compression = info->compression;

	buffer[0] = [imageRep bitmapData];

	while (cinfo.output_scanline < cinfo.output_height)
		{
		jpeg_read_scanlines(&cinfo, buffer, (JDIMENSION)1);
		buffer[0] += (cinfo.output_width * 3);		// data is in RGB planes
		}											// so mult by row stride

	jpeg_finish_decompress(&cinfo);
	jpeg_destroy_decompress(&cinfo);				// release jpg and it's mem

	[array addObject: imageRep];

	return array;
}
												// Loads only the default image
- (id) initWithData:(NSData *)data				// (first) from TIFF contained
{										 		// in data.
	return self;
}

+ (NSData *) representationOfImageRepsInArray:(NSArray *)imageReps usingType:(NSBitmapImageFileType)storageType properties:(NSDictionary *)properties
{
	return nil;
}

@end /* GSBitmapImageRepJPEG */


@interface NSData (ResourceManager)
- (int32_t) resourceType;
- (uint32_t) resourceSize;
- (NSData *) resourceData;		// full resource data (i.e. incl. 8 bytes header!)
@end

@interface NSData (ResourceManagerForICNS)
- (NSData *) subResourceWithType:(int32_t) type len:(uint32_t *) len;   // get subresource
@end

@implementation NSData (ResourceManager)

- (int32_t) resourceType;
{
	int32_t type;
	if([self length] < sizeof(type))
		return 0;	// file too short
	[self getBytes:&type length:sizeof(type)];	// first 4 bytes
	type=NSSwapBigIntToHost(type);	// is stored in big endian order (i.e. PowerPC) and may need to be swapped
#if 0
	NSLog(@"resource type=%4c %08x", type, type);
#endif
	return type;
}

- (uint32_t) resourceSize;
{
	uint32_t size=0;
#if 0
	NSLog(@"range=%@", NSStringFromRange(NSMakeRange(sizeof(int32_t), sizeof(size))));
#endif
	if([self length] < sizeof(uint32_t)+sizeof(size))
		return 0;	// file too short
	[self getBytes:&size range:NSMakeRange(sizeof(int32_t), sizeof(size))];	// second 4 bytes
	size=NSSwapBigIntToHost(size);	// is stored in big endian order (i.e. PowerPC) and needs to be swapped for the ARM processor
	if(size > [self length])
		{
		NSLog(@"invalid resource: resource len=%u/%x > NSData len=%u", size, size, (uint32_t)[self length]);
		NSLog(@"NSData = %@", self);
		}
	return size;
}

- (NSData *) resourceData;
{ // get data (without header)
	return [self subdataWithRange:NSMakeRange(sizeof(int32_t)+sizeof(uint32_t),
											  [self resourceSize]-(sizeof(int32_t)+sizeof(uint32_t)))];
}

@end

@implementation NSData (ResourceManagerForICNS)

- (NSData *) subResourceWithType:(int32_t) t len:(uint32_t *) len;
{ // get named subresource (from catenated list of resources); return length of contents
	NSInteger off=0;
	uint32_t size;
	NSInteger cnt=[self length];
	for(off=0; off < cnt; off+=size)
		{
		int32_t type;
		[self getBytes:&type range:NSMakeRange(off, sizeof(type))];	// type
		[self getBytes:&size range:NSMakeRange(off+sizeof(type), sizeof(size))];	// size
		size=NSSwapBigIntToHost(size);	// is stored in big endian order (i.e. PowerPC) and needs to be swapped for the ARM processor
		type=NSSwapBigIntToHost(type);
		if(off+size > cnt)
			{
#if 0
			NSLog(@"subResourceOfType:'%c%c%c%c' %08x length error: off=%u size=%u cnt=%u", type>>24, type>>16, type>>8, type, type, off, size, cnt);
#endif
			return nil;	// length error
			}
#if 0
		NSLog(@"subResourceOfType:'%c%c%c%c' %08x found", type>>24, type>>16, type>>8, type, type);
#endif
		if(type == t)
			{ // found!
			if(len)
				*len=size-sizeof(type)-sizeof(size);	// payload length
#if 0
			NSLog(@"offset=%u len=%u", off, size);
#endif
			return [self subdataWithRange:NSMakeRange(off, size)];	// cut out resource (incl. type&size)
			}
		}
	return nil; // not found
}

@end

//*****************************************************************************
//
// 		GSBitmapImageRepICNS
//
//*****************************************************************************

// don't use 'icns' etc. but REG('i', 'c', 'n', 's')

#define RES(A, B, C, D) (((A)<<24)+((B)<<16)+((C)<<8)+(D))

@interface GSBitmapImageRepICNS : NSBitmapImageRep
@end

@implementation GSBitmapImageRepICNS 

static NSArray *__bitmapImageRepsICNS;

+ (void) initialize				// in practice, only two of them can load in data from an external source.
{ 
	__bitmapImageRepsICNS = [[NSArray arrayWithObjects: @"icns", nil] retain];
	[NSImageRep registerImageRepClass:[self class]];
}

+ (BOOL) canInitWithData:(NSData *)data
{
#if 0
	NSLog(@"GSBitmapImageRepICNS canInitWithData");
#endif
	return [data resourceType] == RES('i', 'c', 'n', 's');
}

+ (NSArray *) imageFileTypes				{ return __bitmapImageRepsICNS; }
+ (NSArray *) imageUnfilteredFileTypes		{ return __bitmapImageRepsICNS; }

// based on description at http://www.macdisk.com/maciconen.php3
// and Python code found on the net
// and http://ezix.org/project/wiki/MacOSXIcons

#if SUPPORTSPLANAR	// should be faster...
#define set_pixel(offset, plane, val)		bitmap[(offset)+bytesPerRow*(plane)]=(val)				// for planar bitmap
#else
#define set_pixel(offset, plane, val)		bitmap[samplesPerPixel*(offset)+(plane)]=(val)		// for meshed bitmap
#endif
// #define set_pixel_xy(x, y, plane, val)	set_pixel((x)+width*(y), (plane), (val))		// not used

+ (NSArray *) imageRepsWithData:(NSData *)data
{
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:1];
	NSBitmapImageRep *imageRep;
	int i;
	static struct
		{
			int32_t rgb;
			int32_t mask;
			int width;
			int height;
			int depth;
			int skip;		// ... In some icon sizes, there is a 32bit integer at the beginning of the run, whose role remains unknown.
			BOOL isJPEG2000;
		} reps[]=
		{
			//		{ RES('i', 'c', 's', '#'), RES('?', '?', '?', '?'), 16, 16, 1 },
			//		{ RES('I', 'C', 'N', '#'), RES('?', '?', '?', '?'), 32, 32, 1 },
			{ RES('i', 's', '3', '2'), RES('s', '8', 'm', 'k'), 16, 16, 8, 0 },
			{ RES('i', 'l', '3', '2'), RES('l', '8', 'm', 'k'), 32, 32, 8, 0 },
			{ RES('i', 'h', '3', '2'), RES('h', '8', 'm', 'k'), 48, 48, 8, 0 },
			{ RES('i', 't', '3', '2'), RES('t', '8', 'm', 'k'), 128, 128, 8, 4 },
			{ RES('i', 'c', '0', '8'), RES('?', '?', '?', '?'), 256, 256, 8, 0, YES },
			{ RES('i', 'c', '0', '9'), RES('?', '?', '?', '?'), 512, 512, 8, 0, YES },
//			{ RES('i', 'c', 'n', 'V'), RES('?', '?', '?', '?'), 128, 128, 8, 4 },	// version???
		};
#if 0
	NSLog(@"GSBitmapImageRepICNS imageRepsWithData:");
#endif
	NSAssert(data, @"ICNS imageRep data is nil");
	data=[[data subResourceWithType:RES('i', 'c', 'n', 's') len:NULL] resourceData];	// get contents
	if(!data)
		return nil;	// is not an icns resource
#if 0
	NSLog(@"contents=%@ %4c %d", data, [data resourceType], [data resourceSize]);
#endif
#if 0
	[data subResourceWithType:0 len:NULL];	// we won't find and therefore may print all resources in the container
#endif
	for(i=0; i<sizeof(reps)/sizeof(reps[0]); i++)
		{ // get representations
		unsigned long width=reps[i].width;
		unsigned long height=reps[i].height;
		unsigned int bitspersample=reps[i].depth;
		unsigned int samplesPerPixel;
		unsigned long wh=width*height;
		unsigned long wh2=wh+wh;
		unsigned long wh3=wh2+wh;
		unsigned long bytesPerRow;
		uint32_t rgblen;	// size of RGB resource (incl. header!)
		unsigned char *bitmap;
		NSData *rgb=[[data subResourceWithType:reps[i].rgb len:&rgblen] resourceData];
		uint32_t masklen;	// size of mask resource (incl. header!)
		NSData *mask;
		unsigned char *b;	// byte stream from rgb resource
		unsigned long off;
		if(!rgb)
			continue;	// not found
		if(reps[i].isJPEG2000)
				{ // read as JPEG2000 from rgb data (which allows for alpha channel)
					NSLog(@"JPEG ICNS format not implemented");
					imageRep=[[GSBitmapImageRepJPEG alloc] initWithData:rgb];
					if(imageRep)
						[array addObject:imageRep];	// save this representation
					continue;
				}
		mask=[[data subResourceWithType:reps[i].mask len:&masklen] resourceData];	// nil if not existent
		b=(unsigned char *) [rgb bytes]+reps[i].skip;
#if 0
			NSLog(@"rgb=%@", [data subResourceWithType:reps[i].rgb len:&rgblen]);
			NSLog(@"rgb=%@", [[data subResourceWithType:reps[i].rgb len:&rgblen] resourceData]);
			NSLog(@"mask=%@", [data subResourceWithType:reps[i].mask len:&masklen]);
#endif
		samplesPerPixel=(mask != nil)?4:3;	// 4 channels if mask exists
#if 0
			NSLog(@"samplesPerPixel=%d", samplesPerPixel);
#endif
		imageRep = [[[self alloc] initWithBitmapDataPlanes: NULL
														pixelsWide: width
														pixelsHigh: height
													 bitsPerSample: bitspersample
												   samplesPerPixel: samplesPerPixel
														  hasAlpha: (mask != nil)
#if SUPPORTSPLANAR
														  isPlanar: YES
#else
														  isPlanar: NO
#endif
													colorSpaceName: NSDeviceRGBColorSpace
														bitmapFormat: NSAlphaNonpremultipliedBitmapFormat
													   bytesPerRow: 0
													  bitsPerPixel: 0] autorelease];
			bytesPerRow=[imageRep bytesPerRow];
		bitmap=[imageRep bitmapData];	// r, g, b, a planes
		if(rgblen == wh3)
			{ // uncompressed - convert 3 streams to mesh or plane
			int plane;
#if 0
			NSLog(@"uncompressed, len=%u, bpr=%u", wh3, bytesPerRow);
#endif
			for(plane=0; plane<3; plane++)
				{ // streams contain one plane after the other
#if SUPPORTSPLANAR
				memcpy(bitmap+bytesPerRow*plane, b, wh);
				b+=wh;
#else
				for(off=0; off<wh; off++)
					set_pixel(off, plane, *b++);
#endif
				}
			}
		else
			{ // decompress - 3 streams to mesh or plane
			int plane;
#if 0
			NSLog(@"compressed, len=%u, rgblen=%u, bpr=%u", wh3, rgblen, bytesPerRow);
#endif
			off=0;
			plane=0;
			while(plane < 3)
					{
						int cnt;
						if((*b) & 0x80)
								{ // fill a block with next byte
									int pix;
									cnt=(*b++)-125;
									pix=*b++;
#if SUPPORTSPLANAR
									memset(&bitmap[(off)+bytesPerRow*(plane)], cnt, pix);	// copy to plane
									off+=cnt;
#else
									while(cnt-- > 0)
											{
												set_pixel(off, plane, pix);
#if 0
												NSLog(@"(%d, %d, %d) := %d [%d]", off%width, (off%wh)/width, plane, pix, cnt);
#endif
												if(++off >= wh)
														{ // start with next plane
															off=0;
															if(++plane >= 3)
																break;
														}
											}
#endif
								}
						else
								{ // copy a block of given size
									cnt=(*b++)+1;
#if SUPPORTSPLANAR
									memcpy(&bitmap[(off)+bytesPerRow*(plane)], b, cnt);	// copy to plane
									off+=cnt;
#else
									while(cnt-- > 0)
											{
												int pix=*b++;
												set_pixel(off, plane, pix);
#if 0
												NSLog(@"(%d, %d, %d) := %d", off%width, (off%wh)/width, plane, pix);
#endif
												if(++off >= wh)
														{ // start with next plane
															off=0;
															if(++plane >= 3)
																break;
														}
											}
#endif
								}
					}
#if 0
				NSLog(@"bytes read from stream %u (rgblen=%u)", b-(unsigned char *) [rgb bytes], rgblen);
#endif
				if(b-((unsigned char *) [rgb bytes]+reps[i].skip) != rgblen)
						{
							NSLog(@"invalid icns rgb - length error");
							// return nil;
						}
			}
		if(mask)
			{ // mask exists, copy to next plane
				unsigned char *mb;	// byte stream from mask resource
				if(masklen != wh)
						{
							NSLog(@"invalid icns mask - length error");
							return nil;
						}
				mb=(unsigned char *) [mask bytes];	// if it exists
#if 0
			NSLog(@"mask, len=%u", wh);
#endif
#if SUPPORTSPLANAR
				memcpy(&bitmap[(0)+bytesPerRow*(3)], mb, wh);	// copy to plane 3
#else
				for(off=0; off<wh; off++)
					set_pixel(off, 3, *mb++);
#endif
			}
		[array addObject:imageRep];	// save this representation
		}
#if 0
	NSLog(@"incs imageReps = %@", array);
#endif
	return [array count]?array:(NSMutableArray *) nil;	// no representation...
}

// Loads only the default image

- (id) initWithData:(NSData *)data
{
	return self;
}

+ (NSData *) representationOfImageRepsInArray:(NSArray *)imageReps usingType:(NSBitmapImageFileType)storageType properties:(NSDictionary *)properties
{
	return nil;
}

@end /* GSBitmapImageRepICNS */
