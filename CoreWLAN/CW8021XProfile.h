#import <Foundation/Foundation.h>

@interface CW8021XProfile : NSObject <NSCopying, NSCoding>

+ (NSArray *) allUser8021XProfiles;
+ (CW8021XProfile *) profile; 

- (CW8021XProfile *) init; 
- (BOOL) isEqualToProfile:(CW8021XProfile *) profile; 

- (BOOL) alwaysPromptForPassword;
- (void) setAlwaysPromptForPassword:(BOOL) flag; 
// all are copy
- (NSString *) password;
- (void) setPassword:(NSString *) str;
- (NSString *) ssid;
- (void) setSsid:(NSString *) str;
- (NSString *) userDefinedName;
- (void) setUserDefinedName:(NSString *) name;
- (NSString *) username;
- (void) setUsername:(NSString *) name;

@end