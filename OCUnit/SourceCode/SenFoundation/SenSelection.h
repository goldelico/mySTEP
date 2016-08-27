/*$Id: SenSelection.h,v 1.5 2001/11/22 13:11:49 phink Exp $*/

// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import <Foundation/NSObject.h>
#import "SenEmptiness.h"
#import "SenFoundationDefines.h"


@class	NSArray;
@class	NSMutableArray;


SENFOUNDATION_EXPORT NSString *SenSelectionWillChangeNotification;
SENFOUNDATION_EXPORT NSString *SenSelectionDidChangeNotification;


// We could have subclassed NSMutableArray class cluster to make a notifying mutable array

@interface SenSelection : NSObject <SenEmptiness, NSCoding>
{
    NSMutableArray	*selectedObjects;
}

+ (SenSelection *) selection;
+ (SenSelection *) selectionWithObject:(id)anObject;

- (Class) selectedClass;
- (NSObject *) selectedObject;
- (NSArray *) selectedObjects;
- (void) setSelectedObjects:(NSArray *)objects;

- (void) setSelectedObject:(NSObject *)anObject;
- (void) addSelectedObject:(NSObject *)anObject;

- (unsigned int) count;
- (id) objectAtIndex:(unsigned int)anIndex;
- (NSEnumerator *) objectEnumerator;
- (BOOL) containsObject:(id)anObject;

- (void) empty;
- (BOOL) isEmpty;

@end
