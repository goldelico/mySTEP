//
//  IOBluetoothUserNotification.h
//  IOBluetooth
//
//  Created by H. Nikolaus Schaller on 30.10.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOBluetooth/BluetoothAssignedNumbers.h>


@interface IOBluetoothUserNotification : NSObject
{
	NSString *_notification;
	id _observer;
	id _object;
}

- (void) unregister;

+ (IOBluetoothUserNotification *) _bluetoothUserNotification:(NSString *) notif observer:(id) observer selector:(SEL) sel object:(id) object;
- (void) _notify;

@end
