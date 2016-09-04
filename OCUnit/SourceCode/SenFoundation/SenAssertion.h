/*$Id: SenAssertion.h,v 1.4 2001/11/22 13:11:48 phink Exp $*/

// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import <Foundation/NSString.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSException.h>

// Defines precondition, postcondition and invariant macros in addition to assert.
// Each type of condition can be blocked individually.

// FIXME: blocks would be nice...

#ifndef NS_BLOCK_ASSERTIONS
#define senassert(condition)	        NSAssert1(condition,@"Assertion failed: %s", #condition);

// senprecondition
#ifndef SEN_BLOCK_PRECONDITIONS
#define senprecondition(condition)      NSAssert1(condition,@"Broken precondition: %s", #condition);
#else
#define senprecondition(condition)
#endif

// senpostcondition
#ifndef SEN_BLOCK_POSTCONDITIONS
#define senpostcondition(condition)     NSAssert1(condition,@"Broken postcondition: %s", #condition);
#else
#define senpostcondition(condition)
#endif

// seninvariant
#ifndef SEN_BLOCK_INVARIANTS
#define seninvariant(condition)	        NSAssert1(condition,@"Broken invariant: %s", #condition);
#else
#define seninvariant(condition)
#endif

#else // NS_BLOCK_ASSERTIONS

#define senassert(condition)
#define senprecondition(condition)
#define senpostcondition(condition)
#define seninvariant(condition)

#endif // NS_BLOCK_ASSERTIONS

#ifdef DEBUG
#define SEN_DEBUG_OUT(type,message)	NSLog (@"%@ [%@, %@] %@", (type), self, NSStringFromSelector(_cmd), (message))
#define SEN_DEBUG(message)	        SEN_DEBUG_OUT(@"Debug",(message))
#define SEN_TRACE                   SEN_DEBUG_OUT(@"Trace",@"")
#else
#define SEN_DEBUG(message)
#define SEN_TRACE
#endif



