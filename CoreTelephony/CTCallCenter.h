//
//  CTCallCenter.h
//  CoreTelephony
//
//  Created by H. Nikolaus Schaller on 04.07.11.
//  Copyright 2011 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CTCall;

// extension

@protocol CTCallCenterDelegate
- (BOOL) handleCallEvent:(CTCall *) call;	// should ring and -accept/-discard etc. depending on -callState
@end

@interface CTCallCenter : NSObject
{
	NSFileHandle *modem;	// access to the modem AT file
	NSString *lastChunk;	// for handling strings that arrive in chunks
	int state;		// internal state
	IBOutlet NSPanel *pinPanel;
	IBOutlet NSSecureTextField *pin;
	IBOutlet NSButton *okButton;
	
	NSMutableSet *currentCalls;
	id <CTCallCenterDelegate> delegate;
}

// @property (nonatomic, copy) void (^callEventHandler)(CTCall *)

- (NSSet *) currentCalls;

- (IBAction) orderFrontPinPanel:(id) sender;
- (IBAction) pinOk:(id) sender;

@end

@interface CTCallCenter (Extensions)

- (id <CTCallCenterDelegate>) delegate;
- (void) setDelegate:(id <CTCallCenterDelegate>) d;

- (CTCall *) dial:(NSString *) number;
- (BOOL) sendSMS:(NSString *) number message:(NSString *) message;

- (BOOL) checkPin:(NSString *) pin;	// get PIN status and ask if nil and none specified yet

@end
