//
//  CTCall.h
//  CoreTelephony
//
//  Created by H. Nikolaus Schaller on 04.07.11.
//  Copyright 2010 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <CoreTelephony/CoreTelephony.h>
#include <signal.h>

NSString const *CTCallStateDialing=@"CTCallStateDialing";
NSString const *CTCallStateIncoming=@"CTCallStateIncoming";
NSString const *CTCallStateConnected=@"CTCallStateConnected";
NSString const *CTCallStateDisconnected=@"CTCallStateDisconnected";

@interface CTCall (Private)
- (int) _callState;
- (void) _setCallState:(int) state;
- (void) _setPeerPhoneNumber:(NSString *) number;
@end

@interface CTCallCenter (Modem)

enum
{
	CT_STATE_INITIALIZE,
	CT_STATE_DISCONNECTED,
	CT_STATE_DIALLING,
	CT_STATE_CONNECTED,
	CT_STATE_DISCONNECTING,
	CT_STATE_FATAL_ERROR,
	CT_STATE_PIN_SENT,
	CT_STATE_PIN_NOT_ACCEPTED,
	CT_STATE_NO_SIM,
	CT_STATE_MODEM_DEAD,
};

- (void) _gotoState:(int) state;
- (void) _writeCommand:(NSString *) command andGotoState:(int) state;
- (void) _processLine:(NSString *) line;
- (void) _processData:(NSData *) line;
- (void) _dataReceived:(NSNotification *) n;
- (void) _writeCommand:(NSString *) str;

@end

@implementation CTCallCenter (Modem)

- (IBAction) orderFrontPinPanel:(id) sender
{
	if(!pinPanel)
		{ // try to load from NIB
			if(![NSBundle loadNibNamed:@"AskPin" owner:self])	// being the owner allows to connect to views in the panel
				{
				NSLog(@"can't open AskPin panel");
				return;	// ignore
				}
		}
	/// FIXME: es gibt da einen NumberFormatter!!!
	[pin setStringValue:@"****"];
	[pinPanel orderFront:self];
}
	
- (IBAction) pinOk:(id) sender;
{ // a new pin has been provided
	NSString *p=[pin stringValue];
	// store temporarily so that we can check if it returns OK or not
	// if ok, we can save the PIN
	[self _writeCommand:[NSString stringWithFormat:@"AT+CPIN=%@", p] andGotoState:CT_STATE_PIN_SENT];
}

// we may add a checkbox to reveal/hide the PIN...
// [pin setEchosBullets:YES/NO]

- (void) _gotoState:(int) s;
{
	state=s;
	NSLog(@"state=%d", state);
}

- (void) _writeCommand:(NSString *) command andGotoState:(int) s;
{
	[self _writeCommand:command];
	[self _gotoState:s];
}

- (void) _processLine:(NSString *) line;
{
#if 1
	NSLog(@"WWAN r (s=%d): %@", state, line);
#endif
	if([line hasPrefix:@"+CME ERROR: SIM not inserted"])
		{ // response to AT+CPIN?
			switch(state)
			{
				
			}
		// make [CTTelephonyNetworkInfo currentNetwork] show "NO SIM" which can be displayed in the status line
		// cancel any action
			return;
		}
	if([line hasPrefix:@"+CPIN: READY"])
		{ // response to AT+CPIN?
		// already provided, everything ok
			//[self _gotoState:0];	// FIXME: pin state is different from other states...
			return;
		}
	if([line hasPrefix:@"+CPIN: SIM PIN"])
		{ // response to AT+CPIN?
			[self orderFrontPinPanel:nil];
			return;
		}
	
	if([line hasPrefix:@"OK"])
		{
		switch(state)
			{
				
			}
		}
	if([line hasPrefix:@"ERROR"])
		{
		switch(state)
			{
				
			}
		}
	if([line hasPrefix:@"RING"])
		{
		
		}
}

- (void) _processData:(NSData *) line;
{ // we have received a new data block from the serial line
	NSString *s=[[[NSString alloc] initWithData:line encoding:NSASCIIStringEncoding] autorelease];
	NSArray *lines;
	int l;
#if 0
	NSLog(@"data=%@", line);
	NSLog(@"string=%@", s);
#endif
	if(lastChunk)
		s=[lastChunk stringByAppendingString:s];	// append to last chunk
	lines=[s componentsSeparatedByString:@"\n"];	// split into lines
	for(l=0; l<[lines count]-1; l++)
		{ // process lines except last chunk
			s=[[lines objectAtIndex:l] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\r"]];
			[self _processLine:s];
		}
#if 0
	NSLog(@"string=%@", s);
#endif
	[lastChunk release];
	lastChunk=[[lines lastObject] retain];
}

- (void) _dataReceived:(NSNotification *) n;
{
#if 0
	NSLog(@"_dataReceived %@", n);
#endif
	[self _processData:[[n userInfo] objectForKey:@"NSFileHandleNotificationDataItem"]];	// parse data as line
	[[n object] readInBackgroundAndNotify];	// and trigger more notifications
}

- (void) _writeCommand:(NSString *) str;
{
#if 1
	NSLog(@"WWAN w: %@", str);
#endif
	str=[str stringByAppendingString:@"\r"];
	[modem writeData:[str dataUsingEncoding:NSASCIIStringEncoding]];	
}

@end

@implementation CTCallCenter

// FIXME: the call center shouldn't be a singleton!
// reason: there may be multiple and different delegates for each instance

static CTCallCenter *singleton;

- (id) init
{
	if(singleton)
		{
		[self release];
		return [singleton retain];
		}
	if(self=[super init])
		{
		NSString *dev=@"/dev/ttyHS3";	// find out by scanning /sys/.../*/name for the "Application" port
		modem=[[NSFileHandle fileHandleForUpdatingAtPath:dev] retain];
		if(!modem)
			{
			NSLog(@"was not able to open device file %@", dev);
			[self release];
			return nil;
			}
		currentCalls=[[NSMutableSet alloc] initWithCapacity:10];
		signal(SIGIO, SIG_IGN);	// the HSO driver appears to send SIGIO although there was no fcntl(FASYNC)
		[[NSNotificationCenter defaultCenter] addObserver:self
												  selector:@selector(_dataReceived:)
													  name:NSFileHandleReadCompletionNotification 
													object:modem];	// make us see notifications
#if 1
		 NSLog(@"waiting for data on %@", dev);
#endif
		[modem readInBackgroundAndNotify];	// and trigger notifications
		[self _writeCommand:@"ATI" andGotoState:CT_STATE_INITIALIZE];
		[self checkPin:nil];		// could read from a keychain if specified - nil asks the user
		singleton=[self retain];	// keep once more (caller will release!)
		}
	return self;
}

- (void) dealloc
{
	NSLog(@"CTCallCenter dealloc");
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSFileHandleReadCompletionNotification
												  object:modem];	// don't observe any more
	[self _writeCommand:@"AT+CHUP"];	// be as sure as possible to hang up
	[modem closeFile];
	[currentCalls release];
	[modem release];
	[super dealloc];
	singleton=nil;
}

- (NSSet *) currentCalls; { return currentCalls; }

- (id <CTCallCenterDelegate>) delegate; { return delegate; }
- (void) setDelegate:(id <CTCallCenterDelegate>) d; { delegate=d; }

- (CTCall *) dial:(NSString *) number;
{
	// check if we are already dialling or connected
	// then either block, postpone or do something reasonable
	// check string for legal characters
	// check for non-empty
	NSString *cmd=[NSString stringWithFormat:@"ATD%@;", number];
	CTCall *call=[CTCall new];
	[call _setCallState:kCTCallStateDialing];
	[call _setPeerPhoneNumber:number];
	[self _writeCommand:cmd andGotoState:CT_STATE_DIALLING];
	[currentCalls addObject:call];
	[call release];
	return call;
}

- (BOOL) sendSMS:(NSString *) number message:(NSString *) message;
{
	// send a SMS
	return NO;
}

- (BOOL) checkPin:(NSString *) p;	// get PIN status and ask if nil and none specified yet
{
	if(!p)
		[self _writeCommand:@"AT+CPIN?" andGotoState:CT_STATE_PIN_SENT];
	else
		// AT+CPIN=number
		; // check if pin is valid (can be used for a screen saver)
	// runloop until we have received the status
	// may open popup panel to provide the PIN
	return YES;
}

@end

@implementation CTCall

- (void) dealloc
{
	if(callState != kCTCallStateDisconnected)
		[self terminate];
	[callID release];
	[peer release];
	[super dealloc];
}

- (NSString *) callID;
{
	return callID;	// should be a unique number
}

- (NSString *) callState;
{
	switch(callState)
	{
		case kCTCallStateDialing: return (NSString *) CTCallStateDialing;
		case kCTCallStateIncoming: return (NSString *) CTCallStateIncoming;
		case kCTCallStateConnected: return (NSString *) CTCallStateConnected;
		case kCTCallStateDisconnected: return (NSString *) CTCallStateDisconnected;
	}
	return @"callState: unknown";
}

- (int) _callState;
{
	return callState;
}

- (void) _setCallState:(int) state
{
	callState=state;
}

- (NSString *) peerPhoneNumber
{ // caller ID or called ID
	return peer;
}

- (void) _setPeerPhoneNumber:(NSString *) number
{
	[peer autorelease];
	peer=[number retain];
}

- (void) terminate;
{
	CTCallCenter *center=[[CTCallCenter new] autorelease];
	[center _writeCommand:@"AT+CHUP\n" andGotoState:CT_STATE_DISCONNECTING];
	// FIXME: shouldn't we wait for the OK?
	callState=kCTCallStateDisconnected;
}

- (void) hold;
{
	// anytime
}

- (void) reject;	// if incoming
{
	// if CTCallStateIncoming
}

- (void) divert;
{
	// if CTCallStateIncoming
}

// set 
- (void) handsfree:(BOOL) flag;	// switch on handsfree speakers (or headset?)
{
	// if CTCallStateConnected
	// switch amixer
}

- (void) mute:(BOOL) flag;	// mute microphone
{
	// if CTCallStateConnected
	// switch amixer
}

- (void) volume:(float) value;	// general volume (earpiece, handsfree, headset)
{
	// if CTCallStateConnected
	// switch amixer
}

- (void) sendDTMF:(NSString *) digit
{ // 0..9, a-c, #, *
	if([digit length] != 1)
		return;	// we could loop over all digits with a little delay
	// check if this is a valid digit
	NSLog(@"send DTMF: %@", digit);
	[center _writeCommand:[NSString stringWithFormat:@"AT+VTS=%@\n", digit]];
}

@end

@implementation CTCarrier

#if 0

- (NSString *) carrierName;
- (NSString *) isoCountryCode;
- (NSString *) mobileCountryCode;
- (NSString *) mobileNetworkCode;
- (BOOL) allowsVOIP;

- (float) strength;	// signal strength (in db)
- (float) networkType;	// 2.0, 2.5, 3.0, 3.5 etc.
- (NSString *) cellID;	// current cell ID
- (BOOL) canChoose;	// is permitted to select (if there are alternatives)
- (void) choose;	// make the current carrier if there are several options to choose

- (id) initWithName:(NSString *) name isoCode etc. --- oder initWithResponse:

- (void) _updateStrength:(float) strength networkType:(float) type cellID:(NSString *) cell;
{ // process response of a regular AT command to get this info - as long as we stay with the same network
	
}

#endif

@end

@implementation CTTelephonyNetworkInfo

// wie werden Updates auf AT-Befehle angewendet - dazu erst mal die Befehle sammeln und verstehen

- (CTCarrier *) subscriberCellularProvider;
{
	return subscriberCellularProvider;	// FIXME: das sollte einfach ein Index in den carrier-Set sein!
}

- (void) _setSubscriberCellularProvider:(CTCarrier *) provider;
{
	if(subscriberCellularProvider != provider)
		{
		[subscriberCellularProvider release];
		subscriberCellularProvider=[provider retain];
		[delegate subscriberCellularProviderDidUpdate:provider];
		}
}

- (id <CTNetworkInfoDelegate>) delegate;
{
	return delegate;
}

- (void) setDelegate:(id <CTNetworkInfoDelegate>) del;
{
	delegate=del;
}

- (CTCarrier *) currentNetwork;
{ // changes while roaming
	return currentNetwork;
}

- (NSSet *) networks;
{ // list of networks being available
	return nil;
}

@end

