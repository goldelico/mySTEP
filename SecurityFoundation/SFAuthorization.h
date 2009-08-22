//
//  SFAuthorization.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Tue Mar 22 2005.
//  Copyright (c) 2005 DSITRI. All rights reserved.
//

#import <Security/Authorization.h>
#import <Security/AuthorizationDB.h>
#import <Security/AuthorizationTags.h>

#import <Cocoa/Cocoa.h>

@interface SFAuthorization : NSObject
{
struct AuthorizationOpaqueRef
	{
		AuthorizationFlags flags;
		AuthorizationRights *rights;
		AuthorizationEnvironment *env;
	} _auth;
}

+ (id) authorization; 
+ (id) authorizationWithFlags:(AuthorizationFlags) flags
					   rights:(AuthorizationRights *) rights
				  environment:(AuthorizationEnvironment *) env;

- (AuthorizationRef) authorizationRef;
- (id) initWithFlags:(AuthorizationFlags) flags 
			  rights:(AuthorizationRights *) rights
		 environment:(AuthorizationEnvironment *) env;
- (void) invalidateCredentials; 
- (BOOL) obtainWithRight:(AuthorizationString) rightName
									 flags:(AuthorizationFlags) flags
									 error:(NSError **) error;

- (BOOL) obtainWithRights:(const AuthorizationRights *) rights
										flags:(AuthorizationFlags) flags
							environment:(const AuthorizationEnvironment *) environment
				 authorizedRights:(AuthorizationRights **) authorizedRights
										error:(NSError **) error;
- (OSStatus) permitWithRight:(AuthorizationString) name
					   flags:(AuthorizationFlags) flags; 
- (OSStatus) permitWithRights:(AuthorizationRights *) rights
						flags:(AuthorizationFlags) flags
				  environment:(AuthorizationEnvironment *) env 
			 authorizedRights:(AuthorizationRights *) arights; 

@end

