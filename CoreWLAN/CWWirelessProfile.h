#import <Foundation/Foundation.h>

@class CW8021XProfile;

@interface CWWirelessProfile : NSObject <NSCopying, NSCoding>

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
