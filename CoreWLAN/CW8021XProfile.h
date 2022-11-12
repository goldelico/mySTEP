//
//  CW8021XProfile.h
//  CoreWLAN
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2010 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CW8021XProfile : NSObject <NSCopying, NSCoding>
{
	NSString *_password;
	NSString *_ssid;
	NSString *_userDefinedName;
	NSString *_username;
	BOOL _alwaysPromptForPassword;	
}

+ (NSArray *) allUser8021XProfiles;
+ (CW8021XProfile *) profile; 

- (CW8021XProfile *) init; 
- (BOOL) isEqualToProfile:(CW8021XProfile *) profile; 

- (BOOL) alwaysPromptForPassword;
- (void) setAlwaysPromptForPassword:(BOOL) flag; 
// all following setters are by copy
- (NSString *) password;
- (void) setPassword:(NSString *) str;
- (NSString *) ssid;
- (void) setSsid:(NSString *) str;
- (NSString *) userDefinedName;
- (void) setUserDefinedName:(NSString *) name;
- (NSString *) username;
- (void) setUsername:(NSString *) name;

@end
