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
	UIDeviceBatteryStateCharging,	// on USB charger
	UIDeviceBatteryStateFull,
	UIDeviceBatteryStateACCharging,	// on AC charger
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

/* not implemented - QuantumSTEP is uniform over all devices
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

- (BOOL) isMultitaskingSupported;	/* always YES */

// - (NSUUID *) identifierForVendor;
- (NSString *) localizedModel;
- (NSString *) model;	/* e.g. Zaurus, GTA04 */
- (NSString *) name;
- (NSString *) systemName;	/* @"QuantumSTEP" */
- (NSString *) systemVersion;
// - (NSString *) uniqueIdentifier;

- (BOOL) isGeneratingDeviceOrientationNotifications;
- (void) beginGeneratingDeviceOrientationNotifications;
- (void) endGeneratingDeviceOrientationNotifications;

- (UIDeviceOrientation) orientation;
- (BOOL) isProximityMonitoringEnabled;
- (void) setProximityMonitoringEnabled:(BOOL) state;
- (BOOL) proximityState;

// -(UIUserInterfaceIdiom) userInterfaceIdiom;

- (void) playInputClick;
- (void) playVibraCall;

@end

@interface UIDevice (Extensions)

- (NSTimeInterval) remainingTime;
- (float) batteryVoltage;	// in volt
- (float) batteryDischargingCurrent;	// in Ampere (negative = charging)
- (float) batteryHealth;	// full capacity vs. design capacity
- (unsigned int) chargingCycles;
- (float) chargerVoltage;
- (BOOL) checkCable;	// if user should check charging cable

@end

// should be provided through #import <AudioToolbox/AudioToolbox.h>
typedef unsigned int SystemSoundID;
#define kSystemSoundID_FlashScreen 0xffe
#define kSystemSoundID_Vibrate 0xfff
#define kSystemSoundID_UserPreferredAlert = 0x1000
void AudioServicesPlayAlertSound(SystemSoundID sound);
void AudioServicesPlaySystemSound(SystemSoundID sound);
void AudioServicesPlaySystemSoundWithVibration(SystemSoundID sound, id arg, NSDictionary *pattern);
void AudioServicesStopSystemSound(SystemSoundID sound);
