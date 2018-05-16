#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>

int main(int argc, char *argv[])
{
	NSAutoreleasePool *arp=[[NSAutoreleasePool alloc] init];
	CMMotionManager *cm=[CMMotionManager new];
	NSLog(@"cmtest: started - manager=%@", cm);
	NSLog(@"cmtest: add unused port to keep runloop active!");
	[[NSRunLoop mainRunLoop] addPort:[NSPort port] forMode:NSDefaultRunLoopMode];	// we must at least have one entry in the loop or -run will fail immediately
	NSLog(@"cmtest: run loop");
	[cm startDeviceMotionUpdates];
	while(YES)
		{
		CMDeviceMotion *dm=[cm deviceMotion];
		char *str=[[dm description] UTF8String];
		printf("%s\n", str);
		[[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];	// run for another second
		}
	[cm stopDeviceMotionUpdates];
	[cm release];
	[arp release];
	return 0;
}

// EOF
