//
//  CTCarrier.h
//  CoreTelephony
//
//  Created by H. Nikolaus Schaller on 04.07.11.
//  Copyright 2011 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CTCarrier : NSObject
{
	NSString	*carrierName;
	NSString	*isoCountryCode;
	NSString	*mobileCountryCode;
	NSString	*mobileNetworkCode;
	NSString	*cellID;
	float		strength;
	float		dBm;
	float		networkType;
}

- (NSString *) carrierName;
- (NSString *) isoCountryCode;
- (NSString *) mobileCountryCode;
- (NSString *) mobileNetworkCode;
- (BOOL) allowsVOIP;

@end

@interface CTCarrier (Extensions)

- (float) strength;		// signal strength (0..1)
- (float) dBm;			// signal strength (in dBm)
- (float) networkType;	// 2.0, 2.5, 3.0, 3.5 etc.
- (BOOL) canChoose;		// is permitted to use
- (void) choose;		// make this the current carrier
- (NSString *) cellID;	// current cell ID

@end