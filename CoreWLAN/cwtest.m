#import <Foundation/Foundation.h>
#import <CoreWLAN/CoreWLAN.h>

@interface Delegate : NSObject

@end

@implementation Delegate

@end

int main(int argc, char *argv[])
{
	NSAutoreleasePool *arp=[[NSAutoreleasePool alloc] init];
	NSError *err=@"can't find interface";	// will be printed if cw == nil
	CWInterface *cw=[CWWiFiClient interface];	// default interface
	NSArray *nw;
	NSEnumerator *e;
	CWNetwork *network;
	BOOL power=[cw power];	// save power state
	if(![cw setPower:YES error:&err])
		{
		NSLog(@"WLAN power on error: %@", err);
		exit(1);
		}
	NSLog(@"cwtest: started - interface=%@", cw);
	NSLog(@"cwtest: add unused port to keep runloop active!");
	[[NSRunLoop mainRunLoop] addPort:[NSPort port] forMode:NSDefaultRunLoopMode];	// we must at least have one entry in the loop or -run will fail immediately
	NSLog(@"cwtest: run loop");
	while(YES)
		{
		nw=[cw scanForNetworksWithParameters:nil error:&err];
		if(nw)
			break;
		[[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];	// run for another second
		}
	NSLog(@"cwtest: runloop did end with result!");
	e=[nw objectEnumerator];
	while((network=[e nextObject]))
		{
		NSString *str=[NSString stringWithFormat:@"%@: %ld dBm", [network ssid], (long)[network rssiValue]];
		printf("%s\n", [str UTF8String]);
		}
	if(![cw setPower:power error:&err])	// turn off only if it was off before
		NSLog(@"WLAN power off error: %@", err);
	[arp release];
	return 0;
}

// EOF
