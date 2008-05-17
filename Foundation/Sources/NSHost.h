/* 
    NSHost.h

    Interface to host class

    Copyright (C) 1996, 1997 Free Software Foundation, Inc.

    Author:	Luke Howard <lukeh@xedoc.com.au> 
    Date:	1996
   
    H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
    Fabian Spillner, May 2008 - API revised to be compatible to 10.5
 
    This file is part of the mySTEP Library and is provided
    under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSHost
#define _mySTEP_H_NSHost

#import <Foundation/NSObject.h>

@class NSString;
@class NSArray;
@class NSMutableArray;

@interface NSHost : NSObject
{
	NSMutableArray *_names;
	NSMutableArray *_addresses;
}
									// Addresses are in "Dotted Decimal"
+ (NSHost *) currentHost;			// notation such as: @"192.42.172.1"
+ (void) flushHostCache;
+ (NSHost *) hostWithAddress:(NSString *) address;
+ (NSHost *) hostWithName:(NSString *) name;
+ (BOOL) isHostCacheEnabled;		// If enabled, a shared NSHost instance isreturned by methods that return NSHost
+ (void) setHostCacheEnabled:(BOOL) flag;

- (NSString *) address;		// return one address (arbitrarily) if a host has several.
- (NSArray *) addresses;
- (BOOL) isEqualToHost:(NSHost *) aHost;	// Compare hosts, hosts are equal if they share at least one address
- (NSString *) name;			// return one name (arbitrarily chosen) if a host has several.
- (NSArray *) names;

@end

#endif /* _mySTEP_H_NSHost */
