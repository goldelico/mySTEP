//
//  CoreDevice.h
//  CoreDevice
//
//  Created by H. Nikolaus Schaller on 14.11.11.
//  Copyright 2011 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// modeled similar to UIDevice

typedef enum _UIDeviceBatteryState
{
	UIDeviceBatteryStateUnknown,
	UIDeviceBatteryStateUnplugged,
	UIDeviceBatteryStateCharging,
	UIDeviceBatteryStateFull,
} UIDeviceBatteryState;

typedef enum _UIDeviceOrientation
{
	UIDeviceOrientationUnknown,
	UIDeviceOrientationPortrait,
	UIDeviceOrientationPortraitUpsideDown,
	UIDeviceOrientationLandscapeLeft,
	UIDeviceOrientationLandscapeRight,
	UIDeviceOrientationFaceUp,
	UIDeviceOrientationFaceDown
} UIDeviceOrientation;

/* not implemented - QuantumSTEP is uniform
typedef enum _UIUserInterfaceIdiom
 {
	UIUserInterfaceIdiomPhone,
	UIUserInterfaceIdiomPad,
} UIUserInterfaceIdiom;
 */

extern NSString *UIDeviceBatteryLevelDidChangeNotification;
extern NSString *UIDeviceBatteryStateDidChangeNotification;
extern NSString *UIDeviceOrientationDidChangeNotification;
extern NSString *UIDeviceProximityStateDidChangeNotification;

@interface UIDevice : NSObject
{
	UIDeviceBatteryState _previousBatteryState;
	float _previousBatteryLevel;
	UIDeviceOrientation _previousOrientation;
	BOOL _previousProximityState;
	BOOL batteryMonitoringEnabled;
	BOOL proximityMonitoringEnabled;
	BOOL generatingDeviceOrientationNotifications;
}

+ (UIDevice *) currentDevice;

- (float) batteryLevel;
- (BOOL) isBatteryMonitoringEnabled;
- (void) setBatteryMonitoringEnabled:(BOOL) state;
- (UIDeviceBatteryState) batteryState;
- (NSTimeInterval) remainingTime;

- (BOOL) isMultitaskingSupported;	/* always YES */

- (NSString *) localizedModel;
- (NSString *) model;	/* e.g. Zaurus, GTA04 */
- (NSString *) name;
- (NSString *) systemName;	/* @"QuantumSTEP" */
- (NSString *) systemVersion;

- (BOOL) isGeneratingDeviceOrientationNotifications;
- (void) beginGeneratingDeviceOrientationNotifications;
- (void) endGeneratingDeviceOrientationNotifications;

- (UIDeviceOrientation) orientation;
- (BOOL) isProximityMonitoringEnabled;
- (void) setProximityMonitoringEnabled:(BOOL) state;
- (BOOL) proximityState;

// -(UIUserInterfaceIdiom) userInterfaceIdiom;

- (void) playInputClick;

@end
