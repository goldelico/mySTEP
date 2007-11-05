/* 
   NSSet.h

   Copyright (C) 1995, 1996 Ovidiu Predescu and Mircea Oancea.
   All rights reserved.

   Author: Mircea Oancea <mircea@jupiter.elcom.pub.ro>

   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   This file is part of the mySTEP Library and is provided under the 
   terms of the libFoundation BSD type license (See the Readme file).
*/

#ifndef _mySTEP_H_NSSet
#define _mySTEP_H_NSSet

#import <Foundation/NSObject.h>
#import <Foundation/NSMapTable.h>
#import <Foundation/NSHashTable.h>

@class NSString;
@class NSArray;
@class NSDictionary;
@class NSEnumerator;


@interface NSSet : NSObject <NSCoding, NSCopying, NSMutableCopying>

+ (id)set;
+ (id)setWithArray:(NSArray*)array;
+ (id)setWithObject:(id)anObject;
+ (id)setWithObjects:(id)firstObj,...;
+ (id)setWithObjects:(id*)objects count:(unsigned int)count;
+ (id)setWithSet:(NSSet*)aSet;

- (NSArray*)allObjects;
- (id)anyObject;
- (BOOL)containsObject:(id)anObject;
- (unsigned int)count;
- (NSString *) description;
- (NSString *) descriptionWithLocale:(NSDictionary *) locale;
- (id)initWithArray:(NSArray*)array;
- (id)initWithObjects:(id)firstObj,...;
- (id)initWithObjects:(id*)objects count:(unsigned int)count;
- (id)initWithSet:(NSSet*)anotherSet;
- (id)initWithSet:(NSSet*)set copyItems:(BOOL)flag;
- (BOOL)intersectsSet:(NSSet*)otherSet;
- (BOOL)isEqualToSet:(NSSet*)otherSet;
- (BOOL)isSubsetOfSet:(NSSet*)otherSet;
- (void)makeObjectsPerformSelector:(SEL)aSelector;
- (void)makeObjectsPerformSelector:(SEL)aSelector withObject:(id)anObject;
- (id)member:(id)anObject;
- (NSEnumerator*)objectEnumerator;
- (NSSet *)setByAddingObject:(id)anObject;
- (NSSet *)setByAddingObjectsFromSet:(NSSet *)other;
- (NSSet *)setByAddingObjectsFromArray:(NSArray *)other;

@end


@interface NSMutableSet : NSSet

+ (id)setWithCapacity:(unsigned)numItems;

- (void)addObject:(id)object;
- (void)addObjectsFromArray:(NSArray*)array;
- (id)initWithCapacity:(unsigned)numItems;
- (void)intersectSet:(NSSet*)other;
- (void)minusSet:(NSSet*)other;
- (void)removeAllObjects;
- (void)removeObject:(id)object;
- (void)setSet:(NSSet*)other;
- (void)unionSet:(NSSet*)other;

@end


@interface NSCountedSet : NSMutableSet
{
	NSMapTable *table;
}

- (void)addObject:(id)object;
- (unsigned)countForObject:(id)anObject;
- (id)initWithArray:(NSArray*)array;
- (id)initWithCapacity:(unsigned)numItems;
- (id)initWithSet:(NSSet*)anotherSet;
- (NSEnumerator*)objectEnumerator;
- (void)removeObject:(id)object;

@end

#endif /* _mySTEP_H_NSSet */
