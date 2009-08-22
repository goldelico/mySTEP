//
//  CFBase.m
//  CoreFoundation
//
//  Created by H. Nikolaus Schaller on 03.10.08.
//  Copyright 2008 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <CoreFoundation/CFBase.h>

#ifdef __mySTEP__

#if INLINE
#else

#define CFIndex _CFIndex
#import <Foundation/Foundation.h>

CFStringRef CFCopyDescription(CFTypeRef cf) { return (CFStringRef) [(NSObject *) cf description]; }
CFStringRef CFCopyTypeIDDescription(CFTypeID type_id) { return (CFStringRef) NSStringFromClass((Class) type_id); }
Boolean CFEqual(CFTypeRef cf1, CFTypeRef cf2) { return [(NSObject *) cf1 isEqual:(NSObject *) cf2]; }
CFAllocatorRef CFGetAllocator(CFTypeRef cf) { return NULL; }
CFIndex CFGetRetainCount(CFTypeRef cf) { return [(NSObject *) cf retainCount]; }
CFTypeID CFGetTypeID(CFTypeRef cf) { return (CFTypeID) [(NSObject *) cf class]; }	// address of class object is unique
CFHashCode CFHash(CFTypeRef cf) { return [(NSObject *) cf hash]; }
CFTypeRef CFMakeCollectable(CFTypeRef cf) { return cf; }
void CFRelease(CFTypeRef cf) { [(NSObject *) cf release]; }
CFTypeRef CFRetain(CFTypeRef cf) { return [(NSObject *) cf retain]; }
void CFShow(CFTypeRef obj) { fprintf(stderr, "%s\n", [[(NSObject *) obj description] cString]); }
#endif
#endif
