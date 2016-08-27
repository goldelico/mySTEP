/*$Id: SenClassEnumerator.m,v 1.6 2001/11/22 13:11:48 phink Exp $*/

// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import "SenClassEnumerator.h"
#import "SenAssertion.h"

#if defined (MACOSX)
#import <objc/objc-runtime.h>
#endif

@implementation SenClassEnumerator

+ (NSEnumerator *) classEnumerator
{
    return [[[self alloc] init] autorelease];
}

- (void) dealloc
{
#if defined (GNUSTEP)
// Do nothing
#elif defined (MACOSX)
    free(classes);
#else
// Do nothing
#endif    
    [super dealloc];
}

- (id) init
{
#if defined (GNUSTEP)
    self = [super init];
    state = NULL;
    isAtEnd = NO;
#elif defined (MACOSX)
    Class aClass = Nil;
    int	newNumClasses = 0;
    int anIndex = 0;
    int allocatedSize = 0;

    classes = NULL;
    numClasses = 0;
    self = [super init];

    NS_DURING
        newNumClasses = objc_getClassList(NULL, 0);
        if ( newNumClasses > 0 ) {
            while (numClasses < newNumClasses) {
                numClasses = newNumClasses;
                allocatedSize = sizeof(Class) * numClasses;
                classes = realloc(classes, allocatedSize);
                if ( classes == NULL ) {
                    NSAssert((NO),@"In classEnumerator could not allocate memory for classes array!");
                }
                newNumClasses = objc_getClassList(classes, numClasses);
            }
            cleanClasses = [NSMutableArray arrayWithCapacity:numClasses];
            newNumClasses = numClasses; // Just to be sure they are the same. William
            while ( anIndex < numClasses ) {
                aClass = classes[anIndex];
                // William says: this next piece of code is a hack!
                // It removes classes that are not full blown objects. (i.e. they will make our app crash)
                // In tests; I know it will remove the following objects:
                // NSInvocationBuilder
                // NSLeafProxy
                // _NSZombie
                if ( (class_getClassMethod(aClass, @selector(description)) != NULL)
                && (class_getClassMethod(aClass, @selector(conformsToProtocol:)) != NULL)
                && (class_getClassMethod(aClass, @selector(superclass)) != NULL)
                 ) {
                    [cleanClasses addObject:aClass];
                } else {
                    newNumClasses--;
                }
                anIndex++;
            }
            numClasses = newNumClasses; // This is now the number of clean classes.
            if ( numClasses > 0 ) {
                isAtEnd = NO;
            } else {
                isAtEnd = YES;
            }
        } else {
            // No classes; the end is at hand now.
            isAtEnd = YES;
        }
    NS_HANDLER
            SEN_DEBUG (([NSString stringWithFormat:@"Skipping %@ (%@)", NSStringFromClass(aClass), localException]));
    NS_ENDHANDLER
#else
    self = [super init];

    class_hash = objc_getClasses();
    state = NXInitHashState(class_hash);
    isAtEnd = NO;
#endif
    return self;
}


- (id) nextObject
{
    if (isAtEnd) {
        return nil;
    } else {
        Class aClass = Nil;
#if defined (GNUSTEP)
 	aClass = objc_next_class(&state);
 	if (aClass == Nil)
            isAtEnd = YES;
#elif defined (MACOSX)
        isAtEnd = (index >= numClasses);
        if(!isAtEnd) {
            aClass = [cleanClasses objectAtIndex:index++];
        }
#else
        isAtEnd = !NXNextHashState(class_hash, &state, (void **) &aClass);
#endif
        return isAtEnd ? nil : aClass;
    }
}
@end
