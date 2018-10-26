#import <Foundation/Foundation.h>
#import <IOBluetooth/Bluetooth.h>

@interface Delegate : NSObject
{
	BOOL _done;
}
@end

@implementation Delegate

- (BOOL) done; { return _done; }

- (void) deviceInquiryComplete:(IOBluetoothDeviceInquiry *) sender
						 error:(IOReturn) error
					   aborted:(BOOL) aborted;
{
	NSLog(@"%@ error=%d aborted=%d", self, error, aborted);
	NSLog(@"devices=%@", [sender foundDevices]);
	_done=YES;
}

@end

int main(int argc, char *argv[])
{
	NSAutoreleasePool *arp=[[NSAutoreleasePool alloc] init];
	NSError *err;
#ifdef __mySTEP__
	BOOL poweron=[IOBluetoothDeviceInquiry _bluetoothHardwareIsActive];
	if(![IOBluetoothDeviceInquiry _activateBluetoothHardware:YES])
		{
		NSLog(@"Bluetooth power on error: %@", err);
		exit(1);
		}
#endif
	NSLog(@"iobttest: started");
	Delegate *d=[[Delegate new] autorelease];
	IOBluetoothDeviceInquiry *inq=[IOBluetoothDeviceInquiry inquiryWithDelegate:d];
	NSLog(@"iobttest: add unused port to keep runloop active!");
	[[NSRunLoop mainRunLoop] addPort:[NSPort port] forMode:NSDefaultRunLoopMode];	// we must at least have one entry in the loop or -run will fail immediately
	NSLog(@"iobttest: run loop");
	[inq start];
	while(![d done])
		{
		[[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];	// run for another second
		}
	NSLog(@"iobttest: runloop did end with result!");
#ifdef __mySTEP__
	if(![IOBluetoothDeviceInquiry _activateBluetoothHardware:poweron])
		{ // turn off only if it was off before
		NSLog(@"WLAN power off error: %@", err);
		}
#endif
	[arp release];
	return 0;
}

// EOF
