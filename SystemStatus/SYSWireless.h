/* 
 SYSWireless.h
 
 Generic interface for Wireless communication.
  
 Copyright (C)	H. Nikolaus Schaller <hns@computer.org>
 Date:			2004
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#ifndef _mySTEP_H_SYSWirelessStatus
#define _mySTEP_H_SYSWirelessStatus

#import <AppKit/AppKit.h>
#import <SystemStatus/SYSDevice.h>

extern NSString *SYSWirelessInsertedNotification;		// network interface became available
extern NSString *SYSWirelessEjectedNotification;		// network interface has been ejected
extern NSString *SYSWirelessSuspendedNotification;		// network interface suspended (power off)
extern NSString *SYSWirelessResumedNotification;		// network interface resumed (powered on)
extern NSString *SYSWirelessRingingNotification;		// incoming call - notification data is calling line ID
extern NSString *SYSWirelessBusyNotification;			// other side is busy
extern NSString *SYSWirelessEstablishedNotification;	// call established
extern NSString *SYSWirelessHangupNotification;			// call was ended (by either side)
extern NSString *SYSWirelessSignalChangedNotification;	// signal strength changed considerably
extern NSString *SYSWirelessAttachedNotification;		// attached to (new) network
extern NSString *SYSWirelessDetachedNotification;		// deattached from all networks
extern NSString *SYSWirelessMessageNotification;		// (short) message received

// generic wireless interface (WLAN/GPRS/UMTS)

@interface SYSWireless : NSObject
{
@private
	SYSDevice *wlan;   // WLAN device (if present)
	SYSDevice *gprs;   // GPRS device (if present)
	BOOL inCall;			// are we in a call?
	NSString *current;		// current network
	NSFileHandle *file;		// file for accessing GPRS modem
}

+ (SYSWireless *) sharedWireless;	// shared wireless interface manager

- (void) addObserver:(id) delegate;
- (void) removeObserver:(id) delegate;
- (BOOL) wirelessCanDial;			// supports dialling
- (BOOL) wirelessDial:(NSString *) number;  // dial/call that number; YES if it was a valid number
- (BOOL) wirelessAccept;			// accept incoming call (returns NO when ringing ended before accept was called)
- (void) wirelessHangup;			// hang up/abort incoming call
- (BOOL) wirelessInCall;			// currently in call state
- (float) wirelessSignalStrength;   // relative signal strength of current network
- (float) wirelessSignalStrengthOfNetwork:(NSString *) name;	// of specified network
- (float) wirelessSignalStrengthOfNetwork:(NSString *) name andNoise:(float *) noise;	// of specified network
- (NSString *) wirelessBestNetwork; // currently best network to use
- (NSString *) wirelessNetwork;		// current network - nil if none available or detached
- (NSArray *) wirelessNetworks;		// list of current networks
- (BOOL) wirelessAttach:(NSString *) network password:(NSString *) key;   // try to attach to network
									// nil means best/any - if no network available it will attach anyway but return signal strength 0
									// password is WEP key for WLAN or PIN code for GSM SIM Card
- (BOOL) wirelessAttachAsBaseStation:(NSString *) network channel:(int) channel options:(NSDictionary *) options;	// switch to base station mode
- (void) wirelessDetach;			// detach from network and power interface off
- (BOOL) wirelessAttached;			// is attached to a network
- (BOOL) wirelessSendMessage:(NSString *) msg to:(NSString *) dest; // send message
- (void) wirelessEject;				// power interface off and prepare for eject

@end

@interface NSObject (SYSWireless)
- (void) wirelessRinging:(NSNotification *) n;
- (void) wirelessBusy:(NSNotification *) n;
- (void) wirelessEstablished:(NSNotification *) n;
- (void) wirelessHangup:(NSNotification *) n;
- (void) wirelessSignalStrengthChanged:(NSNotification *) n;
- (void) wirelessAttached:(NSNotification *) n;
- (void) wirelessDetached:(NSNotification *) n;
- (void) wirelessMessage:(NSNotification *) n;
- (void) wirelessResumed:(NSNotification *) n;
- (void) wirelessSuspended:(NSNotification *) n;
- (void) wirelessInserted:(NSNotification *) n;
- (void) wirelessEjected:(NSNotification *) n;
@end

#endif