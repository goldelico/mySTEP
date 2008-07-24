/* NSURLHandle.h - Class NSURLHandle
   Copyright (C) 1999 Free Software Foundation, Inc.
   
   Written by: 	Manuel Guesdon <mguesdon@sbuilders.com>
   Date: 	Jan 1999
   
   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   Fabian Spillner, July 2008 - API revised to be coompatible to 10.5

   This file is part of the GNUstep Library.
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#ifndef _NSURLHandle_h__
#define _NSURLHandle_h__

#import <Foundation/NSObject.h>

@class NSData;
@class NSString;
@class NSMutableArray;
@class NSMutableData;
@class NSURLHandle;
@class NSURLProtocol;
@class NSURL;

extern NSString * const NSHTTPPropertyStatusCodeKey;
extern NSString * const NSHTTPPropertyStatusReasonKey;
extern NSString * const NSHTTPPropertyServerHTTPVersionKey;
extern NSString * const NSHTTPPropertyRedirectionHeadersKey;
extern NSString * const NSHTTPPropertyErrorPageDataKey;

/**
 * A protocol to which clients of a handle must conform in order to
 * receive notification of events on the handle.
 */

@protocol NSURLHandleClient

/**
 * Sent by the NSURLHandle object when some data becomes available
 * from the handle.  Note that this does not mean that all data has become
 * available, only that a chunk of data has arrived.
 */
- (void) URLHandle:(NSURLHandle *) sender
  resourceDataDidBecomeAvailable:(NSData *) newData;

/**
 * Sent by the NSURLHandle object on resource load failure.
 * Supplies a human readable failure reason.
 */
- (void) URLHandle:(NSURLHandle *) sender
  resourceDidFailLoadingWithReason:(NSString *) reason;

/**
 * Sent by the NSURLHandle object when it begins loading
 * resource data.
 */
- (void) URLHandleResourceDidBeginLoading: (NSURLHandle *) sender;

/**
 * Sent by the NSURLHandle object when resource loading is canceled
 * by programmatic request (rather than by failure).
 */
- (void) URLHandleResourceDidCancelLoading:(NSURLHandle *) sender;

/**
 * Sent by the NSURLHandle object when it completes loading
 * resource data.
 */
- (void) URLHandleResourceDidFinishLoading:(NSURLHandle *) sender;

@end

typedef enum _NSURLHandleStatus
{
	NSURLHandleNotLoaded = 0,
	NSURLHandleLoadSucceeded,
	NSURLHandleLoadInProgress,
	NSURLHandleLoadFailed
} NSURLHandleStatus;

@interface NSURLHandle : NSObject
{
	NSURLProtocol		*_protocol;
	NSMutableData		*_resourceData;
	NSMutableArray		*_clients;
	NSString			*_failure; 
	long long			_expectedDataLength;
	NSURLHandleStatus	_status;
}

+ (NSURLHandle *) cachedHandleForURL:(NSURL *) url;
+ (BOOL) canInitWithURL:(NSURL *) url;
+ (void) registerURLHandleClass:(Class) urlHandleSubclass;
+ (Class) URLHandleClassForURL:(NSURL *) url;

- (void) addClient:(id <NSURLHandleClient>) client;
- (NSData *) availableResourceData;
- (void) backgroundLoadDidFailWithReason:(NSString *) reason;
- (void) beginLoadInBackground;
- (void) cancelLoadInBackground;
- (void) didLoadBytes:(NSData *) newData
		 loadComplete:(BOOL) loadComplete;
- (void) endLoadInBackground;
- (long long) expectedResourceDataSize;
- (NSString *) failureReason;
- (void) flushCachedData;
- (id) initWithURL:(NSURL *) url
			cached:(BOOL) cached;
- (void) loadInBackground;
- (NSData *) loadInForeground;
- (id) propertyForKey:(NSString *) propertyKey;
- (id) propertyForKeyIfAvailable:(NSString *) propertyKey;
- (void) removeClient:(id <NSURLHandleClient>) client;
- (NSData *) resourceData;
- (NSURLHandleStatus) status;
- (BOOL) writeData:(NSData *) data;
- (BOOL) writeProperty:(id) propertyValue
				forKey:(NSString *) propertyKey;

@end

#endif
