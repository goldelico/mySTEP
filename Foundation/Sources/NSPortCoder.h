/* 
   NSPortCoder.h

   Interface for NSPortCoder object for distributed objects

   Copyright (C) 2005 Free Software Foundation, Inc.

   Author:	H. Nikolaus Schaller <hns@computer.org>
   Date:	December 2005

   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   Fabian Spillner, July 2008 - API revised to be compatible to 10.5
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSPortCoder
#define _mySTEP_H_NSPortCoder

#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSMapTable.h>

@class NSArray;
@class NSMutableArray;
@class NSConnection;
@class NSPort;

@interface NSPortCoder : NSCoder
{
	NSConnection *_connection;
	NSPort *_recv;
	NSPort *_send;
	NSArray *_components;
	NSMutableArray *_imports;
	NSMutableDictionary *_classVersions;
	const unsigned char *_pointer;	// used for decoding
	const unsigned char *_eod;	// used for decoding
	BOOL _isByref;
	BOOL _isBycopy;
}

+ (NSPortCoder *) portCoderWithReceivePort:(NSPort *) recv
								  sendPort:(NSPort *) send
								components:(NSArray *) cmp;

- (NSConnection *) connection;
- (NSPort *) decodePortObject;
- (void) dispatch;
- (void) encodePortObject:(NSPort *) aPort;
- (id) initWithReceivePort:(NSPort *) recv sendPort:(NSPort *) send components:(NSArray *) cmp;
- (BOOL) isBycopy;
- (BOOL) isByref;
// - (void) sendBeforeTime:(NSTimeInterval) time sendReplyPort:(NSPort *) port;	// undocumented private method

@end

@interface NSObject (NSPortCoder)

- (Class) classForPortCoder;
- (id) replacementObjectForPortCoder:(NSPortCoder *) anEncoder;

@end

#endif /* _mySTEP_H_NSPortCoder */
