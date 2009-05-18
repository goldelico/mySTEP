//
//  IOBluetoothRFCOMMChannel.h
//  IOBluetooth
//
//  Created by H. Nikolaus Schaller on 30.10.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOBluetooth/BluetoothAssignedNumbers.h>
#import <IOBluetooth/objc/IOBluetoothObject.h>
#import <IOBluetooth/objc/IOBluetoothDevice.h>
#import <IOBluetooth/objc/IOBluetoothUserNotification.h>

typedef int BluetoothRFCOMMMTU;
typedef int IOBluetoothObjectID;
typedef int IOBluetoothRFCOMMChannelRef;

typedef enum
		{
			kIOBluetoothUserNotificationChannelDirectionAny
		} IOBluetoothUserNotificationChannelDirection;

typedef int BluetoothRFCOMMLineStatus;
typedef int BluetoothRFCOMMParityType;

@interface IOBluetoothRFCOMMChannel : IOBluetoothObject
{
	BluetoothRFCOMMChannelID _getChannelID;
	IOBluetoothDevice *_getDevice;
	BluetoothRFCOMMMTU _getMTU;
	IOBluetoothObjectID _getObjectID;
	IOBluetoothRFCOMMChannelRef _getRFCOMMChannelRef;
	BOOL _isIncoming;
	BOOL _isOpen;
	BOOL _isTransmissionPaused;
}

+ (IOBluetoothUserNotification *) registerForChannelOpenNotifications:(id) object selector:(SEL) sel; 
+ (IOBluetoothUserNotification *) registerForChannelOpenNotifications:(id) object selector:(SEL) sel withChannelID:(BluetoothRFCOMMChannelID) channel direction:(IOBluetoothUserNotificationChannelDirection) direction; 
+ (IOBluetoothRFCOMMChannel *) withObjectID:(IOBluetoothObjectID) object; 
+ (IOBluetoothRFCOMMChannel *) withRFCOMMChannelRef:(IOBluetoothRFCOMMChannelRef) channel; 

- (BluetoothRFCOMMChannelID) getChannelID;
- (IOBluetoothDevice *) getDevice;
- (BluetoothRFCOMMMTU) getMTU;
- (IOBluetoothObjectID) getObjectID;
- (IOBluetoothRFCOMMChannelRef) getRFCOMMChannelRef;
- (BOOL) isIncoming;
- (BOOL) isOpen;
- (BOOL) isTransmissionPaused;
- (IOBluetoothUserNotification *) registerForChannelCloseNotification:(id) observer selector:(SEL) sel; 
#if 0
- (IOReturn) registerIncomingDataListener:(IOBluetoothRFCOMMChannelIncomingDataListener) listener refCon:(void *) ref; 
- (IOReturn) registerIncomingDataListener:(IOBluetoothRFCOMMChannelIncomingDataListener) listener refCon:(void *) ref; 
- (IOReturn) registerIncomingEventListener:(IOBluetoothRFCOMMChannelIncomingEventListener) listener;
- (IOReturn) registerIncomingEventListener:(IOBluetoothRFCOMMChannelIncomingEventListener) listener refCon:(void *) ref; 
#endif
- (IOReturn) sendRemoteLineStatus:(BluetoothRFCOMMLineStatus) status; 
- (IOReturn) setDelegate:(id) delegate; 
- (IOReturn) setSerialParameters:(UInt32) speed dataBits:(UInt8) bits parity:(BluetoothRFCOMMParityType) parity stopBits:(UInt8) stops; 
- (IOReturn) write:(void *) data length:(UInt16) length sleep:(BOOL) sleep; 
- (IOReturn) writeAsync:(void *) data length:(UInt16) length refcon:(void *) ref; 
- (IOReturn) writeSimple:(void *) data length:(UInt16) length sleep:(BOOL) sleep bytesSent:(UInt32 *) sent;
- (IOReturn) writeSync:(void *) data length:(UInt16) length; 
- (IOReturn) writeSync:(void *) data length:(UInt16) length;

@end
