//
//  BluetoothAssignedNumbers.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Fri Jun 30 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

#import <Foundation/Foundation.h>

// FIXME: not sure if this all should really be declared here or somewhere else

#ifdef __mySTEP__

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

#ifndef NIMP
#define NIMP ([NSException raise:@"Not implemented" format:@"method %@ not implemented in %@", NSStringFromSelector(_cmd), NSStringFromClass([self class])], (void *) 0)
#endif

typedef struct _BluetoothDeviceAddress { unsigned char addr[6]; } BluetoothDeviceAddress;

typedef NSTimeInterval BluetoothClockOffset;
typedef NSTimeInterval BluetoothHCIPageTimeout;

typedef id BluetoothConnectionHandle;

// FIXME: should probably be enums...

typedef long BluetoothClassOfDevice;

/*
 e.g.
 kBluetoothServiceClassMajorAny
 kBluetoothDeviceClassMajorPeripheral
 kBluetoothDeviceClassMinorPeripheral1Keyboard
 */

typedef char BluetoothDeviceClassMajor;
typedef short BluetoothDeviceClassMinor;
typedef int BluetoothServiceClassMajor;		// bitmask

typedef int BluetoothHCIEncryptionMode; 
typedef int BluetoothLinkType;
typedef int BluetoothPageScanMode; 
typedef int BluetoothPageScanPeriodMode; 
typedef int BluetoothPageScanRepetitionMode; 

typedef int BluetoothL2CAPPSM;
typedef int BluetoothRFCOMMChannelID;

typedef uint16_t BluetoothSDPUUID16;
typedef uint32_t BluetoothSDPUUID32;
