//
//  BluetoothAssignedNumbers.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Fri Jun 30 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

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
