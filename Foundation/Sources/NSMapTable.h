/* 
    NSMapTable.h

    Copyright (C) 1995, 1996 Ovidiu Predescu and Mircea Oancea.
    All rights reserved.

    Author: Ovidiu Predescu <ovidiu@bx.logicnet.ro>
 
    Fabian Spillner, May 2008 - API revised to be compatible to 10.5 

    This file is part of the mySTEP Library and is provided under the 
    terms of the libFoundation BSD type license (See the Readme file).
*/

#ifndef _mySTEP_H_NSMapTable
#define _mySTEP_H_NSMapTable

#import <Foundation/NSObject.h>

@class NSArray;

enum {
	NSMapTableStrongMemory             = 0,
	NSMapTableZeroingWeakMemory        = NSPointerFunctionsZeroingWeakMemory,
	NSMapTableCopyIn                   = NSPointerFunctionsCopyIn,
	NSMapTableObjectPointerPersonality = NSPointerFunctionsObjectPointerPersonality
};

@interface NSMapTable : NSObject
{
}

+ (id) mapTableWithKeyOptions:(NSPointerFunctionsOptions) keyOptions 
				 valueOptions:(NSPointerFunctionsOptions) valueOptions;
+ (id) mapTableWithStrongToStrongObjects;
+ (id) mapTableWithStrongToWeakObjects;
+ (id) mapTableWithWeakToStrongObjects;
+ (id) mapTableWithWeakToWeakObjects;

- (NSUInteger) count;
- (NSDictionary *) dictionaryRepresentation;
- (id) initWithKeyOptions:(NSPointerFunctionsOptions) keyOpts 
			 valueOptions:(NSPointerFunctionsOptions) valueOpts 
				 capacity:(NSUInteger) cap;
- (id) initWithKeyPointerFunctions:(NSPointerFunctions *) keyFuncts 
			 valuePointerFunctions:(NSPointerFunctions *) valFuncts 
						  capacity:(NSUInteger) cap;
- (NSEnumerator *) keyEnumerator;
- (NSPointerFunctions *) keyPointerFunctions;
- (NSEnumerator *) objectEnumerator;
- (id) objectForKey:(id) key;
- (void) removeAllObjects;
- (void) removeObjectForKey:(id) key;
- (void) setObject:(id) obj forKey:(id) key;
- (NSPointerFunctions *) valuePointerFunctions;

@end

/********************************************************************************/

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
extern const NSMapTableKeyCallBacks   NSIntMapKeyCallBacks; // deprecated since 10.5
extern const NSMapTableValueCallBacks NSIntMapValueCallBacks; // deprecated since 10.5

extern const NSMapTableKeyCallBacks   NSIntegerMapKeyCallBacks;
extern const NSMapTableValueCallBacks NSIntegerMapValueCallBacks;

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

#if NEW
@interface NSMapTable : Object
{
}
#endif

#endif /* _mySTEP_H_NSMapTable */
