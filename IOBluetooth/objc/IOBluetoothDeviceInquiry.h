//
//  IOBluetoothDeviceInquiry.h
//  IOBluetooth
//
//  Created by H. Nikolaus Schaller on 30.10.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOBluetooth/BluetoothAssignedNumbers.h>

@class IOBluetoothDevice;

@interface IOBluetoothDeviceInquiry : NSObject
{
	NSMutableArray *_devices;
	id _delegate;
	uint8_t _timeout;	// in seconds up to 255
	BOOL _bluetoothAvailable;
	BOOL _updateNewDeviceNames;
	BOOL _aborted;
}

+ (IOBluetoothDeviceInquiry *) inquiryWithDelegate:(id) delegate;

- (void) clearFoundDevices;
- (id) delegate;
- (NSArray *) foundDevices;
- (id) initWithDelegate:(id) delegate;
- (uint8_t) inquiryLength;
- (void) setDelegate:(id) delegate;
- (uint8_t) setInquiryLength:(uint8_t) seconds;
- (void) setSearchCriteria:(BluetoothServiceClassMajor) scmaj
		  majorDeviceClass:(BluetoothDeviceClassMajor) dcmaj
		  minorDeviceClass:(BluetoothDeviceClassMinor) dcmin;
- (void) setUpdateNewDeviceNames:(BOOL) flag;
- (IOReturn) start;
- (IOReturn) stop;
- (BOOL) updateNewDeviceNames;

@end

@interface NSObject (IOBluetoothDeviceInquiryDelegate)

- (void) deviceInquiryComplete:(IOBluetoothDeviceInquiry *) sender
						 error:(IOReturn) error
					   aborted:(BOOL) aborted;
- (void) deviceInquiryDeviceFound:(IOBluetoothDeviceInquiry *) sender
						   device:(IOBluetoothDevice *) device;
- (void) deviceInquiryDeviceNameUpdated:(IOBluetoothDeviceInquiry *) sender
								 device:(IOBluetoothDevice *) device
					   devicesRemaining:(int) remaining;
- (void) deviceInquiryStarted:(IOBluetoothDeviceInquiry *) sender;
- (void) deviceInquiryUpdatingDeviceNamesStarted:(IOBluetoothDeviceInquiry *) sender
								devicesRemaining:(int) remaining;

@end

