/* 
 NSHashMap.m
 
 Copyright (C) 1995, 1996 Ovidiu Predescu and Mircea Oancea.
 All rights reserved.
 
 Author: Ovidiu Predescu <ovidiu@bx.logicnet.ro>
 Mircea Oancea <mircea@jupiter.elcom.pub.ro>
 Nikolaus Schaller <hns@computer.org> - adaptation to 10.5 made (Map and Hash tables real subclasses of NSObject)
 
 This file is part of the mySTEP Library and is provided under the 
 terms of the libFoundation BSD type license (See the Readme file).
 */

#import <Foundation/NSHashTable.h>
#import <Foundation/NSMapTable.h>
#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSSet.h>

static void __NSHashGrow(NSHashTable *table, unsigned newSize);
static void __NSMapGrow(NSMapTable *table, unsigned newSize);

// FIXME: speed up by building a cache for smaller values
// e.g. char isprime[2048] - 0=unknown 1=no 2=yes

// #define is_prime(n) (n>=sizeof(isprime)?_is_prime(n):(isprime[n] == 0?(isprime[n]=_is_prime(n)+1)-1:isprime[n]-1))

static BOOL													// Hash and Map table utilities
is_prime(unsigned n)
{
	unsigned divisor, maxDivisor, n2;
#if 0
	fprintf(stderr, "is_prime(%u)?\n", n);	
#endif
	if((n & 1) == 0)
		return NO;	// even number
	// maxDivisor = ceil(sqrt(n));
	// we could also use Newton-Iteration: maxDivisor=(maxDivisor+n/maxDivisor)/2; (start with maxDivisor=n/3)
	// but that might be slower since it involves integer divisions
    for(maxDivisor = 2, n2 = 4; n2 <= n; maxDivisor <<= 1, n2 <<= 2)
		;
#if 0
	fprintf(stderr, "n=%u maxdivisor=%u n2=%u\n", n, maxDivisor, n2);
#endif
	for(divisor = 3; divisor <= maxDivisor; divisor+=2)
        if(n % divisor == 0)
            return NO;
#if 0
	fprintf(stderr, "is_prime(%u)!\n", n);	
#endif
    return YES;
}

static unsigned 
nextPrime(unsigned old_value)
{
	unsigned i, new_value = old_value | 1;	// make odd
    for(i = new_value; i >= new_value; i += 2)
        if(is_prime(i))
            return i;
	return old_value;
}

static void 								
__NSCheckHashTableFull(NSHashTable* table)					// Check if node 
{															// table is full.
    if( ++(table->itemsCount) >= ((table->hashSize * 3) / 4))
		{
		unsigned newSize = nextPrime((table->hashSize * 4) / 3);
		if(newSize != table->hashSize)
			__NSHashGrow(table, newSize);
		}
}

static void 
__NSCheckMapTableFull(NSMapTable* table)
{
    if( ++(table->itemsCount) >= ((table->hashSize * 3) / 4))
		{
		unsigned newSize = nextPrime((table->hashSize * 4) / 3);
		if(newSize != table->hashSize)
			__NSMapGrow(table, newSize);
		}
}

//*****************************************************************************
//
// 		NSHashTable functions 
//
//*****************************************************************************

@implementation NSHashTable

- (id) initWithOptions:(NSPointerFunctionsOptions) opts capacity:(NSUInteger) capacity;
{
	if((self=[super init]))
		{
		capacity = capacity ? capacity : 13;
		if (!is_prime(capacity))
			capacity = nextPrime(capacity);
		hashSize = capacity;
		nodes = objc_calloc(hashSize, sizeof(void*));
		itemsCount = 0;
		}
    return self;
}

- (id) copyWithZone:(NSZone *) z; { return NSCopyHashTable(self); }
- (id) copy; { return NSCopyHashTable(self); }
- (id) mutableCopyWithZone:(NSZone *) z; { return NSCopyHashTable(self); }
- (id) mutableCopy; { return NSCopyHashTable(self); }

- (void) dealloc;
{
	NSResetHashTable(self);
	objc_free(nodes);
	[super dealloc];
}

- (NSString *) description; { return NSStringFromHashTable(self); }

- (void) addObject:(id) obj;
{
	NSHashInsertIfAbsent(self, obj);
}

- (NSArray *) allObjects;
{
	return NSAllHashTableObjects(self);
}

- (id) anyObject;
{
	struct _NSHashNode *node;
	unsigned i;
	for(i = 0; i < hashSize; i++)
		for(node = nodes[i]; node; node = node->next)
			return (id)(node->key);	// first found
	return nil;
}

- (BOOL) containsObject:(id) anObj;
{
	return NSHashGet(self, anObj) != NULL;
}

- (NSUInteger) count;
{
	return NSCountHashTable(self);
}

/*
 - (id) initWithPointerFunctions:(NSPointerFunctions *) functs capacity:(NSUInteger) initCap;
 - (void) intersectHashTable:(NSHashTable *) hashTable;
 - (BOOL) intersectsHashTable:(NSHashTable *) hashTable;
 - (BOOL) isEqualToHashTable:(NSHashTable *) hashTable;
 - (BOOL) isSubsetOfHashTable:(NSHashTable *) hashTable;
 */

- (id) member:(id) obj;
{
	return NSHashGet(self, obj);
}

/*
 - (void) minusHashTable:(NSHashTable *) hashTable;
 - (NSEnumerator *) objectEnumerator;
 - (NSPointerFunctions *) pointerFunctions;
 */

- (void) removeAllObjects;
{
	NSResetHashTable(self);
}

- (void) removeObject:(id) obj;
{
	NSHashRemove(self, obj);
}

- (NSSet *) setRepresentation;
{
	if(itemsCount)
		{
		id array = [NSMutableSet setWithCapacity:itemsCount];
		struct _NSHashNode *node;
		unsigned i;
		for(i = 0; i < hashSize; i++)
			for(node = nodes[i]; node; node = node->next)
				[array addObject:(NSObject*)(node->key)];	// this will retain
		return array;
		}
	else
		return [NSSet set];
}

/*
 - (void) unionHashTable:(NSHashTable *) hashTable;
 */

@end

NSHashTable *
NSCreateHashTable(NSHashTableCallBacks callBacks, NSUInteger capacity)
{
	//	NSHashTable *table = objc_malloc(sizeof(NSHashTable));
	NSHashTable *table = [[NSHashTable alloc] initWithOptions:0	capacity:capacity];
	
	//    capacity = capacity ? capacity : 13;
	//  if (!is_prime(capacity))
	//		capacity = nextPrime(capacity);
	
	//  table->hashSize = capacity;
	//  table->nodes = objc_calloc(table->hashSize, sizeof(void*));
	//  table->itemsCount = 0;
    table->callbacks = callBacks;
    if (table->callbacks.hash == NULL)
		table->callbacks.hash = 
	    (unsigned(*)(NSHashTable*, const void*))__NSHashPointer;
    if (table->callbacks.isEqual == NULL)
		table->callbacks.isEqual = 
		(BOOL(*)(NSHashTable*, const void*, const void*)) __NSComparePointers;
    if (table->callbacks.retain == NULL)
		table->callbacks.retain = 
	    (void(*)(NSHashTable*, const void*))__NSRetainNothing;
    if (table->callbacks.release == NULL)
		table->callbacks.release = 
	    (void(*)(NSHashTable*, void*))__NSReleaseNothing;
    if (table->callbacks.describe == NULL)
		table->callbacks.describe = 
	    (NSString*(*)(NSHashTable*, const void*))__NSDescribePointers;
    return table;
}

NSHashTable *
NSCopyHashTable(NSHashTable *table)
{
	NSHashTable *new;
	struct _NSHashNode *oldnode, *newnode;
	unsigned i;
    
	new = [[NSHashTable alloc] initWithOptions:0 capacity:table->hashSize];
	/*
	 new = objc_malloc(sizeof(NSHashTable));
	 new->hashSize = table->hashSize;
	 new->itemsCount = table->itemsCount;
	 new->nodes = objc_calloc(new->hashSize, sizeof(void*));
	 */
    new->callbacks = table->callbacks;
    
    for (i = 0; i < new->hashSize; i++) 
		{
		for (oldnode = table->nodes[i]; oldnode; oldnode = oldnode->next) 
			{
			newnode = objc_malloc(sizeof(struct _NSHashNode));
			newnode->key = oldnode->key;
			newnode->next = new->nodes[i];
			new->nodes[i] = newnode;
			table->callbacks.retain(new, oldnode->key);
			}	}
    
    return new;
}

void 
NSFreeHashTable(NSHashTable *table)
{																// Free a Table
	[table release];
	//    NSResetHashTable(table);
	//    objc_free(table->nodes);
	//    objc_free(table);
}

void 
NSResetHashTable(NSHashTable *table)
{
	unsigned i;
	
    for(i = 0; i < table->hashSize; i++) 
		{
		struct _NSHashNode *next, *node;
		
		node = table->nodes[i];
		table->nodes[i] = NULL;		
		while (node) 
			{
			table->callbacks.release(table, node->key);
			next = node->next;
			objc_free(node);
			node = next;
			}	}
	
    table->itemsCount = 0;
}

BOOL 
NSCompareHashTables(NSHashTable *table1, NSHashTable *table2)
{
	unsigned i;												// Compare Two Tables
	struct _NSHashNode *node1;
    
    if (table1->hashSize != table2->hashSize)
		return NO;
    for (i = 0; i < table1->hashSize; i++)
		{ 
			for (node1 = table1->nodes[i]; node1; node1 = node1->next) 
				if (NSHashGet(table2, node1->key) == NULL)
					return NO;
		}
	
    return YES;;
}	

NSUInteger 											// return Number of Items
NSCountHashTable(NSHashTable *table)			{ return table->itemsCount;	}

void *
NSHashGet(NSHashTable *table, const void *pointer)
{															// Retrieve Items
	struct _NSHashNode *node;
	
	node =table->nodes[table->callbacks.hash(table,pointer) % table->hashSize];
    for(; node; node = node->next)
        if(table->callbacks.isEqual(table, pointer, node->key))
            return node->key;
	
    return NULL;
}

NSArray *NSAllHashTableObjects(NSHashTable *table)
{
	if(table && table->itemsCount)
		{
		id array = [NSMutableArray arrayWithCapacity:table->itemsCount];
		struct _NSHashNode *node;
		unsigned i;
		for(i = 0; i < table->hashSize; i++)
			for(node = table->nodes[i]; node; node = node->next)
				{
#if 0
				NSLog(@"%@", (NSObject*)(node->key));
#endif
				[array addObject:(NSObject*)(node->key)];	// this will retain				
				}
		return array;
		}
	else
		return [NSArray array];
}

NSHashEnumerator 
NSEnumerateHashTable(NSHashTable *table)
{
	NSHashEnumerator en;
	
    en.table = table;
    en.node = NULL;
    en.bucket = -1;
	
    return en;
}

void *
NSNextHashEnumeratorItem(NSHashEnumerator *en)
{
    if(en->node)
		en->node = en->node->next;
    if(en->node == NULL) {
		for(en->bucket++; ((unsigned)en->bucket)<en->table->hashSize; en->bucket++)
			if (en->table->nodes[en->bucket]) {
				en->node = en->table->nodes[en->bucket];
				break;
			};
		if (((unsigned)en->bucket) >= en->table->hashSize) {
			en->node = NULL;
			en->bucket = en->table->hashSize-1;
			return NULL;
		}
    }
    return en->node->key;
}

static void 
__NSHashGrow(NSHashTable *table, unsigned newSize)		// Add / Remove an Item
{
	unsigned i;
	struct _NSHashNode** newNodeTable =objc_calloc(newSize,sizeof(struct _NSHashNode*));
    
    for(i = 0; i < table->hashSize; i++) 
		{
		struct _NSHashNode *next, *node;
		unsigned int h;
		
		node = table->nodes[i];
		while(node) 
			{
			next = node->next;
			h = table->callbacks.hash(table, node->key) % newSize;
			node->next = newNodeTable[h];
			newNodeTable[h] = node;
			node = next;
			}	}
	
    objc_free(table->nodes);
	table->nodes = newNodeTable;
    table->hashSize = newSize;
}

void 
NSHashInsert(NSHashTable *table, const void *pointer)
{
	unsigned int h;
	struct _NSHashNode *node;
	
    if (pointer == nil)
		[NSException raise: NSInvalidArgumentException
					format: @"Nil object to be added in NSHashTable."];
	
    h = table->callbacks.hash(table, pointer) % table->hashSize;
    for(node = table->nodes[h]; node; node = node->next)
        if(table->callbacks.isEqual(table, pointer, node->key))
            break;
	
    /* Check if an entry for key exist in nodeTable. */
    if(node) {
        /* key exist. Set for it new value and return the old value of it. */
		if (pointer != node->key) {
			table->callbacks.retain(table, pointer);
			table->callbacks.release(table, node->key);
		}
		node->key = (void*)pointer;
        return;
    }
	// key not found. Allocate a new bucket and initialize it.
    node = objc_malloc(sizeof(struct _NSHashNode));
	table->callbacks.retain(table, pointer);
    node->key = (void*)pointer;
    node->next = table->nodes[h];
    table->nodes[h] = node;
	
    __NSCheckHashTableFull(table);
}

void 
NSHashInsertKnownAbsent(NSHashTable *table, const void *pointer)
{
	unsigned int h;
	struct _NSHashNode *node;
	
    if (pointer == nil)
		[NSException raise: NSInvalidArgumentException
					format: @"Nil object to be added in NSHashTable."];
	
    h = table->callbacks.hash(table, pointer) % table->hashSize;
    for(node = table->nodes[h]; node; node = node->next)
        if(table->callbacks.isEqual(table, pointer, node->key))
            break;
	
    /* Check if an entry for key exist in nodeTable. */
    if(node) 
		[NSException raise: NSInvalidArgumentException
					format: @"Nil object already existing in NSHashTable."];
	
	// key not found. Allocate a new bucket and initialize it.
    node = objc_malloc(sizeof(struct _NSHashNode));
	table->callbacks.retain(table, pointer);
    node->key = (void*)pointer;
    node->next = table->nodes[h];
    table->nodes[h] = node;
	
    __NSCheckHashTableFull(table);
}

void *
NSHashInsertIfAbsent(NSHashTable *table, const void *pointer)
{
	unsigned int h;
	struct _NSHashNode *node;
	
    if (pointer == nil)
		[NSException raise: NSInvalidArgumentException
					format: @"Nil object to be added in NSHashTable."];
	
    h = table->callbacks.hash(table, pointer) % table->hashSize;
    for(node = table->nodes[h]; node; node = node->next)
        if(table->callbacks.isEqual(table, pointer, node->key))
            break;
	
    if(node)				// Check if an entry for key exist in nodeTable.
		return node->key;
	
	// key not found. Allocate a new bucket and initialize it.
    node = objc_malloc(sizeof(struct _NSHashNode));
    table->callbacks.retain(table, pointer);
    node->key = (void*)pointer;
    node->next = table->nodes[h];
    table->nodes[h] = node;
	
    __NSCheckHashTableFull(table);
    
    return NULL;
}

void 
NSHashRemove(NSHashTable *table, const void *pointer)
{
	unsigned int h;
	struct _NSHashNode *node, *node1 = NULL;
	
    if (pointer == nil)
	    return;
	
    h = table->callbacks.hash(table, pointer) % table->hashSize;
	
	// node point to current bucket, and node1 to previous bucket 
	// or to NULL if current node is the first node in the list 
    for(node = table->nodes[h]; node; node1 = node, node = node->next)
        if(table->callbacks.isEqual(table, pointer, node->key)) {
			table->callbacks.release(table, node->key);
            if(!node1)
                table->nodes[h] = node->next;
            else
                node1->next = node->next;
			objc_free(node);
			(table->itemsCount)--;
			return;
        }
}

NSString *
NSStringFromHashTable(NSHashTable *table)
{												// Get a String Representation
	id ret = [NSMutableString new];
	unsigned i;
	struct _NSHashNode *node;
    
    for (i = 0; i < table->hashSize; i++)
		for (node = table->nodes[i]; node; node = node->next) 
			{
	    	[ret appendString:table->callbacks.describe(table, node->key)];
	    	[ret appendString:@" "];
			}
    
    return ret;
}

//*****************************************************************************
//
// 		Map Table Functions 
//
//*****************************************************************************

@implementation NSMapTable

- (id) initWithKeyOptions:(NSPointerFunctionsOptions) keyOpts 
			 valueOptions:(NSPointerFunctionsOptions) valueOpts 
				 capacity:(NSUInteger) capacity;
{
	if((self=[super init]))
		{
		capacity = capacity ? capacity : 13;
		if (!is_prime(capacity))
			capacity = nextPrime(capacity);
		hashSize = capacity;
		nodes = objc_calloc(hashSize, sizeof(void*));
		itemsCount = 0;
		}
    return self;
}

- (id) copyWithZone:(NSZone *) z; { return NSCopyMapTable(self); }
- (id) copy; { return NSCopyMapTable(self); }
- (id) mutableCopyWithZone:(NSZone *) z; { return NSCopyMapTable(self); }
- (id) mutableCopy; { return NSCopyMapTable(self); }

- (void) dealloc;
{
	NSResetMapTable(self);
	objc_free(nodes);
	[super dealloc];
}

- (NSString *) description; { return NSStringFromMapTable(self); }

/*
 - (NSUInteger) count;
 - (NSDictionary *) dictionaryRepresentation;
 - (NSEnumerator *) keyEnumerator;
 - (NSEnumerator *) objectEnumerator;
 - (id) objectForKey:(id) key;
 - (void) removeAllObjects;
 - (void) removeObjectForKey:(id) key;
 - (void) setObject:(id) obj forKey:(id) key;
 */

@end

NSMapTable *
NSCreateMapTable(NSMapTableKeyCallBacks keyCallbacks, 
				 NSMapTableValueCallBacks valueCallbacks, 
				 unsigned capacity)
{
	// NSMapTable *table = objc_malloc(sizeof(NSMapTable));
	NSMapTable *table = [[NSMapTable alloc] initWithKeyOptions:0 valueOptions:0 capacity:capacity];
	
	//    capacity = capacity ? capacity : 13;
	//  if (!is_prime(capacity))
	//	capacity = nextPrime(capacity);
	
	//    table->hashSize = capacity;
	//    table->nodes = objc_calloc(table->hashSize, sizeof(void*));
	//    table->itemsCount = 0;
    table->keyCallbacks = keyCallbacks;
    table->valueCallbacks = valueCallbacks;
    if (table->keyCallbacks.hash == NULL)
		table->keyCallbacks.hash = 
		(unsigned(*)(NSMapTable*, const void*))__NSHashPointer;
    if (table->keyCallbacks.isEqual == NULL)
		table->keyCallbacks.isEqual = 
		(BOOL(*)(NSMapTable*, const void*, const void*)) __NSComparePointers;
    if (table->keyCallbacks.retain == NULL)
		table->keyCallbacks.retain = 
	    (void(*)(NSMapTable*, const void*))__NSRetainNothing;
    if (table->keyCallbacks.release == NULL)
		table->keyCallbacks.release = 
	    (void(*)(NSMapTable*, void*))__NSReleaseNothing;
    if (table->keyCallbacks.describe == NULL)
		table->keyCallbacks.describe = 
	    (NSString*(*)(NSMapTable*, const void*))__NSDescribePointers;
    if (table->valueCallbacks.retain == NULL)
		table->valueCallbacks.retain = 
	    (void(*)(NSMapTable*, const void*))__NSRetainNothing;
    if (table->valueCallbacks.release == NULL)
		table->valueCallbacks.release = 
	    (void(*)(NSMapTable*, void*))__NSReleaseNothing;
    if (table->valueCallbacks.describe == NULL)
		table->valueCallbacks.describe = 
	    (NSString*(*)(NSMapTable*, const void*))__NSDescribePointers;
    return table;
}

NSMapTable *
NSCopyMapTable(NSMapTable *table)
{
	NSMapTable *new;
	struct _NSMapNode *oldnode, *newnode;
	unsigned i;
	
	new = [[NSMapTable alloc] initWithKeyOptions:0 valueOptions:0 capacity:table->hashSize];
	
	//    new = objc_malloc(sizeof(NSMapTable));
	//  new->hashSize = table->hashSize;
	//    new->itemsCount = table->itemsCount;
    new->keyCallbacks = table->keyCallbacks;
    new->valueCallbacks = table->valueCallbacks;
	//    new->nodes = objc_calloc(new->hashSize, sizeof(void*));
    
    for (i = 0; i < new->hashSize; i++) 
		{
		for (oldnode = table->nodes[i]; oldnode; oldnode = oldnode->next) 
			{
			newnode = objc_malloc(sizeof(struct _NSMapNode));
			newnode->key = oldnode->key;
			newnode->value = oldnode->value;
			newnode->next = new->nodes[i];
			new->nodes[i] = newnode;
			table->keyCallbacks.retain(new, oldnode->key);
			table->valueCallbacks.retain(new, oldnode->value);
			}	}
    
    return new;
}

void 
NSFreeMapTable(NSMapTable *table)
{																// Free a Table
	[table release];
	//    NSResetMapTable(table);
	//    objc_free(table->nodes);
	//    objc_free(table);
}

void 
NSResetMapTable(NSMapTable *table)
{
	unsigned i;
	
    for(i = 0; i < table->hashSize; i++) 
		{
		struct _NSMapNode *next, *node;
		
		node = table->nodes[i];
		table->nodes[i] = NULL;		
		while (node) 
			{
			table->keyCallbacks.release(table, node->key);
			table->valueCallbacks.release(table, node->value);
			next = node->next;
			objc_free(node);
			node = next;
			}	}
	
    table->itemsCount = 0;
}

BOOL 
NSCompareMapTables(NSMapTable *table1, NSMapTable *table2)
{
	unsigned i;												// Compare Two Tables
	struct _NSMapNode *node1;
    
    if (table1->hashSize != table2->hashSize)
		return NO;
    for (i = 0; i < table1->hashSize; i++) 
		for (node1 = table1->nodes[i]; node1; node1 = node1->next)
			if (NSMapGet(table2, node1->key) != node1->value)
				return NO;
	
    return YES;
}
// Return Number of Items 
NSUInteger
NSCountMapTable(NSMapTable *table)			{ return table->itemsCount; }

BOOL 
NSMapMember(NSMapTable *table, const void *key,void **originalKey,void **value)
{
	struct _NSMapNode *node;
	
	node = table->nodes[table->keyCallbacks.hash(table,key) % table->hashSize];
    for(; node; node = node->next)
        if(table->keyCallbacks.isEqual(table, key, node->key)) 
			{
            *originalKey = node->key;
			*value = node->value;
			return YES;
			}
	
    return NO;
}

void *
NSMapGet(NSMapTable *table, const void *key)
{
	struct _NSMapNode *node;
	
	node = table->nodes[table->keyCallbacks.hash(table,key) % table->hashSize];
    for(; node; node = node->next)
        if(table->keyCallbacks.isEqual(table, key, node->key))
            return node->value;
	
    return NULL;
}

NSMapEnumerator 
NSEnumerateMapTable(NSMapTable *table)
{
	NSMapEnumerator en;
	
    en.table = table;
    en.node = NULL;
    en.bucket = -1;
	
    return en;
}

BOOL 
NSNextMapEnumeratorPair(NSMapEnumerator *en, void **key, void **value)
{
    if(en->node)
		en->node = en->node->next;
    if(en->node == NULL) {
		for(en->bucket++; ((unsigned)en->bucket)<en->table->hashSize; en->bucket++)
			if (en->table->nodes[en->bucket]) {
				en->node = en->table->nodes[en->bucket];
				break;
			}
		if (((unsigned)en->bucket) >= en->table->hashSize) {
			en->node = NULL;
			en->bucket = en->table->hashSize-1;
			return NO;
		}
    }
    *key = en->node->key;
    *value = en->node->value;
    return YES;
}

NSArray *
NSAllMapTableKeys(NSMapTable *table)
{
	id array = [NSMutableArray arrayWithCapacity:table->itemsCount];
	struct _NSMapNode *node;
	unsigned i;
	if(table)
		{
		for(i = 0; i < table->hashSize; i++)
			for(node = table->nodes[i]; node; node=node->next)
				[array addObject:(NSObject*)(node->key)];
		}
    return array;
}

NSArray *
NSAllMapTableValues(NSMapTable *table)
{
	id array = [NSMutableArray arrayWithCapacity:table->itemsCount];
	struct _NSMapNode *node;
	unsigned i;
	if(table)
		{
		for(i = 0; i < table->hashSize; i++)
			for(node = table->nodes[i]; node; node = node->next)
				[array addObject:(NSObject*)(node->value)];
		}
    return array;
}

static void 
__NSMapGrow(NSMapTable *table, unsigned newSize)		// Add / Remove an Item
{
	unsigned i;
	struct _NSMapNode **newNodeTable = objc_calloc(newSize, sizeof(struct _NSMapNode*));
    
    for(i = 0; i < table->hashSize; i++) 
		{
		struct _NSMapNode *next, *node;
		unsigned int h;
		
		node = table->nodes[i];
		while(node) 
			{
			next = node->next;
			h = table->keyCallbacks.hash(table, node->key) % newSize;
			node->next = newNodeTable[h];
			newNodeTable[h] = node;
			node = next;
			}	}
	
    objc_free(table->nodes);
    table->nodes = newNodeTable;
    table->hashSize = newSize;
}

void 
NSMapInsert(NSMapTable *table, const void *key, const void *value)
{
	unsigned int h;
	struct _NSMapNode *node;
	
	if (key == table->keyCallbacks.notAKeyMarker)
		[NSException raise: NSInvalidArgumentException
					format: @"Invalid key (%p) to be added in NSMapTable.", key];
	
    h = table->keyCallbacks.hash(table, key) % table->hashSize;
    for(node = table->nodes[h]; node; node = node->next)
        if(table->keyCallbacks.isEqual(table, key, node->key))
            break;
	// Check if an entry for key exists
    if(node) 								// in nodeTable.
		{									
			if (key != node->key) 				// key exists.  Set it's new value
				{								// and release the old value.
					table->keyCallbacks.retain(table, key);
					table->keyCallbacks.release(table, node->key);
				}
			if (value != node->value) 
				{
				table->valueCallbacks.retain(table, value);
				table->valueCallbacks.release(table, node->value);
				}
			node->key = (void*)key;
			node->value = (void*)value;
			
			return;
		}
	
    node = objc_malloc(sizeof(struct _NSMapNode));	// key not found so allocate a
    table->keyCallbacks.retain(table, key);		// new bucket for the key
	table->valueCallbacks.retain(table, value);
    node->key = (void*)key;
    node->value = (void*)value;
    node->next = table->nodes[h];
    table->nodes[h] = node;
	
    __NSCheckMapTableFull(table);
}

void *
NSMapInsertIfAbsent(NSMapTable *table, const void *key,const void *value)
{
	unsigned int h;
	struct _NSMapNode *node;
	
    if (key == table->keyCallbacks.notAKeyMarker)
		[NSException raise: NSInvalidArgumentException
					format: @"Invalid key (%p) to be added in NSMapTable.", key];
	
    h = table->keyCallbacks.hash(table, key) % table->hashSize;
    for(node = table->nodes[h]; node; node = node->next)
        if(table->keyCallbacks.isEqual(table, key, node->key))
            break;								// Check if key already exists
    if(node)									// in the nodeTable and return
        return node->key;						// it if it does.
	
    node = objc_malloc(sizeof(struct _NSMapNode));	// key not found, alloc a new
    table->keyCallbacks.retain(table, key);		// bucket for the key
    table->valueCallbacks.retain(table, value);
    node->key = (void*)key;
    node->value = (void*)value;
    node->next = table->nodes[h];
    table->nodes[h] = node;
	
    __NSCheckMapTableFull(table);
	
    return NULL;
}

void 
NSMapInsertKnownAbsent(NSMapTable *table, const void *key, const void *value)
{
	unsigned int h;
	struct _NSMapNode *node;
	
    if (key == table->keyCallbacks.notAKeyMarker)
		[NSException raise: NSInvalidArgumentException
					format: @"Invalid key (%p) to be added in NSMapTable.", key];
	
    h = table->keyCallbacks.hash(table, key) % table->hashSize;
    for(node = table->nodes[h]; node; node = node->next)
        if(table->keyCallbacks.isEqual(table, key, node->key))
            break;
	
    if(node) 				// Check if an entry for key exists in nodeTable
		[NSException raise: NSInvalidArgumentException
					format: @"Nil object already existing in NSMapTable."];
	
    node = objc_malloc(sizeof(struct _NSMapNode));	// key not found, alloc a new
    table->keyCallbacks.retain(table, key);		// bucket for the key
    table->valueCallbacks.retain(table, value);
    node->key = (void*)key;
    node->value = (void*)value;
    node->next = table->nodes[h];
    table->nodes[h] = node;
	
    __NSCheckMapTableFull(table);
}

void 
NSMapRemove(NSMapTable *table, const void *key)
{
	unsigned int h;
	struct _NSMapNode *node, *node1 = NULL;
	
    if (key == nil)
	    return;
	
    h = table->keyCallbacks.hash(table, key) % table->hashSize;
	
	// node points to current bucket, and node1 to previous bucket 
	// or to NULL if current node is the first node in the list 
    for(node = table->nodes[h]; node; node1 = node, node = node->next)
        if(table->keyCallbacks.isEqual(table, key, node->key)) 
			{
	    	table->keyCallbacks.release(table, node->key);
	    	table->valueCallbacks.release(table, node->value);
            if(!node1)
                table->nodes[h] = node->next;
            else
                node1->next = node->next;
	    	objc_free(node);
	    	(table->itemsCount)--;
			
	    	return;
        	}
}

NSString *
NSStringFromMapTable(NSMapTable *table)
{
	id ret = [NSMutableString new];
	unsigned i;
	struct _NSMapNode *node;
    
    for (i = 0; i < table->hashSize; i++)
		for (node = table->nodes[i]; node; node = node->next) 
			{
			[ret appendString:table->keyCallbacks.describe(table, node->key)];
			[ret appendString:@"="];
			[ret appendString:table->valueCallbacks.describe(table, node->value)];
			[ret appendString:@"\n"];
			}
    
    return ret;
}

//*****************************************************************************
//
// 		Convenience functions 
//
//*****************************************************************************

unsigned 
__NSHashObject(void *table, const void *anObject)
{
    return (unsigned)[(id)anObject hash];
}

unsigned 
__NSHashPointer(void *table, const void *anObject)
{
    return (unsigned)((long)anObject / 4);
}

unsigned 
__NSHashInteger(void *table, const void *anObject)
{
    return (unsigned)(long)anObject;
}

unsigned 
__NSHashCString(void *table, const void *aString)
{
	register const char *p = (char*)aString;
	register unsigned hash = 0, hash2;
	register int i, n = strlen((char*)aString);
	
    for(i = 0; i < n; i++) 
		{
        hash <<= 4;
        hash += *p++;
        if((hash2 = hash & 0xf0000000))
            hash ^= (hash2 >> 24) ^ hash2;
		}
	
    return hash;
}

BOOL 
__NSCompareObjects(void *table, const void *anObject1, const void *anObject2)
{
    return [(NSObject*)anObject1 isEqual:(NSObject*)anObject2];
}

BOOL 
__NSComparePointers(void *table, const void *anObject1, const void *anObject2)
{
    return anObject1 == anObject2;
}

BOOL 
__NSCompareInts(void *table, const void *anObject1, const void *anObject2)
{
    return anObject1 == anObject2;
}

BOOL 
__NSCompareCString(void *table, const void *anObject1, const void *anObject2)
{
    return strcmp((char*)anObject1, (char*)anObject2) == 0;
}

void 
__NSRetainObjects(void *table, const void *anObject)
{
    [(NSObject*)anObject retain];
}

void 
__NSRetainNothing(void *table, const void *anObject)		{}

void 
__NSReleaseNothing(void *table, void *anObject)				{}

void 
__NSReleasePointers(void *table, void *anObject)			{ objc_free(anObject); }

void 
__NSReleaseObjects(void *table, void *anObject)
{
    [(NSObject*)anObject release];
}

NSString *
__NSDescribeObjects(void *table, const void *anObject)
{
    return [(NSObject*)anObject description];
}

NSString *
__NSDescribePointers(void *table, const void *anObject)
{
    return [NSString stringWithFormat:@"%p", anObject];
}

NSString *
__NSDescribeInts(void *table, const void *anObject)
{
    return [NSString stringWithFormat:@"%ld", (long)anObject];
}

// NSHashTable predefined callbacks
const NSHashTableCallBacks NSIntHashCallBacks = { 
    (unsigned(*)(NSHashTable*, const void*))__NSHashInteger, 
    (BOOL(*)(NSHashTable*, const void*, const void*))__NSCompareInts, 
    (void(*)(NSHashTable*, const void*))__NSRetainNothing, 
    (void(*)(NSHashTable*, void*))__NSReleaseNothing, 
    (NSString*(*)(NSHashTable*, const void*))__NSDescribeInts 
};

const NSHashTableCallBacks NSNonOwnedPointerHashCallBacks = { 
    (unsigned(*)(NSHashTable*, const void*))__NSHashPointer, 
    (BOOL(*)(NSHashTable*, const void*, const void*))__NSComparePointers, 
    (void(*)(NSHashTable*, const void*))__NSRetainNothing, 
    (void(*)(NSHashTable*, void*))__NSReleaseNothing, 
    (NSString*(*)(NSHashTable*, const void*))__NSDescribePointers 
};

const NSHashTableCallBacks NSNonRetainedObjectHashCallBacks = { 
    (unsigned(*)(NSHashTable*, const void*))__NSHashObject, 
    (BOOL(*)(NSHashTable*, const void*, const void*))__NSCompareObjects, 
    (void(*)(NSHashTable*, const void*))__NSRetainNothing, 
    (void(*)(NSHashTable*, void*))__NSReleaseNothing, 
    (NSString*(*)(NSHashTable*, const void*))__NSDescribeObjects 
};

const NSHashTableCallBacks NSObjectHashCallBacks = { 
    (unsigned(*)(NSHashTable*, const void*))__NSHashObject, 
    (BOOL(*)(NSHashTable*, const void*, const void*))__NSCompareObjects, 
    (void(*)(NSHashTable*, const void*))__NSRetainObjects, 
    (void(*)(NSHashTable*, void*))__NSReleaseObjects, 
    (NSString*(*)(NSHashTable*, const void*))__NSDescribeObjects 
};

const NSHashTableCallBacks NSOwnedObjectIdentityHashCallBacks = { 
    (unsigned(*)(NSHashTable*, const void*))__NSHashPointer, 
    (BOOL(*)(NSHashTable*, const void*, const void*))__NSComparePointers, 
    (void(*)(NSHashTable*, const void*))__NSRetainObjects, 
    (void(*)(NSHashTable*, void*))__NSReleaseObjects, 
    (NSString*(*)(NSHashTable*, const void*))__NSDescribeObjects 
};

const NSHashTableCallBacks NSOwnedPointerHashCallBacks = { 
    (unsigned(*)(NSHashTable*, const void*))__NSHashObject, 
    (BOOL(*)(NSHashTable*, const void*, const void*))__NSCompareObjects, 
    (void(*)(NSHashTable*, const void*))__NSRetainNothing, 
    (void(*)(NSHashTable*, void*))__NSReleasePointers, 
    (NSString*(*)(NSHashTable*, const void*))__NSDescribePointers 
};

const NSHashTableCallBacks NSPointerToStructHashCallBacks = { 
    (unsigned(*)(NSHashTable*, const void*))__NSHashPointer, 
    (BOOL(*)(NSHashTable*, const void*, const void*))__NSComparePointers, 
    (void(*)(NSHashTable*, const void*))__NSRetainNothing, 
    (void(*)(NSHashTable*, void*))__NSReleasePointers, 
    (NSString*(*)(NSHashTable*, const void*))__NSDescribePointers 
};

// NSMapTable predefined callbacks 
const NSMapTableKeyCallBacks NSIntMapKeyCallBacks = {
    (unsigned(*)(NSMapTable *, const void *))__NSHashInteger,
    (BOOL(*)(NSMapTable *, const void *, const void *))__NSCompareInts,
    (void (*)(NSMapTable *, const void *anObject))__NSRetainNothing,
    (void (*)(NSMapTable *, void *anObject))__NSReleaseNothing,
    (NSString *(*)(NSMapTable *, const void *))__NSDescribeInts,
    (const void *)NSNotAnIntMapKey
};

const NSMapTableKeyCallBacks NSIntegerMapKeyCallBacks = {
    (unsigned(*)(NSMapTable *, const void *))__NSHashInteger,
    (BOOL(*)(NSMapTable *, const void *, const void *))__NSCompareInts,
    (void (*)(NSMapTable *, const void *anObject))__NSRetainNothing,
    (void (*)(NSMapTable *, void *anObject))__NSReleaseNothing,
    (NSString *(*)(NSMapTable *, const void *))__NSDescribeInts,
    (const void *)NSNotAnIntMapKey
};

const NSMapTableValueCallBacks NSIntMapValueCallBacks = {
    (void (*)(NSMapTable *, const void *))__NSRetainNothing,
    (void (*)(NSMapTable *, void *))__NSReleaseNothing,
    (NSString *(*)(NSMapTable *, const void *))__NSDescribeInts
};

const NSMapTableKeyCallBacks NSNonOwnedPointerMapKeyCallBacks = {
    (unsigned(*)(NSMapTable *, const void *))__NSHashPointer,
    (BOOL(*)(NSMapTable *, const void *, const void *))__NSComparePointers,
    (void (*)(NSMapTable *, const void *anObject))__NSRetainNothing,
    (void (*)(NSMapTable *, void *anObject))__NSReleaseNothing,
    (NSString *(*)(NSMapTable *, const void *))__NSDescribePointers,
    (const void *)NULL
}; 

const NSMapTableKeyCallBacks NSNonOwnedCStringMapKeyCallBacks = {
    (unsigned(*)(NSMapTable *, const void *))__NSHashCString,
    (BOOL(*)(NSMapTable *, const void *, const void *))__NSCompareCString,
    (void (*)(NSMapTable *, const void *anObject))__NSRetainNothing,
    (void (*)(NSMapTable *, void *anObject))__NSReleaseNothing,
    (NSString *(*)(NSMapTable *, const void *))__NSDescribePointers,
    (const void *)NULL
}; 

const NSMapTableKeyCallBacks NSOwnedPointerMapKeyCallBacks = {
    (unsigned(*)(NSMapTable *, const void *))__NSHashPointer,
    (BOOL(*)(NSMapTable *, const void *, const void *))__NSComparePointers,
    (void (*)(NSMapTable *, const void *anObject))__NSRetainNothing,
    (void (*)(NSMapTable *, void *anObject))__NSReleasePointers,
    (NSString *(*)(NSMapTable *, const void *))__NSDescribePointers,
    (const void *)NULL
};

const NSMapTableValueCallBacks NSNonOwnedPointerMapValueCallBacks = {
    (void (*)(NSMapTable *, const void *))__NSRetainNothing,
    (void (*)(NSMapTable *, void *))__NSReleaseNothing,
    (NSString *(*)(NSMapTable *, const void *))__NSDescribePointers
};

const NSMapTableKeyCallBacks NSNonOwnedPointerOrNullMapKeyCallBacks = {
    (unsigned(*)(NSMapTable *, const void *))__NSHashPointer,
    (BOOL(*)(NSMapTable *, const void *, const void *))__NSComparePointers,
    (void (*)(NSMapTable *, const void *anObject))__NSRetainNothing,
    (void (*)(NSMapTable *, void *anObject))__NSReleaseNothing,
    (NSString *(*)(NSMapTable *, const void *))__NSDescribePointers,
    (const void *)NSNotAPointerMapKey
};

const NSMapTableKeyCallBacks NSNonRetainedObjectMapKeyCallBacks = {
    (unsigned(*)(NSMapTable *, const void *))__NSHashObject,
    (BOOL(*)(NSMapTable *, const void *, const void *))__NSCompareObjects,
    (void (*)(NSMapTable *, const void *anObject))__NSRetainNothing,
    (void (*)(NSMapTable *, void *anObject))__NSReleaseNothing,
    (NSString *(*)(NSMapTable *, const void *))__NSDescribeObjects,
    (const void *)NULL
};

const NSMapTableValueCallBacks NSNonRetainedObjectMapValueCallBacks = {
    (void (*)(NSMapTable *, const void *))__NSRetainNothing,
    (void (*)(NSMapTable *, void *))__NSReleaseNothing,
    (NSString *(*)(NSMapTable *, const void *))__NSDescribeObjects
}; 

const NSMapTableKeyCallBacks NSObjectMapKeyCallBacks = {
    (unsigned(*)(NSMapTable *, const void *))__NSHashObject,
    (BOOL(*)(NSMapTable *, const void *, const void *))__NSCompareObjects,
    (void (*)(NSMapTable *, const void *anObject))__NSRetainObjects,
    (void (*)(NSMapTable *, void *anObject))__NSReleaseObjects,
    (NSString *(*)(NSMapTable *, const void *))__NSDescribeObjects,
    (const void *)NULL
}; 

const NSMapTableValueCallBacks NSObjectMapValueCallBacks = {
    (void (*)(NSMapTable *, const void *))__NSRetainObjects,
    (void (*)(NSMapTable *, void *))__NSReleaseObjects,
    (NSString *(*)(NSMapTable *, const void *))__NSDescribeObjects
}; 

const NSMapTableKeyCallBacks GSOwnedCStringMapKeyCallBacks = {
    (unsigned(*)(NSMapTable *, const void *))__NSHashCString,
    (BOOL(*)(NSMapTable *, const void *, const void *))__NSCompareCString,
    (void (*)(NSMapTable *, const void *anObject))__NSRetainNothing,
    (void (*)(NSMapTable *, void *anObject))__NSReleasePointers,
    (NSString *(*)(NSMapTable *, const void *))__NSDescribePointers,
    (const void *)NULL
}; 

const NSMapTableValueCallBacks NSOwnedPointerMapValueCallBacks = {
    (void (*)(NSMapTable *, const void *))__NSRetainNothing,
    (void (*)(NSMapTable *, void *))__NSReleasePointers,
    (NSString *(*)(NSMapTable *, const void *))__NSDescribePointers
}; 

