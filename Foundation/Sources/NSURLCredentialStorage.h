/*
    NSURLCredentialStorage.h
    mySTEP

    Created by Dr. H. Nikolaus Schaller on Wed Jan 04 2006.
    Copyright (c) 2006 DSITRI. All rights reserved.
 
    Fabian Spillner, July 2008 - API revised to be compatible to 10.5
*/

#import <Foundation/NSObject.h>

@class NSDictionary;
@class NSMutableDictionary;
@class NSURLCredential;
@class NSURLProtectionSpace;

@interface NSURLCredentialStorage : NSObject
{
	NSMutableDictionary *_protectionSpaces;
}

+ (NSURLCredentialStorage *) sharedCredentialStorage;

- (NSDictionary *) allCredentials;
- (NSDictionary *) credentialsForProtectionSpace:(NSURLProtectionSpace *) protectionSpace;
- (NSURLCredential *) defaultCredentialForProtectionSpace:(NSURLProtectionSpace *) protectionSpace;
- (void) removeCredential:(NSURLCredential *) credential forProtectionSpace:(NSURLProtectionSpace *) protectionSpace;
- (void) setCredential:(NSURLCredential *) credential forProtectionSpace:(NSURLProtectionSpace *) protectionSpace;
- (void) setDefaultCredential:(NSURLCredential *) credential forProtectionSpace:(NSURLProtectionSpace *) protectionSpace;

@end

extern NSString *NSURLCredentialStorageChangedNotification;
