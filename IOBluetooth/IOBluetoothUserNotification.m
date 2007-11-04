//
//  IOBluetoothUserNotification.m
//  IOBluetooth
//
//  Created by H. Nikolaus Schaller on 30.10.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "IOBluetoothUserNotification.h"


@implementation IOBluetoothUserNotification

- (void) unregister;
{
	[[NSNotificationCenter defaultCenter] removeObserver:_observer name:_notification object:_object];
}

- (id) _initWithUserNotification:(NSString *) notif observer:(id) observer selector:(SEL) sel object:(id) object;
{
	if((self=[super init]))
		{
		[[NSNotificationCenter defaultCenter] addObserver:observer selector:sel name:notif object:object];
		_observer=[observer retain];
		_notification=[notif retain];
		_object=[object retain];
		}
	return self;
}

+ (IOBluetoothUserNotification *) _bluetoothUserNotification:(NSString *) notif observer:(id) observer selector:(SEL) sel object:(id) object;
{
	return [[[self alloc] _initWithUserNotification:notif observer:observer selector:sel object:object] autorelease];
}

- (void) dealloc;
{
	[_observer release];
	[_notification release];
	[_object release];
	[super dealloc];
}


- (void) _notify;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:_notification object:_object];
}

@end
