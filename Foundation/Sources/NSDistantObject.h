/* 
   NSDistantObject.h

   Class which defines proxies for objects in other applications

   Copyright (C) 1997 Free Software Foundation, Inc.

   Author:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   GNUstep:	Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date:	August 1997
   
   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSDistantObject
#define _mySTEP_H_NSDistantObject

#import <Foundation/NSProxy.h>

@class NSConnection;

@interface NSDistantObject : NSProxy  <NSCoding>
{
	NSConnection *_connection;
	id _target;	// remote reference - shouldn't we provide for a 64bit remote address?
	Protocol *_protocol;
	BOOL _isLocal;
}

+ (NSDistantObject*) proxyWithLocal:(id)anObject
						 connection:(NSConnection*)aConnection;
+ (NSDistantObject*) proxyWithTarget:(id)anObject
						  connection:(NSConnection*)aConnection;

- (NSConnection*) connectionForProxy;
- (id) initWithLocal:(id)anObject connection:(NSConnection*)aConnection;
- (id) initWithTarget:(id)anObject connection:(NSConnection*)aConnection;
- (void) setProtocolForProxy:(Protocol*)aProtocol;

@end

#endif /* _mySTEP_H_NSDistantObject */
