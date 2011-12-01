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
} CTPinStatus;

@interface CTModemManager : NSObject
{
	NSFileHandle *modem;
	NSString *lastChunk;	// for handling strings that arrive in chunks
	NSMutableString /*nonretained*/ *response;
	NSString *error;		// updated if runATCommand returns CTModemError
	IBOutlet NSPanel *pinPanel;
	IBOutlet NSTextField *message;
	IBOutlet NSSecureTextField *pin;
	IBOutlet NSButton *okButton;
/* temporary */	IBOutlet NSPanel *pinKeypadPanel;	// until we have a system-wide keyboard or HWR
	id /*nonretained*/ target;
	id /*nonretained*/ unsolicitedTarget;
	SEL action;
	SEL unsolicitedAction;
	CTPinStatus pinStatus;
	enum {
		CTModemTimeout,
		CTModemError,
		CTModemOk,
	} status;	
	BOOL done;	// last AT command is done
	BOOL atstarted;	// last AT command echo received
}

+ (CTModemManager *) modemManager;

- (void) setUnsolicitedTarget:(id) target action:(SEL) action;

- (int) runATCommand:(NSString *) cmd target:(id) t action:(SEL) a timeout:(NSTimeInterval) seconds;
- (int) runATCommand:(NSString *) cmd target:(id) target action:(SEL) action;	// default timeout = 2 seconds
- (int) runATCommand:(NSString *) cmd;
- (NSString *) runATCommandReturnResponse:(NSString *) cmd;

- (NSString *) error;

- (CTPinStatus) pinStatus;
- (BOOL) sendPIN:(NSString *) pin;	// try to unlock
- (BOOL) reset;	// reset modem to CTPinStatusPINRequired

- (IBAction) orderFrontPinPanel:(id) sender;
- (IBAction) pinOk:(id) sender;
/* temporary */- (IBAction) pinKey:(id) sender;

- (BOOL) checkPin:(NSString *) pin;	// get PIN status and ask if nil and none specified yet
- (BOOL) changePin:(NSString *) pin toNewPin:(NSString *) new;

- (BOOL) _openHSO;	// (re)open FileHandle for AT command stream
- (void) _processLine:(NSString *) line;
- (void) _processData:(NSData *) line;
- (void) _dataReceived:(NSNotification *) n;
- (void) _writeCommand:(NSString *) str;

@end
