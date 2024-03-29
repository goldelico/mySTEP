//
//  CWNetworkProfile.h
//  CoreWLAN
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2010 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CW8021XProfile;

@interface CWNetworkProfile : NSObject <NSCopying, NSCoding>
{
	NSData *_ssid;
	CWSecurity _mode;
}

/*- (id) init; */
- (id) initWithNetworkProfile:(CWNetworkProfile *) other;

+ (CWNetworkProfile *) networkProfile;
+ (CWNetworkProfile *) networkProfileWithNetworkProfile:(CWNetworkProfile *) other;

- (BOOL) isEqualToProfile:(CWNetworkProfile *) profile;

- (CWSecurity) security;
- (NSString *) ssid;
- (NSData *) ssidData;

@end

@interface CWMutableNetworkProfile : CWNetworkProfile

- (void) setSecurity:(CWSecurity) security;
- (void) setSsid:(NSString *) ssid;	//encode as UTF8 or WinLatin1, set to nil
- (void) setSsidData:(NSData *) ssid;

@end
