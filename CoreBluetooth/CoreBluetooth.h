//
//  CoreBluetooth.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Fri Jun 2 2019.
//  Copyright (c) 2019 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

// some primitive definitions to get an app compile (but not link or run) without errors and warnings

#import <Foundation/Foundation.h>

typedef enum
{
	CBPeripheralManagerStatePoweredOff,
	CBPeripheralManagerStatePoweredOn,
	CBPeripheralManagerStateUnauthorized,
	CBPeripheralManagerStateUnknown,
	CBPeripheralManagerStateUnsupported
} CBPeripheralManagerState;

enum
{
	CBCharacteristicPropertyRead=1<<0,
	CBCharacteristicPropertyIndicate=1<<1,
	CBCharacteristicPropertyWriteWithoutResponse=1<<2,
	CBAttributePermissionsReadable=1<<4,
	CBAttributePermissionsWriteable=1<<8,
};

#define CBAdvertisementDataLocalNameKey @"CBAdvertisementDataLocalNameKey"
#define CBAdvertisementDataServiceUUIDsKey @"CBAdvertisementDataServiceUUIDsKey"

#define CBATTErrorSuccess 1

@protocol CBPeripheralManagerDelegate
@end

@interface CBUUID : NSObject
+ (CBUUID*) UUIDWithString:(NSString *) uuid;
@end

@interface CBCharacteristic : NSObject
- (id) initWithType:(CBUUID *) properties:(int) props value:(id) value permissions:(int) permissions;
- (CBUUID *) UUID;
@end

@interface CBMutableCharacteristic : CBCharacteristic
@end

@interface CBService : NSObject
@end

@interface CBMutableService : CBService
- (id) initWithType:(CBUUID *) uuid primary:(BOOL) flag;
- (void) setCharacteristics:(CBCharacteristic *) characteristic;
@end

@interface CBCentral : NSObject
@end

@interface CBATTRequest : NSObject
- (CBCharacteristic *) characteristic;
- (CBCentral *) central;
- (id) value;
- (void) setValue:(id) value;
@end

@interface CBPeripheralManager : NSObject
- (id) initWithDelegate:(id <CBPeripheralManagerDelegate>) delegate queue:(id) queue;
- (CBPeripheralManagerState) state;
- (BOOL) isAdvertising;
- (void) startAdvertising:(BOOL) flag;
- (void) addService:(CBMutableService *) service;
- (void) respondToRequest:(CBATTRequest *) request withResult:(int) success;
@end



