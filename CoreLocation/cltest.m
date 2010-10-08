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
	NSLog(@"location: %@", newloc);
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
	if([mgr respondsToSelector:@selector(setPurpose:)])
		[mgr setPurpose:@"cltest"];
	[mgr setDelegate:[[Delegate new] autorelease]];
	[mgr startUpdatingLocation];
	while(YES)
		[[NSRunLoop mainRunLoop] run];
	[arp release];
}