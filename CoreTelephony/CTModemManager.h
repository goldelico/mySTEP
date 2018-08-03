//
//  CTModemManager.h
//  CoreTelephony
//
//  Created by H. Nikolaus Schaller on 29.09.11.
//  Copyright 2011 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum _CTPinStatus
{
	CTPinStatusUnknown = 0,
	CTPinStatusNoSIM,
	CTPinStatusUnlocked,
	CTPinStatusPINRequired,
	CTPinStatusAirplaneMode,
} CTPinStatus;

@interface CTModemManager : NSObject
{
	NSFileHandle *ttyPort;
	NSArray *modes;
	NSString *lastChunk;	// for handling strings that arrive in chunks
	NSMutableArray /*nonretained*/ *response;
	NSString *error;		// updated if runATCommand returns CTModemError
	IBOutlet NSPanel *pinPanel;
	IBOutlet NSTextField *message;
	IBOutlet NSSecureTextField *pin;
	IBOutlet NSButton *okButton;
/* temporary */	IBOutlet NSPanel *pinKeypadPanel;	// until we have a system-wide keyboard or HWR
	id /*nonretained*/ target;	// for current AT command
	id /*nonretained*/ unsolicitedTarget;
	SEL action;	// for current AT command
	SEL unsolicitedAction;
	CTPinStatus pinStatus;
	NSArray *_ati;	// modem identification
	enum {
		CTModemTimeout,
		CTModemError,
		CTModemOk,
	} status;	
	BOOL done;	// last AT command is done
	BOOL atstarted;	// last AT command echo received
}

+ (CTModemManager *) modemManager;
+ (void) enableLog:(BOOL) flag;

- (BOOL) isGTM601;
- (BOOL) isPxS8;

// FIXME: separate public and private API

- (void) setUnsolicitedTarget:(id) target action:(SEL) action;

- (int) runATCommand:(NSString *) cmd target:(id) t action:(SEL) a timeout:(NSTimeInterval) seconds;
- (int) runATCommand:(NSString *) cmd target:(id) target action:(SEL) action;	// default timeout = 2 seconds
- (int) runATCommand:(NSString *) cmd;
- (NSArray *) runATCommandReturnResponse:(NSString *) cmd;

- (NSString *) error;
- (BOOL) isAvailable;

- (CTPinStatus) pinStatus;
- (BOOL) sendPIN:(NSString *) pin;	// try to unlock; if ok, returns YES but use pinStatus to wait for real unlock

- (IBAction) orderFrontPinPanel:(id) sender;
- (IBAction) pinOk:(id) sender;
- (IBAction) pinKey:(id) sender;

- (BOOL) checkPin:(NSString *) pin;	// get PIN status and ask if nil and none specified yet - must be called to enable the modem!
- (BOOL) changePin:(NSString *) pin toNewPin:(NSString *) new;

- (void) setupPCM;	// Run before setting up the call. Modem mutes all voice signals if we do that *during* a call
- (void) setupVoice;
- (void) terminatePCM;


- (void) reset;	// reset modem to CTPinStatusPINRequired
- (BOOL) setAirplaneMode:(BOOL) flag;

@end
