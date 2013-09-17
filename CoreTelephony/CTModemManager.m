//
//  CTModemManager.m
//  CoreTelephony
//
//  Created by H. Nikolaus Schaller on 29.09.11.
//  Copyright 2011 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

/*
 * TODO:
 * this is not yet running 100% stable
 * problems:
 ** AT_ORESET may get the modem into a partial list of /dev/ttyHS* or none at all
 ** in that case we can't send another AT_ORESET
 ** rmmod hso && modprobe hso may help - but also end in a kernel panic
 ** GUI may hang if we allow buttons to be pressed recursively while we wait for timeouts
 ** modem remains enabled if application terminates (or system is shut down)
 ** 
 */

#import "CTPrivate.h"

#include <signal.h>

@interface CTModemManager (Private)

- (void) _openHSO;	// (re)open FileHandle for AT command stream
- (void) _closeHSO;
- (void) _setError:(NSString *) msg;
- (void) _processLine:(NSString *) line;
- (void) _processData:(NSData *) line;
- (void) _dataReceived:(NSNotification *) n;
- (void) _writeCommand:(NSString *) str;

@end

// FIXME: split into low-end (modem serial - Private) and high-end methods (AT command level)

@implementation CTModemManager

BOOL modemLog=NO;

+ (void) enableLog:(BOOL) flag;
{
	modemLog=flag;
}

- (void) log:(NSString *) format, ...
{
	// this is certainly not fast...
	NSString *name=[NSString stringWithFormat:@"/tmp/%@.log", [[NSBundle bundleForClass:[self class]] bundleIdentifier]];
	FILE *f=fopen([name fileSystemRepresentation], "a");
	if(f)
		{
		va_list ap;
		va_start (ap, format);
		NSString *msg = [[NSString alloc] initWithFormat:format arguments:ap];
		fprintf(f, "%s: %s%s", [[[NSDate date] description] UTF8String], [msg UTF8String], [msg hasSuffix:@"\n"]?"":"\n");
		[msg release];
		va_end (ap);		
		fclose(f);
		}
}

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
		}
    }
    return self;
}

- (void) dealloc
{ // should not happen for a singleton!
#if 1
	NSLog(@"CTModemManager dealloc");
	abort();
#endif
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSFileHandleReadCompletionNotification
												  object:modem];	// don't observe any more
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
			if(modemLog) [self log:@"_closeHSO"];
			[[NSNotificationCenter defaultCenter] removeObserver:self
															name:NSFileHandleReadCompletionNotification
														  object:modem];	// don't observe any more
			[self _writeCommand:@"AT+CHUP"];	// be as sure as possible to hang up
			[modes release];
			modes=nil;
			[modem release];
			modem=nil;
			// should we power off the modem?
		}	
	pinStatus=CTPinStatusUnknown;	// needs to check again
	[self _setError:@"Modem closed."];
}

- (void) _openHSO;
{ // try to open during init or reopen after AT_ORESET
	NSString *gpio=@"/sys/devices/virtual/gpio/gpio186/value";
	NSString *dev=@"/dev/ttyHS_Application";
	int i;
	if(modemLog) [self log:@"_openHSO"];
	if(modem)
		{ // already open
		[self _setError:nil];
		return;			
		}
	[self _setError:@"Opening modem."];
	for(i=1; i<5; i++)
		{
			NSDate *timeout;
			modem=[[NSFileHandle fileHandleForUpdatingAtPath:dev] retain];
			if(modemLog) [self log:@"WWAN port %@ %@", dev, modem?@"exists":@"not found"];
			if(modem)
				break;	// found open
			if(modemLog) [self log:@"WWAN pulse %d on: %@", i, gpio];
			[@"1" writeToFile:gpio atomically:NO];	// wake up modem on GTA04A4
			timeout=[NSDate dateWithTimeIntervalSinceNow:1.0];
			while([timeout timeIntervalSinceNow] >= 0)
				[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeout];
			[@"0" writeToFile:gpio atomically:NO];
			timeout=[NSDate dateWithTimeIntervalSinceNow:4.0];
			while(!(modem=[[NSFileHandle fileHandleForUpdatingAtPath:dev] retain]) && [timeout timeIntervalSinceNow] >= 0)
				[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeout];
			if(modem)
				break;	// found earlier
		}
	if(!modem)
		{
		if(modemLog) [self log:@"failed to open modem"];
		[self _setError:@"Can't open modem."];
#if 1
		NSLog(@"could not open %@", dev);
#endif
		return;		
		}
	pinStatus=CTPinStatusUnknown;	// needs to check first
	// FIXME: also listen on /dev/ttyHS_Modem to receive "NO CARRIER" messages
	// FIXME: or should we work only on the /dev/ttyHS_Modem port???
	atstarted=NO;
	done=YES;	// no command is running
	if(!modes)
		modes=[[NSArray arrayWithObjects:NSDefaultRunLoopMode, NSEventTrackingRunLoopMode, nil] retain];
	[self _setError:nil];
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
			[self _setError:@"Failed to intialize modem."];
			return;			
		}
//	[[self runATCommandReturnResponse:@"AT_OID"] componentsSeparatedByString:@"\n"];	// get firmware version to handle differently
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
	[self runATCommand:@"AT_OPCMENABLE=1"];	// renable voice PCM
}

- (NSString *) error; { return error; }

- (void) _setError:(NSString *) msg;
{
	[error autorelease];
	error=[msg retain];
}

- (BOOL) isAvailable; {	return modem != nil; }

- (void) setUnsolicitedTarget:(id) t action:(SEL) a;
{
#if 1
	NSLog(@"setUnsolicitedTarget:");
#endif
	unsolicitedTarget=t;
	unsolicitedAction=a;
}

// FIXME: queue up or protect against recursions

- (int) runATCommand:(NSString *) cmd target:(id) t action:(SEL) a timeout:(NSTimeInterval) seconds;
{
	NSAutoreleasePool *arp=[NSAutoreleasePool new];
	NSDate *timeout=[NSDate dateWithTimeIntervalSinceNow:seconds];
	if(modemLog) [self log:@"run %@", cmd];
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
	status=CTModemTimeout;	// default status
	// CHECKME: does this really work with setting the done flag on receiving OK?
	while(!done && [timeout timeIntervalSinceNow] >= 0)
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeout];
	if(!done)
		{
		if(modemLog) [self log:@"timeout %@", cmd];
#if 1
		NSLog(@"timeout for %@", cmd);
#endif
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
	if(modemLog) [self log:@"r (done=%d at=%d): %@", done, atstarted, line];
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
				[self _setError:line];
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
	if(modemLog) [self log:@"w (done=%d at=%d): %@", done, atstarted, str];
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
	if(modemLog) [self log:@"--- reset ---"];
	[self _openHSO];	// we must have a connection first
	if([[self error] length] > 0)
		return;
	// FIXME: we may still receive some unsolicited messages! So we should temporarily disable their delivery
	if([self runATCommand:@"AT_ORESET"] == CTModemOk)	// with default timeout to give modem a chance to respond with "OK"
		{
		int i;
		[self _closeHSO];
		[self _setError:@"Resetting Modem."];
		for(i=1; i<10; i++)
			{
			NSDate *timeout;
			BOOL usb=[[NSFileManager defaultManager] fileExistsAtPath:@"/sys/devices/platform/usbhs_omap/ehci-omap.0/usb1/1-2"];	// check if OPTION modem is connected on EHCI
			if(!usb)
				break;	// wait until modem has disappeared on USB
			timeout=[NSDate dateWithTimeIntervalSinceNow:1.0];
			while([timeout timeIntervalSinceNow] >= 0)
				[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeout];
			}
		}
	else
		{
		[self _closeHSO];
		[self _setError:@"Can't reset Modem."];
		}
}

- (void) _unlocked;
{
	CTModemManager *m=[CTModemManager modemManager];
	pinStatus=CTPinStatusUnlocked;	// now unlocked
	[unsolicitedTarget performSelector:unsolicitedAction withObject:[m runATCommandReturnResponse:@"AT_OSIMOP"] afterDelay:0.0];
	[unsolicitedTarget performSelector:unsolicitedAction withObject:[m runATCommandReturnResponse:@"AT+CSQ"] afterDelay:0.0];
}

- (BOOL) sendPIN:(NSString *) p;
{ // send pin and run additional initialization commands after unlocking
	if(modemLog) [self log:@"send PIN"];
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
	if(modem && pinStatus == CTPinStatusUnknown)
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
			[self _setError:@"Can't determine PIN status"];
		}
	return pinStatus;
}

- (BOOL) setAirplaneMode:(BOOL) flag;
{
#if 1
	NSLog(@"setAirplaneMode flag=%d pinStatus=%d", flag, pinStatus);
#endif
	if(modemLog) [self log:@"set Airplane Mode %d", flag];
	if(flag)
		{
		if(pinStatus == CTPinStatusAirplaneMode)
			return YES;	// already set
		[self runATCommand:@"AT_OAIR=1"];
		pinStatus=CTPinStatusAirplaneMode;
		// power off modem
		return YES;
		}
	else
		{
		if(pinStatus != CTPinStatusAirplaneMode)
			return YES;	// already disabled
		if(!modem)
			[self _openHSO];
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
#if 1
				NSLog(@"can't open AskPin panel");
#endif
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

// we should add a checkbox to reveal/hide the PIN...
// [pin setEchosBullets:YES/NO]


- (BOOL) checkPin:(NSString *) p;	// get PIN status and ask if nil and none specified yet
{
	if(modemLog) [self log:@"checkpin"];
	[self _openHSO];	// try to connect first
	if([[self error] length] > 0)
		return NO;
	if(!p)
		{
		// loop until pin is valid?
		switch([self pinStatus]) {
			case CTPinStatusUnknown:
				// should we power on the modem first?
				return NO;
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
					return YES;	// sending PIN provided by code was successful - otherwise open panel
				// loop while panel is open (so that the user can cancel it)
				[self orderFrontPinPanel:nil];
				// loop modal while panel is open and block the application
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
