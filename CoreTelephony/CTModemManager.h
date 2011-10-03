//
//  CTModemManager.h
//  CoreTelephony
//
//  Created by H. Nikolaus Schaller on 29.09.11.
//  Copyright 2011 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>


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
	id /*nonretained*/ target;
	id /*nonretained*/ unsolicitedTarget;
	SEL action;
	SEL unsolicitedAction;
	enum {
		CTModemTimeout,
		CTModemError,
		CTModemOk,
	} status;	
	BOOL done;	// last AT command is done
	BOOL atstarted;	// last AT command echo received
	BOOL wwan;
}

+ (CTModemManager *) modemManager;

- (void) setUnsolicitedTarget:(id) target action:(SEL) action;

- (int) runATCommand:(NSString *) cmd target:(id) target action:(SEL) action;
- (int) runATCommand:(NSString *) cmd;
- (NSString *) runATCommandReturnResponse:(NSString *) cmd;

- (NSString *) error;

- (IBAction) orderFrontPinPanel:(id) sender;
- (IBAction) pinOk:(id) sender;
- (BOOL) checkPin:(NSString *) pin;	// get PIN status and ask if nil and none specified yet

- (void) connectWWAN:(BOOL) flag;	// 0 to disconnect

- (void) _processLine:(NSString *) line;
- (void) _processData:(NSData *) line;
- (void) _dataReceived:(NSNotification *) n;
- (void) _writeCommand:(NSString *) str;

@end
