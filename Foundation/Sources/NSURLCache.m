//
//  NSURLCache.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Wed Jan 04 2006.
//  Copyright (c) 2006-2009 DSITRI. All rights reserved.
//

#import <Foundation/NSURLCache.h>
#import <Foundation/NSURLProtocol.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSProcessInfo.h>
#import <Foundation/NSString.h>
#import <Foundation/NSKeyedArchiver.h>

@implementation NSURLCache

static NSURLCache *_sharedURLCache;

// FIXME: the caching mechanism does not clear the disk if the app terminates
// and it does not read cached responses from the last time the application did run
// i.e. we should better organize memory and disk caches as two cache levels (LRU)

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
				_diskPath=[p retain];
				_cachedEntries=[[NSMutableDictionary alloc] initWithCapacity:10];
			}
	return self;
}

- (void) dealloc;
{
	[_cachedEntries release];
	[_diskPath release];
	[super dealloc];
}

- (NSCachedURLResponse *) cachedResponseForRequest:(NSURLRequest *) req;
{
	id resp=[_cachedEntries objectForKey:req];
	if([resp isKindOfClass:[NSString class]])
			resp=[NSKeyedUnarchiver unarchiveObjectWithFile:(NSString *) resp];	// has been saved on disk
	return (NSCachedURLResponse *) resp;	// not available
}

- (NSUInteger) currentDiskUsage; { return _diskUseage; }
- (NSUInteger) currentMemoryUsage;	{ return _memoryUseage; }
- (NSUInteger) diskCapacity;	{ return _diskCapacity; }
- (NSUInteger) memoryCapacity; { return _memoryCapacity; }

- (void) removeAllCachedResponses; { NSEnumerator *e=[_cachedEntries keyEnumerator]; NSURLRequest *req; while((req=[e nextObject])) [self removeCachedResponseForRequest:req]; }

- (void) removeCachedResponseForRequest:(NSURLRequest *) req;
{
	id resp=[_cachedEntries objectForKey:req];
	if(resp)
			{ // is cached
				if([resp isKindOfClass:[NSString class]])
						{ // delete from disk
							// we may save the unarchiving step if we use size of the archive file and not of the contents
							NSCachedURLResponse *r = [NSKeyedUnarchiver unarchiveObjectWithFile:(NSString *) resp];
							[[NSFileManager defaultManager] removeFileAtPath:(NSString *) resp handler:nil];
							_diskUseage -= [[(NSCachedURLResponse *) r data] length];	// reduce
						}
				else
					_memoryUseage -= [[(NSCachedURLResponse *) resp data] length];	// reduce
			}
	[_cachedEntries removeObjectForKey:req];	// remove from memory or remove link to file name
}

- (void) setDiskCapacity:(NSUInteger) diskCap; { _diskCapacity=diskCap; }
- (void) setMemoryCapacity:(NSUInteger) memCap; { _memoryCapacity=memCap; }

- (void) storeCachedResponse:(NSCachedURLResponse *) response forRequest:(NSURLRequest *) req;
{
	NSUInteger size=[[response data] length];	// approximate (does not cover other iVars of NSCachedURLResponse and NSKeyedArchiver headers)
  switch([response storagePolicy])
		{
			case NSURLCacheStorageAllowed:
				if(_memoryUseage + size >= _memoryCapacity)
						{ // must save on disk
							if(_diskUseage + size < _diskCapacity)
									{ // can save on disk
										NSString *name=[_diskPath stringByAppendingString:@"cachedfilename"];	// FIXME: build unique file name for fast file access
										[NSKeyedArchiver archiveRootObject:response toFile:name];
										[_cachedEntries setObject:name forKey:req];	// store file name
										// FIXME: should be size of the archive
										_diskUseage += size;
									}
							return;
						}
			case NSURLCacheStorageAllowedInMemoryOnly:
				[_cachedEntries setObject:response forKey:req];
				_memoryUseage += size;
				break;
			case NSURLCacheStorageNotAllowed:
				return;
		}
	return;
}

@end


@implementation NSCachedURLResponse

- (BOOL) isEqual:(id) other
{
	return [NSURLProtocol requestIsCacheEquivalent:_response toRequest:[other response]];
}

- (NSUInteger) hash;
{ // FIXME: this must me the same for two cache-equivalent responses...
	[NSURLProtocol canonicalRequestForRequest:_response];
	// [NSURLRequest canonicalRequest]
	// so it must be the same request URL but not the same response header
	return (NSUInteger) self;
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
