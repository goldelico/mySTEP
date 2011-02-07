#import <Foundation/Foundation.h>

@interface CWConfiguration : NSObject <NSCopying, NSCoding>

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

// all are copy
- (NSArray *) preferredNetworks;
- (void) setPreferredNetworks:(NSArray *) str;
- (NSArray *) rememberedNetworks;
- (void) setRememberedNetworks:(NSArray *) str;

@end