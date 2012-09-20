#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface Delegate : NSObject <CLLocationManagerDelegate>

@end

@implementation Delegate

- (void) locationManager:(CLLocationManager *) mngr didEnterRegion:(CLRegion *) region;
{
	
}

- (void) locationManager:(CLLocationManager *) mngr didExitRegion:(CLRegion *) region;
{
	
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
	NSLog(@"location: %@", newloc);
#ifdef __mySTEP__
	NSLog(@"time: %@", [mngr satelliteTime]);
	NSLog(@"%d of %d satellites on %@ ant",
		  [mngr numberOfReceivedSatellites], [mngr numberOfVisibleSatellites],
		  ([mngr source]&CLLocationSourceExternalAnt)?@"ext":@"int");
	e=[[mngr satelliteInfo] objectEnumerator];
	while((d=[e nextObject]))
		NSLog(@"%@ az=%@ el=%@ s/n=%@%@", [d objectForKey:@"PRN"], [d objectForKey:@"azimuth"], [d objectForKey:@"elevation"], [d objectForKey:@"SNR"], [[d objectForKey:@"used"] boolValue]?@" *":@"");
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
	NSLog(@"NMEA: %@", str);
}

@end

int main(int argc, char *argv[])
{
	NSAutoreleasePool *arp=[[NSAutoreleasePool alloc] init];
	CLLocationManager *mgr=[CLLocationManager new];
	if(!mgr)
		{
		NSLog(@"needs allocation of manager");
		exit(1);
		}
	NSLog(@"cltest started - mgr=%@", mgr);
	if([mgr respondsToSelector:@selector(setPurpose:)])
		[mgr setPurpose:@"cltest"];
	[mgr setDelegate:[[Delegate new] autorelease]];
	[mgr startUpdatingLocation];
	NSLog(@"add unused port!");
	[[NSRunLoop mainRunLoop] addPort:[NSPort port] forMode:NSDefaultRunLoopMode];	// we must at least have one entry in the loop or -run will fail immediately
	NSLog(@"run loop");
	[[NSRunLoop mainRunLoop] run];
	NSLog(@"runloop did end!");
	[arp release];
	return 0;
}

// EOF
