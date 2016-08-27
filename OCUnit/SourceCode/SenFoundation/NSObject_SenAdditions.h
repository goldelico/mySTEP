/*$Id: NSObject_SenAdditions.h,v 1.4 2001/11/22 13:11:47 phink Exp $*/

// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import <Foundation/Foundation.h>
#import "SenCollection.h"

@interface NSObject (SenAdditions)
- (void) performSelector:(SEL) aSelector withEachObjectInCollection:(id <SenCollection>) aCollection;
- (void) performSelector:(SEL) aSelector withEachObjectInCollection:(id <SenCollection>) aCollection withObject:(id) anObject;

// Collect
// Returns the collection obtained by performing aSelector on each element of the receiver.
- (id <SenCollection>) collectionByPerformingSelector:(SEL) aSelector withEachObjectInCollection:(id <SenCollection>) aCollection;
- (id <SenCollection>) collectionByPerformingSelector:(SEL) aSelector withEachObjectInCollection:(id <SenCollection>) aCollection withObject:(id) anObject;

// Select
// Returns the collection of all the elements of the receiver for which aSelector returns YES
//- (id <SenCollection>) collectionBySelectingWithSelector:(SEL) aSelector withEachObjectInCollection:(id <SenCollection>) aCollection;
//- (id <SenCollection>) collectionBySelectingWithSelector:(SEL) aSelector withEachObjectInCollection:(id <SenCollection>) aCollection withObject:(id) anObject;

// Reject
// Returns the collection of all the elements of the receiver for which aSelector returns NO
//- (id <SenCollection>) collectionByRejectingWithSelector:(SEL) aSelector withEachObjectInCollection:(id <SenCollection>) aCollection;
//- (id <SenCollection>) collectionByRejectingWithSelector:(SEL) aSelector withEachObjectInCollection:(id <SenCollection>) aCollection withObject:(id) anObject;

@end
