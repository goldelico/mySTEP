//
//  CoreFoundation.h
//
//  Created by H. Nikolaus Schaller on 03.10.08.
//  Copyright 2008 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#ifndef _mySTEP_H_CoreFoundation
#define _mySTEP_H_CoreFoundation

#ifdef __linux__

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
typedef UInt32 IOItemCount;

#define kIOReturnSuccess 0
#define kIOReturnError 1

#endif

#import <CoreFoundation/CFBase.h>
#import <CoreFoundation/CFString.h>

#endif /* _mySTEP_H_CoreFoundation */
