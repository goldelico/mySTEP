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

@interface CTCallCenter (Private)

enum
{
	CT_STATE_DEFAULT,
	CT_STATE_ATI,			// ATI sent
	CT_STATE_ATD,			// ATD sent
	CT_STATE_ATCHUP,		// AT+CHUP sent
	CT_STATE_ATCPIN,		// AT+CPIN="" sent
	CT_STATE_ATOBLS,		// AT_OBLS
	CT_STATE_ATOBSI,		// AT_OBSI
	CT_STATE_ATONCI,		// AT_ONCI?
};

- (void) _gotoState:(int) state;
- (void) _writeCommand:(NSString *) command andGotoState:(int) state;
- (void) _processLine:(NSString *) line;
- (void) _processData:(NSData *) line;
- (void) _dataReceived:(NSNotification *) n;
- (void) _writeCommand:(NSString *) str;

@end

@interface CTCarrier (Private)

- (void) _setCarrierName:(NSString *) n;
- (void) _setStrength:(float) s;
- (void) _setdBm:(float) s;
- (void) _setCellID:(NSString *) n;

@end


// FIXME: the call center shouldn't be a singleton!
// reason: there may be multiple and different delegates for each instance

static CTCallCenter *callCenter;
static CTTelephonyNetworkInfo *networkInfo;

@implementation CTCallCenter (Private)

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
	[self _writeCommand:[NSString stringWithFormat:@"AT+CPIN=%@", p] andGotoState:CT_STATE_ATCPIN];
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
	if([line hasPrefix:@"+CPIN: READY"])
		{ // response to AT+CPIN?
		// already provided, everything ok
			//[self _gotoState:0];	// FIXME: pin state is different from other states...
			return;
		}
	if([line hasPrefix:@"+CPIN: SIM PIN"] || [line hasPrefix:@"+CME ERROR: SIM PIN required"])
		{ // response to AT+CPIN?
			[self orderFrontPinPanel:nil];
			return;
		}
	
	if([line hasPrefix:@"OK"])
		{
		switch(state) {
			case CT_STATE_ATI:
				[self _gotoState:CT_STATE_DEFAULT];
				return;
			case CT_STATE_ATCPIN:
				[self _writeCommand:@"AT_OSIMOP" andGotoState:CT_STATE_DEFAULT];	// ask for operator
				return;
			case CT_STATE_ATD:
				// notify that we are connected
				// enable voice etc.
				[self _gotoState:CT_STATE_DEFAULT];
				return;
			case CT_STATE_ATOBLS:
				// FIXME: add delay
				[self _writeCommand:@"AT_OBSI" andGotoState:CT_STATE_ATOBSI];
				return;
			case CT_STATE_ATOBSI:
				// FIXME: add delay
				[self _writeCommand:@"AT_ONCI?" andGotoState:CT_STATE_ATONCI];	// neighbouring base stations
				return;
			case CT_STATE_ATONCI:
				// FIXME: add delay
				// should go back to state DEFAULT and add a delay
				[self _writeCommand:@"AT_OBLS" andGotoState:CT_STATE_ATOBLS];	// get SIM status (removed etc.)
				return;
			default:
				return;
			}
		}
	if([line hasPrefix:@"ERROR"])
		{
		switch(state) {
			case CT_STATE_ATD:
				// notify that we are connected
				// enable voice etc.
				return;
			case CT_STATE_ATCHUP:
				;
			}
		NSLog(@"unsolicited error");
		return;
		}
	if([line hasPrefix:@"+CME ERROR:"])
		{
		if([line hasPrefix:@"+CME ERROR: SIM not inserted"])
			{ // response to AT+CPIN?
				switch(state)
				{
				
				}
				// make [CTTelephonyNetworkInfo currentNetwork] show "NO SIM" which can be displayed in the status line
				// cancel any action
				return;
			}
		}
	if([line hasPrefix:@"RING"])
		{
		
		}
	switch(state) {
		case CT_STATE_ATI:	// ATI result line
			return;
	}
	if([line hasPrefix:@"_OERCN:"])
		{ // remaining pin and puk retries - _OERCN: <PIN retries>, <PUK retries>
			// write to GUI
		}
	if([line hasPrefix:@"_OSIMOP:"])
		{ // home plnm - _OSIMOP: “<long_op>”,”<short_op>”, ”<MCC_MNC>”
			CTCarrier *carrier=[networkInfo subscriberCellularProvider];
			NSScanner *sc=[NSScanner scannerWithString:line];
			NSString *name=@"unknown";
			[sc scanString:@"_OSIMOP: \"" intoString:NULL];
			[sc scanUpToString:@"\"" intoString:&name];
			[carrier _setCarrierName:name];
			NSLog(@"carrier name=%@ delegate=%@", name, [networkInfo delegate]);
			[[networkInfo delegate] subscriberCellularProviderDidUpdate:carrier];
			return;
		}
	if([line hasPrefix:@"_OPON:"])
		{ // current visited network - _OPON: <cs>,<oper>,<src>
			// notify through CTCarrier/CTTelephonyNetworkInfo			
		}
	if([line hasPrefix:@"_OSIGQ:"])
		{ // signal quality - _OSIGQ: 2*<rssi>-113dBm,<ber> (ber=99)
			CTCarrier *carrier=[networkInfo currentNetwork];
			float dbm=[[line substringFromIndex:8] floatValue];
			if(dbm == 99.9)	dbm=0.0;
			[carrier _setdBm:dbm];
			[[networkInfo delegate] signalStrengthDidUpdate:carrier];
			return;
		}
	if([line hasPrefix:@"_OEANT:"])
		{ // antenna level - _OEANT: <n> (0..5 but 4 is the maximum ever reported)
			CTCarrier *carrier=[networkInfo currentNetwork];
			float strength=[[line substringFromIndex:8] floatValue]/4.0;
			if(strength > 1.0) strength=1.0;	// limit
			[carrier _setStrength:strength];
			[[networkInfo delegate] signalStrengthDidUpdate:carrier];
			return;
		}
	if([line hasPrefix:@"_ONCI:"])
		{ // neighbour cell info
			// notify through CTCarrier/CTTelephonyNetworkInfo
		}
	if([line hasPrefix:@"_OBSI:"])
		{ // base station location - _OBSI=<id>,<lat>,<long>
			// notify through CTCarrier/CTTelephonyNetworkInfo
		}
	if(![line hasPrefix:@"AT"])	// not an echoed AT command
		NSLog(@"unexpected message from Modem: %@", line);
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

- (id) init
{
	if(callCenter)
		{
		[self release];
		return [callCenter retain];
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
		[self _writeCommand:@"AT_OPONI=1"];	// report current network registration
		[self _writeCommand:@"AT_OSQI=1"];	// report signal quality in dBm
		[self _writeCommand:@"AT_OEANT=1"];	// report quality level (0..4 or 5)
		[self _writeCommand:@"AT_OUWCTI=1"];	// report available cell data rate		
		[self _writeCommand:@"ATI" andGotoState:CT_STATE_ATI];
		[self checkPin:nil];		// could read from a keychain if specified - nil asks the user
		callCenter=[self retain];	// keep once more (caller will release!)
		}
	return self;
}

- (void) dealloc
{ // should not be possible for a singleton!
	NSLog(@"CTCallCenter dealloc");
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSFileHandleReadCompletionNotification
												  object:modem];	// don't observe any more
	[self _writeCommand:@"AT+CHUP"];	// be as sure as possible to hang up
	[modem closeFile];
	[currentCalls release];
	[modem release];
	[super dealloc];
	callCenter=nil;
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
	[self _writeCommand:cmd andGotoState:CT_STATE_ATD];
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
		[self _writeCommand:@"AT_OERCN\nAT+CPIN?" andGotoState:CT_STATE_ATCPIN];
	else
		// AT+CPIN=number
		; // check if pin is valid (can be used for a screen saver)
	// runloop until we have received the status
	// may open popup panel to provide the PIN
	return YES;
}

// FIXME: in State-Machine einbauen - ein Befehl fertig triggert den nächsten...
// und letzter triggert nach Timeout den ersten
// also eine polling-queue

- (void) timer
{ // timer triggered commands
	[self _writeCommand:@"AT_OBLS"];	// get SIM status (removed etc.)
	// wait for being processed
	[self _writeCommand:@"AT_OBSI"];	// base station location
	// wait for being processed
	[self _writeCommand:@"AT_ONCI?"];	// neighbouring base stations
	// wait for being processed
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
	[center _writeCommand:@"AT+CHUP" andGotoState:CT_STATE_ATCHUP];
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
	[callCenter _writeCommand:[NSString stringWithFormat:@"AT+VTS=%@", digit]];
}

@end

@implementation CTCarrier

- (void) dealloc
{
	[carrierName release];
	[isoCountryCode release];
	[mobileCountryCode release];
	[carrierName release];
	[cellID release];
	[super dealloc];
}

- (NSString *) carrierName; { return carrierName; }
- (NSString *) isoCountryCode; { return isoCountryCode; }
- (NSString *) mobileCountryCode; { return mobileCountryCode; }
- (NSString *) mobileNetworkCode; { return mobileNetworkCode; }
- (BOOL) allowsVOIP; { return YES; }

- (float) strength; { return strength; }	// signal strength (0..1.0)
- (float) dBm; { return dBm; }		// signal strength (in dBm)
- (float) networkType; { return networkType; }	// 2.0, 2.5, 3.0, 3.5 etc.
- (NSString *) cellID;	 { return cellID; }// current cell ID
- (BOOL) canChoose; { return YES; }// is permitted to select (if there are alternatives)

// - (id) initWithName:(NSString *) name isoCode etc. --- oder initWithResponse:

- (void) _setCarrierName:(NSString *) n; { [carrierName autorelease]; carrierName=[n retain]; }
- (void) _setStrength:(float) s; { strength=s; }
- (void) _setdBm:(float) s; { dBm=s; }
- (void) _setCellID:(NSString *) n; { [cellID autorelease]; cellID=[n retain]; }

- (void) choose;
{ // make the current carrier if there are several options to choose
	return strength;
}

@end

@implementation CTTelephonyNetworkInfo

// wie werden Updates auf AT-Befehle angewendet? - dazu erst mal die Befehle sammeln und verstehen

- (id) init
{
	if(!networkInfo)
		{
		networkInfo=self;
		subscriberCellularProvider=[CTCarrier new];	// create default entry
		[subscriberCellularProvider _setCarrierName:@"No SIM"];	// default if we can't read the SIM
		}
	else
		{
		[self release];
		[networkInfo retain];
		}
	return networkInfo;
}

- (void) dealloc
{ // should not be possible for a singleton!
	NSLog(@"CTTelephonyNetworkInfo dealloc");
	[subscriberCellularProvider release];
	[super dealloc];
	networkInfo=nil;
}

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
	// ask AT+COPS?
	return nil;
}

@end

