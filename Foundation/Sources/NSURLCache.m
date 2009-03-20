//
//  NSURLCache.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Wed Jan 04 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

#import <Foundation/NSURLCache.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSProcessInfo.h>
#import <Foundation/NSString.h>

@implementation NSURLCache

static NSURLCache *_sharedURLCache;

+ (void) setSharedURLCache:(NSURLCache *) urlCache;
{
	ASSIGN(_sharedURLCache, urlCache);
}

+ (NSURLCache *) sharedURLCache;
{
	if(!_sharedURLCache)
		_sharedURLCache=[[self alloc] initWithMemoryCapacity:100000 diskCapacity:500000 diskPath:[NSString stringWithFormat:@"%@/Library/Caches/%@", NSHomeDirectory(), [[NSProcessInfo processInfo] processName]]];
	return _sharedURLCache;
}

- (id) initWithMemoryCapacity:(NSUInteger) memCap diskCapacity:(NSUInteger) diskCap diskPath:(NSString *) p;
{
	if((self=[super init]))
			{
				NSError *error;
				if(![[NSFileManager defaultManager] createDirectoryAtPath:p withIntermediateDirectories:YES attributes:nil error:&error])
						{ // create directory at path (check for errors)
							NSLog(@"can't ccreate NSURLCache at %@: %@", p, error);
							[self release];
							return nil;
						}
				_memoryCapacity=memCap;
				_diskCapacity=diskCap;
				_diskPath=[p retain];
			}
	return self;
}

- (void) dealloc;
{
	[_diskPath release];
	[super dealloc];
}

- (NSCachedURLResponse *) cachedResponseForRequest:(NSURLRequest *) req;
{
	/*
	 * use [NSURLProtocol requestIsCacheEquivalent: toRequest: ]
	 * to locate a cached entry
	 */
	
	return nil;	// not available
}

- (NSUInteger) currentDiskUsage; { NIMP; return 0; }
- (NSUInteger) currentMemoryUsage;	{ NIMP; return 0; }
- (NSUInteger) diskCapacity;	{ return _diskCapacity; }
- (NSUInteger) memoryCapacity; { return _memoryCapacity; }
- (void) removeAllCachedResponses; { /* NIMP */ return; }
- (void) removeCachedResponseForRequest:(NSURLRequest *) req; { /* NIMP */ return; }
- (void) setDiskCapacity:(NSUInteger) diskCap; { _diskCapacity=diskCap; }
- (void) setMemoryCapacity:(NSUInteger) memCap; { _memoryCapacity=memCap; }

- (void) storeCachedResponse:(NSCachedURLResponse *) response forRequest:(NSURLRequest *) req;
{
	// NIMP
	return;
}

@end


@implementation NSCachedURLResponse

- (NSData *) data; { return _data; }
- (NSURLResponse *) response; { return _response; }
- (NSURLCacheStoragePolicy) storagePolicy; { return _storagePolicy; }
- (NSDictionary *) userInfo; { return _userInfo; }

- (id) initWithResponse:(NSURLResponse *) response data:(NSData *) data;
{
	return [self initWithResponse:response data:data userInfo:nil storagePolicy:NSURLCacheStorageAllowed];
}

- (id) initWithResponse:(NSURLResponse *) response data:(NSData *) data userInfo:(NSDictionary *) userInfo storagePolicy:(NSURLCacheStoragePolicy) storagePolicy;
{
	if((self=[super init]))
		{
		_response=[response retain];
		_data=[data retain];
		_userInfo=[userInfo retain];
		_storagePolicy=storagePolicy;
		}
	return self;
}

- (void) dealloc;
{
	[_data release];
	[_response release];
	[_userInfo release];
	[super dealloc];
}

@end
