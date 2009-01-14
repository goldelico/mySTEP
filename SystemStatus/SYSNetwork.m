/* 
 Network interface driver.
 
 Copyright (C)	H. Nikolaus Schaller <hns@computer.org>
 Date:			2004
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

/*
 On Unix, network drivers are accessed through the ifconfig command
 */ 

#import <SystemStatus/SYSNetwork.h>

NSString *SYSNetworkNewInterfaceFoundNotification=@"SYSNetworkNewInterfaceFoundNotification";
NSString *SYSNetworkStatusChangedNotification=@"SYSNetworkStatusChangedNotification";

static NSMutableDictionary *_locations;	// dictionary of locations - each one contains a list of interfaces and settings
static NSString *_currentLocation;

#define INTERFACES_PLIST @"/Library/Preferences/SystemConfiguration/NetworkInterfaces.plist"

#define Interfaces @"Interfaces"	// array of interfaces (dictionary)
#define SYSInterfaceName @"BSD Name"
#define SYSInterfaceBuiltin @"IOBuiltin"	// boolean
#define SYSInterfaceType @"IOInterfaceType"
#define SYSInterfaceUnit @"IOInterfaceUnit"
#define SYSInterfaceLocation @"IOInterfaceLocation"
#define SYSInterfaceMACAddress @"IOInterfaceMACAddress"	// NSData

#define LOCATIONS_PLIST @"/Library/Preferences/SystemConfiguration/preferences.plist"
#define SYSCurrentSet @"CurrentSet"
#define SYSNetworkServices @"SYSNetworkServices"

@implementation SYSNetwork

+ (void) initialize
{
	_locations=[[NSMutableDictionary dictionaryWithContentsOfFile:LOCATIONS_PLIST] retain];
	if(!_locations)
		_locations=[[NSMutableDictionary alloc] initWithCapacity:10];
	if(![_locations objectForKey:@"NetworkServices"])
		[_locations setObject:[NSMutableDictionary dictionaryWithCapacity:10] forKey:@"NetworkServices"];
	_currentLocation=[_locations objectForKey:@"CurrentSet"];
	if(!_currentLocation)
		_currentLocation=@"Automatic";
}

+ (void) findNetworkInterfaces;
{ // send a notification if we found a new interface
	// do a "ifconfig", parse results and compare to known interfaces
}

+ (NSArray *) networkInterfacesList;
{ // list of SYSNetwork objects
	return nil;
}

+ (NSArray *) networkInterfaceNamesList;
{ // list of names
	return nil;
}

+ (SYSNetwork *) networkInterfaceByName:(NSString *) name forLocation:(NSString *) loc;
{ // nil loc -> current
	return nil;
}

+ (NSArray *) networkLocationsList;
{ // list of names - always includes @"automatic" as the first entry
	return nil;
}

+ (void) selectLocation:(NSString *) loc;
{
	[_currentLocation autorelease];
	_currentLocation=[loc retain];
}

+ (NSString *) selectedLocation;
{
	return _currentLocation;
}

+ (BOOL) createNetworkLocation:(NSString *) name fromLocation:(NSString *) pattern;
{ // must be unique new location name
	if(!pattern)
		pattern=_currentLocation;
	return NO;
}

+ (BOOL) removeNetworkLocation:(NSString *) name;
{ // can't delete @"automatic"
	if([name isEqualToString:@"automatic"])
		return NO;
	return NO;
}

- (void) apply;
{ // write to sytem configuration
	// ifconfig ...
}

- (void) save;
{ // write to sytem configuration
	[_locations writeToFile:LOCATIONS_PLIST atomically:YES];
}

- (BOOL) changed;
{ // has been changed
	return _changed;
}

- (id) valueForKey:(NSString *) key;
{
	return [_attributes objectForKey:key];
}

- (void) setValue:(id) val forKey:(NSString *) key;
{
	[_attributes setObject:val forKey:key];
	_changed=YES;
}

- (NSString *) name;
{ // name of network interface
	return [self valueForKey:@"IFNAME"];
}

- (SYSNetworkStatus) networkStatus;
{ // get network status (red, yellow, green)
	return 0;
}

@end
