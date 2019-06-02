//
//  CoreBluetooth.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Fri Jun 2 2019.
//  Copyright (c) 2019 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>

@implementation CBUUID
+ (CBUUID*) UUIDWithString:(NSString *) uuid;
{

}
@end

@implementation CBCharacteristic
- (id) initWithType:(CBUUID *) properties:(int) props value:(id) value permissions:(int) permissions;
{

}
- (CBUUID *) UUID;
{

}
@end

@implementation CBMutableCharacteristic
@end

@implementation CBService
@end

@implementation CBMutableService
- (id) initWithType:(CBUUID *) uuid primary:(BOOL) flag;
{

}
- (void) setCharacteristics:(CBCharacteristic *) characteristic;
{

}
@end

@implementation CBCentral
@end

@implementation CBATTRequest
- (CBCharacteristic *) characteristic;
{

}
- (CBCentral *) central;
{

}
- (id) value;
{

}
- (void) setValue:(id) value;
{

}
@end

@implementation CBPeripheralManager
- (id) initWithDelegate:(id <CBPeripheralManagerDelegate>) delegate queue:(id) queue;
{

}
- (CBPeripheralManagerState) state;
{

}
- (BOOL) isAdvertising;
{

}
- (void) startAdvertising:(BOOL) flag;
{

}
- (void) addService:(CBMutableService *) service;
{

}
- (void) respondToRequest:(CBATTRequest *) request withResult:(int) success;
{

}
@end



