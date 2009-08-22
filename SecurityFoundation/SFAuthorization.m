//
//  SFAuthorization.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Tue Mar 22 2005.
//  Copyright (c) 2005 DSITRI. All rights reserved.
//

#import <SecurityFoundation/SFAuthorization.h>

@implementation SFAuthorization

+ (id) authorization; 
{
	return [self authorizationWithFlags:0 rights:NULL environment:NULL];
}


- (AuthorizationRef) authorizationRef;
{
	return &_auth;
}


+ (id) authorizationWithFlags:(AuthorizationFlags) flags
					   rights:(AuthorizationRights *) rights
				  environment:(AuthorizationEnvironment *) env;
{
	return [[[self alloc] initWithFlags:flags rights:rights environment:env] autorelease];
}

- (id) initWithFlags:(AuthorizationFlags) flags 
			  rights:(AuthorizationRights *) rights
		 environment:(AuthorizationEnvironment *) env;
{
	if((self=[super init]))
		{
		_auth.flags=flags;
		_auth.rights=rights;
		_auth.env=env;
		}
	return self;
}

- (void) invalidateCredentials; 
{
	_auth.flags=0;
	_auth.rights=NULL;
	_auth.env=NULL;
}

- (BOOL) obtainWithRight:(AuthorizationString) rightName
									 flags:(AuthorizationFlags) flags
									 error:(NSError **) error;
{
	return NO;
}

- (BOOL) obtainWithRights:(const AuthorizationRights *) rights
										flags:(AuthorizationFlags) flags
							environment:(const AuthorizationEnvironment *) environment
				 authorizedRights:(AuthorizationRights **) authorizedRights
										error:(NSError **) error;
{
	return NO;
}

- (OSStatus) permitWithRight:(AuthorizationString) name
					   flags:(AuthorizationFlags) flags; 
{
//	NIMP;
	return -1;
}

- (OSStatus) permitWithRights:(AuthorizationRights *) rights
						flags:(AuthorizationFlags) flags
				  environment:(AuthorizationEnvironment *) env 
			 authorizedRights:(AuthorizationRights *) arights; 
{
//	NIMP;
	return -1;
}

@end

