//
//  IOBluetoothSDPUUID.h
//  IOBluetooth
//
//  Created by H. Nikolaus Schaller on 30.10.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOBluetooth/BluetoothAssignedNumbers.h>


@class IOBluetoothSDPUUID;

typedef IOBluetoothSDPUUID *IOBluetoothSDPUUIDRef;

@interface IOBluetoothSDPUUID : NSData

/* already defined by NSData:

- (const void *) bytes; 
- (id) initWithBytes:(const void *) bytes length:(unsigned) length; 
- (id) initWithData:(NSData *) data; 
- (BOOL) isEqualToData:(NSData *) other; 
- (unsigned) length; 

*/

- (IOBluetoothSDPUUIDRef) getSDPUUIDRef; 
- (IOBluetoothSDPUUID *) getUUIDWithLength:(unsigned) len; 
- (id) initWithUUID16:(BluetoothSDPUUID16) uuid16; 
- (id) initWithUUID32:(BluetoothSDPUUID32) uuid32; 
- (BOOL) isEqualToUUID:(IOBluetoothSDPUUID *) other; 

+ (IOBluetoothSDPUUID *) uuid16:(BluetoothSDPUUID16) uuid16; 
+ (IOBluetoothSDPUUID *) uuid32:(BluetoothSDPUUID32) uuid32; 
+ (IOBluetoothSDPUUID *) uuidWithBytes:(const void *) bytes length:(unsigned) length; 
+ (IOBluetoothSDPUUID *) uuidWithData:(NSData *) data; 
+ (IOBluetoothSDPUUID *) withSDPUUIDRef:(IOBluetoothSDPUUIDRef) sdpUUIDRef; 

@end
