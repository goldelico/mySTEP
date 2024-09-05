/*
 NSHashTable.h

 Copyright (C) 1995, 1996 Ovidiu Predescu and Mircea Oancea.
 All rights reserved.

 Author: Ovidiu Predescu <ovidiu@bx.logicnet.ro>

 Author:	Fabian Spillner <fabian.spillner@gmail.com>
 Date:	9. May 2008 - aligned with 10.5

 This file is part of the mySTEP Library and is provided under the
 terms of the libFoundation BSD type license (See the Readme file).
 */

#ifndef _mySTEP_H_NSHashTable
#define _mySTEP_H_NSHashTable

#import <Foundation/NSObject.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSPointerFunctions.h>

@class NSArray;
@class NSSet;
@class NSHashTable;

typedef NSUInteger NSHashTableOptions;

enum {
	NSHashTableStrongMemory             = 0,
	NSHashTableZeroingWeakMemory        = NSPointerFunctionsZeroingWeakMemory,
	NSHashTableCopyIn                   = NSPointerFunctionsCopyIn,
	NSHashTableObjectPointerPersonality = NSPointerFunctionsObjectPointerPersonality,
};

typedef struct _NSHashTableCallBacks {
	NSUInteger (*hash)(/*struct _*/NSHashTable *table, const void *anObject);
	BOOL (*isEqual)(/*struct _*/NSHashTable *table, const void *anObject1,
					const void *anObject2);
	void (*retain)(/*struct _*/NSHashTable *table, const void *anObject);
	void (*release)(/*struct _*/NSHashTable *table, void *anObject);
	NSString *(*describe)(/*struct _*/NSHashTable *table, const void *anObject);
} NSHashTableCallBacks;

struct _NSHashNode {
	void *key;
	struct _NSHashNode *next;
};

typedef struct _NSHashEnumerator {
	/*struct _*/ NSHashTable *table;
	struct _NSHashNode *node;
	NSInteger bucket;
} NSHashEnumerator;

@interface NSHashTable : NSObject <NSCopying, NSMutableCopying, NSCoding, NSFastEnumeration>
{
@public	// so that we can access the table as a struct
	struct _NSHashNode **nodes;
	NSUInteger hashSize;
	NSUInteger itemsCount;
	NSHashTableCallBacks callbacks;
}

+ (id) hashTableWithOptions:(NSPointerFunctionsOptions) opts;
+ (id) hashTableWithWeakObjects;

- (void) addObject:(id) obj;
- (NSArray *) allObjects;
- (id) anyObject;
- (BOOL) containsObject:(id) anObj;
- (NSUInteger) count;
- (id) initWithOptions:(NSPointerFunctionsOptions) opts capacity:(NSUInteger) cap;
- (id) initWithPointerFunctions:(NSPointerFunctions *) functs capacity:(NSUInteger) initCap;
- (void) intersectHashTable:(NSHashTable *) hashTable;
- (BOOL) intersectsHashTable:(NSHashTable *) hashTable;
- (BOOL) isEqualToHashTable:(NSHashTable *) hashTable;
- (BOOL) isSubsetOfHashTable:(NSHashTable *) hashTable;
- (id) member:(id) obj;
- (void) minusHashTable:(NSHashTable *) hashTable;
- (NSEnumerator *) objectEnumerator;
- (NSPointerFunctions *) pointerFunctions;
- (void) removeAllObjects;
- (void) removeObject:(id) obj;
- (NSSet *) setRepresentation;
- (void) unionHashTable:(NSHashTable *) hashTable;

@end

// Predefined callback sets
extern const NSHashTableCallBacks NSIntHashCallBacks;  // deprecated since 10.5
extern const NSHashTableCallBacks NSIntegerHashCallBacks;
extern const NSHashTableCallBacks NSNonOwnedPointerHashCallBacks;
extern const NSHashTableCallBacks NSNonRetainedObjectHashCallBacks;
extern const NSHashTableCallBacks NSObjectHashCallBacks;
extern const NSHashTableCallBacks NSOwnedObjectIdentityHashCallBacks;
extern const NSHashTableCallBacks NSOwnedPointerHashCallBacks;
extern const NSHashTableCallBacks NSPointerToStructHashCallBacks;

// Hash Table Functions
NSHashTable *
NSCreateHashTable(NSHashTableCallBacks callBacks, NSUInteger capacity);	// Create a Table

NSHashTable *
NSCreateHashTableWithZone(NSHashTableCallBacks callBacks, NSUInteger capacity, NSZone *zone);

NSHashTable *
NSCopyHashTable(NSHashTable *table);

void NSFreeHashTable(NSHashTable *table); 				// Free a Table
void NSResetHashTable(NSHashTable *table);
// Compare Two Tables
BOOL NSCompareHashTables(NSHashTable *table1, NSHashTable *table2);

NSUInteger NSCountHashTable(NSHashTable *table);			// Get Number of Items

NSArray *NSAllHashTableObjects(NSHashTable *table);		// Retrieve Items
void *NSHashGet(NSHashTable *table, const void *pointer);
void *NSNextHashEnumeratorItem(NSHashEnumerator *enumerator);
NSHashEnumerator NSEnumerateHashTable(NSHashTable *table);
// Add / Remove an Item
void NSHashInsert(NSHashTable *table, const void *pointer);
void NSHashInsertKnownAbsent(NSHashTable *table, const void *pointer);
void *NSHashInsertIfAbsent(NSHashTable *table, const void *pointer);
void NSHashRemove(NSHashTable *table, const void *pointer);

NSString *NSStringFromHashTable(NSHashTable *table);	//String Representation

//
// Convenience functions to deal with Hash and Map Table
//
NSUInteger __NSHashObject(void* table, const void* anObject);
NSUInteger __NSHashPointer(void* table, const void* anObject);
NSUInteger __NSHashInteger(void* table, const void* anObject);
NSUInteger __NSHashCString(void* table, const void* anObject);

BOOL __NSCompareObjects(void* table, const void* aObj1, const void* aObj2);
BOOL __NSComparePointers(void* table, const void* aObj1, const void* aObj2);
BOOL __NSCompareInts(void* table, const void* aObj1, const void* aObj2);
BOOL __NSCompareCString(void* table, const void* aObj1, const void* aObj2);

void __NSRetainNothing(void* table, const void* anObject);
void __NSRetainObjects(void* table, const void* anObject);
void __NSReleaseNothing(void* table, void* anObject);
void __NSReleaseObjects(void* table, void* anObject);
void __NSReleasePointers(void* table, void* anObject);
NSString *__NSDescribeObjects(void* table, const void* anObject);
NSString *__NSDescribePointers(void* table, const void* anObject);
NSString *__NSDescribeInts(void* table, const void* anObject);

#endif /* _mySTEP_H_NSHashTable */
