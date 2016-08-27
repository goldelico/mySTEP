/*$Id: NSObject_SenRuntimeUtilities.h,v 1.5 2001/11/22 13:11:47 phink Exp $*/

// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import <Foundation/Foundation.h>
#import "SenFoundationDefines.h"

SENFOUNDATION_EXPORT NSString *SenMethodName (id self, SEL _cmd);
// Prefixes the selector name with + for class and - for instance methods.

@interface NSObject (SenRuntimeUtilities)
+ (NSEnumerator *) instanceInvocationEnumerator;

+ (NSString *) className;
- (NSString *) className;

// FIXME
// superclasses should be ordered from specific to general => NSArray or NSEnumerator
// subclasses should be in a SenTree -> depthFirstSubclassEnumerator, breadthFirstSubclassEnumerator, directSubclassEnumerator...
+ (NSArray *) allSuperclasses;
+ (NSArray *) allSubclasses;

- (NSArray *) allSuperclasses;
- (NSArray *) allSubclasses;

+ (NSArray *) instanceInvocations;
+ (NSArray *) allInstanceInvocations;
- (NSArray *) instanceInvocations;
- (NSArray *) allInstanceInvocations;

@end

