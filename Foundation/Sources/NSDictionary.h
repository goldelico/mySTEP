/* 
   NSDictionary.h

   Associate a unique key with a value

   Copyright (C) 1995, 1996 Ovidiu Predescu and Mircea Oancea.
   All rights reserved.

   Author: Mircea Oancea <mircea@jupiter.elcom.pub.ro>

   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4

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
+ (id) dictionaryWithContentsOfFile:(NSString*)path;
+ (id) dictionaryWithContentsOfURL:(NSURL*)url;
+ (id) dictionaryWithDictionary:(NSDictionary*)aDict;
+ (id) dictionaryWithObject:(id) object forKey:(id)key;
+ (id) dictionaryWithObjects:(NSArray*)objects forKeys:(NSArray*)keys;
+ (id) dictionaryWithObjects:(id*)objects 
					 forKeys:(id*)keys
					 count:(unsigned int)count;
+ (id) dictionaryWithObjectsAndKeys:(id)firstObject, ...;

- (NSArray*) allKeys;									// Access Keys & Values
- (NSArray*) allKeysForObject:(id)object;
- (NSArray*) allValues;
- (unsigned int) count;									// Count Entries
- (NSString*) description;
- (NSString*) descriptionInStringsFileFormat;
- (NSString*) descriptionWithLocale:(NSDictionary*)localeDictionary;
- (NSString*) descriptionWithLocale:(NSDictionary*)localeDictionary
							 indent:(unsigned int)level;
- (id) initWithContentsOfFile:(NSString*)path;
- (id) initWithContentsOfURL:(NSURL*)url;
- (id) initWithDictionary:(NSDictionary*)dictionary;
- (id) initWithDictionary:(NSDictionary*)dictionary copyItems:(BOOL)flag;
- (id) initWithObjects:(NSArray*)objects forKeys:(NSArray*)keys;
- (id) initWithObjects:(id*)objects forKeys:(id*)keys count:(unsigned int)cnt;
- (id) initWithObjectsAndKeys:(id)firstObject,...;
- (BOOL) isEqualToDictionary:(NSDictionary*)other;		// Compare Dictionaries
- (NSEnumerator*) keyEnumerator;
- (NSArray *) keysSortedByValueUsingSelector:(SEL)comparator;
- (NSEnumerator*) objectEnumerator;
- (id) objectForKey:(id)aKey;
- (NSArray*) objectsForKeys:(NSArray*)keys notFoundMarker:notFoundObj;
- (id) valueForKey:(NSString *)key;
- (BOOL) writeToFile:(NSString*)path atomically:(BOOL)useAuxiliaryFile;
- (BOOL) writeToURL:(NSURL *)aURL atomically:(BOOL)flag;

@end /* NSDictionary */


@interface NSMutableDictionary : NSDictionary

+ (id) dictionaryWithCapacity:(unsigned int)aNumItems;

- (void) addEntriesFromDictionary:(NSDictionary *) otherDictionary;
- (id) initWithCapacity:(unsigned int) aNumItems;
- (void) removeAllObjects;
- (void) removeObjectForKey:(id) theKey;
- (void) removeObjectsForKeys:(NSArray *) keyArray;
- (void) setDictionary:(NSDictionary *) otherDictionary;
- (void) setObject:(id) anObject forKey:(id) aKey;
- (void) setValue:(id) anObject forKey:(NSString *) aKey;

@end /* NSMutableDictionary */

#endif /* _mySTEP_H_NSDictionary */
