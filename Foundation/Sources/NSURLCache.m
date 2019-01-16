//
//  NSURLCache.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Wed Jan 04 2006.
//  Copyright (c) 2006-2009 DSITRI. All rights reserved.
//

#import <Foundation/NSURLCache.h>
#import <Foundation/NSURLProtocol.h>
#import <Foundation/NSURLRequest.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSProcessInfo.h>
#import <Foundation/NSString.h>
#import <Foundation/NSKeyedArchiver.h>

@implementation NSURLCache

static NSURLCache *_sharedURLCache;

+ (void) setSharedURLCache:(NSURLCache *) urlCache;
{
	ASSIGN(_sharedURLCache, urlCache);
}

+ (NSURLCache *) sharedURLCache;
{
	if(!_sharedURLCache)
		_sharedURLCache=[[self alloc] initWithMemoryCapacity:1*(1024*1024) diskCapacity:20*(1024*1024) diskPath:[NSString stringWithFormat:@"%@/Library/Caches/%@", NSHomeDirectory(), [[NSProcessInfo processInfo] processName]]];
	return _sharedURLCache;
}

- (id) initWithMemoryCapacity:(NSUInteger) memCap diskCapacity:(NSUInteger) diskCap diskPath:(NSString *) p;
{
	if((self=[super init]))
			{
				NSError *error;
				NSFileManager *fm=[NSFileManager defaultManager];
				if(![fm fileExistsAtPath:p] && ![fm createDirectoryAtPath:p withIntermediateDirectories:YES attributes:nil error:&error])
						{ // create directory at path (checks for errors)
							NSLog(@"can't create NSURLCache at %@: %@", p, error);	// note in system log
							[self release];
							return nil;
						}
				_memoryCapacity=memCap;
				_diskCapacity=diskCap;
				_diskUseage=0;	// read disk file size
				_diskPath=[p retain];
				_memoryCache=[[NSMutableDictionary alloc] initWithCapacity:10];
			}
	return self;
}

- (void) dealloc;
{
	[_memoryCache release];
	[_diskPath release];
	[super dealloc];
}

- (NSString *) _diskFileNameForRequest:(NSURLRequest *) req;
{
	NSString *file=[NSString stringWithFormat:@"%@/%lu", _diskPath, [[[req URL] absoluteString] hash]];	// should we use a MD5 hash?
#if 1
	NSLog(@"disk file %@", file);
#endif
	return file;
}

- (NSCachedURLResponse *) cachedResponseForRequest:(NSURLRequest *) req;
{
	NSCachedURLResponse *resp=[_memoryCache objectForKey:req];
	if(!resp)
			{
				resp=[NSKeyedUnarchiver unarchiveObjectWithFile:[self _diskFileNameForRequest:req]];	// may have been saved on disk
				// check if that what we have found is really compatible (hash conflict)
				// if we have enough room in the memory cache, we could also save a copy here so that we read from disk only once...
			}
	return resp;	// not available
}

- (NSUInteger) currentDiskUsage;
{
	if(_diskCapacity > 0 && _diskUseage == 0)
			{
				// sum up size of all disk files
			}
	return _diskUseage;
}

- (NSUInteger) currentMemoryUsage;	{ return _memoryUseage; }
- (NSUInteger) diskCapacity;	{ return _diskCapacity; }
- (NSUInteger) memoryCapacity; { return _memoryCapacity; }

- (void) removeAllCachedResponses;
{
	[_memoryCache removeAllObjects];
	// wipe out disk cache
	_memoryUseage=0;
	_diskUseage=0;
}

- (void) removeCachedResponseForRequest:(NSURLRequest *) req;
{
	NSCachedURLResponse *resp=[_memoryCache objectForKey:req];
	_memoryUseage -= [[resp data] length];	// reduce
	// remove from disk 
	_diskUseage=0;	// recalculate
}

- (void) setDiskCapacity:(NSUInteger) diskCap; { _diskCapacity=diskCap; }
- (void) setMemoryCapacity:(NSUInteger) memCap; { _memoryCapacity=memCap; }

- (void) storeCachedResponse:(NSCachedURLResponse *) response forRequest:(NSURLRequest *) req;
{ // store to both caches as long as we have room
	NSUInteger size=[[response data] length];	// approximate (does not cover other iVars of NSCachedURLResponse and NSKeyedArchiver headers)
  switch([response storagePolicy])
		{
			case NSURLCacheStorageAllowed:
				if(size <= _diskCapacity)
						{ // if we have enough space on disk
							NSString *name=[self _diskFileNameForRequest:req];
							while([self currentDiskUsage] + size > _diskCapacity)
								{ // remove other entries to make room (largest first? smallest first? oldest first?)
								}
							// this should be delayed + but already included in the real disk useage
							[NSKeyedArchiver archiveRootObject:response toFile:name];
							_diskUseage=0;	// recalculate
						}
			case NSURLCacheStorageAllowedInMemoryOnly:
				if(size <= _memoryCapacity)
						{
							while(_memoryUseage + size > _memoryCapacity)
								{	// remove entries (largest first? smallest first? oldest first?)
								}
							[_memoryCache setObject:response forKey:req];
							_memoryUseage += size;
						}
				break;
			case NSURLCacheStorageNotAllowed:
				return;
		}
	return;
}

@end


@implementation NSCachedURLResponse

// FIXME: we handle Responses here and not NSURLRequests!

- (BOOL) isEqual:(id) other
{
	// when are two responses equal???
	return [super isEqual:other];
}

- (NSUInteger) hash;
{ // FIXME: this must be the same for two cache-equivalent responses...
	return [super hash];
}

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

- (void) encodeWithCoder:(NSCoder *) encoder
{
	[encoder encodeObject:_response forKey:@"response"];	// NSURLResponse must also implement encode
	[encoder encodeObject:_data forKey:@"data"];
	[encoder encodeObject:_userInfo forKey:@"userInfo"];
	[encoder encodeInt:_storagePolicy forKey:@"storagePolicy"];
}

- (id) initWithCoder:(NSCoder *) decoder
{
	return [self initWithResponse:[decoder decodeObjectForKey:@"response"]
													 data:[decoder decodeObjectForKey:@"data"]
											 userInfo:[decoder decodeObjectForKey:@"userInfo"]
									storagePolicy:(NSURLCacheStoragePolicy) [decoder decodeIntForKey:@"storagePolicy"]];
}

@end
