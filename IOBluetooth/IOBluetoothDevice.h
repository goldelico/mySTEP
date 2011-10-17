//
//  IOBluetoothDevice.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Fri Jun 30 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOBluetooth/BluetoothAssignedNumbers.h>
#import <IOBluetooth/objc/IOBluetoothObject.h>

@class IOBluetoothDevice;
@class IOBluetoothUserNotification;
@class IOBluetoothSDPServiceRecord;
@class IOBluetoothSDPUUID;
@class IOBluetoothL2CAPChannel;
@class IOBluetoothRFCOMMChannel;

typedef IOBluetoothDevice *IOBluetoothDeviceRef;

@interface IOBluetoothDevice : IOBluetoothObject
{
	NSDate *_lastInquiryUpdate;
	NSDate *_lastNameUpdate;
	NSString *_name;
	BluetoothDeviceAddress _addr;
	BluetoothClassOfDevice _classOfDevice;
	BluetoothClockOffset _clockOffset;
}

+ (NSArray *) favoriteDevices; 
+ (NSArray *) pairedDevices; 
+ (NSArray *) recentDevices:(UInt32) limit; 
+ (IOBluetoothUserNotification *) registerForConnectNotifications:(id) observer selector:(SEL) sel; 
+ (IOBluetoothDevice *) withAddress:(const BluetoothDeviceAddress *) address; 
+ (IOBluetoothDevice *) withDeviceRef:(IOBluetoothDeviceRef) ref; 

- (IOReturn) addToFavorites; 
- (IOReturn) closeConnection; 
- (const BluetoothDeviceAddress *) getAddress; 
- (NSString *) getAddressString; 
- (BluetoothClassOfDevice) getClassOfDevice; 
- (BluetoothClockOffset) getClockOffset; 
- (BluetoothConnectionHandle) getConnectionHandle; 
- (BluetoothDeviceClassMajor) getDeviceClassMajor; 
- (BluetoothDeviceClassMinor) getDeviceClassMinor; 
- (IOBluetoothDeviceRef) getDeviceRef; 
- (BluetoothHCIEncryptionMode) getEncryptionMode; 
- (NSDate *) getLastInquiryUpdate; 
- (NSDate *) getLastNameUpdate; 
- (NSDate *) getLastServicesUpdate; 
- (BluetoothLinkType) getLinkType; 
- (NSString *) getName; 
- (NSString *) getNameOrAddress; 
- (BluetoothPageScanMode) getPageScanMode; 
- (BluetoothPageScanPeriodMode) getPageScanPeriodMode; 
- (BluetoothPageScanRepetitionMode) getPageScanRepetitionMode; 
- (BluetoothServiceClassMajor) getServiceClassMajor; 
- (IOBluetoothSDPServiceRecord *) getServiceRecordForUUID:(IOBluetoothSDPUUID *) sdpUUID; 
- (NSArray *) getServices; 
- (BOOL) isConnected; 
- (BOOL) isEqual:(id) other; 
- (BOOL) isFavorite; 
- (BOOL) isIncoming; 
- (BOOL) isPaired; 
- (IOReturn) openConnection; 
- (IOReturn) openConnection:(id) target; 
- (IOReturn) openConnection:(id) target
			withPageTimeout:(BluetoothHCIPageTimeout) timeout 
			authenticationRequired:(BOOL) auth; 
- (IOReturn) openL2CAPChannel:(BluetoothL2CAPPSM) psm 
				 findExisting:(BOOL) flag
				   newChannel:(IOBluetoothL2CAPChannel **) channel; 
- (IOReturn) openL2CAPChannelAsync:(IOBluetoothL2CAPChannel **) channel 
						   withPSM:(BluetoothL2CAPPSM) psm
						  delegate:(id) delegate;
- (IOReturn) openL2CAPChannelSync:(IOBluetoothL2CAPChannel **) channel 
						  withPSM:(BluetoothL2CAPPSM) psm
						 delegate:(id) delegate; 
- (IOReturn) openRFCOMMChannel:(BluetoothRFCOMMChannelID) ident 
					   channel:(IOBluetoothRFCOMMChannel **) channel; 
- (IOReturn) openRFCOMMChannelAsync:(IOBluetoothRFCOMMChannel **) channel 
					  withChannelID:(BluetoothRFCOMMChannelID) ident
						   delegate:(id) delegate; 
- (IOReturn) openRFCOMMChannelSync:(IOBluetoothRFCOMMChannel **) channel 
					 withChannelID:(BluetoothRFCOMMChannelID) ident
						  delegate:(id) delegate; 
- (IOReturn) performSDPQuery:(id) target; 
- (NSDate *) recentAccessDate; 
- (IOBluetoothUserNotification *) registerForDisconnectNotification:(id) observer selector:(SEL) sel; 
- (IOReturn) remoteNameRequest:(id) target; 
- (IOReturn) remoteNameRequest:(id) target withPageTimeout:(BluetoothHCIPageTimeout) timeout; 
- (IOReturn) removeFromFavorites; 
- (IOReturn) requestAuthentication; 
- (IOReturn) sendL2CAPEchoRequest:(void *) data length:(UInt16) length; 

// private

- (id) _initWithAddress:(const BluetoothDeviceAddress *) address;
- (id) _initWithDeviceRef:(IOBluetoothDeviceRef) ref;
- (void) _setName:(NSString *) name;
- (void) _setClockOffset:(BluetoothClockOffset) offset;
- (void) _setClassOfDevice:(BluetoothClassOfDevice) class;

@end

@interface NSObject (IOBluetoothDevice)

- (void) remoteNameRequestComplete:(IOBluetoothDevice *) dev status:(int) status name:(NSString *) name;

@end

