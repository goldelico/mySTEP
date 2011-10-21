//
//  CWConfiguration.h
//  CoreWLAN
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2010 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CWConfiguration : NSObject <NSCopying, NSCoding>
{
	NSArray *_preferredNetworks;
	NSArray *_rememberedNetworks;	
	BOOL _alwaysRememberNetworks;
	BOOL _disconnectOnLogout;
	BOOL _requireAdminForIBSSCreation;
	BOOL _requireAdminForNetworkChange;
	BOOL _requireAdminForPowerChange;	
}

+ (CWConfiguration *) configuration; 

- (CWConfiguration *) init; 
- (BOOL) isEqualToConfiguration:(CWConfiguration *) config; 

- (BOOL) alwaysRememberNetworks;
- (void) setAlwaysRememberNetworks:(BOOL) flag; 
- (BOOL) disconnectOnLogout;
- (void) setDiconnectOnLogout:(BOOL) flag; 
- (BOOL) requireAdminForIBSSCreation;
- (void) setRequireAdminForIBSSCreation:(BOOL) flag; 
- (BOOL) requireAdminForNetworkChange;
- (void) setRequireAdminForNetworkChange:(BOOL) flag; 
- (BOOL) requireAdminForPowerChange;
- (void) setRequireAdminForPowerChange:(BOOL) flag; 

- (NSArray *) preferredNetworks;	// CWWirelessProfile
- (void) setPreferredNetworks:(NSArray *) str;
- (NSArray *) rememberedNetworks;	// CWWirelessProfile
- (void) setRememberedNetworks:(NSArray *) str;

@end
