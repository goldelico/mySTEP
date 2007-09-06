//
//  NSURLProtectionSpace.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Wed Jan 04 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

#import <Foundation/NSObject.h>

extern NSString *NSURLProtectionSpaceHTTPProxy;
extern NSString *NSURLProtectionSpaceHTTPSProxy;
extern NSString *NSURLProtectionSpaceFTPProxy;
extern NSString *NSURLProtectionSpaceSOCKSProxy;

extern NSString *NSURLAuthenticationMethodDefault;
extern NSString *NSURLAuthenticationMethodHTTPBasic;
extern NSString *NSURLAuthenticationMethodHTTPDigest;
extern NSString *NSURLAuthenticationMethodHTMLForm;

@interface NSURLProtectionSpace : NSObject <NSCopying>
{
	NSString *_authenticationMethod;
	NSString *_host;
	NSString *_protocol;
	NSString *_proxyType;
	NSString *_realm;
	int _port;
	BOOL _receivesCredentialSecurely;
}

- (NSString *) authenticationMethod;
- (NSString *) host;
- (id) initWithHost:(NSString *) host
			   port:(int) port
		   protocol:(NSString *) protocol
			  realm:(NSString *) realm
 authenticationMethod:(NSString *) method;
- (id) initWithProxyHost:(NSString *) host
					port:(int) port
					type:(NSString *) type
				   realm:(NSString *) realm
	authenticationMethod:(NSString *) method;
- (BOOL) isProxy;
- (int) port;
- (NSString *) protocol;
- (NSString *) proxyType;
- (NSString *) realm;
- (BOOL) receivesCredentialSecurely;

@end