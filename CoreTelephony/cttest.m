#import <Foundation/Foundation.h>
#import <CoreTelephony/CoreTelephony.h>
#import <CoreTelephony/CTModemManager.h>


@interface CCDelegate : NSObject <CTCallCenterDelegate>
@end

@implementation CCDelegate

// auf fprintf umstellen so dass es ohne NSLog=yes anzeigt!

- (BOOL) callCenter:(CTCallCenter *) center handleCall:(CTCall *) call;	// should ring and -accept/-discard etc. depending on -callState
{
	fprintf(stderr, "%s\n", [[NSString stringWithFormat:@"callCenter:%@ handleCall:%@", center, call] UTF8String]);
	return YES;
}

- (void) callCenter:(CTCallCenter *) center didReceiveSMS:(NSString *) message fromNumber:(NSString *) sender attributes:(NSDictionary *) dict;
{
	fprintf(stderr, "%s\n", [[NSString stringWithFormat:@"callCenter:%@ didReceiveSMS:%@ from %@ attribs %@", center, message, sender, dict] UTF8String]);
}

@end

@interface NTDelegate : NSObject <CTNetworkInfoDelegate>
@end

@implementation NTDelegate

- (void) subscriberCellularProviderDidUpdate:(CTCarrier *) carrier;	// SIM card was changed
{
	fprintf(stderr, "%s\n", [[NSString stringWithFormat:@"subscriberCellularProviderDidUpdate:%@", carrier] UTF8String]);
}

- (void) currentNetworkDidUpdate:(CTCarrier *) carrier;	// roaming or connected/disconnected from Internet
{
	fprintf(stderr, "%s\n", [[NSString stringWithFormat:@"currentNetworkDidUpdate:%@", carrier] UTF8String]);
}

- (void) currentCellDidUpdate:(CTCarrier *) carrier;	// mobile operation
{
	fprintf(stderr, "%s\n", [[NSString stringWithFormat:@"currentCellDidUpdate:%@", carrier] UTF8String]);
}

- (void) signalStrengthDidUpdate:(CTCarrier *) carrier;	// also called for network type changes
{
	float paTemp=[[CTTelephonyNetworkInfo telephonyNetworkInfo] paTemperature];	//may have changed
	float paVolt=[[CTTelephonyNetworkInfo telephonyNetworkInfo] paVoltage];	//may have changed
	fprintf(stderr, "%s\n", [[NSString stringWithFormat:@"signalStrengthDidUpdate:%@ PAtemp=%.1f PAvolt=%.1f", carrier, paTemp, paVol] UTF8String]);
}

@end

/* this is a GUI based command line tool... */

int main(int argc, char *argv[])
{
	NSAutoreleasePool *arp=[[NSAutoreleasePool alloc] init];
	[CTModemManager enableLog:YES];
	CTModemManager *mm=[CTModemManager modemManager];
	CTTelephonyNetworkInfo *ni=[CTTelephonyNetworkInfo telephonyNetworkInfo];
	CTCallCenter *cc=[CTCallCenter callCenter];
	[ni setDelegate:[NTDelegate new]];
	[cc setDelegate:[CCDelegate new]];
	if([mm pinStatus] != CTPinStatusUnlocked)
		[mm orderFrontPinPanel:nil];
	if(argc == 2)
		NSLog(@"call = %@", [cc dial:[NSString stringWithUTF8String:argv[1]]]);	/* allows +, *, # and spaces within numbers */
	NSLog(@"cttest: run loop");
	// we must run the application and not only the runloop - or window events are not processed
	[[NSApplication sharedApplication] run];
	[arp release];
	return 0;
}

// EOF
