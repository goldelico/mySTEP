/*
    NSStream.h
    mySTEP

    Created by Dr. H. Nikolaus Schaller on Mon Mar 14 2005.
    Copyright (c) 2005 DSITRI.

    H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
    Fabian Spillner, May 2008 - API revised to be compatible to 10.5 (NSInputStream, NSOutputStream)
 
    This file is part of the mySTEP Library and is provided
    under the terms of the GNU Library General Public License.
*/

#ifndef mySTEP_NSSTREAM_H
#define mySTEP_NSSTREAM_H

#import "Foundation/NSObject.h"

@class NSString;
@class NSData;
@class NSError;
@class NSMutableDictionary;
@class NSHost;
@class NSRunLoop;
@class NSInputStream;
@class NSOutputStream;
@class NSSocketPort;

typedef enum _NSStreamStatus
{
	NSStreamStatusNotOpen=0,
	NSStreamStatusOpening,
	NSStreamStatusOpen,
	NSStreamStatusReading,
	NSStreamStatusWriting,
	NSStreamStatusAtEnd,
	NSStreamStatusClosed,
	NSStreamStatusError
} NSStreamStatus;

typedef enum _NSStreamEvent
{
	NSStreamEventNone=0,
	NSStreamEventOpenCompleted=1,
	NSStreamEventHasBytesAvailable=2,
	NSStreamEventHasSpaceAvailable=4,
	NSStreamEventErrorOccurred=8,
	NSStreamEventEndEncountered=16
} NSStreamEvent;

extern NSString *NSStreamDataWrittenToMemoryStreamKey;
extern NSString *NSStreamFileCurrentOffsetKey;
extern NSString *NSStreamSocketSecurityLevelKey;
extern NSString *NSStreamSOCKSProxyConfigurationKey;

extern NSString *NSStreamSocketSecurityLevelNone;
extern NSString *NSStreamSocketSecurityLevelSSLv2;
extern NSString *NSStreamSocketSecurityLevelSSLv3;
extern NSString *NSStreamSocketSecurityLevelTLSv1;
extern NSString *NSStreamSocketSecurityLevelNegotiatedSSL;

extern NSString *NSStreamSocketSSLErrorDomain;
extern NSString *NSStreamSOCKSErrorDomain;

extern NSString *NSStreamSOCKSProxyHostKey;
extern NSString *NSStreamSOCKSProxyPortKey;
extern NSString *NSStreamSOCKSProxyVersionKey;
extern NSString *NSStreamSOCKSProxyUserKey;
extern NSString *NSStreamSOCKSProxyPasswordKey;

extern NSString *NSStreamSOCKSProxyVersion4;
extern NSString *NSStreamSOCKSProxyVersion5;

@interface NSStream : NSObject	// NSStream can't be instantiated - only subclasses
{
	id _delegate;
	NSError *_streamError;
	NSStreamStatus _streamStatus;
}

+ (void) getStreamsToHost:(NSHost *) host
					 port:(int) port
			  inputStream:(NSInputStream **) inp
			 outputStream:(NSOutputStream **) outp;
- (void) close;
- (id) delegate;
- (void) open;
- (id) propertyForKey:(NSString *) key;
- (void) removeFromRunLoop:(NSRunLoop *) rloop forMode:(NSString *) mode;
- (void) scheduleInRunLoop:(NSRunLoop *) rloop forMode:(NSString *) mode;
- (void) setDelegate:(id) delegate;
- (BOOL) setProperty:(id) value forKey:(NSString *) key;
- (NSError *) streamError;
- (NSStreamStatus) streamStatus;

@end


@interface NSInputStream : NSStream
{
	int _fd;
}

+ (id) inputStreamWithData:(NSData *) data;
+ (id) inputStreamWithFileAtPath:(NSString *) path;
- (BOOL) getBuffer:(unsigned char **) buffer length:(NSUInteger *) len;
- (BOOL) hasBytesAvailable;
- (id) initWithData:(NSData *) data;
- (id) initWithFileAtPath:(NSString *) path;
- (NSInteger) read:(unsigned char *) buffer maxLength:(NSUInteger) len;

@end


@interface NSOutputStream : NSStream
{
	int _fd;
}

+ (id) outputStreamToBuffer:(unsigned char *) buffer capacity:(NSUInteger) len;
+ (id) outputStreamToFileAtPath:(NSString *) path append:(BOOL) flag;
+ (id) outputStreamToMemory;

- (BOOL) hasSpaceAvailable;
- (id) initToBuffer:(unsigned char *) buffer capacity:(NSUInteger) len;
- (id) initToFileAtPath:(NSString *) path append:(BOOL) flag;
- (id) initToMemory;
- (NSInteger) write:(const unsigned char *) buffer maxLength:(NSUInteger) len;

@end


@interface NSObject (NSStreamDelegate)

- (void) stream:(NSStream *) stream handleEvent:(NSStreamEvent) event;

@end

#endif // mySTEP_NSSTREAM_H
