/* 
   NSArray.h

   Interface to NSArray

   Copyright (C) 1995, 1996 Free Software Foundation, Inc.

   Author:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   Date:	1995
   
   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	01. April 2008 - aligned with 10.5 
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSArray
#define _mySTEP_H_NSArray

#import <Foundation/NSObject.h>
#import <Foundation/NSRange.h>

@class NSString;
@class NSEnumerator;
@class NSData;
@class NSDictionary;
@class NSIndexSet;
@class NSURL;

@interface NSArray : NSObject  <NSCoding, NSCopying, NSMutableCopying>
{
	@public
	id *_contents;
	unsigned int _count;
}

- (id) initWithObjects:(id *) objects count:(NSUInteger) count;
- (id) objectAtIndex:(NSUInteger) index;
- (NSUInteger) count;

@end

@interface NSArray (NonCore)

+ (id) array;
+ (id) arrayWithArray:(NSArray *) array;
+ (id) arrayWithContentsOfFile:(NSString *) file;
+ (id) arrayWithContentsOfURL:(NSURL *) url;
+ (id) arrayWithObject:(id) anObject;
+ (id) arrayWithObjects:(id) firstObj, ...;
+ (id) arrayWithObjects:(id *) objects count:(NSUInteger) count;

- (NSArray *) arrayByAddingObject: anObject;
- (NSArray *) arrayByAddingObjectsFromArray:(NSArray *) anotherArray;
- (NSString *) componentsJoinedByString:(NSString *) separator;
- (BOOL) containsObject:(id) anObject;
- (NSString *) description;
- (NSString *) descriptionWithLocale:(id) locale;
- (NSString *) descriptionWithLocale:(id) locale
							  indent:(NSUInteger) level;
- (id) firstObjectCommonWithArray:(NSArray *) otherArray;
- (void) getObjects:(id *) objs;
- (void) getObjects:(id *) objs range:(NSRange) aRange;
- (NSUInteger) indexOfObject:(id) anObject;
- (NSUInteger) indexOfObject:(id) anObject inRange:(NSRange) aRange;
- (NSUInteger) indexOfObjectIdenticalTo:(id) anObject;
- (NSUInteger) indexOfObjectIdenticalTo:(id) anObject inRange:(NSRange) aRange;
- (id) initWithArray:(NSArray *) array;
- (id) initWithArray:(NSArray *) array copyItems:(BOOL) flag;
- (id) initWithContentsOfFile:(NSString *) file;
- (id) initWithContentsOfURL:(NSURL *) url;
- (id) initWithObjects:(id) firstObj, ...;
- (id) inttWithObjects:(id *) objects count:(NSUInteger) count;
- (BOOL) isEqualToArray:(NSArray *) otherArray;
- (id) lastObject;
- (void) makeObjectsPerformSelector:(SEL) aSelector;
- (void) makeObjectsPerformSelector:(SEL) aSelector withObject:(id) argument;
- (NSEnumerator *) objectEnumerator;
- (NSArray *) objectsAtIndexes:(NSIndexSet *) idx;
- (NSArray *) pathsMatchingExtensions:(NSArray *) extensions;
- (NSEnumerator *) reverseObjectEnumerator;
- (void) setValue:(id) value forKey:(NSString *) key;
- (NSData *) sortedArrayHint;
- (NSArray *) sortedArrayUsingFunction:(NSInteger (*)(id, id, void*)) comparator
							   context:(void *) context;
- (NSArray *) sortedArrayUsingFunction:(NSInteger (*)(id, id, void*)) comparator
							   context:(void *) context
							      hint:(NSData *) hint;
- (NSArray *) sortedArrayUsingSelector:(SEL) comparator;
- (NSArray *) subarrayWithRange:(NSRange) range;
- (BOOL) writeToFile:(NSString *) path atomically:(BOOL) useAuxilliaryFile;
- (BOOL) writeToURL:(NSString *) path atomically:(BOOL) flag;

@end


@interface NSMutableArray : NSArray
{
	unsigned int _capacity;
//	unsigned int _mutationSequence;	// used to detect mutation in enumerator
}

- (void) addObject:(id) anObject;
- (id) initWithCapacity:(NSUInteger) numItems;
- (void) insertObject:anObject atIndex:(NSUInteger) index;
- (void) exchangeObjectAtIndex:(NSUInteger) i1 withObjectAtIndex:(NSUInteger) i2;
- (void) removeObjectAtIndex:(NSUInteger) index;
- (void) removeObject:(id) anObject inRange:(NSRange) aRange;
- (void) removeObjectIdenticalTo:(id) anObject;
- (void) removeObjectIdenticalTo:(id) anObject inRange:(NSRange) aRange;
- (void) replaceObjectAtIndex:(NSUInteger) index withObject:(id) anObject;
- (void) replaceObjectsInRange:(NSRange) aRange
		  withObjectsFromArray:(NSArray *) anArray;
- (void) replaceObjectsInRange:(NSRange) aRange
		  withObjectsFromArray:(NSArray *) anArray
						 range:(NSRange) anotherRange;

@end

@interface NSMutableArray (NonCore)

+ (id) arrayWithCapacity:(NSUInteger) numItems;

- (void) addObjectsFromArray:(NSArray *) otherArray;
- (void) insertObjects:(NSArray *) objects atIndexes:(NSIndexSet *) indexes;
- (void) removeAllObjects;
- (void) removeLastObject;
- (void) removeObject:(id) anObject;
- (void) removeObjectsAtIndexes:(NSIndexSet *) indexes;
- (void) removeObjectsFromIndices:(NSUInteger *) indices 
					   numIndices:(NSUInteger) count;
- (void) removeObjectsInArray:(NSArray *) otherArray;
- (void) removeObjectsInRange:(NSRange) aRange;
- (void) replaceObjectsAtIndexes:(NSIndexSet *) indexes withObjects:(NSArray *) objects;
- (void) setArray:(NSArray *) otherArray;
- (void) sortUsingFunction:(NSInteger(*)(id,id,void*)) compare
				   context:(void *) context;
- (void) sortUsingSelector:(SEL) aSelector;

@end

#endif /* _mySTEP_H_NSArray */
