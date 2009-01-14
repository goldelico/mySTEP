/* 
 SYSDeviceStatus.h
 
 Generic interface to removable devices (e.g. PCMCIA).

 Copyright (C)	H. Nikolaus Schaller <hns@computer.org>
 Date:			2004
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#ifndef _mySTEP_H_SYSDeviceStatus
#define _mySTEP_H_SYSDeviceStatus

#import <AppKit/AppKit.h>

extern NSString *SYSDeviceInsertedShouldLockNotification;	// device was inserted - first pass: this allows one observer to lock on first pass and check another on second
extern NSString *SYSDeviceInsertedNotification;		// device was inserted
extern NSString *SYSDeviceEjectedNotification;			// device was ejected (or unplugged)
extern NSString *SYSDeviceSuspendedNotification;		// device was deactivated
extern NSString *SYSDeviceResumedNotification;			// device was activated

@interface SYSDevice : NSObject
{
@private
	NSMutableDictionary *deviceInfo;
	BOOL locked;		// somebody has locked the device
	BOOL wasInserted;	// previous cycle's status
	BOOL wasSuspended;	// previous cycle's status
}

+ (NSArray *) deviceList;   // array of all devices
+ (void) updateDeviceList:(BOOL) flag;	// enable/disable device polling loop - default is NO
+ (void) addObserver:(id) delegate;		// make delegate receive notifications (there may be more than one!)
+ (void) removeObserver:(id) delegate;	// make delegate no longer receive notifications
+ (SYSDevice *) deviceByIndex:(unsigned) index;

- (BOOL) isLocked;	// locked by someone?
- (void) lock:(BOOL) flag;
- (NSDictionary *) deviceInfo;
- (NSString *) deviceName;
- (NSString *) deviceDriver;
- (NSString *) deviceManufacturer;
- (NSString *) devicePath;  // I/O device path (/dev)
- (NSString *) mountPath;	// mount path for memory devices (/mnt)
- (NSString *) deviceType;	// PCMCIA, SD, USB
- (BOOL) eject;				// eject if removable
- (BOOL) insert;			// not really useful - except to note that device has not really been removed and can be mounted again
- (BOOL) suspend;			// power down
- (BOOL) resume;			// power up
- (BOOL) isRemovable;
- (BOOL) isSuspended;
- (BOOL) isInserted;
- (BOOL) isReady;			// inserted and not suspended
- (NSFileHandle *) open:(NSString *) stty;	// open device file - and issue stty command if stty != nil
@end

@interface NSObject (SYSDevice)
- (void) deviceShouldLock:(NSNotification *) n;
- (void) deviceInserted:(NSNotification *) n;
- (void) deviceEjected:(NSNotification *) n;
- (void) deviceSuspended:(NSNotification *) n;
- (void) deviceResumed:(NSNotification *) n;
@end

#endif
