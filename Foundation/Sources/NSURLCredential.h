//
//  NSURLCredential.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Wed Jan 04 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

#import <Foundation/NSObject.h>

typedef enum _NSURLCredentialPersistence
{
	NSURLCredentialPersistenceNone,
	NSURLCredentialPersistenceForSession,
	NSURLCredentialPersistencePermanent
} NSURLCredentialPersistence;


@interface NSURLCredential : NSObject <NSCopying>
{
	NSString *_password;
	NSString *_user;
	NSURLCredentialPersistence _persistence;
}

+ (NSURLCredential *) credentialWithUser:(NSString *) user
								password:(NSString *) password
							 persistence:(NSURLCredentialPersistence) persistence;

- (BOOL) hasPassword;
- (id) initWithUser:(NSString *) user
		   password:(NSString *) password
		persistence:(NSURLCredentialPersistence) persistence;
- (NSString *) password;
- (NSURLCredentialPersistence) persistence;
- (NSString *) user;

@end