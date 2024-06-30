/* 
    NSSet.h

    Copyright (C) 1995, 1996 Ovidiu Predescu and Mircea Oancea.
    All rights reserved.

    Author: Mircea Oancea <mircea@jupiter.elcom.pub.ro>

    H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
    Fabian Spillner - API revised to be compatible to 10.5
 
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

+ (id) set;
+ (id) setWithArray:(NSArray *) array;
+ (id) setWithObject:(id) anObject;
+ (id) setWithObjects:(id) firstObj,...;
+ (id) setWithObjects:(id *) objects count:(NSUInteger) count;
+ (id) setWithSet:(NSSet *) aSet;

- (NSArray *) allObjects;
- (id) anyObject;
- (BOOL) containsObject:(id) anObject;
- (NSUInteger) count;
- (NSString *) description;
- (NSString *) descriptionWithLocale:(id) locale;
- (id) initWithArray:(NSArray *) array;
- (id) initWithObjects:(id) firstObj,...;
- (id) initWithObjects:(id *) objects count:(NSUInteger) count;
- (id) initWithSet:(NSSet *) anotherSet;
- (id) initWithSet:(NSSet *) set copyItems:(BOOL) flag;
- (BOOL) intersectsSet:(NSSet *) otherSet;
- (BOOL) isEqualToSet:(NSSet *) otherSet;
- (BOOL) isSubsetOfSet:(NSSet *) otherSet;
- (void) makeObjectsPerformSelector:(SEL) aSelector;
- (void) makeObjectsPerformSelector:(SEL) aSelector withObject:(id) anObject;
- (id) member:(id) anObject;
- (NSEnumerator *) objectEnumerator;
- (NSSet *) setByAddingObject:(id) anObject;
- (NSSet *) setByAddingObjectsFromSet:(NSSet *) other;
- (NSSet *) setByAddingObjectsFromArray:(NSArray *) other;

@end


@interface NSMutableSet : NSSet

+ (id) setWithCapacity:(NSUInteger) numItems;

- (void) addObject:(id) object;
- (void) addObjectsFromArray:(NSArray *) array;
- (id) initWithCapacity:(NSUInteger) numItems;
- (void) intersectSet:(NSSet *) other;
- (void) minusSet:(NSSet *) other;
- (void) removeAllObjects;
- (void) removeObject:(id) object;
- (void) setSet:(NSSet *) other;
- (void) unionSet:(NSSet *) other;

@end


@interface NSCountedSet : NSMutableSet
{
	NSMapTable *table;
}

- (void) addObject:(id) object;
- (NSUInteger) countForObject:(id) anObject;
- (id) initWithArray:(NSArray *) array;
- (id) initWithCapacity:(NSUInteger) numItems;
- (id) initWithSet:(NSSet *) anotherSet;
- (NSEnumerator *) objectEnumerator;
- (void) removeObject:(id) object;

@end

@interface NSOrderedSet : NSObject <NSCoding, NSCopying, NSMutableCopying>
{
	NSArray *_array;	// we simply wrap an NSArray instead of an optimized solution
}

+ (NSOrderedSet *) orderedSet;
+ (NSOrderedSet *) orderedSetWithArray:(NSArray *) array;
+ (NSOrderedSet *) orderedSetWithArray:(NSArray *) array range:(NSRange) range copyItems:(BOOL) flag;
+ (NSOrderedSet *) orderedSetWithObject:(id) object;
+ (NSOrderedSet *) orderedSetWithObjects:(id) object, ...;
+ (NSOrderedSet *) orderedSetWithObjects:(id *) objects count:(NSUInteger) cnt;
+ (NSOrderedSet *) orderedSetWithOrderedSet:(NSOrderedSet) other;
+ (NSOrderedSet *) orderedSetWithOrderedSet:(NSOrderedSet) other range:(NSRange) range copyItems:(BOOL) flag;
+ (NSOrderedSet *) orderedSetWithSet:(id) object;
+ (NSOrderedSet *) orderedSetWithSet:(id) object copyItems:(BOOL) flag;

- (id) initWithArray:(NSArray *) array;
- (id) initWithArray:(NSArray *) array copyItems:(BOOL) flag;
- (id) initWithWithArray:(NSArray *) array range:(NSRange) range copyItems:(BOOL) flag;
- (id) initWithWithObject:(id) object;
- (id) initWithWithObjects:(id) object, ...;
- (id) initWithWithObjects:(id *) objects count:(NSUInteger) cnt;
- (id) initWithWithOrderedSet:(NSOrderedSet) other;
- (id) initWithWithOrderedSet:(NSOrderedSet) other copyItems:(BOOL) flag;
- (id) initWithWithOrderedSet:(NSOrderedSet) other range:(NSRange) range copyItems:(BOOL) flag;
- (id) initWithWithSet:(id) object;
- (id) initWithtWithSet:(id) object copyItems:(BOOL) flag;
- (id) init;
- (NSUInteger) count;
- (BOOL) containsObject:(id) object;
/* enumerateUsingBlock */
- (id) firstObject;
- (id) lastObject;
- (id) objectAtIndex:(NSUInteger) idx;
- (id) objectAtIndexedSubscript:(NSUInteger) idx;
- (NSArray *) objectsAtIndexes:(NSIndexSet *) indexes;
- (NSUInteger) indexOfObject:(id) object;
/* - (NSUInteger)indexOfObject:(ObjectType) object
			  inSortedRange:(NSRange) range
					options:(NSBinarySearchingOptions) options
			usingComparator:(NSComparator) comparator;
 */
// indexOfObjectPassingTest: and friends
- (NSEnumerator *) objectEnumerator;
- (NSEnumerator *) reverseObjectEnumerator;
- (NSOrderedSet *) reversedOrderedSet;
- (void) getObjects:(id *) objects range:(NSRange) range;
- (void) setValue:(id) value forKey:(NSString *) key;	// call for all elements
- (id) valueForKey:(NSString *) key;	// call for all elements and collect in new NSOrderedSet
// observer methods
- (BOOL) isEqualToOrderedSet:(NSOrderedSet *) other;
- (BOOL) intersectsOrderedSet:(NSOrderedSet *) other;
- (BOOL) intersectsSet:(NSSet *) other;
- (BOOL) isSubsetOfOrderedSet:(NSOrderedSet *) other;
- (BOOL) isSubsetOfSet:(NSSet *) other;
- (NSArray *) sortedArrayUsingDescriptors:(NSArray *) sortDescriptors;
// sortedArrayUsingComparator
- (NSOrderedSet *) filteredOrderedSetUsingPredicate:(NSPredicate *) predicate;
- (NSString *) description;	// formatted as a property list
- (NSString *) descriptionWithLocale:(id) locale;
- (NSString *) descriptionWithLocale:(id) locale indent:(NSUInteger) level;
- (NSArray *) array;
- (NSSet *) set;

/*
 - (NSOrderedCollectionDifference *) differenceFromOrderedSet:(NSOrderedSet *) other;
 and friends...
 - (NSOrderedSet *) orderedSetByApplyingDifference:(NSOrderedCollectionDifference *) difference;
 */
@end

@interface NSMutableOrderedSet : NSOrderedSet
// a lot of methods to be added...
@end

#endif /* _mySTEP_H_NSSet */
