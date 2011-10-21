//
//  IOBluetoothDeviceInquiry.m
//  IOBluetooth
//
//  Created by H. Nikolaus Schaller on 30.10.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "IOBluetoothDeviceInquiry.h"
#import <IOBluetooth/BluetoothAssignedNumbers.h>
#import <IOBluetooth/objc/IOBluetoothDevice.h>

#import "BluetoothPrivate.h"

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

- (NSArray*) foundDevices; 
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
#ifdef BLUEZ
			_socket = socket(AF_BLUETOOTH, SOCK_RAW, BTPROTO_HCI));
			if(_socket < 0)
					{
						perror("Can't open HCI socket.");
						[self release];
						return nil;
					}
#endif
			_timeout=10;
			_delegate=delegate;
			_devices=[[NSMutableArray alloc] initWithCapacity:5];
			_updateNewDeviceNames=YES;
		}
	return self;
}

- (void) dealloc;
{
#ifdef BLUEZ
	if(_socket >= 0)
		[self stop];
#else
	if(_task)
		[self stop];
#endif
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

#ifndef BLUEZ

+ (NSTask *) _hcitool:(NSArray *) cmds handler:(id) handler done:(SEL) sel;
{
#if OLD
	NSString *tool=[NSSystemStatus sysInfoForKey:@"Bluetooth Tool"];
#else
	NSString *tool=@"/usr/bin/hcitool";
#endif
	NSTask *task;
#if 1
	NSLog(@"tool=%@", tool);
#endif
	if(!tool)
		return nil;	// bluetooth is not supported
	task=[[NSTask new] autorelease];
	[[NSNotificationCenter defaultCenter] addObserver:handler selector:sel name:NSTaskDidTerminateNotification object:task];
	[task setLaunchPath:tool];
	[task setArguments:cmds];
	[task setStandardOutput:[NSPipe pipe]];
	[task setStandardError:nil];	// hide error messages
#if 0
	NSLog(@"launching task %@ %p %u", task, task, [task retainCount]);
#endif
	[task launch];
#if 1
	NSLog(@"launched task %@ %p %u", task, task, [task retainCount]);
#endif
	return task;
}

#endif

- (IOReturn) start; 
{ // start background polling
#if 1
	NSLog(@"start %@", self);
#endif
#ifdef BLUEZ
	_aborted=NO;
	// see hcitool.c
	/* --- make this non-blocking!
	 num_rsp = hci_inquiry(dev_id, length, num_rsp, lap, &info, flags);
	 if (num_rsp < 0) {
		perror("Inquiry failed.");
		exit(1);
	 }

	 int hci_inquiry(int dev_id, int len, int nrsp, const uint8_t *lap, inquiry_info **ii, long flags)
	 {
	 struct hci_inquiry_req *ir;
	 uint8_t num_rsp = nrsp;
	 void *buf;
	 int dd, size, err, ret = -1;
	 
	 if (nrsp <= 0) {
	 num_rsp = 0;
	 nrsp = 255;
	 }
	 
	 if (dev_id < 0) {
	 dev_id = hci_get_route(NULL);
	 if (dev_id < 0) {
	 errno = ENODEV;
	 return -1;
	 }
	 }	
	 
	 dd = socket(AF_BLUETOOTH, SOCK_RAW, BTPROTO_HCI);
	 if (dd < 0)
	 return dd;
	 
	 buf = malloc(sizeof(*ir) + (sizeof(inquiry_info) * (nrsp)));
	 if (!buf)
	 goto done;
	 
	 ir = buf;
	 ir->dev_id  = dev_id;
	 ir->num_rsp = num_rsp;
	 ir->length  = len;
	 ir->flags   = flags;
	 
	 if (lap) {
	 memcpy(ir->lap, lap, 3);
	 } else {
	 ir->lap[0] = 0x33;
	 ir->lap[1] = 0x8b;
	 ir->lap[2] = 0x9e;
	 }

	 // is this one blocking the process?
	 
	 ret = ioctl(dd, HCIINQUIRY, (unsigned long) buf);
	 if (ret < 0)
	 goto free;
	 
	 size = sizeof(inquiry_info) * ir->num_rsp;
	 
	 if (!*ii)
	 *ii = malloc(size);
	 
	 if (*ii) {
	 memcpy((void *) *ii, buf + sizeof(*ir), size);
	 ret = ir->num_rsp;
	 } else
	 ret = -1;
	 
	 free:
	 free(buf);
	 
	 done:
	 err = errno;
	 close(dd);
	 errno = err;
	 
	 return ret;
	 }
	 
	 */
	
//		return 42;	// could not launch
	[_delegate deviceInquiryStarted:self];
	return kIOReturnSuccess;
#else
	if(_task)
		return kIOReturnError;	// task is already running
	_aborted=NO;
	_task=[[isa _hcitool:[NSArray arrayWithObjects:_updateNewDeviceNames?@"inq":@"inq", @"--flush", nil] handler:self done:@selector(_done:)] retain];
	if(!_task)
		return 42;	// could not launch
	[_delegate deviceInquiryStarted:self];
	return kIOReturnSuccess;
#endif	
}

// NOTE: this assumes that the full output of the subtask can be buffered and the pipe does never stall
// and we process the result of a "hcitool inq" command

/* output looks like

$ hcitool inq 
Inquiring ...
	01:90:71:10:02:AA       clock offset: 0x4402    class: 0x720204
	00:11:24:AF:2E:E3       clock offset: 0x0704    class: 0x102104
	00:16:CB:2F:A0:46       clock offset: 0x30d2    class: 0x10210c

*/

- (void) _done:(NSNotification *) notif;
{
#ifndef BLUEZ
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
#else
	{ // no data - i.e. we don't currently support bluetooth (e.g. hcitool installed, but no device)
			status=31;
			}
					BluetoothDeviceAddress addr;
					dev=[IOBluetoothDevice withAddress:&addr];
					idx=[recentDevices indexOfObject:dev];
					if(idx == NSNotFound)
						{ // this is really a new device
						[recentDevices insertObject:dev atIndex:0];	// most recent
						if([recentDevices count] > 100)
							{
							// truncate list...
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
						{
						[_devices addObject:dev];			// device found
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
#endif
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

- (IOReturn) stop; 
{
	_aborted=YES;
#ifndef BLUEZ
	[_task interrupt];
	[_task waitUntilExit];
#endif
	return kIOReturnSuccess;
}

- (BOOL) updateNewDeviceNames; 
{
	return _updateNewDeviceNames;
}

+ (BOOL) _activateBluetoothHardware:(BOOL) flag;
{
	if([self _bluetoothHardwareIsActive] != flag)
		{
#if OLD
		NSString *cmd=[NSSystemStatus sysInfoForKey:(flag?@"Bluetooth On":@"Bluetooth Off")];
#if 1
		NSLog(@"command=%@", cmd);
#endif
		return system([cmd UTF8String]) == 0;
#else
		if(flag)
			{
			if([[NSString stringWithContentsOfFile:@"/sys/devices/platform/reg-virt-consumer.4/max_microvolts"] intValue] == 0)
				{ // not yet powered on - will also power on WLAN!
#if 1
					NSLog(@"BT power on");
#endif
					if(system("VDD=3150000;"
							  "echo \"255\" >/sys/class/leds/tca6507:6/brightness &&"
							  "echo \"$VDD\" >/sys/devices/platform/reg-virt-consumer.4/max_microvolts &&"
							  "echo \"$VDD\" >/sys/devices/platform/reg-virt-consumer.4/min_microvolts &&"
							  "echo \"normal\" >/sys/devices/platform/reg-virt-consumer.4/mode &&"
							  "echo \"0\" >/sys/class/leds/tca6507:6/brightness &&"
							  "sleep 1") != 0)
						{
						NSLog(@"VAUX4 power on failed");
						return NO;	// something failed
						}
				}
#if 1
			NSLog(@"BT hciattach");
#endif
			return system("hciattach -s 115200 /dev/ttyS0 any 115200 flow && sleep 2 &&"
						  "hciconfig hci0 up && sleep 2 &&"
						  "hciconfig hci0 name GTA04") == 0;
			}
		else
			{
#if 1
			NSLog(@"BT killall hciattach");
#endif
			system("killall hciattach");
			/* only if WLAN is inactive (iwconfig | fgrep wlan*) */
			/* WLAN manager will check if bluetooth is active */
#if 1
			NSLog(@"BT power off");
#endif
			system("echo \"255\" >/sys/class/leds/tca6507:6/brightness;"
				   "echo 0 >/sys/devices/platform/reg-virt-consumer.4/max_microvolts");
			return YES;
			}
#endif		
		}
	return YES;	// unchaged
}

+ (BOOL) _bluetoothHardwareIsActive;
{
	FILE *file;
	char line[256];
#if OLD
	NSString *cmd=[NSSystemStatus sysInfoForKey:@"Bluetooth Status"];
#else
	NSString *cmd=@"hciconfig -a";
#endif
	if(!cmd)
		return NO;
	file=popen([cmd UTF8String], "r");	// check status
	if(!file)
		return NO;
	/* result looks like
		hci0:   Type: USB				<- we may have more than one Bluetooth interface!
        BD Address: 00:06:6E:14:4B:5A ACL MTU: 384:8 SCO MTU: 64:8    <- this is our own address (if we need it)
        UP RUNNING PSCAN ISCAN
        RX bytes:154 acl:0 sco:0 events:17 errors:0
        TX bytes:314 acl:0 sco:0 commands:16 errors:0
		*/
	memset(line, sizeof(line), 0);
	line[fread(line, sizeof(line[0]), sizeof(line)-1, file)]=0; // read as much as we get but not more than buffer holds
	pclose(file);
#if 1
	NSLog(@"_bluetoothHardwareIsActive -> %d", strlen(line) > 0);
#endif
	return strlen(line) > 0;
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
