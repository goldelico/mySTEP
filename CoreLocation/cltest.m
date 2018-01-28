#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface Delegate : NSObject <CLLocationManagerDelegate>

@end

@implementation Delegate

- (void) locationManager:(CLLocationManager *) mngr didEnterRegion:(CLRegion *) region;
{
	NSLog(@"didEnterRegion: %@", region);
}

- (void) locationManager:(CLLocationManager *) mngr didExitRegion:(CLRegion *) region;
{
	NSLog(@"didExitRegion: %@", region);
}

- (void) locationManager:(CLLocationManager *) mngr didFailWithError:(NSError *) err;
{
	NSLog(@"failed: %@", err);
	exit(1);
}

- (void) locationManager:(CLLocationManager *) mngr didUpdateHeading:(CLHeading *) head;
{
	NSLog(@"heading: %@", head);
}

- (void) locationManager:(CLLocationManager *) mngr didUpdateToLocation:(CLLocation *) newloc fromLocation:(CLLocation *) old;
{
	NSEnumerator *e;
	NSDictionary *d;
	printf("location: %s\n", [[newloc description] UTF8String]);
#ifdef __mySTEP__
	printf("time: %s\n", [[[mngr satelliteTime] description] UTF8String]);
	printf("%d of %d satellites on %s ant\n",
		  [mngr numberOfReceivedSatellites], [mngr numberOfVisibleSatellites],
		  ([mngr source]&CLLocationSourceExternalAnt)?"ext":"int");
	e=[[mngr satelliteInfo] objectEnumerator];
	while((d=[e nextObject]))
		printf("%s az=%s el=%s s/n=%s%s\n", [[d objectForKey:@"PRN"] UTF8String], [[d objectForKey:@"azimuth"] UTF8String], [[d objectForKey:@"elevation"] UTF8String], [[d objectForKey:@"SNR"] UTF8String], [[d objectForKey:@"used"] boolValue]?" *":"");
#endif
}

- (void) locationManager:(CLLocationManager *) mngr monitoringDidFailForRegion:(CLRegion *) region withError:(NSError *) err;
{
	
}

- (BOOL) locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *) mngr;
{
	return YES;
}

- (void) locationManager:(CLLocationManager *) mngr didReceiveNMEA:(NSString *) str;
{
	printf("NMEA: %s\n", [str UTF8String]);
}

@end

int main(int argc, char *argv[])
{
	NSAutoreleasePool *arp=[[NSAutoreleasePool alloc] init];
#if 0
	{ // test NSMessagePort creation and caching
	NSPort *p;
	NSLog(@"first NSMessagePort: %@", p=[NSMessagePort port]);
	NSLog(@"second NSMessagePort: %@", [NSMessagePort port]);
	NSLog(@"copied NSMessagePort: %@", [[NSMessagePort alloc] initRemoteWithProtocolFamily:[p protocolFamily]
															   socketType:[p socketType]
																 protocol:[p protocol]
																  address:[p address]]);
	return 0;
	}
#endif
	CLLocationManager *mgr=[CLLocationManager new];
	if(!mgr)
		{
		NSLog(@"needs allocation of manager");
		exit(1);
		}
#if 0
	{
	NSPort *p;
	NSLog(@"first NSMessagePort: %@", [NSMessagePort port]);
	NSLog(@"second NSMessagePort: %@", p=[NSMessagePort port]);
	NSLog(@"copy %@", [[NSMessagePort alloc] initRemoteWithProtocolFamily:[p protocolFamily]
															   socketType:[p socketType]
																 protocol:[p protocol]
																  address:[p address]]);
	}
#endif 
	NSLog(@"cltest: started - mgr=%@", mgr);
	if([mgr respondsToSelector:@selector(setPurpose:)])
		[mgr setPurpose:@"cltest - CoreLocation Test"];
	[mgr setDelegate:[[Delegate new] autorelease]];
	[mgr startUpdatingLocation];
	NSLog(@"cltest: add unused port to keep runloop active!");
	[[NSRunLoop mainRunLoop] addPort:[NSPort port] forMode:NSDefaultRunLoopMode];	// we must at least have one entry in the loop or -run will fail immediately
	NSLog(@"cltest: run loop");
	[[NSRunLoop mainRunLoop] run];
	NSLog(@"cltest: runloop did end!");
	[arp release];
	return 0;
}

// EOF
