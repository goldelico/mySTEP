/* 
SYSInternet.h
 
 Generic Dialup interface.
 
 Copyright (C)	H. Nikolaus Schaller <hns@computer.org>
 Date:			2006
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#ifndef _mySTEP_H_SYSInternetStatus
#define _mySTEP_H_SYSInternetStatus

#import <AppKit/AppKit.h>

extern NSString *SYSInternetStatusChangedNotification;		// status has changed

@interface SYSInternet : NSObject
{
}

+ (NSArray *) interfaces;	// list of all interfaces we can dial to
+ (NSString *) currentInterface;
+ (BOOL) selectInterface:(NSString *) string;

+ (BOOL) isConnected;
+ (BOOL) connect;		// start pppd
+ (BOOL) disconnect;	// stop pppd

@end

#endif