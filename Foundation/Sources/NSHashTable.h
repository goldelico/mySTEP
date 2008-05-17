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

@class NSArray;

struct _NSHashTable;

typedef struct _NSHashTableCallBacks {
    unsigned (*hash)(struct _NSHashTable *table, const void *anObject);
    BOOL (*isEqual)(struct _NSHashTable *table, const void *anObject1, 
					const void *anObject2);
    void (*retain)(struct _NSHashTable *table, const void *anObject);
    void (*release)(struct _NSHashTable *table, void *anObject);
    NSString *(*describe)(struct _NSHashTable *table, const void *anObject);
} NSHashTableCallBacks;

struct _NSHashNode {
    void *key;
    struct _NSHashNode *next;
};

typedef struct _NSHashTable {
    struct _NSHashNode **nodes;
    unsigned int hashSize;
    unsigned int itemsCount;
    NSHashTableCallBacks callbacks;
} NSHashTable;

typedef struct _NSHashEnumerator {
    struct _NSHashTable *table;
    struct _NSHashNode *node;
    int bucket;
} NSHashEnumerator;

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
NSHashTable *											// Create a Table
NSCreateHashTable(NSHashTableCallBacks callBacks, unsigned capacity);

NSHashTable *
NSCreateHashTable(NSHashTableCallBacks callBacks, unsigned capacity);

NSHashTable *
NSCopyHashTable(NSHashTable *table);

void NSFreeHashTable(NSHashTable *table); 				// Free a Table
void NSResetHashTable(NSHashTable *table); 
														// Compare Two Tables
BOOL NSCompareHashTables(NSHashTable *table1, NSHashTable *table2);	

unsigned NSCountHashTable(NSHashTable *table);			// Get Number of Items

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
unsigned __NSHashObject(void* table, const void* anObject);
unsigned __NSHashPointer(void* table, const void* anObject);
unsigned __NSHashInteger(void* table, const void* anObject);
unsigned __NSHashCString(void* table, const void* anObject);

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

#if NEW

typedef NSUInteger NSHashTableOptions;

enum {
	NSHashTableStrongMemory             = 0,
	NSHashTableZeroingWeakMemory        = NSPointerFunctionsZeroingWeakMemory,
	NSHashTableCopyIn                   = NSPointerFunctionsCopyIn,
	NSHashTableObjectPointerPersonality = NSPointerFunctionsObjectPointerPersonality,
};

@interface NSHashTable : Object
{
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

#endif

#endif /* _mySTEP_H_NSHashTable */
