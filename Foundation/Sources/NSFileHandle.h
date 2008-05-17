/* 
    NSFileHandle.h

    Interface for NSFileHandle for mySTEP

    Copyright (C) 1997 Free Software Foundation, Inc.

    Author:	Richard Frith-Macdonald <richard@brainstorm.co.uk>
    Date:	1997

    H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
    Author:	Fabian Spillner <fabian.spillner@gmail.com>
    Date:	9. May 2008 - aligned with 10.5 
 
    This file is part of the mySTEP Library and is provided
    under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSFileHandle
#define _mySTEP_H_NSFileHandle

#import <Foundation/NSObject.h>
#import <Foundation/NSRunLoop.h>

@class NSMutableArray;
@class NSMutableData;
@class NSMutableDictionary;
@class NSDate;
@class NSString;
@class NSData;
@class NSInputStream, NSOutputStream;


@interface NSFileHandle : NSObject
{
	NSInputStream *_inputStream;
	NSOutputStream *_outputStream;
	NSMutableData *_inputBuffer;	// collects data from input stream
	NSArray *_readModes;	// store a copy
	enum
		{
			kIsNotWaiting=0,
			kIsListening=0x01,
			kIsReading=0x02,
			kIsReadingToEOF=0x04,
			kIsWaiting=0x08
		} _readMode;	// mutually excluding waiting modes
	BOOL _closeOnDealloc;
}

+ (id) fileHandleForReadingAtPath:(NSString *) path;
+ (id) fileHandleForUpdatingAtPath:(NSString *) path;
+ (id) fileHandleForWritingAtPath:(NSString *) path;
+ (id) fileHandleWithNullDevice;
+ (id) fileHandleWithStandardError;
+ (id) fileHandleWithStandardInput;
+ (id) fileHandleWithStandardOutput;

- (void) acceptConnectionInBackgroundAndNotify;
- (void) acceptConnectionInBackgroundAndNotifyForModes:(NSArray *) modes;
- (NSData *) availableData;							// Synchronous I/O ops
- (void) closeFile;									// file operations
- (int) fileDescriptor;								// Returning file handles
- (id) initWithFileDescriptor:(int) desc;
- (id) initWithFileDescriptor:(int) desc closeOnDealloc:(BOOL) flag;
- (unsigned long long) offsetInFile;				// Seek within a file
- (NSData *) readDataOfLength:(NSUInteger) len;
- (NSData *) readDataToEndOfFile;
- (void) readInBackgroundAndNotify;
- (void) readInBackgroundAndNotifyForModes:(NSArray *) modes;
- (void) readToEndOfFileInBackgroundAndNotify;
- (void) readToEndOfFileInBackgroundAndNotifyForModes:(NSArray *) modes;
- (unsigned long long) seekToEndOfFile;
- (void) seekToFileOffset:(unsigned long long) pos;
- (void) synchronizeFile;
- (void) truncateFileAtOffset:(unsigned long long) pos;
- (void) waitForDataInBackgroundAndNotify;
- (void) waitForDataInBackgroundAndNotifyForModes:(NSArray *) modes;
- (void) writeData:(NSData *) item;

@end


@interface NSPipe : NSObject
{
	NSFileHandle *read;
	NSFileHandle *write;
}

+ (id) pipe;
- (NSFileHandle *) fileHandleForReading;
- (NSFileHandle *) fileHandleForWriting;
- (id) init;

@end

// Notification names.

extern NSString *NSFileHandleConnectionAcceptedNotification;
extern NSString *NSFileHandleDataAvailableNotification;
extern NSString *NSFileHandleReadCompletionNotification;
extern NSString *NSFileHandleReadToEndOfFileCompletionNotification;

// Keys for accessing userInfo dictionary in notification handlers.

extern NSString *NSFileHandleNotificationFileHandleItem;
extern NSString *NSFileHandleNotificationDataItem;
extern NSString *NSFileHandleError;

// Exceptions

extern NSString *NSFileHandleOperationException;

#endif /* _mySTEP_H_NSFileHandle */
