//
//  NSURLProtectionSpace.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Wed Jan 04 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

// CODE NOT TESTED

#import <Foundation/Foundation.h>


@implementation NSURLProtectionSpace

- (NSString *) authenticationMethod; { return _authenticationMethod; }
- (NSString *) host; { return _host; }
- (BOOL) isProxy; { return _proxyType != nil; }
- (int) port; { return _port; }
- (NSString *) protocol; { return _protocol; }
- (NSString *) proxyType; { return _proxyType; }
- (NSString *) realm; { return _realm; }
- (BOOL) receivesCredentialSecurely; { return _receivesCredentialSecurely; }

- (id) initWithHost:(NSString *) host
			   port:(int) port
		   protocol:(NSString *) protocol
			  realm:(NSString *) realm
 authenticationMethod:(NSString *) method;
{
	if((self=[super init]))
		{
		_host=[host retain];
		_port=port;
		_protocol=[protocol retain];
		_realm=[realm retain];
		_authenticationMethod=[method retain];
		}
	return self;
}

- (id) initWithProxyHost:(NSString *) host
					port:(int) port
					type:(NSString *) type
				   realm:(NSString *) realm
	authenticationMethod:(NSString *) method;
{
	if((self=[super init]))
		{
		_host=[host retain];
		_port=port;
		_proxyType=[type retain];
		_realm=[realm retain];
		_authenticationMethod=[method retain];
		}
	return self;
}

- (void) dealloc;
{
	[_authenticationMethod release];
	[_host release];
	[_protocol release];
	[_proxyType release];
	[_realm release];
	[super dealloc];
}

- (id) copyWithZone:(NSZone *) z;
{
	NSURLProtectionSpace *c=[NSURLProtectionSpace allocWithZone:z];
	if(c)
		{
		c->_authenticationMethod=[_authenticationMethod retain];
		c->_host=[_host retain];
		c->_protocol=[_protocol retain];
		c->_proxyType=[_proxyType retain];
		c->_realm=[_realm retain];
		c->_port=_port;
		}
	return c;
}

@end
