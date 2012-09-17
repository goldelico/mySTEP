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

@end

int main(int argc, char *argv[])
{
	NSAutoreleasePool *arp=[[NSAutoreleasePool alloc] init];
	CLLocationManager *mgr=[CLLocationManager new];
	NSLog(@"cltest started");
	if([mgr respondsToSelector:@selector(setPurpose:)])
		[mgr setPurpose:@"cltest"];
	[mgr setDelegate:[[Delegate new] autorelease]];
	[mgr startUpdatingLocation];
	while(YES)
		[[NSRunLoop mainRunLoop] run];
	[arp release];
}

// EOF
