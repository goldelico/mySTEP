//
//  IOBluetoothDeviceInquiry.m
//  IOBluetooth
//
//  Created by H. Nikolaus Schaller on 30.10.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <IOBluetooth/objc/IOBluetoothDeviceInquiry.h>
#import <IOBluetooth/objc/IOBluetoothDevice.h>
#import <IOBluetooth/BluetoothAssignedNumbers.h>
#import "../BluetoothPrivate.h"

#import <IOBluetooth/objc/IOBluetoothController.h>

#if 0	// debugging
#define system(CMD) (printf("system: %s\n", (CMD)), 0)
#endif

@implementation IOBluetoothDeviceInquiry

+ (IOBluetoothDeviceInquiry *) inquiryWithDelegate:(id) delegate;
{
	return [[[self alloc] initWithDelegate:delegate] autorelease];
}

- (void) clearFoundDevices;
{
	[_devices removeAllObjects];
}

- (id) delegate;
{
	return _delegate;
}

- (NSArray *) foundDevices;
{
	return _devices;
}

- (id) init;
{
	NIMP;
	[self release];
	return nil;
}

- (id) initWithDelegate:(id) delegate;
{
	if((self=[super init]))
		{
			_timeout=10;
			_delegate=delegate;
			_devices=[[NSMutableArray alloc] initWithCapacity:5];
			_updateNewDeviceNames=YES;
		}
	return self;
}

- (void) dealloc;
{
	if(_task)
		[self stop];
	[_devices release];
	[super dealloc];
}

- (uint8_t) inquiryLength;
{
	return _timeout;
}

- (void) setDelegate:(id) delegate;
{
	_delegate=delegate;
}

- (uint8_t) setInquiryLength:(uint8_t) seconds;
{
	if(seconds > 0)
		_timeout=seconds;
	return _timeout;
}

- (void) setSearchCriteria:(BluetoothServiceClassMajor) scmaj
		  majorDeviceClass:(BluetoothDeviceClassMajor) dcmaj
		  minorDeviceClass:(BluetoothDeviceClassMinor) dcmin;
{
	NIMP;
}

- (void) setUpdateNewDeviceNames:(BOOL) flag;
{ // NOTE: this makes it much slower because we isssue a separate hcitool name command for each device
	_updateNewDeviceNames=flag;
}

- (void) _done:(NSNotification *) notif;
{
	int status=[_task terminationStatus];
	NSFileHandle *rfh=[[_task standardOutput] fileHandleForReading];
	NSMutableArray *recentDevices=(NSMutableArray *) [IOBluetoothDevice recentDevices:0];
	IOBluetoothDevice *dev;
#if 0
	NSLog(@"task is done status=%d %@", status, _task);
	NSLog(@"rfh=%@", rfh);
#endif
	[rfh retain];	// keep even if we release the task and observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSTaskDidTerminateNotification object:_task];
	[_task autorelease];
	_task=nil;
	if(status == 0)
		{ // build new list of devices
			NSData *result=[rfh readDataToEndOfFile];
			unsigned rlength;
#if 0
			NSLog(@"result=%@", result);
#endif
			if((rlength=[result length]) == 0)
				{ // no data - i.e. we don't currently support bluetooth (e.g. hcitool installed, but no device)
					status=31;
				}
			else
				{
				const char *cp=[result bytes];
				const char *cend=cp+rlength;
				if(cend > cp+8 && strncmp(cp, "Inquiring", 8) == 0)
					{ // ok
						while(cp < cend)
							{ // get next line
								BluetoothDeviceAddress addr;
								long offset;
								long class;
								int idx;
								while(cp < cend && *cp != '\n')
									cp++;	// skip previous line and/or "Scanning..."
								cp++;
								if(cp >= cend)
									break;
								sscanf(cp, "%hhx:%hhx:%hhx:%hhx:%hhx:%hhx clock offset: %lx class: %lx", 
									   &addr.addr[0], &addr.addr[1], &addr.addr[2], &addr.addr[3], &addr.addr[4], &addr.addr[5],
									   &offset, &class);
								dev=[IOBluetoothDevice withAddress:&addr];
#if 1
								NSLog(@"new bluetooth device: %@", dev);
#endif
								idx=[recentDevices indexOfObject:dev];	// requires -hash and -isEqual
								if(idx == NSNotFound)
									{ // this is really a new device
										[recentDevices insertObject:dev atIndex:0];	// most recent
										if([recentDevices count] > 100)
											{
											// truncate...
											}
#if 0
										NSLog(@"device added to recent devices: %@", dev);
#endif
									}
								else
									{
									dev=[recentDevices objectAtIndex:idx];	// use existing record and not the new one
									[dev retain];
									[recentDevices removeObjectAtIndex:idx];
									[recentDevices insertObject:dev atIndex:0];	// move to front (LRU queue)
									[dev release];
									}
								
								// recentDevices should be written to a persistent storage so that processes can share...
								
								[dev _setClassOfDevice:class];			// this updates the last Inquiry update timestamp
								[dev _setClockOffset:offset];
								if(![_devices containsObject:dev])
									{ // new device found
									[_devices addObject:dev];
									[_delegate deviceInquiryDeviceFound:self device:dev];
									}
							}
					}
				}
			if(_updateNewDeviceNames)
				{ // find devices still without a name
					int i, cnt=[_devices count];
					int remaining=0;
					for(i=0; i<cnt; i++)
						{
						dev=[_devices objectAtIndex:i];
						if([dev getName] == nil)
							remaining++;
						}
					if(remaining)
						{ // now fetch device names
							[_delegate deviceInquiryUpdatingDeviceNamesStarted:self devicesRemaining:remaining];
							[self remoteNameRequestComplete:nil status:status name:nil];	// trigger first one
							return;
						}
				}
		}
	else
		status=31;	// not available
	[_delegate deviceInquiryComplete:self error:status aborted:_aborted];	// nothing remaining
	[rfh release];
}

- (void) remoteNameRequestComplete:(IOBluetoothDevice *) dev status:(int) status name:(NSString *) name;
{ // device name received
	int i, cnt=[_devices count];
	int remaining=0;
	IOBluetoothDevice *d;
	for(i=0; i<cnt; i++)
		{ // count remaining devices still without name
		d=[_devices objectAtIndex:i];
		if(d != dev && [d getName] == nil)
			remaining++;	// don't count
		}
	if(dev)
		{
#if 0
		NSLog(@"name request completed: %@", name);
#endif
		[dev _setName:name];
		[_delegate deviceInquiryDeviceNameUpdated:self device:dev devicesRemaining:remaining];
		}
	if(!_aborted && remaining > 0)
		{ // any names remaining
		for(i=0; i<cnt; i++)
			{ // find first and request name
			d=[_devices objectAtIndex:i];
			if([d getName] == nil)
				{
				[d remoteNameRequest:self];	// request to asynchronously update the device name once
				break;
				}
			}
		}
	else
		{
		NSLog(@"nothing remaining");
		[_delegate deviceInquiryComplete:self error:status aborted:_aborted];	// nothing remains
		}
}

- (IOReturn) start;
{
	[[IOBluetoothController sharedController] runCommand:@"scan on"];
	return kIOReturnSuccess;
}

- (IOReturn) stop;
{
	[[IOBluetoothController sharedController] runCommand:@"scan off"];
	return kIOReturnSuccess;
}

- (BOOL) updateNewDeviceNames;
{
	return _updateNewDeviceNames;
}

@end

@implementation NSObject (IOBluetoothDeviceInquiryDelegate)

- (void) deviceInquiryComplete:(IOBluetoothDeviceInquiry *) sender 
						 error:(IOReturn) error
					   aborted:(BOOL) aborted;
{ // default;
	return;
}

- (void) deviceInquiryDeviceFound:(IOBluetoothDeviceInquiry *) sender 
						   device:(IOBluetoothDevice *) device;
{ // default;
	return;
}

- (void) deviceInquiryDeviceNameUpdated:(IOBluetoothDeviceInquiry *) sender 
								 device:(IOBluetoothDevice *) device
					   devicesRemaining:(int) remaining;
{ // default;
	return;
}

- (void) deviceInquiryStarted:(IOBluetoothDeviceInquiry *) sender;
{ // default;
	return;
}

- (void) deviceInquiryUpdatingDeviceNamesStarted:(IOBluetoothDeviceInquiry *) sender 
								devicesRemaining:(int) remaining;
{ // default;
	return;
}

@end

#ifndef __mySTEP__

@implementation NSSystemStatus
+ (NSDictionary *) sysInfo; { return nil; }
+ (id) sysInfoForKey:(NSString *) key; { return nil; }
@end

#endif
