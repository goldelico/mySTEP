/* 
    NSData.h

    Interface to NSData

    Copyright (C) 1995 Free Software Foundation, Inc.

    Author:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
    Date:	1995
   
    H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
    NSData - aligned with 10.5 by Fabian Spillner 23.04.2008
 
    This file is part of the mySTEP Library and is provided
    under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSData
#define _mySTEP_H_NSData

#import <Foundation/NSObject.h>
#import <Foundation/NSRange.h>

@class NSError;
@class NSURL;

enum _NSDataOptions
{
	NSMappedRead=0x01,
	NSUncachedRead=0x02,
	NSAtomicWrite=0x04	// this differs from the documentation
};

@interface NSData : NSObject <NSCoding, NSCopying, NSMutableCopying>

+ (id) data;
+ (id) dataWithBytes:(const void *) bytes length:(NSUInteger) length;
+ (id) dataWithBytesNoCopy:(void *) bytes length:(NSUInteger) length;
+ (id) dataWithBytesNoCopy:(void *) bytes length:(NSUInteger) length freeWhenDone:(BOOL) flag;
+ (id) dataWithContentsOfFile:(NSString *) path;
+ (id) dataWithContentsOfFile:(NSString *) path options:(NSUInteger) mask error:(NSError **) errorPtr;
+ (id) dataWithContentsOfMappedFile:(NSString *) path;
+ (id) dataWithContentsOfURL:(NSURL *) url;
+ (id) dataWithContentsOfURL:(NSURL *) aURL options:(NSUInteger) mask error:(NSError **) errorPtr;
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
- (id) initWithContentsOfFile:(NSString *) path options:(NSUInteger) mask error:(NSError **) errorPtr;
- (id) initWithContentsOfMappedFile:(NSString *) path;
- (id) initWithContentsOfURL:(NSURL *) url;
- (id) initWithContentsOfURL:(NSURL *) aURL options:(NSUInteger) mask error:(NSError **) errorPtr;
- (id) initWithData:(NSData *) data;
- (BOOL) isEqualToData:(NSData *) other;
- (NSUInteger) length;
- (NSData *) subdataWithRange:(NSRange) aRange;
- (BOOL) writeToFile:(NSString *) path atomically:(BOOL) useAuxiliaryFile;
- (BOOL) writeToFile:(NSString *) path options:(NSUInteger) mask error:(NSError **) errorPtr;
- (BOOL) writeToURL:(NSURL *) url atomically:(BOOL) useAuxiliaryFile;
- (BOOL) writeToURL:(NSURL *) aURL options:(NSUInteger) mask error:(NSError **) errorPtr;

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
