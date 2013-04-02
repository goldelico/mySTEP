//
//  CFBase.h
//  CoreFoundation
//
//  Created by H. Nikolaus Schaller on 03.10.08.
//  Copyright 2008 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//
//  Note:
//  * we have a completely different architecture - our CoreFoundation.framework is built on top of Foundation.framework
//

#ifndef _mySTEP_H_CFBase
#define _mySTEP_H_CFBase

#include <stdio.h>

#if INLINE
@class NSObject;
@class NSString;
typedef char BOOL;

NSString *NSStringFromClass(Class class);

@interface CFType	// declare methods that we can call
- (NSString *) description;
- (BOOL) isEqual:(id) other;
- (unsigned int) retainCount;
- (Class) class;
- (unsigned int) hash;
- (void) release;
- (id) retain;
- (char *) cString;
@end
#endif

// declares types from libkern/IOTypes.h

typedef unsigned int UInt;
typedef signed int SInt;
typedef unsigned char UInt8;
typedef unsigned short UInt16;
typedef unsigned long UInt32;
typedef unsigned long long UInt64;
typedef signed char SInt8;
typedef signed short SInt16;
typedef signed long SInt32;
typedef signed long long SInt64;
typedef SInt32 OSStatus;
typedef UInt32 OptionBits;
typedef unsigned char Boolean;

// declares from IOKit/IOReturn.h

typedef int IOReturn;

#define kIOReturnSuccess 0
#define kIOReturnError 1

// other typedefs

typedef UInt32 CFOptionFlags;

typedef const void *CFTypeRef;
typedef const struct __CFString *CFStringRef;

typedef UInt32 CFHashCode;
typedef UInt32 CFTypeID;

typedef const struct __CFAllocator *CFAllocatorRef;
#ifndef _mySTEP_H_NSObjCRuntime
typedef SInt32 CFIndex;
#endif
typedef struct NSRange CFRange;

#if INLINE
inline CFStringRef CFCopyDescription(CFTypeRef cf) { return [(id) cf description]; }
inline CFStringRef CFCopyTypeIDDescription(CFTypeID type_id) { return NSStringFromClass((Class) type_id); }
inline Boolean CFEqual(CFTypeRef cf1, CFTypeRef cf2) { return [cf1 isEqual:cf2]; }
inline CFAllocatorRef CFGetAllocator(CFTypeRef cf) { return NULL; }
inline CFIndex CFGetRetainCount(CFTypeRef cf) { return [cf retainCount]; }
CFTypeID CFGetTypeID(CFTypeRef cf) { return (CFTypeID) [cf class]; }	// address of class object is unique
inline CFHashCode CFHash(CFTypeRef cf) { return [cf hash]; }
inline CFTypeRef CFMakeCollectable(CFTypeRef cf) { return cf; }
inline void CFRelease(CFTypeRef cf) { [cf release]; }
inline CFTypeRef CFRetain(CFTypeRef cf) { return [cf retain]; }
inline void CFShow(CFTypeRef obj) { fprintf(stderr, "%s", [obj cString]); }
#else

CFStringRef CFCopyDescription(CFTypeRef cf);
CFStringRef CFCopyTypeIDDescription(CFTypeID type_id);
Boolean CFEqual(CFTypeRef cf1, CFTypeRef cf2);
CFAllocatorRef CFGetAllocator(CFTypeRef cf);
CFIndex CFGetRetainCount(CFTypeRef cf);
CFTypeID CFGetTypeID(CFTypeRef cf);
CFHashCode CFHash(CFTypeRef cf);
CFTypeRef CFMakeCollectable(CFTypeRef cf);
void CFRelease(CFTypeRef cf);
CFTypeRef CFRetain(CFTypeRef cf);
void CFShow(CFTypeRef obj);

#endif

#endif

// EOF
