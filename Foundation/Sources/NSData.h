/* 
    NSData.h

    Interface to NSData

    Copyright (C) 1995 Free Software Foundation, Inc.

    Author:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
    Date:	1995
   
    H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
    Aligned with 10.5 by Fabian Spillner 23.04.2008
 
    This file is part of the mySTEP Library and is provided
    under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSData
#define _mySTEP_H_NSData

#import <Foundation/NSObject.h>
#import <Foundation/NSRange.h>

@class NSError;
@class NSURL;

typedef enum NSDataReadingOptions
{
	NSDataReadingMappedIfSafe						= 1<<0,
	NSDataReadingUncached							= 1<<1,
	NSDataReadingMappedAlways						= 1<<3,
	/* deprecated */
	NSDataReadingMapped = NSDataReadingMappedIfSafe,
	NSMappedRead = NSDataReadingMapped,
	NSUncachedRead = NSDataReadingUncached,
} NSDataReadingOptions;

typedef enum NSDataWritingOptions
{
	NSDataWritingAtomic								= 1<<0,
	NSDataWritingWithoutOverwriting					= 1<<1,
	NSDataWritingFileProtectionNone					= 0x10<<24,
	NSDataWritingFileProtectionComplete				= 0x20<<24,
	NSDataWritingFileProtectionCompleteUnlessOpen	= 0x30<<24,
	NSDataWritingFileProtectionCompleteUntilFirstUserAuthentication
													= 0x40<<24,
	NSDataWritingFileProtectionMask					= 0xf0<<24,
	/* deprecated */
	NSAtomicWrite = NSDataWritingAtomic,
} NSDataWritingOptions;

typedef enum NSDataBase64EncodingOptions
{
	NSDataBase64Encoding64CharacterLineLength		= 1<<0,
	NSDataBase64Encoding76CharacterLineLength		= 1<<1,
	NSDataBase64EncodingEndLineWithCarriageReturn	= 1<<4,
	NSDataBase64EncodingEndLineWithLineFeed			= 1<<5,

} NSDataBase64EncodingOptions;

typedef enum NSDataBase64DecodingOptions
{
	NSDataBase64DecodingIgnoreUnknownCharacters		= 1<<0,
} NSDataBase64DecodingOptions;

@interface NSData : NSObject <NSCoding, NSCopying, NSMutableCopying>

+ (id) data;
+ (id) dataWithBytes:(const void *) bytes length:(NSUInteger) length;
+ (id) dataWithBytesNoCopy:(void *) bytes length:(NSUInteger) length;
+ (id) dataWithBytesNoCopy:(void *) bytes length:(NSUInteger) length freeWhenDone:(BOOL) flag;
+ (id) dataWithContentsOfFile:(NSString *) path;
+ (id) dataWithContentsOfFile:(NSString *) path options:(NSDataReadingOptions) mask error:(NSError **) errorPtr;
+ (id) dataWithContentsOfMappedFile:(NSString *) path;
+ (id) dataWithContentsOfURL:(NSURL *) url;
+ (id) dataWithContentsOfURL:(NSURL *) aURL options:(NSDataReadingOptions) mask error:(NSError **) errorPtr;
+ (id) dataWithData:(NSData *) data;

- (const void *) bytes;
- (NSString *) description;
- (void) getBytes:(void *) buffer;
- (void) getBytes:(void *) buffer length:(NSUInteger) length;
- (void) getBytes:(void *) buffer range:(NSRange) aRange;
- (id) initWithBytes:(const void *) bytes length:(NSUInteger) length;
- (id) initWithBytesNoCopy:(void *) bytes length:(NSUInteger) length;
- (id) initWithBytesNoCopy:(void *) bytes length:(NSUInteger) length freeWhenDone:(BOOL) flag;
- (id) initWithContentsOfFile:(NSString *) path;
- (id) initWithContentsOfFile:(NSString *) path options:(NSDataReadingOptions) mask error:(NSError **) errorPtr;
- (id) initWithContentsOfMappedFile:(NSString *) path;
- (id) initWithContentsOfURL:(NSURL *) url;
- (id) initWithContentsOfURL:(NSURL *) aURL options:(NSDataReadingOptions) mask error:(NSError **) errorPtr;
- (id) initWithData:(NSData *) data;
- (BOOL) isEqualToData:(NSData *) other;
- (NSUInteger) length;
- (NSData *) subdataWithRange:(NSRange) aRange;
- (BOOL) writeToFile:(NSString *) path atomically:(BOOL) useAuxiliaryFile;
- (BOOL) writeToFile:(NSString *) path options:(NSDataWritingOptions) mask error:(NSError **) errorPtr;
- (BOOL) writeToURL:(NSURL *) url atomically:(BOOL) useAuxiliaryFile;
- (BOOL) writeToURL:(NSURL *) aURL options:(NSDataWritingOptions) mask error:(NSError **) errorPtr;

- (id) initWithBase64EncodedData:(NSData *) data options:(NSDataBase64DecodingOptions) options;
- (id) initWithBase64EncodedString:(NSString *) string options:(NSDataBase64DecodingOptions) options;
- (id) initWithBase64Encoding:(NSString *) string;
- (NSData *) base64EncodedDataWithOptions:(NSDataBase64EncodingOptions)options;
- (NSString *) base64EncodedStringWithOptions:(NSDataBase64EncodingOptions)options;
- (NSString *) base64Encoding;

@end


@interface NSMutableData :  NSData

+ (id) dataWithCapacity:(NSUInteger) numBytes;
+ (id) dataWithLength:(NSUInteger) length;

- (void) appendBytes:(const void *) bytes length:(NSUInteger) length;
- (void) appendData:(NSData *) other;
- (void) increaseLengthBy:(NSUInteger) extraLength;
- (id) initWithCapacity:(NSUInteger) capacity;
- (id) initWithLength:(NSUInteger) length;
- (void *) mutableBytes;
- (void) replaceBytesInRange:(NSRange) aRange withBytes:(const void *) bytes;
- (void) replaceBytesInRange:(NSRange) range 
				   withBytes:(const void *) replacementBytes
					  length:(NSUInteger) replacementLength;
- (void) resetBytesInRange:(NSRange) aRange;
- (void) setLength:(NSUInteger) length;
- (void) setData:(NSData *) data;

@end


#import <Foundation/NSSerialization.h>

#endif /* _mySTEP_H_NSData */
