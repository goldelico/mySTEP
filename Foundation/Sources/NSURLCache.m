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
