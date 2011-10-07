//
//  CTModemManager.m
//  CoreTelephony
//
//  Created by H. Nikolaus Schaller on 29.09.11.
//  Copyright 2011 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "CTPrivate.h"

#include <signal.h>

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

- (void)release {}

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
		if(![self _openHSO])
			{
			[self release];
			return nil;
			}
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
	[modem closeFile];
	[modem release];
	[error release];
	[lastChunk release];
	[super dealloc];
	modemManager=nil;
}

- (BOOL) _openHSO;
{ // open during init or reopen after AT_ORESET
	NSString *dir=@"/sys/class/tty";
	NSDirectoryEnumerator *e=[[NSFileManager defaultManager] enumeratorAtPath:dir];
	NSString *typ;
	NSString *dev=nil;
	if(modem)
		{ // close previous modem
			[[NSNotificationCenter defaultCenter] removeObserver:self
															name:NSFileHandleReadCompletionNotification
														  object:modem];	// don't observe any more
			[modem release];
			modem=nil;
		}
	while((typ=[e nextObject]))
		{ // search Application interface
		NSString *hs=[typ lastPathComponent];
#if 1
		NSLog(@"file: %@ - %@", typ, hs);
#endif
		if([hs hasPrefix:@"ttyHS"])
			{
			NSString *path=[[dir stringByAppendingPathComponent:typ] stringByAppendingPathComponent:@"hsotype"];
			NSString *type=[NSString stringWithContentsOfFile:path];
#if 1
			NSLog(@"%@ -> %@", path, type);
#endif
			if([type hasPrefix:@"Application"])
				{
				dev=[NSString stringWithFormat:@"/dev/%@", hs];
				break;	// application port found			
				}
			}
		}
	if(!dev)
		{
		NSLog(@"No GTM601 found");
		return NO;		
		}
	signal(SIGIO, SIG_IGN);	// the HSO driver appears to send SIGIO although there was no fcntl(FASYNC)
	modem=[[NSFileHandle fileHandleForUpdatingAtPath:dev] retain];
	if(!modem)
		{
		NSLog(@"could not open %@", dev);
		return NO;		
		}
	atstarted=NO;
	done=YES;	// no command is running
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(_dataReceived:)
												 name:NSFileHandleReadCompletionNotification 
											   object:modem];	// make us see notifications
#if 1
	NSLog(@"waiting for data on %@", dev);
#endif
	[modem readInBackgroundAndNotify];	// and trigger notifications
	if([self runATCommand:@"ATE1"] != CTModemOk)	// enable echo so that we can separate unsolicited lines from responses
		return NO;
	[self runATCommand:@"AT_OPONI=1"];	// report current network registration
	[self runATCommand:@"AT_OSQI=1"];	// report signal quality in dBm
	[self runATCommand:@"AT_OEANT=1"];	// report quality level (0..4 or 5)
	[self runATCommand:@"AT_OUWCTI=1"];	// report available cell data rate		
	[self runATCommand:@"AT_OCTI=1"];	// report GSM/GPRS/EDGE cell data rate		
	[self runATCommand:@"AT+CLIP=1"];	// report CLIP		
	[self runATCommand:@"AT+CRC=1"];	// report +CRING: instead of RING		
	return YES;
}

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
	[self _writeCommand:cmd];
	done=NO;
	atstarted=NO;	// make us wait until we receive the echo
	target=t;
	action=a;
	status=CTModemTimeout;
	while(!done && [timeout timeIntervalSinceNow] >= 0)
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeout];
	if(!done)
		NSLog(@"timeout for %@", cmd);
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

- (NSString *) error; { return error; }

- (int) runATCommand:(NSString *) cmd
{ // without callback
	return [self runATCommand:cmd target:nil action:NULL];
}

- (void) _collectResponse:(NSString *) line
{
	[response appendString:line];
}

- (NSString *) runATCommandReturnResponse:(NSString *) cmd
{ // collect response in string
	response=[NSMutableString stringWithCapacity:100];
	if([self runATCommand:cmd target:self action:@selector(_collectResponse:)] != CTModemOk)
		return nil;	// wasn't able to get response
	return response;
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
		atstarted=YES;	// divert future responses
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
	[[n object] readInBackgroundAndNotify];	// and trigger more notifications
	[arp release];
}

- (void) _writeCommand:(NSString *) str;
{
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

- (IBAction) orderFrontPinPanel:(id) sender
{
	NSString *pinstatus;
	NSString *pinpuk;
	if(!pinPanel)
		{ // try to load from NIB
			if(![NSBundle loadNibNamed:@"AskPin" owner:self])	// being the owner allows to connect to views in the panel
				{
				NSLog(@"can't open AskPin panel");
				return;	// ignore
				}
		}
	pinstatus=[self runATCommandReturnResponse:@"AT+CPIN?"];
	[message setStringValue:@"Unknown SIM status"];
	[pin setEditable:NO];
	if(!pinstatus)
		{
		if([error hasPrefix:@"+CME ERROR: SIM not inserted"])
			[message setStringValue:@"No SIM inserted"];
		}
	else if([pinstatus hasPrefix:@"+CPIN: READY"])
		{ // response to AT+CPIN? - PIN is ok!
			[message setStringValue:@"Already unlocked"];
		}
	else if([pinstatus hasPrefix:@"+CPIN: SIM PIN"] || [pinstatus hasPrefix:@"+CPIN: SIM PUK"])
		{ // user needs to provide pin
		pinpuk=[self runATCommandReturnResponse:@"AT_OERCN"];	// Improvement: could also check PIN2, PUK2
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
			}
		}
	else
		NSLog(@"unknown PIN status: %@", pinstatus);	// may be +CPIN: SIM PIN2
	[pin setStringValue:@""];	// clear
	[pinPanel setBackgroundColor:[NSColor blackColor]];
	[pinPanel center];
	[pinPanel orderFront:self];
}

// we may add a checkbox to reveal/hide the PIN...
// [pin setEchosBullets:YES/NO]


- (BOOL) checkPin:(NSString *) p;	// get PIN status and ask if nil and none specified yet
{
	if(!p)
		{
		// loop until pin is valid?
		NSString *pinstatus=[self runATCommandReturnResponse:@"AT+CPIN?"];
		if(!pinstatus)
			{
			if([error hasPrefix:@"+CME ERROR: SIM not inserted"])
				{
				[[NSAlert alertWithMessageText:@"NO SIM"
								 defaultButton:@"Ok"
							   alternateButton:nil
								   otherButton:nil
						informativeTextWithFormat:@"No SIM inserted"] runModal];
				return NO;
				}
			[[NSAlert alertWithMessageText:@"SIM Error"
							 defaultButton:@"Ok"
						   alternateButton:nil
							   otherButton:nil
				 informativeTextWithFormat:@"Error accessing SIM: %@", error] runModal];
			return NO;	// wasn't able to access modem
			}
		if([pinstatus hasPrefix:@"+CPIN: READY"])
			{ // response to AT+CPIN? - PIN is ok!
				NSString *simop;
				// ask information that is only available with PIN
				CTModemManager *m=[CTModemManager modemManager];
				simop=[m runATCommandReturnResponse:@"AT_OSIMOP"];
				if(simop)
					{ // home plnm - _OSIMOP: “<long_op>”,”<short_op>”, ”<MCC_MNC>”
						NSScanner *sc=[NSScanner scannerWithString:simop];
						NSString *name=@"unknown";
						[sc scanString:@"_OSIMOP: \"" intoString:NULL];
						[sc scanUpToString:@"\"" intoString:&name];
						[[[CTTelephonyNetworkInfo telephonyNetworkInfo] subscriberCellularProvider] _setCarrierName:name];
#if 1
						NSLog(@"carrier name=%@", name);
#endif
					}
				else
					NSLog(@"AT_OSIMOP error: %@", [m error]);
				return YES;
			}
		if([pinstatus hasPrefix:@"+CPIN: SIM PIN"] || [pinstatus hasPrefix:@"+CPIN: SIM PUK"])
			{
			// loop while panel is open (so that the user can cancel it)
			[self orderFrontPinPanel:nil];
			// loop modal while panel is open
			// return YES if PIN was successfully provided
			return YES;
			}
		NSLog(@"unknown PIN status: %@", pinstatus);	// may be +CPIN: SIM PIN2
		return NO;
		}
	else
		// AT+CPIN=number
		; // check if given pin is valid (can be used for a screen saver)
	return NO;
}

- (IBAction) pinOk:(id) sender;
{ // a new pin has been provided
	NSString *p=[pin stringValue];
	// store temporarily so that we can check if it returns OK or not
	// if ok, we can save the PIN
	if([self runATCommand:[NSString stringWithFormat:@"AT+CPIN=%@", p]] == CTModemOk)
		{ // is accepted
		// save PIN
		[pinPanel orderOut:self];
			// run AT_OSIMOP
		}
	else
		{
		NSString *err=[self error];
		if([err hasPrefix:@"+CME ERROR: incorrect password"])
			[self checkPin:nil];	// check again and update Retries counter
		// report error and keep panel open
		}
}

- (BOOL) reset;
{
	[self _writeCommand:@"AT_ORESET"];
	wwan=NO;
	// kill all connections...
	sleep(1);
	if([self _openHSO])
		return YES;
	return NO;
}

- (BOOL) changePin:(NSString *) pin toNewPin:(NSString *) new;
{
	if(![self reset])
		return NO;
	// AT+CPIN="old","new"
	return NO;
}

- (void) connectWWAN:(BOOL) flag;	// 0 to disconnect
{
	if(!wwan && flag)
		{ // set up WWAN connection
			NSString *data;
			// cdgcont has numbers (1)
			// [self runATCommand:[NSString stringWithFormat:@"AT+CGDCONT=1,\"%@\",\"%@\"", @"ip", @"apn"]];
			[self runATCommand:@"AT_OWANCALL=1,1,1"];	// context #1, start, send unsolicited response
			// will give unsolicited response: _OWANCALL: 1, 1

			// FIXME: should we do that on receiving _OWANCALL: 1, 1?
			data=[self runATCommandReturnResponse:@"AT_OWANDATA?"];	// e.g. _OWANDATA: 1, 10.152.124.183, 0.0.0.0, 193.189.244.225, 193.189.244.206, 0.0.0.0, 0.0.0.0,144000
			if(!data)
				{ // some error!
				
				}
			// split up into fields
/*
 IP=$(expr "$IP" : "\(.*\),")
				DNS1=$(expr "$DNS1" : "\(.*\),")
				DNS2=$(expr "$DNS2" : "\(.*\),")
				system("ifconfig hso0 $IP netmask 255.255.255.255 up");
				// write/append to resolv.conf
				echo "nameserver $DNS1" >/etc/resolv.conf
				echo "nameserver $DNS2" >>/etc/resolv.conf
*/				
			
		}
	else if(wwan && !flag)
		{ // disable WWAN connection
			[self runATCommand:@"AT_OWANCALL=1,0,1"];	// start
			// will give unsolicited response: _OWANCALL: 1, 0 
		// restore resolv.conf
		}
	wwan=flag;
}

@end

