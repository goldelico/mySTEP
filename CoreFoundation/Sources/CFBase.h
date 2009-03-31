//
//  CFBase.h
//  CoreFoundation
//
//  Created by H. Nikolaus Schaller on 03.10.08.
//  Copyright 2008 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//
//  Note:
//  * we have a completely different architecture - our CF.framework is built on Foundation.framework
//  * if you simply #import <Foundation/Foundation.h> you don't have to care about it and can mix both
//

#ifndef _mySTEP_H_CFBase
#define _mySTEP_H_CFBase

#include <stdio.h>

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

@class NSObject;
typedef NSObject *CFTypeRef;
// should be typedef const void * CFTypeRef;

@class NSString;
typedef NSString *CFStringRef;

typedef UInt32 CFHashCode;
typedef UInt32 CFTypeID;

typedef CFAllocatorRef;
typedef CFIndex;

inline CFStringRef CFCopyDescription(CFTypeRef cf) { return [cf description]; }
inline CFStringRef CFCopyTypeIDDescription(CFTypeID type_id);
inline Boolean CFEqual(CFTypeRef cf1, CFTypeRef cf2) { return [cf1 isEqual:cf2]; }

inline CFAllocatorRef CFGetAllocator(CFTypeRef cf) { }
inline CFIndex CFGetRetainCount(CFTypeRef cf) { return [cf retainCount]; }
CFTypeID CFGetTypeID(CFTypeRef cf) { }
inline CFHashCode CFHash(CFTypeRef cf) { return [cf hash]; }
inline CFTypeRef CFMakeCollectable(CFTypeRef cf) { }
inline void CFRelease(CFTypeRef cf) { [cf release]; }
inline CFTypeRef CFRetain(CFTypeRef cf) { return [cf retain]; }
inline void CFShow(CFTypeRef obj) { fprintf(stderr, "%s", [obj cString]); }

#endif

// EOF
