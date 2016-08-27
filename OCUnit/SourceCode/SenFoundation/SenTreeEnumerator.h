/*$Id: SenTreeEnumerator.h,v 1.5 2001/11/22 13:11:49 phink Exp $*/

// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import <Foundation/NSEnumerator.h>
#import "SenTrees.h"


@class NSArray;


@interface SenTreeEnumerator : NSEnumerator
{
    @private
    SenTreeTraversalType	traversalType;
    NSArray					*queue;
}

+ (SenTreeEnumerator *) enumeratorWithTree:(id <SenTrees>)aTree traversalType:(SenTreeTraversalType)aTraversalType;
+ (SenTreeEnumerator *) enumeratorWithTree:(id <SenTrees>)aTree;

- (id) initWithTree:(id <SenTrees>)aTree traversalType:(SenTreeTraversalType)aTraversalType;
- (id) initWithTree:(id <SenTrees>)aTree;

- (BOOL) shouldEnter:(id <SenTrees>)aTree;

@end
