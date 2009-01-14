/* 
 SYSNetwork.h
 
 Generic network configuration interface.
 
 Copyright (C)	H. Nikolaus Schaller <hns@computer.org>
 Date:			2004
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#ifndef _mySTEP_H_SYSNetworkStatus
#define _mySTEP_H_SYSNetworkStatus

#import <AppKit/AppKit.h>

extern NSString *SYSNetworkNewInterfaceFoundNotification;	// new network interface became available
extern NSString *SYSNetworkStatusChangedNotification;		// status has changed

// define standard attributes for an interface
// e.g. IP address, subnet mask, etc.

/* FIXME: handle "Network Locations"
http://www.net.princeton.edu/mac/network-config-x/
*/

typedef enum _SYSNetworkStatus
{
	NSSYSNetworkDisabled=0,
	NSSYSNetworkDown,
	NSSYSNetworkIntermediate,
	NSSYSNetworkUp,
} SYSNetworkStatus;

@interface SYSNetwork : NSObject
{
	@private
	BOOL _changed;
	NSMutableDictionary *_attributes;
}

+ (void) findNetworkInterfaces;				// sends a notification if we found a new interface
+ (NSArray *) networkInterfacesList;		// list of SYSNetwork objects
+ (NSArray *) networkInterfaceNamesList;	// list of names
+ (SYSNetwork *) networkInterfaceByName:(NSString *) name forLocation:(NSString *) loc;	// nil loc -> current

+ (NSArray *) networkLocationsList;			// list of names - includes @"automatic" as the first entry
+ (void) selectLocation:(NSString *) loc;
+ (NSString *) selectedLocation;
+ (BOOL) createNetworkLocation:(NSString *) name fromLocation:(NSString *) pattern;	// must be unique new location name
+ (BOOL) removeNetworkLocation:(NSString *) name;	// can't delete last one

- (void) apply;		// write to sytem configuration (i.d. notify configd)
- (BOOL) changed;	// has been changed
- (id) valueForKey:(NSString *) key;
- (void) setValue:(id) val forKey:(NSString *) key;
- (NSString *) name;	// name of network (interface)
- (SYSNetworkStatus) networkStatus;	// get network status

@end

#endif
