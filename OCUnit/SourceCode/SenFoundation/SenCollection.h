/*$Id: SenCollection.h,v 1.5 2001/11/22 13:11:48 phink Exp $*/

// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import <Foundation/Foundation.h>
#import "SenEmptiness.h"

// FIXME This is an experiment to add a missing abstraction to Foundation. 
// Do we really want this?

@protocol SenCollection <SenEmptiness>

// Primitives
- (NSEnumerator *) objectEnumerator;
- (unsigned) count;
- (BOOL) containsObject:(id) anObject;


// Conversions
- (NSArray *) asArray;
- (NSSet *) asSet;

// Closures

// Execute
- (void) makeObjectsPerformSelector:(SEL) aSelector;
- (void) makeObjectsPerformSelector:(SEL) aSelector with:(id) anObject;


// Detect
// Returns the first object for which aSelector returns YES.
- (id) firstObjectDetectedBySelector:(SEL)aSelector;
- (id) firstObjectDetectedBySelector:(SEL)aSelector with:(id) anObject;
- (id) firstObjecRejectedBySelector:(SEL)aSelector;
- (id) firstObjecRejectedBySelector:(SEL)aSelector with:(id) anObject;

- (BOOL)existsObjectSatisfyingSelector:(SEL)aSelector;
- (BOOL)existsObjectSatisfyingSelector:(SEL)aSelector with:(id) anObject;
- (BOOL)existsObjectNotSatisfyingSelector:(SEL)aSelector;
- (BOOL)existsObjectNotSatisfyingSelector:(SEL)aSelector with:(id) anObject;


// FIXME
// The following methods currently return <SenCollection>.
// Should the result be of the same class as the receiver? an NSArray? an enumerator ?

// Collect
// Returns the collection obtained by performing aSelector on each element of the receiver.
- (id <SenCollection>) collectionByPerformingSelector:(SEL) aSelector;
- (id <SenCollection>) collectionByPerformingSelector:(SEL) aSelector withObject:(id) anObject;

// Select
// Returns the collection of all the elements of the receiver for which aSelector returns YES
- (id <SenCollection>) collectionBySelectingWithSelector:(SEL) aSelector;
- (id <SenCollection>) collectionBySelectingWithSelector:(SEL) aSelector withObject:(id) anObject;

// Reject
// Returns the collection of all the elements of the receiver for which aSelector returns NO
- (id <SenCollection>) collectionByRejectingWithSelector:(SEL) aSelector;
- (id <SenCollection>) collectionByRejectingWithSelector:(SEL) aSelector withObject:(id) anObject;

// Sum
// Returns the sum obtained by performing aSelector on each element of the receiver
// FIXME: add other types as needed or avoid  code duplication with something like
// - (void) inject:(const void *) addr inSumWithSelector:(SEL) aSelector ofObjCType:(const char *) type
- (unsigned int) sumWithUnsignedIntSelector:(SEL) aSelector;
- (double) sumWithDoubleSelector:(SEL) aSelector;
@end


@interface NSArray (SenCollection) <SenCollection>
@end


@interface NSSet (SenCollection) <SenCollection>
@end


@interface NSDictionary (SenCollection) <SenCollection>
@end
