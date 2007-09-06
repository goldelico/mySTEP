/* 
   NSMapTable.h

   Copyright (C) 1995, 1996 Ovidiu Predescu and Mircea Oancea.
   All rights reserved.

   Author: Ovidiu Predescu <ovidiu@bx.logicnet.ro>

   This file is part of the mySTEP Library and is provided under the 
   terms of the libFoundation BSD type license (See the Readme file).
*/

#ifndef _mySTEP_H_NSMapTable
#define _mySTEP_H_NSMapTable

#import <Foundation/NSObject.h>

@class NSArray;

struct _NSMapTable;

struct _NSMapNode {
    void *key;
    void *value;
    struct _NSMapNode *next;
};

typedef struct _NSMapTableKeyCallBacks {
    unsigned (*hash)(struct _NSMapTable *table, const void *anObject);
    BOOL (*isEqual)(struct _NSMapTable *table, const void *anObject1, 
	    const void *anObject2);
    void (*retain)(struct _NSMapTable *table, const void *anObject);
    void (*release)(struct _NSMapTable *table, void *anObject);
    NSString  *(*describe)(struct _NSMapTable *table, const void *anObject);
    const void *notAKeyMarker;
} NSMapTableKeyCallBacks;

typedef struct _NSMapTableValueCallBacks {
    void (*retain)(struct _NSMapTable *table, const void *anObject);
    void (*release)(struct _NSMapTable *table, void *anObject);
    NSString  *(*describe)(struct _NSMapTable *table, const void *anObject);
} NSMapTableValueCallBacks;

typedef struct _NSMapTable {
	struct _NSMapNode **nodes;
	unsigned int hashSize;
	unsigned int itemsCount;
	NSMapTableKeyCallBacks keyCallbacks;
	NSMapTableValueCallBacks valueCallbacks;
} NSMapTable;

typedef struct NSMapEnumerator {
    struct _NSMapTable *table;
    struct _NSMapNode *node;
    int bucket;
} NSMapEnumerator;

#define NSNotAnIntMapKey (NSNotFound)
#define NSNotAPointerMapKey ((long)1)
														// Predefined callbacks
extern const NSMapTableKeyCallBacks   NSIntMapKeyCallBacks;
extern const NSMapTableValueCallBacks NSIntMapValueCallBacks;

extern const NSMapTableKeyCallBacks   NSOwnedPointerMapKeyCallBacks;
extern const NSMapTableKeyCallBacks   NSNonOwnedPointerMapKeyCallBacks;
extern const NSMapTableValueCallBacks NSOwnedPointerMapValueCallBacks;
extern const NSMapTableValueCallBacks NSNonOwnedPointerMapValueCallBacks;

// extern const NSMapTableKeyCallBacks   GSOwnedCStringMapKeyCallBacks;
extern const NSMapTableKeyCallBacks   NSNonOwnedCStringMapKeyCallBacks;

extern const NSMapTableKeyCallBacks   NSNonOwnedPointerOrNullMapKeyCallBacks;

extern const NSMapTableKeyCallBacks   NSObjectMapKeyCallBacks; 
extern const NSMapTableValueCallBacks NSObjectMapValueCallBacks;
extern const NSMapTableKeyCallBacks   NSNonRetainedObjectMapKeyCallBacks; 
extern const NSMapTableValueCallBacks NSNonRetainedObjectMapValueCallBacks;

														// Map Table Functions

														// Create a Table
NSMapTable *NSCreateMapTable(NSMapTableKeyCallBacks keyCallBacks, 
							 NSMapTableValueCallBacks valueCallBacks,
							 unsigned capacity);
NSMapTable *NSCopyMapTable(NSMapTable *table);

void NSFreeMapTable(NSMapTable *table);					// Free a Table
void NSResetMapTable(NSMapTable *table);
														// Compare Two Tables
BOOL NSCompareMapTables(NSMapTable *table1, NSMapTable *table2);

unsigned NSCountMapTable(NSMapTable *table);			// Number of Items

BOOL NSMapMember(NSMapTable *table,						// Retrieve Items
				 const void *key,
				 void **originalKey,
				 void **value);

void *NSMapGet(NSMapTable *table, const void *key);

NSMapEnumerator NSEnumerateMapTable(NSMapTable *table);

BOOL NSNextMapEnumeratorPair(NSMapEnumerator *enumerator, 
							 void **key, 
							 void **value);

NSArray *NSAllMapTableKeys(NSMapTable *table);
NSArray *NSAllMapTableValues(NSMapTable *table);

	// Add or Remove an Item
void NSMapInsert(NSMapTable *table, const void *key, const void *value);

void *NSMapInsertIfAbsent(NSMapTable *table, 
						  const void *key, 
						  const void *value);

void NSMapInsertKnownAbsent(NSMapTable *table, 
							const void *key, 
							const void *value);

void NSMapRemove(NSMapTable *table, const void *key);

NSString *NSStringFromMapTable(NSMapTable *table);

#endif /* _mySTEP_H_NSMapTable */
