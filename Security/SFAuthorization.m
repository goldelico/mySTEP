//
//  SFAuthorization.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Tue Mar 22 2005.
//  Copyright (c) 2005 DSITRI. All rights reserved.
//

#import <Security/SFAuthorization.h>

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

- (OSStatus) permitWithRight:(AuthorizationString) name
					   flags:(AuthorizationFlags) flags; 
{
	return -1;
}

- (OSStatus) permitWithRights:(AuthorizationRights *) rights
						flags:(AuthorizationFlags) flags
				  environment:(AuthorizationEnvironment *) env 
			 authorizedRights:(AuthorizationRights *) arights; 
{
	return -1;
}

@end

