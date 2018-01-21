#import <Foundation/Foundation.h>
#import <CoreWLAN/CoreWLAN.h>

@interface Delegate : NSObject

@end

@implementation Delegate

@end

int main(int argc, char *argv[])
{
	NSAutoreleasePool *arp=[[NSAutoreleasePool alloc] init];
	NSError *err;
	CWInterface *cw=[CWInterface interface];
	if(![cw setPower:YES error:&err])
		{
		NSLog(@"WLAN power on error: %@", err);
		exit(1);
		}
	NSLog(@"cwtest: started - interface=%@", cw);
	NSArray *nw=[cw scanForNetworksWithParameters:nil error:&err];
	CWNetwork *network;
	NSEnumerator *e=[nw objectEnumerator];
	while((network=[e nextObject]))
		{
		NSString *str=[NSString stringWithFormat:@"%@: %ld dBm", [network ssid], (long)[network rssiValue]];
		printf("%s\n", [str UTF8String]);
		}
	NSLog(@"cwtest: add unused port to keep runloop active!");
	[[NSRunLoop mainRunLoop] addPort:[NSPort port] forMode:NSDefaultRunLoopMode];	// we must at least have one entry in the loop or -run will fail immediately
	NSLog(@"cwtest: run loop");
	[[NSRunLoop mainRunLoop] run];
	NSLog(@"cwtest: runloop did end!");
#if 0
	// turn off only if it was already off
	if(![cw setPower:NO error:&err])
		{
		NSLog(@"WLAN power off error: %@", err);
		}
#endif
	[arp release];
	return 0;
}

// EOF
