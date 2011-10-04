//
//  CTCall.h
//  CoreTelephony
//
//  Created by H. Nikolaus Schaller on 04.07.11.
//  Copyright 2010 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <CoreTelephony/CoreTelephony.h>
#import "CTModemManager.h"

NSString const *CTCallStateDialing=@"CTCallStateDialing";
NSString const *CTCallStateIncoming=@"CTCallStateIncoming";
NSString const *CTCallStateConnected=@"CTCallStateConnected";
NSString const *CTCallStateDisconnected=@"CTCallStateDisconnected";

@interface CTCall (Private)
- (int) _callState;
- (void) _setCallState:(int) state;
- (void) _setPeerPhoneNumber:(NSString *) number;
@end

@interface CTCarrier (Private)

- (void) _setCarrierName:(NSString *) n;
- (void) _setStrength:(float) s;
- (void) _setNetworkType:(float) s;
- (void) _setdBm:(float) s;
- (void) _setCellID:(NSString *) n;

@end

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
		CTModemManager *m=[CTModemManager modemManager];
		currentCalls=[[NSMutableSet alloc] initWithCapacity:10];
		[m setUnsolicitedTarget:self action:@selector(processUnsolicitedInfo:)];
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

- (void) processUnsolicitedInfo:(NSString *) line
{
#if 1
	NSLog(@"processUnsolicitedInfo: %@", line);
#endif
	if([line hasPrefix:@"RING"] || [line hasPrefix:@"+CRING:"])
		{
		// incoming call
		NSLog(@"incoming call: %@", line);
		return;
		}
	if([line hasPrefix:@"BUSY"])
		{
		NSLog(@"busy: %@", line);
		return;
		}
	if([line hasPrefix:@"NO CARRIER"])
		{
		NSLog(@"remote hangup: %@", line);
		return;
		}
	if([line hasPrefix:@"+CBM:"])
		{
		NSLog(@"cell broadcast message: %@", line);
		return;
		}
	if([line hasPrefix:@"_OPON:"])
		{ // current visited network - _OPON: <cs>,<oper>,<src>
			// notify through CTCarrier/CTTelephonyNetworkInfo
			NSLog(@"visited network: %@", line);
/*
 CTTelephonyNetworkInfo *ni=[CTTelephonyNetworkInfo telephonyNetworkInfo];
 CTCarrier *carrier=[ni subscriberCellularProvider];
 NSScanner *sc=[NSScanner scannerWithString:line];
 NSString *cs=@"unknown";
 NSString *name=@"unknown";
 NSString *name=@"src";
 [sc scanString:@"_OPON: \"" intoString:NULL];
 [sc scanUpToString:@"\"" intoString:&cs];
 [sc scanUpToString:@"\"" intoString:&name];
 [sc scanUpToString:@"\"" intoString:&src];
 [carrier _setCarrierName:name];
 #if 1
 NSLog(@"carrier name=%@ delegate=%@", name, [ni delegate]);
 #endif
 [[ni delegate] subscriberCellularProviderDidUpdate:carrier];
 return;
*/
			return;
		}
	if([line hasPrefix:@"_OSIGQ:"])
		{ // signal quality - _OSIGQ: 2*<rssi>-113dBm,<ber> (ber=99)
			CTTelephonyNetworkInfo *ni=[CTTelephonyNetworkInfo telephonyNetworkInfo];
			CTCarrier *carrier=[ni currentNetwork];
			int dbm=[[line substringFromIndex:8] intValue];
			if(dbm == 99) dbm=(113-999)/2;	// show -999 dBm
			[carrier _setdBm:2.0*dbm-113.0];
			[[ni delegate] signalStrengthDidUpdate:carrier];
			return;
		}
	if([line hasPrefix:@"_OEANT:"])
		{ // antenna level - _OEANT: <n> (0..5 but 4 is the maximum ever reported)
			CTTelephonyNetworkInfo *ni=[CTTelephonyNetworkInfo telephonyNetworkInfo];
			CTCarrier *carrier=[ni currentNetwork];
			float strength=[[line substringFromIndex:8] floatValue]/4.0;
			if(strength > 1.0) strength=1.0;	// limit
			[carrier _setStrength:strength];
			[[ni delegate] signalStrengthDidUpdate:carrier];
			return;
		}
	if([line hasPrefix:@"_OCTI:"])
		{ // GSM/EDGE cell type - _OCTI: <n> (0..3)
			CTTelephonyNetworkInfo *ni=[CTTelephonyNetworkInfo telephonyNetworkInfo];
			CTCarrier *carrier=[ni currentNetwork];
#if 1
			NSLog(@"GSM capability: %@", line);
#endif
			switch([[line substringFromIndex:8] intValue]) {
				case 1:
					[carrier _setNetworkType:2.0];	// GSM
					break;
				case 2:
					[carrier _setNetworkType:2.5];	// GPRS
					break;
				case 3:
					[carrier _setNetworkType:2.75];	// EDGE - see http://en.wikipedia.org/wiki/2G#Evolution
					break;
				default:
					[carrier _setNetworkType:0.0];	// unknown
			}
			[[ni delegate] signalStrengthDidUpdate:carrier];
			return;
		}
	if([line hasPrefix:@"_OUWCTI:"])
		{ // WDMA cell type - _OUWCTI: <n> (0..4)
			CTTelephonyNetworkInfo *ni=[CTTelephonyNetworkInfo telephonyNetworkInfo];
			CTCarrier *carrier=[ni currentNetwork];
#if 1
			NSLog(@"WCDMA capability: %@", line);
#endif
			switch([[line substringFromIndex:8] intValue]) { // see http://3g4g.blogspot.com/2007/05/3g-39g.html
				default:
					return;	// non-wcdma - don't overwrite
				case 1:
					[carrier _setNetworkType:3.0];	// WCDMA
					break;
				case 2:
					[carrier _setNetworkType:3.5];	// WCDMA+HSDPA
					break;
				case 3:
					[carrier _setNetworkType:3.75];	// WCDMA+HSUPA
					break;
				case 4:
					[carrier _setNetworkType:3.75];	// WCDMA+HSDPA+HSUPA
					break;
			}
			[[ni delegate] signalStrengthDidUpdate:carrier];
			return;
		}
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
}

- (NSSet *) currentCalls; { return currentCalls; }

- (id <CTCallCenterDelegate>) delegate; { return delegate; }
- (void) setDelegate:(id <CTCallCenterDelegate>) d; { delegate=d; }

// see ANNEX G of GSM 07.07 how voice dialling works */

- (CTCall *) dial:(NSString *) number;
{
	CTModemManager *mm=[CTModemManager modemManager];
	// check if we are already connected
	// check string for legal characters (0-9, +, #, *, G/g, I/i, space)
	NSString *colp, *err;
	NSString *cmd=[NSString stringWithFormat:@"ATD%@;", number];	// initiate a voice call
	[mm runATCommand:@"AT+COLP=1"];	// report phone number and make ATD blocking
	colp=[mm runATCommandReturnResponse:cmd];
	if(colp)
		{ // successfull call setup
#if 1
			NSLog(@"dial ok: %@", colp);
#endif
			// we could check the COLP message to set the peer phone number!
			CTCall *call=[[CTCall new] autorelease];
			[call _setCallState:kCTCallStateDialing];
			[call _setPeerPhoneNumber:number];
			[currentCalls addObject:call];
			// notify delegate
			return call;
		}
	err=[mm error];
#if 1
	NSLog(@"dial error: %@", err);
#endif
	/*
	 unsolicited responses may be
	 NO CARRIER, BUSY, NO ANSWER and CONNECT
	 */
	if([err isEqualToString:@""])
		{
		
		}
	return nil;	// not successfull
}

- (BOOL) sendSMS:(NSString *) number message:(NSString *) message;
{
	// send a SMS
	return NO;
}

// FIXME: in State-Machine einbauen - ein Befehl fertig triggert den nächsten...
// und letzter triggert nach Timeout den ersten
// also eine polling-queue

- (void) timer
{ // timer triggered commands
	[[CTModemManager modemManager] runATCommand:@"AT_OBLS"];	// get SIM status (removed etc.)
	// wait for being processed
	[[CTModemManager modemManager] runATCommand:@"AT_OBSI"];	// base station location
	// wait for being processed
	[[CTModemManager modemManager] runATCommand:@"AT_ONCI?"];	// neighbouring base stations
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
	[[CTModemManager modemManager] runATCommand:@"AT+CHUP"];
	// error handling?
}

- (void) hold;
{
	// anytime
}

- (void) accept;	// if incoming
{
	// ATO?
	// if CTCallStateIncoming
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

- (NSString *) carrierName; { return carrierName; }
- (NSString *) isoCountryCode; { return isoCountryCode; }
- (NSString *) mobileCountryCode; { return mobileCountryCode; }
- (NSString *) mobileNetworkCode; { return mobileNetworkCode; }
- (BOOL) allowsVOIP; { return YES; }

- (float) strength; { return strength; }	// signal strength (0..1.0)
- (float) dBm; { return dBm; }		// signal strength (in dBm)
- (float) networkSpeed; { return networkType; }	// 1.0, 2.0, 2.5, 3.0, 3.5 etc.
- (NSString *) cellID;	 { return cellID; }// current cell ID
- (BOOL) canChoose; { return YES; }// is permitted to select (if there are alternatives)

// - (id) initWithName:(NSString *) name isoCode etc. --- oder initWithResponse:

- (void) _setCarrierName:(NSString *) n; { [carrierName autorelease]; carrierName=[n retain]; }
- (void) _setStrength:(float) s; { strength=s; }
- (void) _setNetworkType:(float) s; { networkType=s; }
- (void) _setdBm:(float) s; { dBm=s; }
- (void) _setCellID:(NSString *) n; { [cellID autorelease]; cellID=[n retain]; }

- (void) choose;
{ // make the current carrier if there are several options to choose
	return;
}

@end

@implementation CTTelephonyNetworkInfo

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
		NSString *simop;
		CTModemManager *m=[CTModemManager modemManager];
		SINGLETON_VARIABLE = self;
		/* custom initialization here */
		subscriberCellularProvider=[CTCarrier new];	// create default entry
		currentNetwork=[subscriberCellularProvider retain];	// default: the same
		[subscriberCellularProvider _setCarrierName:@"No SIM"];	// default if we can't read the SIM
		// FIXME: this works only with PIN!
		simop=[m runATCommandReturnResponse:@"AT_OSIMOP"];
		if(simop)
			{ // home plnm - _OSIMOP: “<long_op>”,”<short_op>”, ”<MCC_MNC>”
				NSScanner *sc=[NSScanner scannerWithString:simop];
				NSString *name=@"unknown";
				[sc scanString:@"_OSIMOP: \"" intoString:NULL];
				[sc scanUpToString:@"\"" intoString:&name];
				[subscriberCellularProvider _setCarrierName:name];
#if 1
				NSLog(@"carrier name=%@", name);
#endif
			}
		else
			NSLog(@"AT_OSIMOP error: %@", [m error]);
		}
	}
    return self;
}

- (void) dealloc
{ // should not be possible for a singleton!
	NSLog(@"CTTelephonyNetworkInfo dealloc");
	abort();
	[subscriberCellularProvider release];
	[super dealloc];
}

#undef SINGLETON_CLASS
#undef SINGLETON_VARIABLE
#undef SINGLETON_HANDLE

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
	// geht auch ohne PIN
	// ask AT+COPS? - blockiert sehr lange (30-60 Sekunden)
	// +COPS: (1,"E-Plus","E-Plus","26203",0),(2,"o2 - de","o2 - de","26207",2),(1,"E-Plus","E-Plus","26203",2),(1,"T-Mobile D","TMO D","26201",0),(1,"o2 - de","o2 - de","26207",0),(1,"Vodafone.de","voda DE","26202",0),(1,"Vodafone.de","voda DE","26202",2),(1,"T-Mobile D","TMO D","26201",2),,(0,1,2,3,4),(0,1,2)	
	// +COPS: (2,"o2 - de","o2 - de","26207",2),(1,"E-Plus","E-Plus","26203",0),(1,"E-Plus","E-Plus","26203",2),(1,"o2 - de","o2 - de","26207",0),(1,"Vodafone.de","voda DE","26202",0),(1,"T-Mobile D","TMO D","26201",0),(1,"T-Mobile D","TMO D","26201",2),(1,"Vodafone.de","voda DE","26202",2),,(0,1,2,3,4),(0,1,2)
	// 	at+cops=0  -- automatisch
	//  at+cops=1,2,27207  -- feste Wahl, Format <numerisch>
	// ohne SIM: +COPS: 0,0,"Limited Service",2
	return nil;
}

@end
