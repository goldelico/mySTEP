//
//  NSURLCredentialStorage.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Wed Jan 04 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

// CODE NOT TESTED

#import <Foundation/NSURLCredentialStorage.h>
#import <Foundation/NSURLCredential.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>

// FIXME:
// send NSURLCredentialStorageChangedNotification
// store somewhere in a shared file or the keychain
// depending on the persistence settings

@implementation NSURLCredentialStorage

+ (NSURLCredentialStorage *) sharedCredentialStorage;
{
	static NSURLCredentialStorage *_sharedCredentialStorage;
	if(!_sharedCredentialStorage)
		_sharedCredentialStorage=[self new];
	return _sharedCredentialStorage;
}

- (id) init;
{
	if((self=[super init]))
		{ // should read from external storage...
		}
	return self;
}

- (NSDictionary *) allCredentials;
{
	// merge all
	return NIMP;
}

- (NSDictionary *) credentialsForProtectionSpace:(NSURLProtectionSpace *) protectionSpace;
{
	return [_protectionSpaces objectForKey:protectionSpace];
}

- (NSURLCredential *) defaultCredentialForProtectionSpace:(NSURLProtectionSpace *) protectionSpace;
{
	return [[_protectionSpaces objectForKey:protectionSpace] objectForKey:@"Default"];
}

- (void) removeCredential:(NSURLCredential *) credential forProtectionSpace:(NSURLProtectionSpace *) protectionSpace;
{
	[[_protectionSpaces objectForKey:protectionSpace] removeObjectForKey:[credential user]];
}

- (void) setCredential:(NSURLCredential *) credential forProtectionSpace:(NSURLProtectionSpace *) protectionSpace;
{
	NSMutableDictionary *space=[_protectionSpaces objectForKey:protectionSpace];
	if(!space)
		[_protectionSpaces setObject:space=[NSMutableDictionary dictionaryWithCapacity:10] forKey:protectionSpace];
	[space setObject:credential forKey:[credential user]];
}

- (void) setDefaultCredential:(NSURLCredential *) credential forProtectionSpace:(NSURLProtectionSpace *) protectionSpace;
{
	NSMutableDictionary *space=[_protectionSpaces objectForKey:protectionSpace];
	if(!space)
		[_protectionSpaces setObject:space=[NSMutableDictionary dictionaryWithCapacity:10] forKey:protectionSpace];
	[space setObject:credential forKey:@"Default"];
}

@end
