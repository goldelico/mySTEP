/* NSURL.h - Class NSURL
   Copyright (C) 1999 Free Software Foundation, Inc.
   
   Written by: 	Manuel Guesdon <mguesdon@sbuilders.com>
   Date:	Jan 1999
   
   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   Fabian Spillner, July 2008 - API revised to be compatible to 10.5

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

/*
 How an URL is split into NSURL components:
 
	scheme://user:password@host.domain.org:888/path/path.htm;parameter?query#fragment
 
 */

#ifndef _NSURL_h__
#define _NSURL_h__

#import <Foundation/NSURLHandle.h>

@class NSNumber;

extern NSString *NSURLFileScheme;	// @"file"

@interface NSURL : NSObject <NSCoding, NSCopying, NSURLHandleClient>
{
	NSString	*_urlString;
	NSURL		*_baseURL;
	void		*_clients;
	void		*_data;
}

+ (id) fileURLWithPath:(NSString *) aPath;
+ (id) fileURLWithPath:(NSString *) aPath isDirectory:(BOOL) isDir;
+ (id) URLWithString:(NSString *) aUrlString;
+ (id) URLWithString:(NSString *) aUrlString relativeToURL:(NSURL *) aBaseUrl;

- (NSString *) absoluteString;
- (NSURL *) absoluteURL;
- (NSURL *) baseURL;
- (const char *) fileSystemRepresentation;	// since 10.9
- (NSString *) fragment;
- (NSString *) host;
- (id) initFileURLWithPath:(NSString *) aPath;
- (id) initFileURLWithPath:(NSString *) aPath isDirectory:(BOOL) isDir;
- (id) initWithScheme:(NSString *) aScheme
				 host:(NSString *) aHost
				 path:(NSString *) aPath;
- (id) initWithString:(NSString *) aUrlString;
- (id) initWithString:(NSString *) aUrlString
		relativeToURL:(NSURL *) aBaseUrl;
- (BOOL) isFileURL;
- (NSString *) lastPathComponent;	// since 10.6
- (void) loadResourceDataNotifyingClient:(id) client
							  usingCache:(BOOL) shouldUseCache;
- (NSString *) parameterString;
- (NSString *) password;
- (NSString *) path;
- (NSArray *) pathComponents;	// since 10.6
- (NSString *) pathExtension;	// since 10.6
- (NSNumber *) port;
- (id) propertyForKey:(NSString *) propertyKey;
- (NSString *) query;
- (NSString *) relativePath;
- (NSString *) relativeString;
- (NSData *) resourceDataUsingCache:(BOOL) shouldUseCache;
- (NSString *) resourceSpecifier;
- (NSString *) scheme;
- (BOOL) setProperty:(id) property
			  forKey:(NSString *) propertyKey;
- (BOOL) setResourceData:(NSData *) data;
- (NSURL *) standardizedURL;
- (NSURL *) URLByDeletingLastPathComponent;	// since 10.6
- (NSURL *) URLByDeletingPathExtension;	// since 10.6
- (NSURLHandle *) URLHandleUsingCache:(BOOL) shouldUseCache;
- (NSURL *) URLByResolvingSymlinksInPath;	// since 10.6
- (NSURL *) URLByStandardizingPath;	// since 10.6
- (NSString *) user;

@end

@interface NSObject (NSURLClient)

- (void) URL:(NSURL *) sender resourceDataDidBecomeAvailable:(NSData *) newBytes;
- (void) URL:(NSURL *) sender resourceDidFailLoadingWithReason:(NSString *) reason;
- (void) URLResourceDidCancelLoading:(NSURL *) sender;
- (void) URLResourceDidFinishLoading:(NSURL *) sender;

@end

#endif //_NSUrl_h__
