//
//  CTPrivate.h
//  CoreTelephony
//
//  Created by H. Nikolaus Schaller on 04.07.11.
//  Copyright 2011 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "CTModemManager.h"

@interface CTCall (Private)
- (int) _callState;
- (void) _setCallState:(int) state;
- (void) _setPeerPhoneNumber:(NSString *) number;
@end

@interface CTCarrier (Private)
- (void) _setCarrierName:(NSString *) n;
- (void) _setStrength:(float) s;
- (void) _setNetworkSpeed:(float) s;
- (void) _setdBm:(float) s;
- (void) _setCellID:(NSString *) n;
@end

@interface CTTelephonyNetworkInfo (Private)
- (void) _processUnsolicitedInfo:(NSString *) line;
@end

@interface CTCallCenter (QStepPrivate)
// forward to modem manager
+ (void) _closeModem;
+ (void) orderFrontPinPanel;
+ (BOOL) setAirplaneMode:(BOOL) flag;
+ (int) pinStatus;
@end
