/* 
    NSDictionary.h

    Associate a unique key with a value

    Copyright (C) 1995, 1996 Ovidiu Predescu and Mircea Oancea.
    All rights reserved.

    Author: Mircea Oancea <mircea@jupiter.elcom.pub.ro>

    H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
    Author:	Fabian Spillner <fabian.spillner@gmail.com>
    Date:	28. April 2008 - aligned with 10.5

    This file is part of the mySTEP Library and is provided under the 
    terms of the libFoundation BSD type license (See the Readme file).
*/

#ifndef _mySTEP_H_NSDictionary
#define _mySTEP_H_NSDictionary

#import <Foundation/NSObject.h>
#import <Foundation/NSMapTable.h>

@class NSString;
@class NSArray;
@class NSEnumerator;
@class NSURL;

@interface NSDictionary : NSObject  <NSCoding, NSCopying, NSMutableCopying>

+ (id) dictionary;
+ (id) dictionaryWithContentsOfFile:(NSString *) path;
+ (id) dictionaryWithContentsOfURL:(NSURL *) url;
+ (id) dictionaryWithDictionary:(NSDictionary *) aDict;
+ (id) dictionaryWithObject:(id) object forKey:(id) key;
+ (id) dictionaryWithObjects:(NSArray *) objects forKeys:(NSArray *) keys;
+ (id) dictionaryWithObjects:(id *) objects 
					 forKeys:(id *) keys
					 count:(NSUInteger) count;
+ (id) dictionaryWithObjectsAndKeys:(id) firstObject, ...;

- (NSArray *) allKeys;
- (NSArray *) allKeysForObject:(id) object;
- (NSArray *) allValues;
- (NSUInteger) count;
- (NSString *) description;
- (NSString *) descriptionInStringsFileFormat;
- (NSString *) descriptionWithLocale:(id) localeDictionary;
- (NSString *) descriptionWithLocale:(id) localeDictionary
							  indent:(NSUInteger) level;
- (void) getObjects:(id *) objects andKeys:(id *) keys;
- (id) initWithContentsOfFile:(NSString *) path;
- (id) initWithContentsOfURL:(NSURL *) url;
- (id) initWithDictionary:(NSDictionary *) dictionary;
- (id) initWithDictionary:(NSDictionary *) dictionary copyItems:(BOOL) flag;
- (id) initWithObjects:(NSArray *) objects forKeys:(NSArray *) keys;
- (id) initWithObjects:(id *) objects forKeys:(id *) keys count:(NSUInteger) cnt;
- (id) initWithObjectsAndKeys:(id) firstObject, ...;
- (BOOL) isEqualToDictionary:(NSDictionary *) other;
- (NSEnumerator *) keyEnumerator;
- (NSArray *) keysSortedByValueUsingSelector:(SEL) comparator;
- (NSEnumerator *) objectEnumerator;
- (id) objectForKey:(id) aKey;
- (NSArray *) objectsForKeys:(NSArray *) keys notFoundMarker:(id) notFoundObj;
- (id) valueForKey:(NSString *) key;
- (BOOL) writeToFile:(NSString *) path atomically:(BOOL) useAuxiliaryFile;
- (BOOL) writeToURL:(NSURL *) aURL atomically:(BOOL) flag;

@end /* NSDictionary */


@interface NSMutableDictionary : NSDictionary

+ (id) dictionaryWithCapacity:(NSUInteger) aNumItems;

- (void) addEntriesFromDictionary:(NSDictionary *) otherDictionary;
- (id) initWithCapacity:(NSUInteger) aNumItems;
- (void) removeAllObjects;
- (void) removeObjectForKey:(id) theKey;
- (void) removeObjectsForKeys:(NSArray *) keyArray;
- (void) setDictionary:(NSDictionary *) otherDictionary;
- (void) setObject:(id) anObject forKey:(id) aKey;
- (void) setValue:(id) anObject forKey:(NSString *) aKey;

@end /* NSMutableDictionary */

#endif /* _mySTEP_H_NSDictionary */
