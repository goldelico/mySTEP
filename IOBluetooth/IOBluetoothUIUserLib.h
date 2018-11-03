//
//  IOBluetoothUIUserLib.h
//  IOBluetooth
//
//  Created by H. Nikolaus Schaller on 30.10.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <IOBluetooth/IOBluetooth.h>

typedef enum _IOBluetoothServiceBrowserControllerOptions {
	kIOBluetoothServiceBrowserControllerOptionsNone = 0L,
	kIOBluetoothServiceBrowserControllerOptionsAutoStartInquiry = ( 1L << 0 ),
	kIOBluetoothServiceBrowserControllerOptionsDisconnectWhenDone = ( 1L << 1 )
} IOBluetoothServiceBrowserControllerOptions;


// struct ?

@class IOBluetoothDeviceSearchDeviceAttributes;
typedef NSUInteger IOBluetoothDeviceSearchOptions;

@interface IOBluetoothDeviceSearchAttributes : NSObject
{
	IOBluetoothDeviceSearchDeviceAttributes *attributeList;
	IOItemCount deviceAttributeCount;
	IOItemCount maxResults;
	IOBluetoothDeviceSearchOptions options;
}
@end
