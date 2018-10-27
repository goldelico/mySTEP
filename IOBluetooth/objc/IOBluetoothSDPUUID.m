//
//  IOBluetoothSDPUUID.m
//  IOBluetooth
//
//  Created by H. Nikolaus Schaller on 30.10.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <IOBluetooth/objc/IOBluetoothSDPUUID.h>


@implementation IOBluetoothSDPUUID

- (IOBluetoothSDPUUIDRef) getSDPUUIDRef;
{
	return NIMP;
}

- (IOBluetoothSDPUUID *) getUUIDWithLength:(unsigned) len;
{
	if(len == [self length])
		return self;
	if(len > [self length])
		; // pad;
	return nil;
}

- (id) initWithUUID16:(BluetoothSDPUUID16) uuid16;
{
	return [self initWithBytes:&uuid16 length:sizeof(uuid16)];
}

- (id) initWithUUID32:(BluetoothSDPUUID32) uuid32; 
{
	return [self initWithBytes:&uuid32 length:sizeof(uuid32)];
}

- (BOOL) isEqualToUUID:(IOBluetoothSDPUUID *) other;
{
	return [self isEqualToData:other];
}

+ (IOBluetoothSDPUUID *) uuid16:(BluetoothSDPUUID16) uuid16; { return [[[self alloc] initWithUUID16:uuid16] autorelease]; }
+ (IOBluetoothSDPUUID *) uuid32:(BluetoothSDPUUID32) uuid32;  { return [[[self alloc] initWithUUID32:uuid32] autorelease]; }

+ (IOBluetoothSDPUUID *) uuidWithBytes:(const void *) bytes length:(unsigned) length;
{
	// check for valid length
	return [[[self alloc] initWithBytes:bytes length:length] autorelease];
}

+ (IOBluetoothSDPUUID *) uuidWithData:(NSData *) data; 
{
	// check for valid length
	return [[[self alloc] initWithData:data] autorelease];
}

+ (IOBluetoothSDPUUID *) withSDPUUIDRef:(IOBluetoothSDPUUIDRef) sdpUUIDRef; 
{
	return NIMP;
}

@end
