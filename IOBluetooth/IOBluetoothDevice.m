//
//  IOBluetoothDevice.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Fri Jun 30 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

#import <IOBluetooth/objc/IOBluetoothDevice.h>
#import <IOBluetooth/objc/IOBluetoothDeviceInquiry.h>
#import <IOBluetooth/objc/IOBluetoothUserNotification.h>
#import <IOBluetooth/objc/IOBluetoothSDPServiceRecord.h>
#import <IOBluetooth/objc/IOBluetoothSDPUUID.h>

static NSMutableArray *_favorites;
static NSMutableArray *_paired;

@implementation IOBluetoothDevice

+ (void) initialize
{
	// read favourite addresses from user defaults
}

+ (NSArray *) favoriteDevices;
{
	return _favorites;
}

+ (NSArray *) pairedDevices;
{
	return _paired;
}

+ (NSArray *) recentDevices:(UInt32) limit;
{
	return NIMP;
}

+ (IOBluetoothUserNotification *) registerForConnectNotifications:(id) observer selector:(SEL) sel; { return NIMP; }

+ (IOBluetoothDevice *) withAddress:(const BluetoothDeviceAddress *) address; { return [[[self alloc] _initWithAddress:address] autorelease]; }
+ (IOBluetoothDevice *) withDeviceRef:(IOBluetoothDeviceRef) ref; { return [[[self alloc] _initWithDeviceRef:ref] autorelease]; }

- (IOReturn) addToFavorites;
{
	[_favorites addObject:self];
	// store addresses in user defaults
	return kIOReturnSuccess;
}

- (IOReturn) closeConnection;
{
	/* use "hcitool dc <bdaddr>" */
	NIMP; return 0;
}

- (const BluetoothDeviceAddress *) getAddress; { return &_addr; }

- (NSString *) getAddressString; 
{
	return [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x", _addr.addr[0], _addr.addr[1], _addr.addr[2], _addr.addr[3], _addr.addr[4], _addr.addr[5]];
}

- (BluetoothClassOfDevice) getClassOfDevice; { NIMP; return 0; }
- (BluetoothClockOffset) getClockOffset; { NIMP; return 0; }
- (BluetoothConnectionHandle) getConnectionHandle; { NIMP; return nil; }
- (BluetoothDeviceClassMajor) getDeviceClassMajor; { NIMP; return 0; }
- (BluetoothDeviceClassMinor) getDeviceClassMinor; { NIMP; return 0; }
- (IOBluetoothDeviceRef) getDeviceRef; { return NIMP; }
- (BluetoothHCIEncryptionMode) getEncryptionMode; { NIMP; return 0; }
- (NSDate *) getLastInquiryUpdate; { return NIMP; }
- (NSDate *) getLastNameUpdate; { return NIMP; }
- (NSDate *) getLastServicesUpdate; { return NIMP; }
- (BluetoothLinkType) getLinkType; { NIMP; return 0; }
- (NSString *) getName; { return _name; }
- (NSString *) getNameOrAddress; { return _name?_name:[self getAddressString]; }
- (BluetoothPageScanMode) getPageScanMode; { NIMP; return 0; }
- (BluetoothPageScanPeriodMode) getPageScanPeriodMode; { NIMP; return 0; }
- (BluetoothPageScanRepetitionMode) getPageScanRepetitionMode; { NIMP; return 0; }
- (BluetoothServiceClassMajor) getServiceClassMajor; { NIMP; return 0; }
- (IOBluetoothSDPServiceRecord *) getServiceRecordForUUID:(IOBluetoothSDPUUID *) sdpUUID; { return NIMP; }
- (NSArray *) getServices; { return NIMP; }
- (BOOL) isConnected; { return NO; }
- (BOOL) isEqual:(id) other; { NIMP; return NO; }
- (BOOL) isFavorite; { return [_favorites containsObject:self]; }
- (BOOL) isIncoming; { return NO; }
- (BOOL) isPaired; { return NO; }
- (IOReturn) openConnection; { return [self openConnection:nil]; }
- (IOReturn) openConnection:(id) target; { return [self openConnection:target withPageTimeout:10 authenticationRequired:NO]; }

- (IOReturn) openConnection:(id) target
			withPageTimeout:(BluetoothHCIPageTimeout) timeout 
	 authenticationRequired:(BOOL) auth;
{
	/* use "hcitool cc" e.g.
		Usage:
			cc [--role=m|s] [--ptype=pkt_types] <bdaddr>
		Example:
			cc --ptype=dm1,dh3,dh5 01:02:03:04:05:06
			cc --role=m 01:02:03:04:05:06
	*/
	NIMP;
	return 0;
}

- (IOReturn) openL2CAPChannel:(BluetoothL2CAPPSM) psm 
				 findExisting:(BOOL) flag
				   newChannel:(IOBluetoothL2CAPChannel **) channel; { NIMP; return 0; }
- (IOReturn) openL2CAPChannelAsync:(IOBluetoothL2CAPChannel **) channel 
						   withPSM:(BluetoothL2CAPPSM) psm
						  delegate:(id) delegate; { NIMP; return 0; }
- (IOReturn) openL2CAPChannelSync:(IOBluetoothL2CAPChannel **) channel 
						  withPSM:(BluetoothL2CAPPSM) psm
						 delegate:(id) delegate; { NIMP; return 0; } 
- (IOReturn) openRFCOMMChannel:(BluetoothRFCOMMChannelID) ident 
					   channel:(IOBluetoothRFCOMMChannel **) channel; { NIMP; return 0; }
- (IOReturn) openRFCOMMChannelAsync:(IOBluetoothRFCOMMChannel **) channel 
					  withChannelID:(BluetoothRFCOMMChannelID) ident
						   delegate:(id) delegate; { NIMP; return 0; } 
- (IOReturn) openRFCOMMChannelSync:(IOBluetoothRFCOMMChannel **) channel 
					 withChannelID:(BluetoothRFCOMMChannelID) ident
						  delegate:(id) delegate; { NIMP; return 0; }

- (IOReturn) performSDPQuery:(id) target; { NIMP; return 0; }
- (NSDate *) recentAccessDate; { return NIMP; } 

- (IOBluetoothUserNotification *) registerForDisconnectNotification:(id) observer selector:(SEL) sel;
{
	return [IOBluetoothUserNotification _bluetoothUserNotification:@"Disconnect" observer:(id) observer selector:(SEL) sel object:self];
}

- (IOReturn) remoteNameRequest:(id) target; { return [self remoteNameRequest:target withPageTimeout:10]; }

- (void) _remoteNameRequestDone:(NSNotification *) notif;
{
	int status=[[notif object] terminationStatus];
	NSData *result=[[[[notif object] standardOutput] fileHandleForReading] readDataToEndOfFile];
#if 1
	NSLog(@"_remoteNameRequestDone is done status=%d", status);
	NSLog(@"result=%@", result);
#endif
	// [self _setName:name];
	// [target - (void) remoteNameRequestComplete:self status:(int) status name:(NSString *) name;
}
	
- (IOReturn) remoteNameRequest:(id) target withPageTimeout:(BluetoothHCIPageTimeout) timeout;
{
	// FIXME: pass target through to _remoteNameRequestDone:
	NSTask *task=[IOBluetoothDeviceInquiry _hcitool:[NSArray arrayWithObjects:@"scan", nil] handler:self done:@selector(_remoteNameRequestDone:)];
	if(!task)
		return kIOReturnError;	// could not launch
	if(!target)
		{ // wait for completion
		[task waitUntilExit];
		if([task terminationStatus] != 0)
			return kIOReturnError;	// some error
		}
	return kIOReturnSuccess;
}

- (IOReturn) removeFromFavorites;
{
	[_favorites removeObject:self];
	// store addresses in user defaults
	return kIOReturnSuccess;
}

- (IOReturn) requestAuthentication;
{
	// "hcitool auth"
	NIMP; return 0;
}

- (IOReturn) sendL2CAPEchoRequest:(void *) data length:(UInt16) length; { NIMP; return 0; }

- (id) _initWithAddress:(const BluetoothDeviceAddress *) address;
{
	if((self=[super init]))
		{
		_addr=*address;
		}
	return self;
}

- (id) _initWithDeviceRef:(IOBluetoothDeviceRef) ref;
{
	if((self=[self _initWithAddress:[ref getAddress]]))
		{
		[self _setName:[ref getName]];
		}
	return self;
}

- (void) _setName:(NSString *) name;
{
	[_name autorelease];
	_name=[name retain];
}

- (void) dealloc;
{
	[_name release];
	[super dealloc];
}

@end

