/* 
 pppd driver.
 
 Copyright (C)	H. Nikolaus Schaller <hns@computer.org>
 Date:			2006
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#import <SystemStatus/SYSInternet.h>

NSString *SYSInternetStatusChangedNotification=@"SYSInternetStatusChangedNotification";

@implementation SYSInternet

+ (NSArray *) interfaces;
{ // list of all interfaces we can dial to
	return [NSArray arrayWithObjects:@"Modem", @"IrDA", nil];
}

+ (NSString *) currentInterface;
{
	return nil;
}

+ (BOOL) selectInterface:(NSString *) string;
{
	return NO;
}

+ (BOOL) isConnected;
{
	return NO;
}

+ (BOOL) connect;
{ // start pppd
	return NO;
}

+ (BOOL) disconnect;
{ // stop pppd
	return YES;
}

@end
