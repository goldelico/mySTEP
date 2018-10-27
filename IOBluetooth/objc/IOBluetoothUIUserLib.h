//
//  IOBluetoothUIUserLib.h
//  IOBluetooth
//
//  Created by H. Nikolaus Schaller on 30.10.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

// #import <IOBluetooth/IOBluetoothUserLib.h>
#import <IOBluetoothUI/objc/IOBluetoothDeviceSelectorController.h>
#import <IOBluetoothUI/objc/IOBluetoothObjectPushUIController.h>
#import <IOBluetoothUI/objc/IOBluetoothPairingController.h>
#import <IOBluetoothUI/objc/IOBluetoothServiceBrowserController.h>

typedef uint32_t IOBluetoothServiceBrowserControllerOptions;

enum {
	kIOBluetoothServiceBrowserControllerOptionsNone					= 0L,
	kIOBluetoothServiceBrowserControllerOptionsAutoStartInquiry		= (1L << 0),
	kIOBluetoothServiceBrowserControllerOptionsDisconnectWhenDone	= (1L << 1),
};
