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

#ifdef __mySTEP__
#import <SystemStatus/NSSystemStatus.h>
#else
@interface NSSystemStatus : NSObject
+ (NSDictionary *) sysInfo;
+ (id) sysInfoForKey:(NSString *) key;
@end
@implementation NSSystemStatus
+ (NSDictionary *) sysInfo; { return nil; }
+ (id) sysInfoForKey:(NSString *) key; { return nil; }
@end
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
		_timeout=10;
		_delegate=delegate;
		_devices=[[NSMutableArray alloc] initWithCapacity:5];
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

+ (NSTask *) _hcitool:(NSArray *) cmds handler:(id) handler done:(SEL) sel;
{
	NSString *tool=[NSSystemStatus sysInfoForKey:@"Bluetooth Tool"];
	NSTask *task;
#if 0
	NSLog(@"tool=%@", tool);
#endif
	if(!tool)
		return nil;	// bluetooth is not supported
	task=[NSTask new];
	[[NSNotificationCenter defaultCenter] addObserver:handler selector:sel name:NSTaskDidTerminateNotification object:task];
	[task setLaunchPath:tool];
	[task setArguments:cmds];
	[task setStandardOutput:[NSPipe pipe]];
#if 0
	NSLog(@"task=%@", task);
#endif
	[task launch];
	return [task autorelease];
}

- (IOReturn) start; 
{
#if 0
	NSLog(@"start %@", self);
#endif
	if(_task)
		return kIOReturnError;	// task is already running
	_aborted=NO;
	_task=[[isa _hcitool:[NSArray arrayWithObjects:_updateNewDeviceNames?@"inq":@"scan", nil] handler:self done:@selector(_done:)] retain];
	if(!_task)
		return 42;	// could not launch
	[_delegate deviceInquiryStarted:self];
	return kIOReturnSuccess;
}

// NOTE: this assumes that the full output of the subtask can be buffered and the pipe does never stall
// and we process the result of a "hcitool scan" command (should simply be "hcitool inq")

- (void) _done:(NSNotification *) notif;
{
	int status=[_task terminationStatus];
	NSFileHandle *rfh=[[[[_task standardOutput] fileHandleForReading] retain] autorelease];	// keep
#if 1
	NSLog(@"task is done status=%d %@", status, _task);
	NSLog(@"rfh=%@", rfh);
#endif
	[_task release];
	_task=nil;
	if(status == 0)
		{ // build new list of devices
		NSData *result=[rfh readDataToEndOfFile];
		unsigned rlength;
#if 1
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
			if(cend > cp+8 && strncmp(cp, "Scanning", 8) == 0)
				{ // ok
				[_devices removeAllObjects];
				while(cp < cend && *cp != '\n')
					cp++;	// skip "Scanning..."
				cp++;
				while(cp < cend)
					{ // get next line
					IOBluetoothDevice *dev;
					BluetoothDeviceAddress addr;
					const char *c0;
					int len;
					/*	a line looks like
00:16:CB:2F:A0:46       MacBook
00:11:24:AF:2E:E3       MacMini
						*/
					while(cp < cend && isspace(*cp)) cp++;
					sscanf(cp, "%hhx:%hhx:%hhx:%hhx:%hhx:%hhx%n", &addr.addr[0], &addr.addr[1], &addr.addr[2], &addr.addr[3], &addr.addr[4], &addr.addr[5], &len);
					cp+=len;
					while(cp < cend && isspace(*cp)) cp++;	// skip spaces
					c0=cp;
					while(cp < cend && *cp != '\n') cp++;	// get span of name
					dev=[IOBluetoothDevice withAddress:&addr];
					[_devices addObject:dev];
					if(_updateNewDeviceNames)
						[dev remoteNameRequest:self];	// request to asynchronously update the device name
					else
						[dev _setName:[NSString stringWithCString:c0 length:cp-c0]];	// store what we got
					cp++;	// skip \n
					}
				}
			}
		}
	else
		status=31;	// not available
	[_delegate deviceInquiryComplete:self error:status aborted:_aborted];
}

- (void) remoteNameRequestComplete:(IOBluetoothDevice *) dev status:(int) status name:(NSString *) name;
{ // device name received
	// FIXME: isn't this already done by the name request?
	[dev _setName:name];
}

- (IOReturn) stop; 
{
	_aborted=YES;
	[_task interrupt];
	[_task waitUntilExit];
	return kIOReturnSuccess;
}

- (BOOL) updateNewDeviceNames; 
{
	return _updateNewDeviceNames;
}

+ (BOOL) _activateBluetoothHardware:(BOOL) flag;
{
	NSString *cmd=[NSSystemStatus sysInfoForKey:(flag?@"Bluetooth On":@"Bluetooth Off")];
#if 1
	NSLog(@"command=%@", cmd);
#endif
	return system([cmd cString]) == 0;
}

+ (BOOL) _bluetoothHardwareIsActive;
{
	FILE *file;
	char line[256];
	NSString *cmd=[NSSystemStatus sysInfoForKey:@"Bluetooth Status"];
	if(!cmd)
		return NO;
	file=popen([cmd cString], "r");	// check status
	/* result looks like
		hci0:   Type: USB				<- we may have more than one Bluetooth interface
        BD Address: 00:06:6E:14:4B:5A ACL MTU: 384:8 SCO MTU: 64:8    <- this is our own address (if we need it)
        UP RUNNING PSCAN ISCAN
        RX bytes:154 acl:0 sco:0 events:17 errors:0
        TX bytes:314 acl:0 sco:0 commands:16 errors:0
		*/
	memset(line, sizeof(line), 0);
	line[fread(line, sizeof(line[0]), sizeof(line)-1, file)]=0; // read as much as we get but not more than buffer holds
	pclose(file);
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

