//
//  SFAuthorization.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Tue Mar 22 2005.
//  Copyright (c) 2005 DSITRI. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef char *AuthorizationString;
typedef void *AuthorizationRights;
typedef void *AuthorizationEnvironment;
typedef int AuthorizationFlags;
typedef id AuthorizationRef;
#ifndef __APPLE__
typedef int OSStatus;
#endif

@interface SFAuthorization

+ (id) authorization; 
- (AuthorizationRef) authorizationRef;
+ (id) authorizationWithFlags:(AuthorizationFlags) flags
					   rights:(AuthorizationRights *) rights
				  environment:(AuthorizationEnvironment *) env;
- (id) initWithFlags:(AuthorizationFlags) flags 
			  rights:(AuthorizationRights *) rights
		 environment:(AuthorizationEnvironment *) env;
- (void) invalidateCredentials; 
- (OSStatus) permitWithRight:(AuthorizationString) name
					   flags:(AuthorizationFlags) flags; 
- (OSStatus) permitWithRights:(AuthorizationRights *) rights
						flags:(AuthorizationFlags) flags
				  environment:(AuthorizationEnvironment *) env 
			 authorizedRights:(AuthorizationRights *) arights; 

@end

