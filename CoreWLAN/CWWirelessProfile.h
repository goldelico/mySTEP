//
//  CWWirelessProfile.h
//  CoreWLAN
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2010 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CW8021XProfile;

@interface CWWirelessProfile : NSObject <NSCopying, NSCoding>
{
	
}

+ (CWWirelessProfile *) profile; 

- (CWWirelessProfile *) init; 
- (BOOL) isEqualToProfile:(CWWirelessProfile *) profile; 

- (NSString *) passphrase;
- (void) setPassphrase:(NSString *) str;	// copy
- (NSNumber *) securityMode;
- (void) setSecurityMode:(NSNumber *) str;
- (NSString *) ssid;
- (void) setSsid:(NSString *) name;
- (CW8021XProfile *) user8021XProfile;
- (void) setUser8021XProfile:(CW8021XProfile *) name;

@end
