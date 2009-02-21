//
//  NSURLCredential.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Wed Jan 04 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

#import <Foundation/Foundation.h>


@implementation NSURLCredential

+ (NSURLCredential *) credentialWithUser:(NSString *) user
								password:(NSString *) password
							 persistence:(NSURLCredentialPersistence) persistence;
{
	return [[[self alloc] initWithUser:user password:password persistence:persistence] autorelease];
}

- (BOOL) hasPassword; { return _password != nil; }
- (NSString *) password; { return _password; }
- (NSURLCredentialPersistence) persistence; { return _persistence; }
- (NSString *) user; { return _user; }

- (id) initWithUser:(NSString *) user
		   password:(NSString *) password
		persistence:(NSURLCredentialPersistence) persistence;
{
	if((self=[super init]))
		{
		_password=[password retain];
		_user=[user retain];
		_persistence=persistence;
		}
	return self;
}

- (void) dealloc;
{
	[_password release];
	[_user release];
	[super dealloc];
}

- (id) copyWithZone:(NSZone *) zone;
{
	NSURLCredential *c=[isa allocWithZone:zone];
	if(c)
		{
		c->_password=[_password copyWithZone:zone];
		c->_user=[_user retain];
		c->_persistence=_persistence;
		}
	return c;
}

@end
