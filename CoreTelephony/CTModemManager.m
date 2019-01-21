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

/* communicate with the hardware */

@interface CTModemManager (ModemHardware)

+ (void) enableLog:(BOOL) flag;
- (void) log:(NSString *) format, ...;
- (int) _power:(BOOL) on;	// power up/down modem
// FIXME: we could open the port on the first write and keep it working on each write command
- (int) _openPort;	// open FileHandle for AT command stream
- (int) _closePort;
- (void) _setError:(NSString *) msg;
- (void) _processData:(NSData *) line;
- (void) _dataReceived:(NSNotification *) n;
- (void) _writeCommand:(NSString *) str;

// runAT...

@end

/* send specific AT commands */

@interface CTModemManager (ATCommands)

- (int) _openModem;	// open and initialize modem
- (int) _closeModem;
- (void) _processLine:(NSString *) line;
- (void) _initModem;
- (BOOL) getPinCount:(int *) pinretries pukCount:(int *) pukretries facility:(NSString **) facility;

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

- (NSUInteger) retainCount { return UINT_MAX; }

- (oneway void) release {}

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
												  object:ttyPort];	// don't observe any more
	[self _closeModem];
	[error release];
	[super dealloc];
	modemManager=nil;
}

@end

// FIXME: split into low-end (modem serial - Private) and high-end methods (AT command level) and user-level (GUI)

@implementation CTModemManager (Logging)

BOOL modemLog=NO;

+ (void) enableLog:(BOOL) flag;
{
	modemLog=flag;
}

- (void) log:(NSString *) format, ...
{
	static NSString *name;
	if(!name)
		name=[[NSString stringWithFormat:@"/tmp/%@.log", [[NSBundle bundleForClass:[self class]] bundleIdentifier]] retain];
	// open/append/close is certainly not fast...
	FILE *f=fopen([name fileSystemRepresentation], "a");
	if(f)
		{
		va_list ap;
		va_start (ap, format);
		NSString *msg = [[NSString alloc] initWithFormat:format arguments:ap];
		fprintf(f, "%s: %s%s", [[[NSDate date] description] UTF8String], [msg UTF8String], [msg hasSuffix:@"\n"]?"":"\n");
		fprintf(stderr, "%s: %s%s", [[[NSDate date] description] UTF8String], [msg UTF8String], [msg hasSuffix:@"\n"]?"":"\n");
		[msg release];
		va_end (ap);
		fclose(f);
		}
}

@end

@implementation CTModemManager (ModemHardware)

- (NSString *) runSystemCommand:(NSString *) cmdPath arguments:(NSArray *) args error:(NSString **) error;
{
	NSTask *task=[NSTask new];
	NSPipe *pipe=[NSPipe pipe];
	NSData *data;
	NSString *result;
	// FIXME: wir kommen so nicht aus dem chroot raus!
	// => evtl Mechanismus in Foundation mit "//root/wwan-on" für echte Systembefehle?
	[task setLaunchPath:cmdPath];
	[task setArguments:args];
	[task setStandardOutput:[pipe fileHandleForWriting]];
	[task setStandardError:[pipe fileHandleForWriting]];
	[task launch];
	[task waitUntilExit];
	// get status and return error
	[task release];
	data=[[pipe fileHandleForReading] readDataToEndOfFile];
	result=[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	return result;
}

- (BOOL) _isPoweredOn;
{
	// find better/universal way - e.g. ask "rfkill wwan" if blocked?
	return YES;
}

- (int) _power:(BOOL) on
{
	if(modemLog) [self log:@"_power:%d", on];
	if(ttyPort)
		{
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:NSFileHandleReadCompletionNotification
													  object:ttyPort];	// don't observe any more
		[ttyPort release];	// will always reconnect!
		ttyPort=nil;
		}
	if(on)
		{
		// FIXME: should not block GUI while this script is running...
		// run this in a NSTask and waitUntilTerminated
		if(modemLog) [self log:@"run /root/wwan-on"];
		// [self runSystemCommand:@"/root/wwan-on" arguments:[NSArray arrayWithObject:@"Application"] error:NULL];
		FILE *p=popen("/root/wwan-on Application", "r");	// open the Application port (needs latest Letux-kernel) to receive unsolicited messages
		NSString *device;
		char dev[200];
		if(!p)
			{
			[self _setError:@"Can't run /root/wwan-on."];
			return NO;	// failed
			}
		fgets(dev, sizeof(dev)-1, p);
		pclose(p);
		device=[NSString stringWithUTF8String:dev];
		device=[device stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if(modemLog) [self log:@"found device:%@", device];
		if([device length] == 0)
			{
			[self _setError:@"No modem found."];
			return NO;	// failed
			}
		ttyPort=[[NSFileHandle fileHandleForUpdatingAtPath:device] retain];
		if(ttyPort)	// ok, was successfully opened!
			{
			if(!modes)
				modes=[[NSArray arrayWithObjects:NSDefaultRunLoopMode, NSEventTrackingRunLoopMode, nil] retain];
			[lastChunk release];
			lastChunk=nil;
			[self _setError:nil];
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(_dataReceived:)
														 name:NSFileHandleReadCompletionNotification
													   object:ttyPort];	// make us see notifications
			[ttyPort readInBackgroundAndNotifyForModes:modes];	// and trigger notifications
			if(modemLog) [self log:@"Modem port opened: %@", device];
			return YES;
			}
		if(modemLog) [self log:@"Failed to open command access."];
		[self _setError:@"Can't access modem."];
		return NO;
		}
	if(modemLog) [self log:@"run /root/wwan-off"];
	// [self runSystemCommand:@"/root/wwan-off" arguments:nil error:NULL];
	system("/root/wwan-off");
	[self _setError:@"Modem powered off."];
	return YES;
}

- (int) _openPort;	// will not reconnect if already connected
{ // open tty port for AT commands
	if(modemLog) [self log:@"_openPort"];
	if(ttyPort)
		{ // already open
			[self _setError:nil];
			return YES;
		}
	return [self _power:YES];
}

- (int) _closePort;	// will also power down
{
	[self _power:NO];
	[lastChunk release];
	lastChunk=nil;
	[modes release];
	modes=nil;
	[ttyPort release];
	return YES;
}

- (void) _processData:(NSData *) line;
{ // we have received a new data block from the serial line
  // FIXME: if we want to process UTF8 we have to split the NSData into chunks and then convert to NSString
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
			s=[lines objectAtIndex:l];
			s=[s stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\r"]];
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
	if(modemLog) [self log:@"w (done=%d at=%d): %@", done, atstarted, str];
	if(!ttyPort)
		{
		if(modemLog) [self log:@"no port open!"];
		return;
		}
	str=[str stringByAppendingString:@"\r"];
	NS_DURING
	[ttyPort writeData:[str dataUsingEncoding:NSASCIIStringEncoding]];
	NS_HANDLER
	if(modemLog) [self log:@"_writeCommand: %@", localException];
	NS_ENDHANDLER
}

- (NSString *) error; { return error; }

- (void) _setError:(NSString *) msg;
{
	if(modemLog) [self log:[NSString stringWithFormat:@"Error: %@", msg]];
	[error autorelease];
	error=[msg retain];
	if(modemLog) [self log:@"error: %@", error];
}

- (BOOL) isAvailable; {	return ttyPort != nil; }

// FIXME: queue up or protect against recursions

- (int) runATCommand:(NSString *) cmd target:(id) t action:(SEL) a timeout:(NSTimeInterval) seconds;
{
	NSAutoreleasePool *arp=[NSAutoreleasePool new];
	if(modemLog) [self log:@"run %@", cmd];
	status=CTModemTimeout;	// default status
	if(ttyPort || [self _openModem])	// _openHSO may run recursively to initialize the modem
		{
		NSDate *timeout=[NSDate dateWithTimeIntervalSinceNow:seconds];
		done=NO;
		atstarted=NO;	// make us wait until we receive the echo
		target=t;
		action=a;
		[self _writeCommand:cmd];
		// CHECKME: does this really work with setting the done flag on receiving OK?
		while(!done && [timeout timeIntervalSinceNow] >= 0)
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeout];
		if(!done)
			{
			if(modemLog) [self log:@"timeout %@", cmd];
			[self _closePort];
			}
		}
	done=YES;	// even if we did timeout
	[arp release];
	if(modemLog) [self log:@"done %@ (%d)", cmd, status];
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
// try to run another AT command before the current one has finished

- (void) _collectResponse:(NSString *) line
{
	[response addObject:line];
}

- (NSArray *) runATCommandReturnResponse:(NSString *) cmd
{ // collect response in string
	NSMutableArray *sr=response;	// save response (if we are a nested call)
	NSMutableArray *r=[NSMutableArray arrayWithCapacity:3];
	response=r;
	[self _setError:nil];
	if([self runATCommand:cmd target:self action:@selector(_collectResponse:)] != CTModemOk)
		{
		if(status == CTModemTimeout)
			[self _setError:@"timeout"];
		r=nil;	// wasn't able to get response
		}
	response=sr;	// restore
	while([r count] && [[r lastObject] length] == 0)
		[r removeLastObject];	// remove trailing empty lines, e.g. before OK
	return r;
}

- (void) _processLine:(NSString *) line;
{
	if(modemLog) [self log:@"r (done=%d at=%d): %@", done, atstarted, line];
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
					/* e.g.
					 +CME ERROR: SIM PIN required
					 +CME ERROR: FDN Mismatch -- FDN = fixed dialling number
					 */
					[self _setError:line];
					status=CTModemError;
					done=YES;
					atstarted=NO;	// treat further responses as unsolicited
					return;
				}
			if(target && action)
				{ // anything between the AT echo and OK/ERROR
					[target performSelector:action withObject:line];	// repsonse to current command
					return;
				}
		}
	if(!atstarted && [line hasPrefix:@"AT"])	// is some echoed AT command
		atstarted=YES;	// divert future responses - FIXME: may not work reliably if echoing is slow
	else if([line length] > 0)
		[unsolicitedTarget performSelector:unsolicitedAction withObject:line afterDelay:0.0];	// unsolicited response - process in main runloop!
}

- (void) setUnsolicitedTarget:(id) t action:(SEL) a;
{
#if 1
	NSLog(@"setUnsolicitedTarget:");
#endif
	unsolicitedTarget=t;
	unsolicitedAction=a;
}

@end

@implementation CTModemManager (ATCommands)

/* modem model dependent stuff */
/* could this be handled by subclassing? */

- (BOOL) isGTM601
{ // OPTION GTM601W
	if(!_ati)
		[self _openModem];
	return [_ati containsObject:@"Model: GTM601"];
}

- (BOOL) isPxS8
{ // Cinterion PHS8/PLS8
	if(!_ati)
		[self _openModem];
	return [_ati containsObject:@"Cinterion"];
}

// FIXME: can this block other AT commands?

- (void) poll:(NSDictionary *) info
{ // timer triggered commands (because there is no unsolicited notification)
	NSString *cmd=[info objectForKey:@"cmd"];
	NSNumber *repeat=[info objectForKey:@"repeat"];
	[[CTModemManager modemManager] runATCommand:cmd];
	if(repeat)
		[self performSelector:_cmd withObject:info afterDelay:[repeat doubleValue]];	// repeat
}

- (void) pollATCommand:(NSString *) cmd everySeconds:(int) seconds;
{ // run after seconds and repeat if seconds > 0
	NSNumber *repeat=seconds > 0 ? [NSNumber numberWithInt:seconds]:nil;
	NSDictionary *info=[NSDictionary dictionaryWithObjectsAndKeys:
						cmd, @"cmd",
						repeat, @"repeat",	// will not be stored if seconds <= 0
						nil
						];
	[self performSelector:@selector(poll:) withObject:info afterDelay:seconds];	// trigger first run
}

- (void) _initModem
{ // enable URCs and do some setup
	[self runATCommand:@"AT+COPS"];		// report RING etc.
	[self runATCommand:@"AT+CRC=1"];	// report +CRING: instead of RING
	[self runATCommand:@"AT+CLIP=1"];	// report +CLIP:
	[self runATCommand:@"AT+CMGF=1"];	// switch to SMS text mode
	//	[self runATCommand:@"AT+CSCS=????"];	// define character set
	if([self isGTM601])
		{ // initialize GTM601
			[self runATCommand:@"AT_OLCC=1"];	// report changes in call status
			[self runATCommand:@"AT_OPONI=1"];	// report current network registration
			[self runATCommand:@"AT_OSQI=1"];	// report signal quality in dBm
			[self runATCommand:@"AT_OEANT=1"];	// report quality level (0..4 or 5)
			[self runATCommand:@"AT_OCTI=1"];	// report GSM/GPRS/EDGE cell data rate
			[self runATCommand:@"AT_OUWCTI=1"];	// report available cell data rate
			[self runATCommand:@"AT_OUHCIP=1"];	// report HSDPA call in progress
			[self runATCommand:@"AT_OSSYS=1"];	// report system (GSM / UTRAN)
			[self runATCommand:@"AT_OPATEMP=1"];	// report PA temperature
			[self pollATCommand:@"AT_OBLS" everySeconds:10];	// get SIM status (removed etc.)
			[self pollATCommand:@"AT_OBSI" everySeconds:20];	// base station location
			[self pollATCommand:@"AT_ONCI?" everySeconds:20];	// neighbouring base stations
			[self pollATCommand:@"AT+CMGL=\"REC UNREAD\"" everySeconds:5];	// received SMS - until we have 3G wakeup
		}
	else if([self isPxS8])
		{ // initialize Cinterion PxS8
		  // [self runATCommand:@"AT^SQPORT?"] to check if we are on the correct port?
		  //	[self runATCommand:@"AT^SIND=..."];	// report some URCs
			[self runATCommand:@"AT+CREG=2"];	// report network registration
			[self runATCommand:@"AT^SAD=10"];	// turn off RX diversity
			[self runATCommand:@"AT^SCTM=1,1"];	// monitor temperature - should send ^SCTM_B: URCs
			[self pollATCommand:@"AT^SCTM?" everySeconds:20];	// get temperature
			[self pollATCommand:@"AT^SBV" everySeconds:20];		// get voltage
			[self pollATCommand:@"ATCSQ?" everySeconds:10];		// get for signal quality
			[self pollATCommand:@"AT^SMONI" everySeconds:10];	// get network
			[self pollATCommand:@"AT^SMONP" everySeconds:30];	// get base stations
			[self pollATCommand:@"AT+CMGL=\"REC UNREAD\"" everySeconds:5];	// received SMS - until we have 3G wakeup
		}
	//	[self performSelector:@selector(poll) withObject:nil afterDelay:5.0];
}

- (int) _openModem;
{
	if(modemLog) [self log:@"_openModem"];
	if(![self _openPort])
		return NO;
	pinStatus=CTPinStatusUnknown;	// needs to check again
	// FIXME: this does not correctly work - unsolicited messages may interrupt echo of AT commands - but the echo is split up by e.g. \nRING\n i.e. it is a full line
	if([self runATCommand:@"ATE1"] != CTModemOk)	// enable echo so that we can separate unsolicited lines from responses
		{
		[self _setError:@"Failed to intialize modem."];
		return NO;
		}
	_ati=[[self runATCommandReturnResponse:@"ATI"] retain];	// determine modem type
	//	[[self runATCommandReturnResponse:@"AT_OID"] componentsSeparatedByString:@"\n"];	// get firmware version to handle differently
#if 1
	NSLog(@"ATI=%@", _ati);
#endif
	[self _initModem];
	return YES;
}

- (int) _closeModem;
{
	if(modemLog) [self log:@"_closeModem"];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(poll:) object:nil];
	[self setUnsolicitedTarget:nil action:NULL];	// there may be some more incoming messages
	if(ttyPort)
		{
		[self _writeCommand:@"AT+CHUP"];	// be as sure as possible to hang up
		[self _closePort];
		}
	// should we power off the modem?
	pinStatus=CTPinStatusUnknown;	// needs to check again
	[_ati release];
	_ati=nil;
	return YES;
}

- (BOOL) getPinCount:(int *) pinretries pukCount:(int *) pukretries facility:(NSString **) facility;
{ // for current PIN status (i.e. PIN, PIN2, PH-SIM, PH-NET)
	*facility=@"";	// default
	if([self isGTM601])
		{
		NSArray *result=[self runATCommandReturnResponse:@"AT_OERCN"];	// Improvement: could also check PIN2, PUK2
		NSString *pinpuk=[result lastObject];
		NSArray *a=[pinpuk componentsSeparatedByString:@" "];
		// FIXME: handle PH-NET etc. like we do for PxS8
#if 0
		NSLog(@"PIN/PUK retries: %@", pinpuk);
#endif
		if([a count] == 3)
			{
			*pinretries=[[a objectAtIndex:1] intValue];
			*pukretries=[[a objectAtIndex:2] intValue];
#if 1
			NSLog(@"%d pin retries; %d puk retries", *pinretries, *pukretries);
#endif
			return YES;
			}
		}
	else if([self isPxS8])
		{
		NSArray *result=[self runATCommandReturnResponse:@"AT^SPIC?"];	// determine facility
		NSString *pinpuk=[result lastObject];
		NSArray *a;
		NSString *code;
#if 1
		NSLog(@"PIN/PUK code: %@", pinpuk);
#endif
		if([pinpuk rangeOfString:@"2"].location != NSNotFound)
			*facility=@"PIN2", code=@"P2";
		else if([pinpuk rangeOfString:@"PH-NET"].location != NSNotFound)
			*facility=@"PH-NET", code=@"PN";
		else if([pinpuk rangeOfString:@"PH-SIM"].location != NSNotFound)
			*facility=@"PH-SIM", code=@"PS";
		else if([pinpuk rangeOfString:@"SIM"].location != NSNotFound)
			*facility=@"", code=@"SC";
		else
			return NO;
		result=[self runATCommandReturnResponse:[NSString stringWithFormat:@"AT^SPIC=%@", code]];	// get PIN count
		pinpuk=[result lastObject];
#if 1
		NSLog(@"PIN retries: %@", pinpuk);
#endif
		a=[[result lastObject] componentsSeparatedByString:@" "];
		if([a count] == 2)
			*pinretries=[[a objectAtIndex:1] intValue];
		else
			return NO;
		result=[self runATCommandReturnResponse:[NSString stringWithFormat:@"AT^SPIC=%@,1", code]];	// get PUK count
		pinpuk=[result lastObject];
#if 1
		NSLog(@"PUK retries: %@", pinpuk);
#endif
		a=[[result lastObject] componentsSeparatedByString:@" "];
		if([a count] == 2)
			*pukretries=[[a objectAtIndex:1] intValue];
		else
			return NO;
#if 1
		NSLog(@"%d pin retries; %d puk retries", *pinretries, *pukretries);
#endif
		return YES;
		}
	return NO;	// failed to read
}

- (void) _delayedUnlock;
{
	NSEnumerator *e;
	NSString *line;
	if(modemLog) [self log:@"delayed unlock"];
	if([self isGTM601])
		{
		e=[[self runATCommandReturnResponse:@"AT_OSIMOP"] objectEnumerator];
		while(line=[e nextObject])
			[unsolicitedTarget performSelector:unsolicitedAction withObject:line];
		e=[[self runATCommandReturnResponse:@"AT+CSQ"] objectEnumerator];
		while(line=[e nextObject])
			[unsolicitedTarget performSelector:unsolicitedAction withObject:line];
		}
}

- (void) _unlock;
{ // run additional commands after successful unlocking and report any results to unsolicited delegate
	pinStatus=CTPinStatusUnlocked;	// now unlocked
	[self performSelector:@selector(_delayedUnlock) withObject:nil afterDelay:0.0];
}

- (CTPinStatus) pinStatus;
{ // get current PIN status
	if(pinStatus == CTPinStatusUnknown)
		{ // ask modem
			NSArray *result;
			NSString *pinstatus;
			if([self isGTM601])
				{
				if([[self runATCommandReturnResponse:@"AT_OAIR?"] containsObject:@"1"])
					return CTPinStatusAirplaneMode;
				}
			else if([self isPxS8])
				{
				if(![[self runATCommandReturnResponse:@"AT+CFUN?"] containsObject:@"+CFUN: 1"])
					return CTPinStatusAirplaneMode;
				}
			result=[self runATCommandReturnResponse:@"AT+CPIN?"];
			pinstatus=[result lastObject];
			if(!pinstatus)
				{
				if(modemLog) [self log:@"AT+CPIN? error %@", error];
				if([error hasPrefix:@"+CME ERROR: SIM not inserted"])	// GTM601W
					return CTPinStatusNoSIM;
				if([error hasPrefix:@"+CME ERROR: SIM failure"])	// PxS8
					return CTPinStatusNoSIM;
				}
			if([pinstatus hasPrefix:@"+CPIN: READY"])
				{ // response to AT+CPIN? - PIN is ok!
					[self _unlock];
					return pinStatus;
				}
			if([pinstatus hasPrefix:@"+CPIN: "])
				{ // user needs to provide pin/puk
					return pinStatus=CTPinStatusPINRequired;
				}
			[self _setError:@"Can't determine PIN status"];
		}
	return pinStatus;
}

- (BOOL) sendPIN:(NSString *) p;
{ // send pin and run additional initialization commands after unlocking
	if(modemLog) [self log:@"send PIN"];
	if([self runATCommand:[NSString stringWithFormat:@"AT+CPIN=%@", p]] == CTModemOk)
		{ // is accepted
			if(modemLog) [self log:@"send PIN accepted"];
			[self _unlock];
			return YES;
		}
	if(modemLog) [self log:@"send PIN rejected"];
	pinStatus=CTPinStatusUnknown;
	return NO;	// no SIM, wrong PIN or already unlocked
}

- (BOOL) changePin:(NSString *) pin toNewPin:(NSString *) new;
{
	if(modemLog) [self log:@"change PIN"];
	[self reset];
	// AT+CPIN="old","new"
	return NO;
}

- (BOOL) setAirplaneMode:(BOOL) flag;
{
	if(modemLog) [self log:@"set Airplane Mode %d (pinStatus=%d)", flag, pinStatus];
	if(flag)
		{
		if(pinStatus == CTPinStatusAirplaneMode)
			return YES;	// already set
		[self setUnsolicitedTarget:nil action:NULL];	// user app must restore after exiting airplane mode!
		if([self isGTM601])
			[self runATCommand:@"AT_OAIR=1"];
		else if([self isPxS8])
			[self runATCommand:@"AT+CFUN=4"];
		pinStatus=CTPinStatusAirplaneMode;
		return YES;
		}
	else
		{
		if(pinStatus != CTPinStatusAirplaneMode)
			return YES;	// already disabled
		if([self isGTM601])
			[self runATCommand:@"AT_OAIR=0"];
		else if([self isPxS8])
			[self runATCommand:@"AT+CFUN=1"];
		pinStatus=CTPinStatusUnknown;	// check on next call for pinStatus
		return YES;
		}
}

- (void) reset;
{
	if(modemLog) [self log:@"reset"];
	if([self isGTM601])
		{
		[self terminatePCM];
		[self setUnsolicitedTarget:nil action:NULL];
		if([self runATCommand:@"AT+CHUP"] == CTModemOk &&
		   [self runATCommand:@"AT_ORESET"] == CTModemOk)	// with default timeout to give modem a chance to respond with "OK"
			{
			int i;
			NSDate *timeout;
			[self _closePort];
			[self _setError:@"Resetting Modem."];
			for(i=1; i<10; i++)
				{
				if(![self _isPoweredOn])
					break;	// wait until modem has disappeared on USB
				timeout=[NSDate dateWithTimeIntervalSinceNow:1.0];
				while([timeout timeIntervalSinceNow] >= 0)
					[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeout];
				}
			[self _setError:@"Modem disappeared."];
			timeout=[NSDate dateWithTimeIntervalSinceNow:5.0];	// leave some time for modem to come up again - or calling [self _openHSO] will turn it off instead of on...
			while([timeout timeIntervalSinceNow] >= 0)
				[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeout];
			[self _setError:nil];	// ok
			}
		else
			{
			[self _closePort];
			[self _setError:@"Can't reset Modem."];
			}
		}
}

// can we mix setupPCM and setupVoice into single method? optionally with a parameter?
- (void) setupPCM;
{
	// Run before setting up the call. Modem mutes all voice signals if we do that *during* a call
	if(modemLog) [self log:@"setup PCM"];
	if([self isGTM601])
		{
		[self runATCommand:@"AT_OPCMENABLE=1"];
		[self runATCommand:@"AT_OPCMPROF=0"];	// default "handset"
		[self runATCommand:@"AT+VIP=0"];
		}
	else if([self isPxS8])
		{ // select I2S, Master Mode, Short Frame, clock only during activity,8kHz sample rate
		  // AT^SAIC=<io>, <mic>, <ep>, <clock>, <mode>, <frame_mode>, <ext_clk_mode>[, <sample_rate>]
		[self runATCommand:@"AT^SAIC=3,1,1,0,1,0,1,0"];
		}
}

- (void) setupVoice;
{
	if(modemLog) [self log:@"setup Voice"];
	// check for HW vs. SW routing
	system("killall arecord aplay;"	// stop any running audio forwarding
		   "arecord -fS16_LE -r8000 | aplay -Dhw:1,0 &"	// forward microphone -> network
		   "arecord -Dhw:1,0 -fS16_LE -r8000 | aplay &"	// forward network -> handset/earpiece
		   );
}

- (void) terminatePCM;
{
	if(modemLog) [self log:@"terminate PCM"];
	system("killall arecord aplay");	// stop audio forwarding
	// error handling?
	if([self isGTM601])
		{
		[self runATCommand:@"AT_OPCMENABLE=0"];	// disable PCM clocks to save some energy
		}
	else if([self isPxS8])
		{

		}
}

@end

@implementation CTModemManager (GUI)

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
			[message setStringValue:@"SIM already unlocked"];
			[okButton setTitle:@"Close"];
			break;
		case CTPinStatusPINRequired: {
			int pinretries=0;
			int pukretries=0;
			NSString *facility=nil;
			if([self getPinCount:&pinretries pukCount:&pukretries facility:&facility])
				{
				if(facility)
					facility=[facility stringByAppendingString:@" "];
				if(pukretries != 10)
					[message setStringValue:[NSString stringWithFormat:@"%d %@PUK / %d PIN retries", pukretries, facility, pinretries]];
				else
					[message setStringValue:[NSString stringWithFormat:@"%d %@PIN retries", pinretries, facility]];
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
#if 1
	NSLog(@"pinOk: %@ %@", [okButton title], sender);
#endif
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
#if 1
	NSLog(@"pinKey: %@ %@", [sender title], sender);
#endif
	if([[sender title] isEqualToString:@"C"])
		[pin setStringValue:@""];	// clear
	else
		[pin setStringValue:[[pin stringValue] stringByAppendingString:[sender title]]];	// type digit
}

// we should add a checkbox to reveal/hide the PIN...
// [pin setEchosBullets:YES/NO]

- (BOOL) checkPin:(NSString *) unlockPin;	// get PIN status and ask if nil and none specified yet
{
	if(modemLog) [self log:@"checkpin"];
	while(YES)
		{ // loop until pin is valid
			switch([self pinStatus]) {
				case CTPinStatusUnknown: {
					if([error isEqualToString:@"timeout"])
						{ // we may have lost the modem connection
							[self _closeModem];	// disconnect modem tty and reconnect
							continue;
						}
					if([error hasPrefix:@"+CME ERROR: Sim interface not started yet"])
						{ // we were too fast for the modem (or the modem is shutting down through impulse???)
						  // FIXME: do by NSRunLoop
							sleep(2);
							continue;	// try again
						}
					return NO;
				}
				case CTPinStatusNoSIM:
					[[NSAlert alertWithMessageText:@"NO SIM"
									 defaultButton:@"Ok"
								   alternateButton:nil
									   otherButton:nil
						 informativeTextWithFormat:@"No SIM inserted"] runModal];
					return NO;
				case CTPinStatusUnlocked:
				case CTPinStatusAirplaneMode:
					return YES;
				case CTPinStatusPINRequired:
					if(unlockPin && [self sendPIN:unlockPin])
						return YES;	// sending PIN provided by code was successful - otherwise open panel
									// loop while panel is open (so that the user can cancel it)
					[self orderFrontPinPanel:nil];
					// loop modal while panel is open and block the application
					// return YES only if PIN was successfully provided, NO if cancelled
					return YES;
			}
		}
}

@end
