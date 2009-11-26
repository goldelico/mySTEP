/* 
    NSDistantObject.h

    Class which defines proxies for objects in other applications

    Copyright (C) 1997 Free Software Foundation, Inc.

    Author:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
    GNUstep:	Richard Frith-Macdonald <richard@brainstorm.co.uk>
    Date:	August 1997
   
    H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
    Author:	Fabian Spillner <fabian.spillner@gmail.com>
    Date:	28. April 2008 - aligned with 10.5
 
    This file is part of the mySTEP Library and is provided
    under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSDistantObject
#define _mySTEP_H_NSDistantObject

#import <Foundation/NSProxy.h>

@class NSConnection;
@class NSMutableDictionary;
@class Protocol;

@interface NSDistantObject : NSProxy  <NSCoding>
{
	unsigned long long _refCount;
	NSConnection *_connection;
	id _target;	// dependent object if we are a local proxy
	Protocol *_protocol;
	NSMutableDictionary *_selectorCache;	// cache the method signatures we have asked for
	unsigned long _reference;	// reference number (same on both sides)
}

+ (NSDistantObject *) proxyWithLocal:(id) anObject
						  connection:(NSConnection *) aConnection;
+ (NSDistantObject *) proxyWithTarget:(id) anObject
						   connection:(NSConnection *) aConnection;

- (NSConnection *) connectionForProxy;
- (id) initWithLocal:(id) anObject connection:(NSConnection *) aConnection;
- (id) initWithTarget:(id) anObject connection:(NSConnection *) aConnection;
- (void) setProtocolForProxy:(Protocol *) aProtocol;

@end

#endif /* _mySTEP_H_NSDistantObject */
