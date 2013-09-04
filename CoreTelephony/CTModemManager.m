//
//  CTModemManager.m
//  CoreTelephony
//
//  Created by H. Nikolaus Schaller on 29.09.11.
//  Copyright 2011 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "CTPrivate.h"

#include <signal.h>

@interface CTModemManager (Private)

- (void) _openHSO;	// (re)open FileHandle for AT command stream
- (void) _closeHSO;
- (void) _processLine:(NSString *) line;
- (void) _processData:(NSData *) line;
- (void) _dataReceived:(NSNotification *) n;
- (void) _writeCommand:(NSString *) str;

@end

@implementation CTModemManager

/* NIB-safe Singleton pattern */

#define SINGLETON_CLASS		CTModemManager
#define SINGLETON_VARIABLE	modemManager
#define SINGLETON_HANDLE	modemManager

/* static part */

static SINGLETON_CLASS * SINGLETON_VARIABLE = nil;

+ (id) allocWithZone:(NSZone *)zone
{
	//   @synchronized(self)
	{
	if (! SINGLETON_VARIABLE)
		return [super allocWithZone:zone];
	}
    return SINGLETON_VARIABLE;
}

- (id) copyWithZone:(NSZone *)zone { return self; }

- (id) retain { return self; }

- (unsigned) retainCount { return UINT_MAX; }

- (void) release {}

- (id) autorelease { return self; }

+ (SINGLETON_CLASS *) SINGLETON_HANDLE
{
	//   @synchronized(self)
	{
	if (! SINGLETON_VARIABLE)
		[[self alloc] init];
    }
    return SINGLETON_VARIABLE;
}

/* customized part */

- (id) init
{
	//    Class myClass = [self class];
	//    @synchronized(myClass)
	{
	if (!SINGLETON_VARIABLE && (self = [super init]))
		{
		SINGLETON_VARIABLE = self;
		/* custom initialization here */
		[self _openHSO];	// try to connect
		}
    }
    return self;
}

- (void) dealloc
{ // should not happen for a singleton!
	NSLog(@"CTModemManager dealloc");
	abort();
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSFileHandleReadCompletionNotification
												  object:modem];	// don't observe any more
	[self _writeCommand:@"AT+CHUP"];	// be as sure as possible to hang up
	[self _closeHSO];
	[error release];
	[lastChunk release];
	[super dealloc];
	modemManager=nil;
}

- (void) _closeHSO;
{
	if(modem)
		{ // close previous modem
			[[NSNotificationCenter defaultCenter] removeObserver:self
															name:NSFileHandleReadCompletionNotification
														  object:modem];	// don't observe any more
			[modem release];
			modem=nil;
			[modes release];
			modes=nil;
			error=@"Modem closed";
		}	
}

- (void) _openHSO;
{ // try to open during init or reopen after AT_ORESET
	NSString *dev=@"/dev/ttyHS_Application";
	int i;
	modes=[[NSArray arrayWithObjects:NSDefaultRunLoopMode, NSEventTrackingRunLoopMode, nil] retain];
	pinStatus=CTPinStatusUnknown;	// needs to check
	[self _closeHSO];	// if open
	for(i=1; i<5; i++)
		{		
			modem=[[NSFileHandle fileHandleForUpdatingAtPath:dev] retain];
			if(modem)
				break;	// found open
			system("echo 1 >/sys/devices/virtual/gpio/gpio186/value");	// wake up modem on GTA04A4
			system("echo 0 >/sys/devices/virtual/gpio/gpio186/value");
			sleep(5);
		}
	if(!modem)
		{
		error=@"Can't open modem.";
		NSLog(@"could not open %@", dev);
		return;		
		}
	// FIXME: also listen on /dev/ttyHS_Modem to receive "NO CARRIER" messages
	// FIXME: or should we work only on the /dev/ttyHS_Modem port???
	atstarted=NO;
	done=YES;	// no command is running
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(_dataReceived:)
												 name:NSFileHandleReadCompletionNotification 
											   object:modem];	// make us see notifications
#if 1
	NSLog(@"waiting for data on %@", dev);
#endif
	[modem readInBackgroundAndNotifyForModes:modes];	// and trigger notifications
	// FIXME: this does not correctly work - unsolicited messages may interrupt echo of AT commands - but the echo is split up by e.g. \nRING\n i.e. it is a full line
	if([self runATCommand:@"ATE1"] != CTModemOk)	// enable echo so that we can separate unsolicited lines from responses
		{
			error=@"Failed to intialize modem.";
			return;			
		}
//	[[self runATCommandReturnResponse:@"AT_OID"] componentsSeparatedByString:@"\n"];	// get firmware version and handle differently
	// FIXME:
//	[self runATCommand:@"AT+CSCS=????"];	// define character set
	[self runATCommand:@"AT_OPONI=1"];	// report current network registration
	[self runATCommand:@"AT_OSQI=1"];	// report signal quality in dBm
	[self runATCommand:@"AT_OEANT=1"];	// report quality level (0..4 or 5)
	[self runATCommand:@"AT_OCTI=1"];	// report GSM/GPRS/EDGE cell data rate		
	[self runATCommand:@"AT_OUWCTI=1"];	// report available cell data rate		
	[self runATCommand:@"AT_OUHCIP=1"];	// report HSDPA call in progress		
	[self runATCommand:@"AT_OSSYS=1"];	// report system (GSM / UTRAN)		
	[self runATCommand:@"AT_OPATEMP=1"];	// report PA temperature		
	[self runATCommand:@"AT+COPS"];		// report RING etc.		
	[self runATCommand:@"AT+CRC=1"];	// report +CRING: instead of RING		
	[self runATCommand:@"AT+CLIP=1"];	// report +CLIP:
}

- (NSString *) error; { return error; }

- (BOOL) isAvailable; {	return modem != nil; }

- (void) setUnsolicitedTarget:(id) t action:(SEL) a;
{
#if 1
	NSLog(@"setUnsolicitedTarget:");
#endif
	unsolicitedTarget=t;
	unsolicitedAction=a;
}

- (int) runATCommand:(NSString *) cmd target:(id) t action:(SEL) a timeout:(NSTimeInterval) seconds;
{
	NSAutoreleasePool *arp=[NSAutoreleasePool new];
	NSDate *timeout=[NSDate dateWithTimeIntervalSinceNow:seconds];
#if 1
	NSLog(@"run: %@", cmd);
#endif
	if(!modem)
		{
		// we could try to open the modem here!
		return CTModemTimeout;	// treat as timeout without trying
		}
	[self _writeCommand:cmd];
	done=NO;
	atstarted=NO;	// make us wait until we receive the echo
	target=t;
	action=a;
	status=CTModemTimeout;
	while(!done && [timeout timeIntervalSinceNow] >= 0)
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeout];
	if(!done)
		{
		NSLog(@"timeout for %@", cmd);
		// we could try to reopen the modem file handle here	
		}
	done=YES;	// even if we did timeout
	[arp release];
#if 1
	NSLog(@"done: %@ (%d)", cmd, status);
#endif
	return status;
}

- (int) runATCommand:(NSString *) cmd target:(id) t action:(SEL) a;
{
	return [self runATCommand:cmd target:t action:a timeout:2.0];
}

- (int) runATCommand:(NSString *) cmd
{ // without callback
	return [self runATCommand:cmd target:nil action:NULL];
}

// FIXME: this is not reentrant!
// Why is it a problem: because there may arrive unsolicited messages
// while we wait for the answer and these may trigger callbacks that
// try to run another AT command

- (void) _collectResponse:(NSString *) line
{
	[response appendString:line];
}

- (NSString *) runATCommandReturnResponse:(NSString *) cmd
{ // collect response in string
	NSMutableString *sr=response;	// save response (if we are a nested call)
	NSMutableString *r=[NSMutableString stringWithCapacity:100];
	response=r;	
	if([self runATCommand:cmd target:self action:@selector(_collectResponse:)] != CTModemOk)
		r=nil;	// wasn't able to get response
	response=sr;	// restore
	return r;
}

- (void) _processLine:(NSString *) line;
{
#if 1
	fprintf(stderr, "WWAN r (done=%d at=%d): %s\n", done, atstarted, [[line description] UTF8String]);
	//	NSLog(@"WWAN r (s=%d): %@", state, line);
#endif
	if(atstarted)
		{ // response to AT command
		if([line hasPrefix:@"OK"])
			{
			status=CTModemOk;
			done=YES;
			atstarted=NO;	// further responses are unsolicited
			return;
			}
		if([line hasPrefix:@"ERROR"] ||
		   [line hasPrefix:@"+CME ERROR:"] ||
		   [line hasPrefix:@"+CEER:"] ||
		   [line hasPrefix:@"BUSY"] ||
		   [line hasPrefix:@"NO CARRIER"] ||
		   [line hasPrefix:@"NO ANSWER"])
			{ // reponse to AT command
				[error release];
				error=[line retain];
#if 1
				NSLog(@"error: %@", error);
#endif
				/*
				 +CME ERROR: SIM PIN required
				 +CME ERROR: FDN Mismatch -- FDN = fixed dialling number
				 */
				status=CTModemError;
				done=YES;
				atstarted=NO;	// treat further responses as unsolicited
				return;
			}
		if(target && action)
			[target performSelector:action withObject:line];	// repsonse to current command
		}
	if([line hasPrefix:@"AT"])	// is some echoed AT command
		atstarted=YES;	// divert future responses - FIXME: may not work reliably if echoing is slow
	else
		[unsolicitedTarget performSelector:unsolicitedAction withObject:line afterDelay:0.0];	// unsolicited response - process in main runloop!
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
	NSAutoreleasePool *arp=[NSAutoreleasePool new];
#if 0
	NSLog(@"_dataReceived %@", n);
#endif
	[self _processData:[[n userInfo] objectForKey:@"NSFileHandleNotificationDataItem"]];	// parse data as line
	[[n object] readInBackgroundAndNotifyForModes:modes];	// and trigger more notifications
	[arp release];
}

- (void) _writeCommand:(NSString *) str;
{
	NSAssert(modem, @"needs NSFileHandle");
#if 1
	fprintf(stderr, "WWAN w (done=%d at=%d): %s\n", done, atstarted, [[str description] UTF8String]);
	//	NSLog(@"WWAN w: %@", str);
#endif
	str=[str stringByAppendingString:@"\r"];
	NS_DURING
		[modem writeData:[str dataUsingEncoding:NSASCIIStringEncoding]];
	NS_HANDLER
		NSLog(@"_writeCommand: %@", localException);
	NS_ENDHANDLER
}

- (void) reset;
{
	[self runATCommand:@"AT_ORESET"];	// with default timeout to give modem a chance to respond with "OK"
	error=@"Resetting Modem.";
	[self _openHSO];	// will close current connection and reopen
}

- (void) _unlocked;
{
	CTModemManager *m=[CTModemManager modemManager];
	pinStatus=CTPinStatusUnlocked;	// now unlocked
	[[CTTelephonyNetworkInfo telephonyNetworkInfo] _processUnsolicitedInfo:[m runATCommandReturnResponse:@"AT_OSIMOP"]];
	[[CTTelephonyNetworkInfo telephonyNetworkInfo] _processUnsolicitedInfo:[m runATCommandReturnResponse:@"AT+CSQ"]];
}

- (BOOL) sendPIN:(NSString *) p;
{ // send pin and run additional initialization commands after unlocking
	if([self runATCommand:[NSString stringWithFormat:@"AT+CPIN=%@", p]] == CTModemOk)
		{ // is accepted
			// save PIN so that we can reuse it
			[self performSelector:@selector(_unlocked) withObject:nil afterDelay:1.0];	// run with delay since they do not work immediately
			return YES;
		}
	return NO;	// no SIM, wrong PIN or already unlocked
}

- (CTPinStatus) pinStatus;
{ // get current PIN status
	if(pinStatus == CTPinStatusUnknown)
		{ // ask modem
			// check if we are in airplane mode!
			NSString *pinstatus=[self runATCommandReturnResponse:@"AT+CPIN?"];
			if(!pinstatus)
				{
				if([error hasPrefix:@"+CME ERROR: SIM not inserted"])
					return CTPinStatusNoSIM;
				}
			if([pinstatus hasPrefix:@"+CPIN: READY"])
				{ // response to AT+CPIN? - PIN is ok!
					[self _unlocked];
					return pinStatus;
				}
			if([pinstatus hasPrefix:@"+CPIN: SIM PIN"] || [pinstatus hasPrefix:@"+CPIN: SIM PUK"])
				{ // user needs to provide pin
					return pinStatus=CTPinStatusPINRequired;
				}
		}
	return pinStatus;
}

- (BOOL) setAirplaneMode:(BOOL) flag;
{
#if 1
	NSLog(@"setAirplaneMode flag=%d pinStatus=%d", flag, pinStatus);
#endif
	if(flag)
		{
		if(pinStatus == CTPinStatusAirplaneMode)
			return YES;	// already set
		[self runATCommand:@"AT_OAIR=1"];
		pinStatus=CTPinStatusAirplaneMode;
		return YES;
		}
	else
		{
		if(pinStatus != CTPinStatusAirplaneMode)
			return YES;	// already disabled
		[self runATCommand:@"AT_OAIR=0"];
		pinStatus=CTPinStatusUnknown;	// check on next call for pinStatus
		return YES;
		}
}

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
	[pin setEditable:NO];
	switch([self pinStatus]) {
		case CTPinStatusAirplaneMode:
			[message setStringValue:@"Airplane mode"];
			[okButton setTitle:@"Cancel"];
			break;
		case CTPinStatusNoSIM:
			[message setStringValue:@"No SIM inserted"];
			[okButton setTitle:@"Cancel"];
			break;
		case CTPinStatusUnlocked:
			[message setStringValue:@"Already unlocked"];
			[okButton setTitle:@"Cancel"];
			break;
		case CTPinStatusPINRequired: {
			NSString *pinpuk=[self runATCommandReturnResponse:@"AT_OERCN"];	// Improvement: could also check PIN2, PUK2
			if([pinpuk length] > 0)
				{ // split into pin and puk retries
					NSArray *a=[pinpuk componentsSeparatedByString:@" "];
#if 0
					NSLog(@"PIN/PUK retries: %@", pinpuk);
#endif
					if([a count] == 3)
						{
						int pinretries=[[a objectAtIndex:1] intValue];
						int pukretries=[[a objectAtIndex:2] intValue];
#if 1
						NSLog(@"%d pin retries; %d puk retries", pinretries, pukretries);
#endif
						if(pukretries != 10)
							[message setStringValue:[NSString stringWithFormat:@"%d PUK / %d PIN retries", pukretries, pinretries]];
						else
							[message setStringValue:[NSString stringWithFormat:@"%d PIN retries", pinretries]];
						}
					[pin setEditable:YES];
					[okButton setTitle:@"Unlock"];
				}
			break;			
		}
		default:
			[message setStringValue:@"Unknown SIM status"];			
		}
	[pin setStringValue:@""];	// clear
	[pinPanel setBackgroundColor:[NSColor blackColor]];
	[pinPanel center];
	[pinPanel orderFront:self];
	[pinKeypadPanel orderFront:self];
}

- (IBAction) pinOk:(id) sender;
{ // a new pin has been provided
	NSString *p=[pin stringValue];
	if(![[okButton title] isEqualToString:@"Unlock"])	// either we have no SIM or are already unlocked
		{ // cancel
		[pinPanel orderOut:self];
			[pinKeypadPanel orderOut:self];
		return;
		}
	// store temporarily so that we can check if it returns OK or not
	// if ok, we can save the PIN
	if([self sendPIN:p])
		{ // is accepted
			[pinPanel orderOut:self];
			[pinKeypadPanel orderOut:self];
			return;
		}
	else
		{
		NSString *err=[self error];
		if([err hasPrefix:@"+CME ERROR: incorrect password"])
			;
		// report error and keep panel open
		[message setStringValue:@"Invalid PIN"];
		// FIXME: will this be overwritten by PIN/PUK retries?
		}
}

- (IBAction) pinKey:(id) sender;
{
	if([[sender title] isEqualToString:@"C"])
		[pin setStringValue:@""];	// clear
	else
		[pin setStringValue:[[pin stringValue] stringByAppendingString:[sender title]]];	// type digit
}

// we may add a checkbox to reveal/hide the PIN...
// [pin setEchosBullets:YES/NO]


- (BOOL) checkPin:(NSString *) p;	// get PIN status and ask if nil and none specified yet
{
	if(!p)
		{
		// loop until pin is valid?
		switch([self pinStatus]) {
			case CTPinStatusNoSIM:
				[[NSAlert alertWithMessageText:@"NO SIM"
								 defaultButton:@"Ok"
							   alternateButton:nil
								   otherButton:nil
					 informativeTextWithFormat:@"No SIM inserted"] runModal];
				return NO;
			case CTPinStatusUnlocked:
				return YES;
			case CTPinStatusPINRequired:
				if(p && [self sendPIN:p])
					return YES;	// successful - otherwise open panel
				// loop while panel is open (so that the user can cancel it)
				[self orderFrontPinPanel:nil];
				// loop modal while panel is open
				// return YES only if PIN was successfully provided, NO if cancelled
				return YES;
		}
		}
	return NO;
}

- (BOOL) changePin:(NSString *) pin toNewPin:(NSString *) new;
{
	[self reset];
	// AT+CPIN="old","new"
	return NO;
}

@end
