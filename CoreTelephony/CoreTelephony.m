//
//  CTCall.h
//  CoreTelephony
//
//  Created by H. Nikolaus Schaller on 04.07.11.
//  Copyright 2010 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "CTPrivate.h"

NSString const *CTCallStateDialing=@"CTCallStateDialing";
NSString const *CTCallStateIncoming=@"CTCallStateIncoming";
NSString const *CTCallStateConnected=@"CTCallStateConnected";
NSString const *CTCallStateDisconnected=@"CTCallStateDisconnected";

// FIXME: the call center shouldn't be a singleton!
// reason: there may be multiple and different delegates for each instance

@implementation CTCallCenter

/* NIB-safe Singleton pattern */

#define SINGLETON_CLASS		CTCallCenter
#define SINGLETON_VARIABLE	callCenter
#define SINGLETON_HANDLE	callCenter

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
		CTModemManager *m=[CTModemManager modemManager];
		currentCalls=[[NSMutableSet alloc] initWithCapacity:10];
		[CTTelephonyNetworkInfo telephonyNetworkInfo];	// initialize
		[m checkPin:nil];		// could read from a keychain if specified - nil asks the user
		}
	}
	return self;
}

- (void) dealloc
{ // should not be possible for a singleton!
	NSLog(@"CTCallCenter dealloc");
	abort();
	[currentCalls release];
	[super dealloc];
	callCenter=nil;
}

#undef SINGLETON_CLASS
#undef SINGLETON_VARIABLE
#undef SINGLETON_HANDLE

- (NSSet *) currentCalls; { return currentCalls; }

- (id <CTCallCenterDelegate>) delegate; { return delegate; }
- (void) setDelegate:(id <CTCallCenterDelegate>) d; { delegate=d; }

// see ANNEX G of GSM 07.07 how voice dialling works */

- (CTCall *) dial:(NSString *) number;
{
	CTModemManager *mm=[CTModemManager modemManager];
	// check if we are already connected
	// check string for legal characters (0-9, +, #, *, G/g, I/i, space or someone could inject arbitraty AT commands...)
	NSString *err;
	NSString *cmd=[NSString stringWithFormat:@"ATD%@;", number];	// initiate a voice call
	[mm runATCommand:@"AT+COLP=1"];	// report phone number and make ATD blocking
	[mm setupPCM];
	if([mm runATCommand:cmd target:nil action:NULL timeout:120.0])	// ATD blocks only until connection is setup and remote ringing starts; so don't timeout too early!
		{ // successfull call setup
			CTCall *call=[[CTCall new] autorelease];
			[call _setCallState:kCTCallStateDialing];
			[call _setPeerPhoneNumber:number];	// should this come from AT+COLP (later)?
			[currentCalls addObject:call];
			// notify delegate
			return call;
		}
	err=[mm error];
#if 1
	NSLog(@"dial error: %@", err);
#endif
	/*
	 error responses may be
	 ERROR
	 NO CARRIER (kein Anschluß unter dieser Nummer)
	 BUSY
	 NO ANSWER
	 CONNECT

	 could also use AT+CEER to get a more precise information
	 */
	if([err isEqualToString:@""])
		{

		}
	return nil;	// not successfull
}

- (BOOL) sendSMS:(NSString *) message toNumber:(NSString *) number;
{ // send a SMS
	CTModemManager *mm=[CTModemManager modemManager];
	NSString *cmd=[NSString stringWithFormat:@"AT+CMGS=\"%@\"\n%@%c", number, message, 'Z'-'@'];
	return [mm runATCommand:cmd target:nil action:NULL timeout:5.0];
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
  // can we read that from the Modem so that we never have to set it?
	return peer;
}

- (void) _setPeerPhoneNumber:(NSString *) number
{
	[peer autorelease];
	peer=[number retain];
}

- (void) terminate;
{
	CTModemManager *mm=[CTModemManager modemManager];
	[mm runATCommand:@"AT+CHUP"];
	[mm terminatePCM];
}

- (void) hold;
{
	// anytime
}

- (void) accept;	// if incoming
{
	// ATA?
	// if CTCallStateIncoming
	[[CTModemManager modemManager] runATCommand:@"ATA"];
	// start PCM
}

- (void) reject;	// if incoming
{
	// if CTCallStateIncoming
	[self terminate];
}

- (void) divert;
{
	// if CTCallStateIncoming
}

// set
- (void) handsfree:(BOOL) flag;	// switch on handsfree speakers (or headset?)
{
	system("amixer set 'DAC1 Analog' off;"
		   "amixer set 'DAC2 Analog' on;"
		   //"amixer set  'Codec Operation Mode' 'Option 1 (audio)'");
		   "amixer set  'Codec Operation Mode' 'Option 2 (voice/audio)'");
	system("amixer set Earpiece 100%;"
		   "amixer set 'Earpiece Mixer AudioL2' on;"
		   /* "amixer set 'Earpiece Mixer AudioR2' off;" -- does not exist */
		   "amixer set 'Earpiece Mixer Voice' off");
	system("amixer set 'Analog' 5;"
		   "amixer set TX1 'Analog';"
		   "amixer set 'TX1 Digital' 12;"
		   "amixer set 'Analog Left AUXL' nocap;"
		   "amixer set 'Analog Right AUXR' nocap;"
		   "amixer set 'Analog Left Main Mic' cap;"
		   "amixer set 'Analog Left Headset Mic' nocap");
#if 1
	NSLog(@"handsfree: %d", flag);
#endif
	// if CTCallStateConnected (?)
	if(flag)
		{
#if 0	// does not work with Modem Firmware during a voice call
		[[CTModemManager modemManager] runATCommand:@"AT_OPCMPROF=2"];
#endif
		system("amixer set HandsfreeL on;"
			   "amixer set HandsfreeR on;"
			   "amixer set 'HandsfreeL Mux' AudioL2;"
			   "amixer set 'HandsfreeR Mux' AudioR2");
		}
	else
		{
		system("amixer set HandsfreeL off;"
			   "amixer set HandsfreeR off");
#if 0	// does not work with Modem Firmware during a voice call
		[[CTModemManager modemManager] runATCommand:@"AT_OPCMPROF=0"];
#endif
		}
}

- (void) mute:(BOOL) flag;	// mute microphone
{
	/* return */ [[CTModemManager modemManager] runATCommand:[NSString stringWithFormat:@"AT+CMUT=%d", flag != 0]];
	// if CTCallStateConnected
	// switch amixer
}

- (void) volume:(float) value;	// general volume (earpiece, handsfree, headset)
{
	/* return */ [[CTModemManager modemManager] runATCommand:[NSString stringWithFormat:@"AT+CLVL=%d", (int) (7.0*value)]];
	// if CTCallStateConnected
	// switch amixer
}

- (void) sendDTMF:(NSString *) digit
{ // 0..9, a-c, #, *
	if([digit length] != 1)
		return;	// we could loop over all digits with a little delay
				// check if this is a valid digit
	NSLog(@"send DTMF: %@", digit);
	// if this already blocks until the tone has been sent, we can simply loop over all characters
	if(![[CTModemManager modemManager] runATCommand:[NSString stringWithFormat:@"AT+VTS=%@", digit]] != CTModemOk)
		;
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

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@: carrier=%@ iso=%@ country=%@ network=%@ strength=%.2f dBm=%g speed=%.1gG cell=%@",
			[super description], carrierName, isoCountryCode, mobileCountryCode, mobileNetworkCode, strength, dBm, networkSpeed, cellID];
}

- (NSString *) carrierName; { return carrierName; }
- (NSString *) isoCountryCode; { return isoCountryCode; }
- (NSString *) mobileCountryCode; { return mobileCountryCode; }
- (NSString *) mobileNetworkCode; { return mobileNetworkCode; }
- (BOOL) allowsVOIP; { return YES; }

- (float) strength; { return strength; }	// signal strength (0..1.0)
- (float) dBm; { return dBm; }		// signal strength (in dBm)
- (float) networkSpeed; { return networkSpeed; }	// 1.0, 2.0, 2.5, 3.0, 3.5 etc.
- (NSString *) cellID;	 { return cellID; }	// current cell ID
- (BOOL) canChoose; { return YES; }	// is permitted to select (if there are alternatives)

// - (id) initWithName:(NSString *) name isoCode etc. --- oder initWithResponse:

- (void) _setCarrierName:(NSString *) n; { [carrierName autorelease]; carrierName=[n retain]; }
- (void) _setStrength:(float) s; { strength=s; }
- (void) _setNetworkSpeed:(float) s; { networkSpeed=s; }
- (void) _setdBm:(float) s; { dBm=s; }
- (void) _setCellID:(NSString *) n; { [cellID autorelease]; cellID=[n retain]; }

- (void) choose;
{ // make the current carrier if there are several options to choose
	return;
}

- (void) connectWWAN:(BOOL) flag;	// 0 to disconnect
{
	CTModemManager *mm=[CTModemManager modemManager];
#if 1
	NSLog(@"connectWWAN %d", flag);
#endif
	if([mm isGTM601])
		{
		unsigned int context=1;
		if(flag && [self WWANstate] != CTCarrierWWANStateConnected)
			{ // set up WWAN connection
			  // FIXME: this should be carrier specific!!!
				// see: http://blog.mobilebroadbanduser.eu/page/Worldwide-Access-Point-Name-%28APN%29-list.aspx#403
				NSString *apn=@"web.vodafone.de";	// lookup in some database? Or let the user choose by a prefPane?
				NSString *protocol=@"IP";	// either "IP" or "PPP"
											// FXIME: make configurable if user wants to use 3G
				[mm runATCommand:@"AT_OPSYS=3,2"];	// register to any network in any mode
				[mm runATCommand:@"AT_OWANCALLUNSOL=1"];	// receive unsolicited _OWANCALL messages
				[mm runATCommand:[NSString stringWithFormat:@"AT+CGDCONT=%u,\"%@\",\"%@\"", context, protocol, apn]];
				// secure: 0=no, 1=pap, 2=chap
				// [mm runATCommand:[NSString stringWithFormat:@"AT_OPDPP=%u,%u,\"%@\",\"%@\"", context, secure, passwd, user]];
				[mm runATCommand:[NSString stringWithFormat:@"AT_OWANCALL=%u,1,1", context]];	// context #1, start, send unsolicited response
			}
		else if(!flag && [self WWANstate] != CTCarrierWWANStateDisconnected)
			{ // disable WWAN connection
				system("ifconfig hso0 down");	// we could make the ifconfig up/down trigger our daemon...
				// FIXME: do by NSRunLoop
				sleep(1);
				[mm runATCommand:[NSString stringWithFormat:@"AT_OWANCALL=%u,0,1", context]];	// stop
			}
		}
	else if([mm isPxS8])
		{
		if(flag && [self WWANstate] != CTCarrierWWANStateConnected)
			system("ifconfig usb1 up");
		else if(!flag && [self WWANstate] != CTCarrierWWANStateDisconnected)
			system("ifconfig usb1 down");
		}
}

- (CTCarrierWWANState) WWANstate;
{ // ask the modem
  // FIXME: this may be a little slow if we call it too often
	// so we should cache the state and update only if last value is older than e.g. 1 second
#if 1
	char bfr[512];
	FILE *f=popen("ifconfig -s | fgrep hso0", "r");
	NSLog(@"WWANstate f=%p", f);
	if(!f)
		return CTCarrierWWANStateUnknown;
	fgets(bfr, sizeof(bfr)-1, f);
	pclose(f);
	NSLog(@"WWANstate strlen=%d", strlen(bfr));
	return strlen(bfr) > 10?CTCarrierWWANStateConnected:CTCarrierWWANStateDisconnected;


#else
	// does not work well since it may get called recursively (why???) - but would be the correct way of checking connectivity

	CTModemManager *mm=[CTModemManager modemManager];
	NSArray *a=[mm runATCommandReturnResponse:@"AT_OWANCALL?"];
#if 1
	NSLog(@"a=%@", a);
#endif
	if([a count] >= 2)
		{
		return [[a objectAtIndex:1] intValue];	// 0..3
		}
#endif
	return CTCarrierWWANStateUnknown;
}

@end

@implementation CTTelephonyNetworkInfo

// FIXME: is this really a Singleton???
// if not, we can have multiple delegates

/* NIB-safe Singleton pattern */

#define SINGLETON_CLASS		CTTelephonyNetworkInfo
#define SINGLETON_VARIABLE	telephonyNetworkInfo
#define SINGLETON_HANDLE	telephonyNetworkInfo

/* static part */

static SINGLETON_CLASS * SINGLETON_VARIABLE = nil;

+ (id) allocWithZone:(NSZone *) zone
{
	//   @synchronized(self)
	{
	if (! SINGLETON_VARIABLE)
		return [super allocWithZone:zone];
	}
	return SINGLETON_VARIABLE;
}

- (id) copyWithZone:(NSZone *) zone { return self; }

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
		CTModemManager *m;
		SINGLETON_VARIABLE = self;
		/* custom initialization here */
		subscriberCellularProvider=[CTCarrier new];	// create default entry
		currentNetwork=[subscriberCellularProvider retain];	// default: the same
		[subscriberCellularProvider _setCarrierName:@"No Carrier"];	// default if we can't read the SIM
		m=[CTModemManager modemManager];
		[m setUnsolicitedTarget:self action:@selector(_processUnsolicitedInfo:)];
		}
	}
	return self;
}

- (void) dealloc
{ // should not be possible for a singleton!
	NSLog(@"CTTelephonyNetworkInfo dealloc");
	[subscriberCellularProvider release];
	abort();
	[super dealloc];
}

#undef SINGLETON_CLASS
#undef SINGLETON_VARIABLE
#undef SINGLETON_HANDLE

- (void) _processUnsolicitedInfo:(NSString *) line
{
#if 1
	NSLog(@"_processUnsolicitedInfo: %@", line);
#endif
	if(!line) return;	// if called with empty/missing result from directly running a command
	if([line hasPrefix:@"RING"] || [line hasPrefix:@"+CRING:"])
		{
		// incoming call
		NSLog(@"incoming call: %@", line);
		// decode CLIP information
		// create a new call and notify
		// FIXME: this message may repeat and end without other notice
		return;
		}
	if([line hasPrefix:@"BUSY"])
		{
		NSEnumerator *e=[[[CTCallCenter callCenter] currentCalls] objectEnumerator];
		CTCall *call;
		NSLog(@"busy: %@", line);
		while((call=[e nextObject]))
			{ // update connection state to connected
				if([call _callState] == kCTCallStateDialing)
					{ // found the call that was dialling
						[call _setCallState:kCTCallStateDisconnected];	// well, it was busy
						[[[CTCallCenter callCenter] delegate] callCenter:[CTCallCenter callCenter] handleCall:call];	// notify through CallCenter
						break;
					}
			}
		return;
		}
	if([line hasPrefix:@"NO CARRIER"])
		{
		NSEnumerator *e=[[[CTCallCenter callCenter] currentCalls] objectEnumerator];
		CTCall *call;
		NSLog(@"remote hangup: %@", line);
		while((call=[e nextObject]))
			{ // update connection state to connected
				if([call _callState] == kCTCallStateDialing)
					{ // found the call that was dialling
						[call _setCallState:kCTCallStateDisconnected];	// well, it was rejected
						[[[CTCallCenter callCenter] delegate] callCenter:[CTCallCenter callCenter] handleCall:call];	// notify through CallCenter
						break;
					}
				if([call _callState] == kCTCallStateConnected)
					{ // found the call that was established
						CTModemManager *mm=[CTModemManager modemManager];
						[mm terminatePCM];
						[call _setCallState:kCTCallStateDisconnected];
						[[[CTCallCenter callCenter] delegate] callCenter:[CTCallCenter callCenter] handleCall:call];	// notify through CallCenter
						break;
					}
			}
		return;
		}
	if([line hasPrefix:@"+CBM:"])
		{
		NSLog(@"cell broadcast message: %@", line);
		return;
		}
	if([line hasPrefix:@"+CLIP:"])
		{
		NSLog(@"CLIP message: %@", line);
		return;
		}
	if([line hasPrefix:@"+COLP:"])
		{
		CTModemManager *mm=[CTModemManager modemManager];
		NSEnumerator *e=[[[CTCallCenter callCenter] currentCalls] objectEnumerator];
		CTCall *call;
		while((call=[e nextObject]))
			{ // update connection state to connected
				if([call _callState] == kCTCallStateDialing)
					{ // found the call that was dialling
						[call _setCallState:kCTCallStateConnected];
						[[[CTCallCenter callCenter] delegate] callCenter:[CTCallCenter callCenter] handleCall:call];	// notify through CallCenter
						break;
					}
			}
#if 1
		NSLog(@"connection established: %@", call);
#endif
#if 0	// does not work! Modem mutes all voice signals if we do that *during* a call
		[mm runATCommand:@"AT_OPCMENABLE=1"];
		[mm runATCommand:@"AT_OPCMPROF=0"];	// default "handset"
		[mm runATCommand:@"AT+VIP=0"];
#endif
		[call handsfree:YES];	// switch profile and enable speakers
		[call volume:1.0];

		// FIXME: recording a phone call should only be possible under active user's control

		[mm setupVoice];
		return;
		}
	if([line hasPrefix:@"+CREG:"])
		{
		NSLog(@"network registration: %@", line);
		// FIXME
		return;
		}
	// same for cell broadcasts (?) AT+CPMS="BM"
	if([line hasPrefix:@"+CMGL:"])
		{ // SMS received (should be in SMS text mode
			CTModemManager *mm=[CTModemManager modemManager];
			CTCallCenter *cc=[CTCallCenter callCenter];
			NSString *message=nil;
			NSString *sender=nil;
			NSDate *date=nil;
			NSMutableDictionary *attributes=nil;
			NSUInteger index;
			NSLog(@"SMS received: %@", line);
			// NOTE: it is recommended to use PDU mode so that rogue SMS messages can't interfere with AT command decoding
		/*
			AT+CMGL="REC UNREAD"

			+CMGL: 0,"REC UNREAD","08954290367",,"17/02/07,14:26:32+04"
			Mailbox: Der Anrufer hat keine Nachricht hinterlassen:\0A +498954290367 \0A 07.02.2017 14:25:32 \0A 3 Versuche \0A\0A
			... more messages

			OK
		 */
			// index=
			// sender=
			// date=	Uhrzeit & Datum -> NSDate wandeln - Achtung TimeZone ist in 15min-Schritten, AT+CSDH=1
			// message=
			[attributes setObject:date forKey:@"date"];
			[mm runATCommand:[NSString stringWithFormat:@"AT+CMGD=%u", index]];	// delete SMS after reception
			// we should send this from the runloop by a delayed performer so that activities triggered by the delegate can't interfere with URC processing
			[[cc delegate] callCenter:cc didReceiveSMS:message fromNumber:sender attributes:attributes];
		// FIXME
		return;
		}
	if([line hasPrefix:@"_OPON:"])
		{ // current visited network - _OPON: <cs>,<oper>,<src>
		  // cs=8bit code
		  // src=3 -> SE13 hex format
		  // src=4 -> MCCMNC in decimal
			CTTelephonyNetworkInfo *ni=[CTTelephonyNetworkInfo telephonyNetworkInfo];
			CTCarrier *carrier=[ni subscriberCellularProvider];
			NSScanner *sc=[NSScanner scannerWithString:line];
			NSString *cs=@"unknown";
			NSString *name=@"unknown";
			NSMutableString *s;
			int src;
			NSLog(@"visited network: %@", line);
			// Parameterliste kann auch leer sein!
			// => Visited Network verloren gegangen
			// wenn [ni currentNetwork] != nil -> löschen
			[sc scanString:@"_OPON: \"" intoString:NULL];
			[sc scanUpToString:@"," intoString:&cs];
			[sc scanString:@"," intoString:NULL];
			[sc scanUpToString:@"," intoString:&name];
			[sc scanString:@"," intoString:NULL];
			if(![sc scanInt:&src] || src != 3)
				return;
			s=[NSMutableString string];
			while([name length] >= 2)
				{ // eat each 2 characters
					unichar c1=[name characterAtIndex:0];
					unichar c2=[name characterAtIndex:1];
					c1=(c1 > '9') ? tolower(c1)-'a'+10 : c1 - '0';
					c2=(c2 > '9') ? tolower(c2)-'a'+10 : c2 - '0';
					[s appendFormat:@"%c", (c1<<4)+c2];
					name=[name substringFromIndex:2];
				}
			name=s;
#if 1
			NSLog(@"carrier name=%@ delegate=%@", name, [ni delegate]);
#endif
			// neuen Carrier in [ni currentNetwork] eintragen
			// [carrier _setCarrierName:name];
			[[ni delegate] subscriberCellularProviderDidUpdate:carrier];
			return;
		}
	if([line hasPrefix:@"_OSIGQ:"] || [line hasPrefix:@"+CSQ:"])
		{ // signal quality - _OSIGQ: 2*<rssi>-113dBm,<ber> (ber=99)
			int dbm=[[[line componentsSeparatedByString:@" "] lastObject] intValue];
			if(dbm == 99) dbm=(113-999)/2;	// show -999 dBm
			[currentNetwork _setdBm:2.0*dbm-113.0];
#if 1
			NSLog(@"ni=%@", currentNetwork);
			NSLog(@"ni.delegate=%@", delegate);
#endif
			[delegate signalStrengthDidUpdate:currentNetwork];
			return;
		}
	if([line hasPrefix:@"_OEANT:"])
		{ // antenna level - _OEANT: <n> (0..5 but 4 is the maximum ever reported)
		  // GTAM601W on GTA04A5 reports 5 as well
#if 1
			NSLog(@"OEANT: %@", line);
			NSLog(@"substr: %@", [line substringFromIndex:8]);
#endif
			float strength=[[line substringFromIndex:8] floatValue]/4.0;
			NSLog(@"strength=%g", strength);
			if(strength > 1.0) strength=1.0;	// limit
			[currentNetwork _setStrength:strength];
			[delegate signalStrengthDidUpdate:currentNetwork];
			return;
		}
	if([line hasPrefix:@"_OCTI:"])
		{ // GSM/EDGE cell type - _OCTI: <n> (0..3)
#if 1
			NSLog(@"GSM capability: %@", line);
#endif
			switch([[line substringFromIndex:7] intValue]) {
				case 1:
					[currentNetwork _setNetworkSpeed:2.0];	// GSM
					break;
				case 2:
					[currentNetwork _setNetworkSpeed:2.5];	// GPRS
					break;
				case 3:
					[currentNetwork _setNetworkSpeed:2.75];	// EDGE - see http://en.wikipedia.org/wiki/2G#Evolution
					break;
				default:
					[currentNetwork _setNetworkSpeed:0.0];	// unknown
			}
			[delegate signalStrengthDidUpdate:currentNetwork];
			return;
		}
	if([line hasPrefix:@"_OUWCTI:"])
		{ // WDMA cell type - _OUWCTI: <n> (0..4)
#if 1
			NSLog(@"WCDMA capability: %@", line);
#endif
			switch([[line substringFromIndex:9] intValue]) { // see http://3g4g.blogspot.com/2007/05/3g-39g.html
				default:
					return;	// non-wcdma - don't overwrite
				case 1:
					[currentNetwork _setNetworkSpeed:3.0];	// WCDMA
					break;
				case 2:
					[currentNetwork _setNetworkSpeed:3.5];	// WCDMA+HSDPA
					break;
				case 3:
					[currentNetwork _setNetworkSpeed:3.6];	// WCDMA+HSUPA
					break;
				case 4:
					[currentNetwork _setNetworkSpeed:3.75];	// WCDMA+HSDPA+HSUPA
					break;
			}
			[delegate signalStrengthDidUpdate:currentNetwork];
			return;
		}
	if([line hasPrefix:@"_OSSYSI:"])
		{ // selected system: 0=GSM, 2=UTRAN, 3=No Service
		  // notify through CTCarrier/CTTelephonyNetworkInfo
			NSLog(@"selected system: %@", line);
			return;
		}
	if([line hasPrefix:@"_OUHCIP:"])
		{ // HSDPA call in progress: 1
		  // notify through CTCarrier/CTTelephonyNetworkInfo
			NSLog(@"HSDPA: %@", line);
			return;
		}
	if([line hasPrefix:@"_OPATEMP:"])
		{ // PA temperature
			NSArray *a=[line componentsSeparatedByString:@" "];
			NSLog(@"PA TEMP: %@", line);
			if([a count] == 3)
				paTemp=[[a objectAtIndex:2] intValue];
			[delegate signalStrengthDidUpdate:currentNetwork];
			return;
		}
	if([line hasPrefix:@"_OWANCALL:"])
		{ // internet connection state did change
			int state=[[[line componentsSeparatedByString:@","] lastObject] intValue];	// connection state
			unsigned int context=1;	// get from _OWANCALL: message
			if(state == 0)
				{ // became disconnected
					NSMutableArray *resolv=[[[NSString stringWithContentsOfFile:@"/etc/resolv.conf"] componentsSeparatedByString:@"\n"] mutableCopy];
					unsigned int i=[resolv count];
					while(i-- > 0)
						{
						if([[resolv objectAtIndex:i] hasSuffix:@" # wwan"])
							[resolv removeObjectAtIndex:i];	// remove wwan config
						}
#if 1
					NSLog(@"new resolv.conf: %@", resolv);
#endif
					[resolv writeToFile:@"/etc/resolv.conf" atomically:NO];
					[resolv release];
				}
			else if(state == 1)
				{ // became connected
					NSArray *data=[[CTModemManager modemManager] runATCommandReturnResponse:[NSString stringWithFormat:@"AT_OWANDATA=%u", context]];	// e.g. _OWANDATA: 1, 10.152.124.183, 0.0.0.0, 193.189.244.225, 193.189.244.206, 0.0.0.0, 0.0.0.0,144000
					NSArray *a=[[data lastObject] componentsSeparatedByString:@","];
#if 1
					NSLog(@"Internet config: %@", a);
#endif
					if([a count] == 8)
						{ // format as expected: <c>, <ip>, <gw>, <dns1>, <dns2>, <nbns1>, <nbns2>, <csp>
							NSMutableString *resolv=[NSMutableString stringWithContentsOfFile:@"/etc/resolv.conf"];
							// FIXME: process <gw>
							NSString *cmd=[NSString stringWithFormat:@"ifconfig hso0 '%@' netmask 255.255.255.255 up",
										   [[a objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
#if 1
							NSLog(@"system: %@", cmd);
#endif
							system([cmd UTF8String]);
							// check for errors
							if(!resolv) resolv=[NSMutableString string];
							[resolv appendFormat:@"nameserver %@ # wwan\n",
							 [[a objectAtIndex:3] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
							[resolv appendFormat:@"nameserver %@ # wwan\n",
							 [[a objectAtIndex:4] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
							// FIXME: the network interface namer daemon should collect all DNS entries for interfaces coming and going
							// i.e. we should write the DNS entries into that database (/Library/Preferences/SystemConfiguration/NetworkInterfaces.plist)
							// and trigger the interface namer for an update
							// or add interface-specific record(s) to /etc/network/interfaces

							// notify connection speed [[a objectAtIndex:7] intValue] in kbit/s

#if 1
							NSLog(@"new resolv.conf: %@", resolv);
#endif
							[resolv writeToFile:@"/etc/resolv.conf" atomically:NO];
#if 1
							system("route add default hso0");
							// FIXME: this should be done by Sharing&Network setup (i.e. only ONE connection can/should be the -o)
							[@"1" writeToFile:@"/proc/sys/net/ipv4/ip_forward" atomically:NO];	// enable forwarding
							system("iptables -t nat -A POSTROUTING -o hso0 -j MASQUERADE");
#endif
						}
				}
			else
				{ // error
					NSArray *error=[[CTModemManager modemManager] runATCommandReturnResponse:@"AT_OWANNWERROR?"];
#if 1
					NSLog(@"WWAN error=%@", error);
#endif
				}
			// FIXME: how do we know the "carrier"?
			//			[[[CTTelephonyNetworkInfo telephonyNetworkInfo] delegate] currentNetworkDidUpdate:self];	// notify
			[delegate signalStrengthDidUpdate:currentNetwork];
		}
	// the following responses are not really "unsolicted" but are handled as if they were
	if([line hasPrefix:@"_ONCI:"])
		{ // neighbour cell info
		  // notify through CTCarrier/CTTelephonyNetworkInfo
			NSLog(@"neighbour cell: %@", line);
			return;
		}
	if([line hasPrefix:@"_OBSI:"])
		{ // base station location - _OBSI=<id>,<lat>,<long>
		  // notify through CTCarrier/CTTelephonyNetworkInfo
			NSLog(@"base station location: %@", line);
			// forward to CLLocation?
			return;
		}
	if([line hasPrefix:@"_OSIMOP:"])
		{ // home plnm - _OSIMOP: “<long_op>”,”<short_op>”,”<MCC_MNC>”
			NSScanner *sc=[NSScanner scannerWithString:line];
			NSString *name=@"unknown";
			// FIXME: response does not necessarily enclose args in quotes!
			[sc scanString:@"_OSIMOP: \"" intoString:NULL];
			[sc scanUpToString:@"\"" intoString:&name];
			[subscriberCellularProvider _setCarrierName:name];
#if 1
			NSLog(@"carrier name=%@", name);
#endif
			[delegate subscriberCellularProviderDidUpdate:currentNetwork];
			return;
		}
	if([line hasPrefix:@"_OLCC:"])
		{ // call status - _OLCC: <call>,<direction>,<status>,<mode>,<multi>,<number>,<?>
			NSArray *st=[line componentsSeparatedByString:@","];
			int call=[[[st objectAtIndex:0] substringFromIndex:6] intValue];	// call number
			int dir=[[st objectAtIndex:1] intValue];	// direction
			switch([[st objectAtIndex:2] intValue]) {
				case 0: NSLog(@"active"); break;
				case 1: NSLog(@"held"); break;
				case 2: NSLog(@"dialing (MO)"); break;
				case 3: NSLog(@"alerting (MO)"); break;
				case 4: NSLog(@"incoming (MT)"); break;
				case 5: NSLog(@"waiting (MT)"); break;
				case 30: NSLog(@"terminated"); break;
			}
			return;
		}
	/* PLS8 messages */
	if([line hasPrefix:@"+CIEV:"])
		{ // diverse network indications enabled by AT^SIND="type"
			NSLog(@"network indication: %@", line);
			/*
			 service	- Verbunden oder nicht
			 roam	- beim roaming
			 eons	- operator
			 nitz	- datum/zeit/Zeitzone aus dem Netz
			 simstatus/simlocal
			 psinfo	- packet switched level
			 */
			if([line hasPrefix:@"+CIEV: eons"])
				;	// operator
			if([line hasPrefix:@"+CIEV: nitz"])
				;	// network date, time and time zone
			if([line hasPrefix:@"+CIEV: psinfo"])
				;	// should indicate 2G..4G
			return;
		}
	if([line hasPrefix:@"^SBC:"])
		{ // under/overvoltage
			CTModemManager *mm=[CTModemManager modemManager];
			if([line hasPrefix:@"^SBC: Overvoltage"])
				{
				[self _processUnsolicitedInfo:[[mm runATCommandReturnResponse:@"AT^SBV"] lastObject]];	// try to read voltage
				[mm _closePort];	// modem will close, so do before...
				[mm _closeModem];	// try shutdown
				}
			return;
		}
	if([line hasPrefix:@"^SBV:"])
		{ // voltage ^SBV: 4249
			NSArray *st=[line componentsSeparatedByString:@" "];
			paVolt=[[st lastObject] intValue];
			[delegate signalStrengthDidUpdate:currentNetwork];
			return;
		}
	if([line hasPrefix:@"^SCTM_B:"])
		{ // under/overtemperature - AT^SCTM? -> ^SCTM: 0,0,41
			NSArray *st=[line componentsSeparatedByString:@","];
			// check for -1, -2 or +1, +2
			if([st count] == 3)
				{
				paTemp=[[st objectAtIndex:2] intValue];	// PA temperature
				[delegate signalStrengthDidUpdate:currentNetwork];
				}
			return;
		}
	if([line hasPrefix:@"^SYSSTART"])
		{ // normal or AIRPLANE MODE
			paTemp=25.0;	// we do not know better
			[delegate signalStrengthDidUpdate:currentNetwork];
			return;
		}
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
	if(currentNetwork)
		return [NSSet setWithObject:currentNetwork];	// we can at least report the current network...
	return [NSSet set];
	// geht auch ohne PIN
	// ask AT+COPS=? - blockiert sehr lange (30-60 Sekunden)
	// +COPS: (1,"E-Plus","E-Plus","26203",0),(2,"o2 - de","o2 - de","26207",2),(1,"E-Plus","E-Plus","26203",2),(1,"T-Mobile D","TMO D","26201",0),(1,"o2 - de","o2 - de","26207",0),(1,"Vodafone.de","voda DE","26202",0),(1,"Vodafone.de","voda DE","26202",2),(1,"T-Mobile D","TMO D","26201",2),,(0,1,2,3,4),(0,1,2)
	// +COPS: (2,"o2 - de","o2 - de","26207",2),(1,"E-Plus","E-Plus","26203",0),(1,"E-Plus","E-Plus","26203",2),(1,"o2 - de","o2 - de","26207",0),(1,"Vodafone.de","voda DE","26202",0),(1,"T-Mobile D","TMO D","26201",0),(1,"T-Mobile D","TMO D","26201",2),(1,"Vodafone.de","voda DE","26202",2),,(0,1,2,3,4),(0,1,2)
	// 	at+cops=0  -- automatisch
	//  at+cops=1,2,26207  -- feste Wahl, Format <numerisch>
	// ohne SIM: +COPS: 0,0,"Limited Service",2
	// "1&1" scheint auch "26202" zu melden -> 26202 = physikalisches Netz (D1, D2, E1, E2)
	return nil;
}

- (float) paTemperature; { return paTemp; }
- (float) paVoltage; { return paVolt; }

@end
