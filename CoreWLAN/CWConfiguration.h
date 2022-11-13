//
//  CWConfiguration.h
//  CoreWLAN
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2010 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CWConfiguration : NSObject <NSCopying, NSMutableCopying, NSSecureCoding>
{
	NSOrderedSet *_networkProfiles;
	BOOL _rememberJoinedNetworks;
	BOOL _requireAdministratorForAssociation;
	BOOL _requireAdministratorForIBSSMode;
	BOOL _requireAdministratorForPower;
}

+ (CWConfiguration *) configuration; 
+ (CWConfiguration *) configurationWithConfiguration:(CWConfiguration *) other;

- (id) init;
- (id) initWithConfiguration:(CWConfiguration *) other;

- (BOOL) isEqualToConfiguration:(CWConfiguration *) config;

- (NSOrderedSet *) networkProfiles;	// CWNetworkProfile
- (BOOL) rememberJoinedNetworks;
- (BOOL) requireAdministratorForAssociation;
- (BOOL) requireAdministratorForIBSSMode;
- (BOOL) requireAdministratorForPower;

@end

@interface CWMutableConfiguration : CWConfiguration
- (void) setRememberJoinedNetworks:(BOOL) flag;
- (void) setRequireAdministratorForAssociation:(BOOL) flag;
- (void) setRequireAdministratorForIBSSMode:(BOOL) flag;
- (void) setRequireAdministratorForPower:(BOOL) flag;
@end
