/*$Id: SenUtilities.h,v 1.8 2001/11/22 13:11:50 phink Exp $*/

// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import <Foundation/Foundation.h>
#import "SenFoundationDefines.h"
#import "SenAssertion.h"

// Defining ASSIGN and RETAIN.
//
// ASSIGN should be used in -set... methods instead of the Apple 
// promoted pattern (autorelease / retain). It is faster and 
// semantically more correct.
// newVal is to avoid multiple evaluations of val.
// RETAIN is deprecated and should not used.

#if defined (GNUSTEP)
// GNUstep has its own definitions of ASSIGN and RETAIN
#else
    #define RETAIN(var,val) \
    do { \
        id newVal = (val); \
        if (var != newVal) { \
            if (var) { \
                [var release]; \
            } \
            if (newVal) { \
                [newVal retain]; \
            } \
            var = newVal; \
        } \
    } while (0)
    
    #if defined(GARBAGE_COLLECTION)
        #define ASSIGN(var,val) \
        do { \
            var = val; \
        } while (0)
    #else
        #define ASSIGN RETAIN
    #endif
#endif

// Defining CHANGE_ASSIGN and CHANGE_RETAIN.
//
// Like ASSIGN above, CHANGE_ASSIGN should be used in -set... methods 
// instead of the Apple promoted pattern (autorelease / retain).
// CHANGE_ASSIGN sends willChange to self, but only if the variable 
// is really changed.
// CHANGE_RETAIN is deprecated and should not used.

@protocol Changes
- (void) willChange;
@end

#define SELF_WILL_CHANGE do { \
        [(id <Changes>) self willChange]; \
} while (0)


#define CHANGE_RETAIN(var,val) do { \
    id newVal = (val); \
    if (var != newVal) { \
        SELF_WILL_CHANGE; \
        if (var) { \
            [var release]; \
        } \
        if (newVal) { \
            [newVal retain]; \
        } \
        var = newVal; \
    } \
} while (0)

#if defined(GARBAGE_COLLECTION)
    #define CHANGE_ASSIGN(var,val) \
    do { \
        SELF_WILL_CHANGE; \
        var = val; \
    } while (0)
#else
    #define CHANGE_ASSIGN  CHANGE_RETAIN 
#endif

// Defining RELEASE.
//
// The RELEASE macro can be used in any place where a release 
// message would be sent. VAR is released and set to nil
#if defined (GNUSTEP)
// GNUstep has its own macro.
#else
    #if defined(GARBAGE_COLLECTION)
        #define RELEASE(var)
    #else
        #define RELEASE(var) \
        do { \
            if (var) { \
                [(id) var release]; \
                var = nil; \
            } \
        } while (0)
    #endif
#endif


// Protected type casting
#define AsKindOfClass(_class,_object) \
({ \
    id _val = (_object); \
    senassert((_val == nil) || [_val isKindOfClass:[_class class]]); \
    (_class *) _val; \
})


#define AsConformingToProtocol(_protocol,_object) \
({ \
    id _val = (_object); \
    senassert((_val == nil) || [_val conformsToProtocol:@protocol(_protocol)]); \
    (id <_protocol>) _val; \
})


// Miscellaneous constants and predicates
SENFOUNDATION_EXPORT NSRange SenRangeNotFound;

#define isEmptyStringRange(x)          ((x).length == 0)
#define isFoundStringRange(x)          ((x).length > 0)
#define isValidTextRange(x)            ((x).location != NSNotFound)

#define SenDefaultNotificationCenter   [NSNotificationCenter defaultCenter]
#define SenDefaultUserDefaults         [NSUserDefaults standardUserDefaults]
#define SenDefaultFileManager          [NSFileManager defaultManager]
#define SenDefaultNotificationQueue    [NSNotificationQueue defaultQueue]
#define SenDefaultTimeZone             [NSTimeZone defaultTimeZone]
