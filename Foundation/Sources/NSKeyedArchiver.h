/*
   NSKeyedArchiver.h

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: October 1997

   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   Fabian Spillner, May 2008 - API revised to be compatible to 10.5
 
   Copyright (C) 1997 Free Software Foundation, Inc.
   All rights reserved.

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSKeyedArchiver
#define _mySTEP_H_NSKeyedArchiver

#import <Foundation/NSCoder.h>
#import <Foundation/NSPropertyList.h>

@class NSArray, NSMutableArray, NSData, NSDictionary, NSString, NSMutableData, NSMutableDictionary;

extern NSString *NSInvalidArchiveOperationException;
extern NSString *NSInvalidUnarchiveOperationException;

@interface NSKeyedArchiver : NSCoder
{
	NSMutableDictionary *_aliasToClassMappings;
	NSMutableData *_data;
	NSMutableDictionary *_plist;
	id _delegate;
	NSPropertyListFormat _outputFormat;
}

+ (NSData *) archivedDataWithRootObject:(id) rootObject;
+ (BOOL) archiveRootObject:(id) rootObject toFile:(NSString *) path;
+ (NSString *) classNameForClass:(Class) cls;
+ (void) setClassName:(NSString *) codedName forClass:(Class) cls;

- (NSString *) classNameForClass:(Class) cls;
- (id) delegate;
- (void) encodeBool:(BOOL) value forKey:(NSString *) key;
- (void) encodeBytes:(const uint8_t *) bytes length:(NSUInteger) length forKey:(NSString *) key;
- (void) encodeConditionalObject:(id) value forKey:(NSString *) key;
- (void) encodeDouble:(double) value forKey:(NSString *) key;
- (void) encodeFloat:(float) value forKey:(NSString *) key;
- (void) encodeInt32:(int32_t) value forKey:(NSString *) key;
- (void) encodeInt64:(int64_t) intv forKey:(NSString *) key;
- (void) encodeInt:(int) value forKey:(NSString *) key;
- (void) encodeObject:(id) value forKey:(NSString *) key;
- (void) finishEncoding;
- (id) initForWritingWithMutableData:(NSMutableData *) data;
- (NSPropertyListFormat) outputFormat;
- (void) setClassName:(NSString *) codedName forClass:(Class) cls;
- (void) setDelegate:(id) delegate;
- (void) setOutputFormat:(NSPropertyListFormat) format;

@end

@interface NSObject (NSKeyedArchiver)

- (void) archiver:(NSKeyedArchiver *) archiver didEncodeObject:(id) object;
- (id) archiver:(NSKeyedArchiver *) archiver willEncodeObject:(id) object;
- (void) archiver:(NSKeyedArchiver *) archiver willReplaceObject:(id) object withObject:(id) newObject;
- (void) archiverDidFinish:(NSKeyedArchiver *) archiver;
- (void) archiverWillFinish:(NSKeyedArchiver *) archiver;

@end

#define KEY_CHECK 1	// for checking if all available keys are decoded

@interface NSKeyedUnarchiver : NSCoder
{
	NSMutableDictionary *_classToAliasMappings;
	NSData *_data;
	NSDictionary *_objectRepresentation;	// list of attributes
	NSMutableArray *_objects;			// array with all objects (either raw or decoded)
	id _delegate;
#if KEY_CHECK
	NSMutableArray *_unprocessedKeys;
#endif
	unsigned int _sequentialKey;
}

+ (Class) classForClassName:(NSString *) codedName;
+ (void) setClass:(Class) cls forClassName:(NSString *) codedName;
+ (id) unarchiveObjectWithData:(NSData *) data;
+ (id) unarchiveObjectWithFile:(NSString *) path;

- (Class) classForClassName:(NSString *) codedName;
- (BOOL) containsValueForKey:(NSString *) key;
- (BOOL) decodeBoolForKey:(NSString *) key;
- (const uint8_t *) decodeBytesForKey:(NSString *) key returnedLength:(NSUInteger *) length;
- (double) decodeDoubleForKey:(NSString *) key;
- (float) decodeFloatForKey:(NSString *) key;
- (int32_t) decodeInt32ForKey:(NSString *) key;
- (int64_t) decodeInt64ForKey:(NSString *) key;
- (int) decodeIntForKey:(NSString *) key;
- (id) decodeObjectForKey:(NSString *) key;
- (id) delegate;
- (void) finishDecoding;
- (id) initForReadingWithData:(NSData *) data;
- (void) setClass:(Class) cls forClassName:(NSString *) codedName;
- (void) setDelegate:(id) delegate;

@end

@interface NSObject (NSKeyedUnarchiver)

- (Class) unarchiver:(NSKeyedUnarchiver *) unarchiver cannotDecodeObjectOfClassName:(NSString *) name originalClasses:(NSArray *) classNames;
- (id) unarchiver:(NSKeyedUnarchiver *) unarchiver didDecodeObject:(id) object;
- (void) unarchiver:(NSKeyedUnarchiver *) unarchiver willReplaceObject:(id) object withObject:(id) newObject;
- (void) unarchiverDidFinish:(NSKeyedUnarchiver *) unarchiver;
- (void) unarchiverWillFinish:(NSKeyedUnarchiver *) unarchiver;

@end

#endif /* _mySTEP_H_NSKeyedArchiver */
