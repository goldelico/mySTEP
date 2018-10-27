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
#import "../BluetoothPrivate.h"

static NSMutableArray *_paired;

#define DEFAULTS	@"com.apple.Bluetooth"	// compatibility

@interface _IOBluetoothDeviceNameRequestHandler : NSObject
{
	IOBluetoothDevice *_dev;
	id _target;
}
- (id) initWithDevice:(IOBluetoothDevice *) dev andTarget:(id) target;
- (void) remoteNameRequestDone:(NSNotification *) notif;
@end

@implementation _IOBluetoothDeviceNameRequestHandler

- (id) initWithDevice:(IOBluetoothDevice *) dev andTarget:(id) target;
{
	if((self=[super init]))
		{
		_dev=[dev retain];
		_target=[target retain];
		}
	return self;
}

- (void) dealloc;
{
	[_dev release];
	[_target release];
	[super dealloc];
}

- (void) remoteNameRequestDone:(NSNotification *) notif;
{
	NSTask *task=[notif object];
#if 0
	NSLog(@"remoteNameRequestDone %p notif=%@", self, notif);
	NSLog(@"remoteNameRequestDone task %@ %p %u", task, task, [task retainCount]);
	{
#endif
	int status=[task terminationStatus];
	NSData *result=[[[task standardOutput] fileHandleForReading] readDataToEndOfFile];
	NSString *name=[[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];	// contains a terminating \n
	int len=[name length];
	if(len > 0)
		{
		name=[name substringToIndex:len-1];
#if 0
		NSLog(@"_remoteNameRequestDone is done status=%d", status);
		NSLog(@"result=%@", result);
		NSLog(@"name=%@", name);
#endif
		[_dev _setName:name];
		[_target remoteNameRequestComplete:_dev status:status name:name];
		}
	[[NSNotificationCenter defaultCenter] removeObserver:self];
#if 0
	NSLog(@"remoteNameRequestDone releasing task %@ %p %u", task, task, [task retainCount]);
#endif
	[task release];	// was retained when created
	[self release];	// we can be released now...
#if 0
	}
	NSLog(@"remoteNameRequestDone %p", self);
#endif
}

@end

@implementation IOBluetoothDevice

+ (void) initialize
{
	_paired=[[NSMutableArray alloc] initWithCapacity:10];
}

+ (NSArray *) favoriteDevices;
{
	NSEnumerator *e=[[[[NSUserDefaults standardUserDefaults] persistentDomainForName:DEFAULTS] objectForKey:@"FavoriteDevices"] objectEnumerator];
	NSString *addr;
	NSMutableArray *result=[NSMutableArray arrayWithCapacity:10];
	while((addr=[e nextObject]))
		{
		BluetoothDeviceAddress *addr;
		// translate addr string into BluetoothDeviceAddress descriptor
		[result addObject:[self withAddress:addr]];
		}
	return result;
}

+ (NSArray *) pairedDevices;
{
	return _paired;
}

+ (NSArray *) recentDevices:(UInt32) limit;
{
	NSDictionary *recents=[[[NSUserDefaults standardUserDefaults] persistentDomainForName:DEFAULTS] objectForKey:@"RecentDevices"];
	NSEnumerator *e=[recents keyEnumerator];
	NSString *addr;
	NSMutableArray *result=[NSMutableArray arrayWithCapacity:10];
	// sort keys by object value (NSDate) descending
	while(limit-- > 0 && (addr=[e nextObject]))
		{ // copy first limit records to result
		BluetoothDeviceAddress *addr;
		// translate addr string into BluetoothDeviceAddress descriptor
		[result addObject:[self withAddress:addr]];
		}
	return result;
}

+ (IOBluetoothUserNotification *) registerForConnectNotifications:(id) observer selector:(SEL) sel; { return NIMP; }

+ (IOBluetoothDevice *) withAddress:(const BluetoothDeviceAddress *) address; { return [[[self alloc] _initWithAddress:address] autorelease]; }
+ (IOBluetoothDevice *) withDeviceRef:(IOBluetoothDeviceRef) ref; { return [[[self alloc] _initWithDeviceRef:ref] autorelease]; }

- (IOReturn) addToFavorites;
{
	NSUserDefaults *ud=[NSUserDefaults standardUserDefaults];
	NSMutableDictionary *dom=[[[ud persistentDomainForName:DEFAULTS] mutableCopy] autorelease];
	NSString *addr=[self getAddressString];
	NSArray *favs;
	if(!dom) dom=[NSMutableDictionary dictionaryWithCapacity:1];
	favs=[dom objectForKey:@"FavoriteDevices"];
	if([favs containsObject:addr])
		return kIOReturnError;	// already a favourite
	[dom setObject:[favs arrayByAddingObject:addr] forKey:@"FavoriteDevices"];	// update list
	[ud setPersistentDomain:dom forName:DEFAULTS];
	return [ud synchronize]?kIOReturnSuccess:kIOReturnError;	// save
}

- (IOReturn) closeConnection;
{
	/* use "hcitool dc <bdaddr>" */
	NIMP; return 0;
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"IOBluetoothDevice %@ name: %@ class:%d clockoff:%d", [self getAddressString], [self getName], [self getClassOfDevice], [self getClockOffset]];
}

- (const BluetoothDeviceAddress *) getAddress; { return &_addr; }

- (NSString *) getAddressString; 
{
	// CHECKME - should we return the address separated by - characters?
	return [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x", _addr.addr[0], _addr.addr[1], _addr.addr[2], _addr.addr[3], _addr.addr[4], _addr.addr[5]];
}

- (BluetoothClassOfDevice) getClassOfDevice; { return _classOfDevice; }
- (BluetoothClockOffset) getClockOffset; { return _clockOffset; }
- (BluetoothConnectionHandle) getConnectionHandle; { NIMP; return nil; }
- (BluetoothDeviceClassMajor) getDeviceClassMajor; { return (_classOfDevice>>8)&0x0f; }
- (BluetoothDeviceClassMinor) getDeviceClassMinor; { return (_classOfDevice>>0)&0x0ff; }
- (IOBluetoothDeviceRef) getDeviceRef; { return NIMP; }
- (BluetoothHCIEncryptionMode) getEncryptionMode; { NIMP; return 0; }
- (NSDate *) getLastInquiryUpdate; { return _lastInquiryUpdate; }
- (NSDate *) getLastNameUpdate; { return _lastNameUpdate; }
- (NSDate *) getLastServicesUpdate; { return NIMP; }
- (BluetoothLinkType) getLinkType; { NIMP; return 0; }
- (NSString *) getName; { return _name; }
- (NSString *) getNameOrAddress; { return _name?_name:[self getAddressString]; }
- (BluetoothPageScanMode) getPageScanMode; { NIMP; return 0; }
- (BluetoothPageScanPeriodMode) getPageScanPeriodMode; { NIMP; return 0; }
- (BluetoothPageScanRepetitionMode) getPageScanRepetitionMode; { NIMP; return 0; }
- (BluetoothServiceClassMajor) getServiceClassMajor; { return (_classOfDevice>>12)&0x0fffff; }
- (IOBluetoothSDPServiceRecord *) getServiceRecordForUUID:(IOBluetoothSDPUUID *) sdpUUID; { return NIMP; }
- (NSArray *) getServices; { return NIMP; }
- (BOOL) isConnected; { return NO; }

- (NSUInteger) hash;
{
	NSUInteger h = _addr.addr[0];
	h = 2*h + _addr.addr[1];
	h = 3*h + _addr.addr[2];
	h = 5*h + _addr.addr[3];
	h = 7*h + _addr.addr[4];
	h = 11*h + _addr.addr[5];
	return h;
}

- (BOOL) isEqual:(id) other;
{ // same address?
	const BluetoothDeviceAddress *addr;
	if(self == other)
		return YES;
	addr=[other getAddress];
	return addr->addr[5]==_addr.addr[5] &&
		addr->addr[4]==_addr.addr[4] &&
		addr->addr[3]==_addr.addr[3] &&
		addr->addr[2]==_addr.addr[2] &&
		addr->addr[1]==_addr.addr[1] &&
		addr->addr[0]==_addr.addr[0];
}

- (BOOL) isFavorite;
{
	NSArray *favs=[[[NSUserDefaults standardUserDefaults] persistentDomainForName:DEFAULTS] objectForKey:@"FavoriteDevices"];
	return [favs containsObject:[self getAddressString]];
}

- (BOOL) isIncoming; { return NO; }
- (BOOL) isPaired; { return [_paired containsObject:self]; }
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

- (IOReturn) remoteNameRequest:(id) target withPageTimeout:(BluetoothHCIPageTimeout) timeout;
{
	_IOBluetoothDeviceNameRequestHandler *handler=[[_IOBluetoothDeviceNameRequestHandler alloc] initWithDevice:self andTarget:target];
	NSTask *task=[IOBluetoothDeviceInquiry _hcitool:[NSArray arrayWithObjects:@"name", [self getAddressString], nil] handler:handler done:@selector(remoteNameRequestDone:)];
	if(!task)
		{
		[handler release];		// will never be called...
		return kIOReturnError;	// could not launch
		}
	[task retain];	// don't autorelease until we received the notification in our _IOBluetoothDeviceNameRequestHandler
#if 0
	NSLog(@"remoteNameRequest task %@ %p %u", task, task, [task retainCount]);
#endif
	if(!target)
		{ // if no target, synchronously wait for completion
		[task waitUntilExit];
		if([task terminationStatus] != 0)
			return kIOReturnError;	// some error
		}
	return kIOReturnSuccess;
}

- (IOReturn) removeFromFavorites;
{
	NSUserDefaults *ud=[NSUserDefaults standardUserDefaults];
	NSMutableDictionary *dom=[[[ud persistentDomainForName:DEFAULTS] mutableCopy] autorelease];
	NSString *addr=[self getAddressString];
	NSMutableArray *favs=[[[dom objectForKey:@"FavoriteDevices"] mutableCopy] autorelease];
	if(![favs containsObject:addr])
		return kIOReturnError;	// not a favourite
	[favs removeObject:addr];
	[dom setObject:favs forKey:@"FavoriteDevices"];	// update list
	[ud setPersistentDomain:dom forName:DEFAULTS];
	return [ud synchronize]?kIOReturnSuccess:kIOReturnError;	// save
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
	[_lastNameUpdate release];
	_lastNameUpdate=[[NSDate alloc] init];	// now
}

- (void) _setClockOffset:(BluetoothClockOffset) offset; { _clockOffset=offset; }

- (void) _setClassOfDevice:(BluetoothClassOfDevice) class;
{
	_classOfDevice=class;
	[_lastInquiryUpdate release];
	_lastInquiryUpdate=[[NSDate alloc] init];	// now
}

- (void) dealloc;
{
	[_name release];
	[super dealloc];
}

@end

