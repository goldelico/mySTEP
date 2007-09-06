//
//  NSURLCache.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Wed Jan 04 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

#import <Foundation/NSURLResponse.h>

@class NSData;
@class NSDictionary;

typedef enum _NSURLCacheStoragePolicy
{
	NSURLCacheStorageAllowed,
	NSURLCacheStorageAllowedInMemoryOnly,
	NSURLCacheStorageNotAllowed,
} NSURLCacheStoragePolicy;


@interface NSCachedURLResponse : NSObject
{
	NSData *_data;
	NSURLResponse *_response;
	NSURLCacheStoragePolicy _storagePolicy;
	NSDictionary *_userInfo;
}

- (NSData *) data;
- (id) initWithResponse:(NSURLResponse *) response data:(NSData *) data;
- (id) initWithResponse:(NSURLResponse *) response data:(NSData *) data userInfo:(NSDictionary *) userInfo storagePolicy:(NSURLCacheStoragePolicy) storagePolicy;
- (NSURLResponse *) response;
- (NSURLCacheStoragePolicy) storagePolicy;
- (NSDictionary *) userInfo;

@end