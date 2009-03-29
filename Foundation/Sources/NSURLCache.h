/*
    NSURLCache.h
    mySTEP

    Created by Dr. H. Nikolaus Schaller on Wed Jan 04 2006.
    Copyright (c) 2006 DSITRI. All rights reserved.
 
    Fabian Spillner, July 2008 - API revised to be compatible to 10.5 (NSURLCache)
*/

#import <Foundation/NSURLResponse.h>

@class NSData;
@class NSDictionary;
@class NSMutableDictionary;
@class NSURLRequest;
@class NSCachedURLResponse;

@interface NSURLCache : NSObject
{
	NSUInteger _memoryCapacity;
	NSUInteger _memoryUseage;
	NSUInteger _diskCapacity;
	NSUInteger _diskUseage;
	NSString *_diskPath;
	NSMutableDictionary *_cachedEntries;	// either NSCachedURLResponse or NSString (file path)
}

+ (void) setSharedURLCache:(NSURLCache *) urlCache;
+ (NSURLCache *) sharedURLCache;

- (NSCachedURLResponse *) cachedResponseForRequest:(NSURLRequest *) req;
- (NSUInteger) currentDiskUsage;
- (NSUInteger) currentMemoryUsage;
- (NSUInteger) diskCapacity;
- (id) initWithMemoryCapacity:(NSUInteger) memCap 
				 diskCapacity:(NSUInteger) diskCap 
					 diskPath:(NSString *) p;
- (NSUInteger) memoryCapacity;
- (void) removeAllCachedResponses;
- (void) removeCachedResponseForRequest:(NSURLRequest *) req;
- (void) setDiskCapacity:(NSUInteger) diskCap;
- (void) setMemoryCapacity:(NSUInteger) memCap;
- (void) storeCachedResponse:(NSCachedURLResponse *) response forRequest:(NSURLRequest *) req;

@end

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
