/* 
   NSFileHandle.m

   Implementation of NSFileHandle for mySTEP

   Copyright (C) 1997 Free Software Foundation, Inc.

   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date:	1997

   Complete rewrite based on NSStream:
   Dr. H. Nikolaus Schaller <hns@computer.org>
   Date: Jan 2006
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

// CODE NOT TESTED

#import <Foundation/NSData.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSFileHandle.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSException.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSNotificationQueue.h>
#import <Foundation/NSHost.h>
#import <Foundation/NSByteOrder.h>

#import "NSPrivate.h"

#include <signal.h>

// class variables
static NSFileHandle *__stdin = nil;
static NSFileHandle *__stdout = nil;
static NSFileHandle *__stderr = nil;

// Keys for accessing userInfo dictionary in notification handlers

NSString *NSFileHandleNotificationDataItem = @"NSFileHandleNotificationDataItem";
NSString *NSFileHandleNotificationFileHandleItem = @"NSFileHandleNotificationFileHandleItem";
NSString *NSFileHandleError = @"NSFileHandleError";

// Notification names

NSString *NSFileHandleConnectionAcceptedNotification = @"NSFileHandleConnectionAcceptedNotification";
NSString *NSFileHandleDataAvailableNotification = @"NSFileHandleDataAvailableNotification";
NSString *NSFileHandleReadCompletionNotification = @"NSFileHandleReadCompletionNotification";
NSString *NSFileHandleReadToEndOfFileCompletionNotification = @"NSFileHandleReadToEndOfFileCompletionNotification";

// Exceptions

NSString *NSFileHandleOperationException = @"NSFileHandleOperationException";

@implementation NSFileHandle

+ (void) initialize;
{  
	if(self == [NSFileHandle class])
		{
		signal(SIGPIPE, SIG_IGN);	// If SIGPIPE is not ignored, we will abort on any attempt to write to a pipe/socket that has been closed by the other end!
		signal(SIGSTOP, SIG_IGN);	// some devices might send a SIGSTOP if they become inactive
		}
}

+ (id) fileHandleForReadingAtPath:(NSString*) path
{
	return [[[self alloc] initWithFileDescriptor:open([path fileSystemRepresentation], O_RDONLY) closeOnDealloc:YES] autorelease];
}

+ (id) fileHandleForWritingAtPath:(NSString*) path
{
	return [[[self alloc] initWithFileDescriptor:open([path fileSystemRepresentation], O_WRONLY) closeOnDealloc: YES] autorelease];
}

+ (id) fileHandleForUpdatingAtPath:(NSString*) path
{
	return [[[self alloc] initWithFileDescriptor:open([path fileSystemRepresentation], O_RDWR) closeOnDealloc:YES] autorelease];
}

+ (id) fileHandleWithStandardError
{
	if(!__stderr)
		__stderr=[[self alloc] initWithFileDescriptor:2 closeOnDealloc:NO];
    return __stderr;
}

+ (id) fileHandleWithStandardInput
{
	if(!__stdin)
		__stdin=[[self alloc] initWithFileDescriptor:0 closeOnDealloc:NO];
    return __stdin;
}

+ (id) fileHandleWithStandardOutput
{
	if(!__stdout)
		__stdout=[[self alloc] initWithFileDescriptor:1 closeOnDealloc:NO];
    return __stdout;
}

+ (id) fileHandleWithNullDevice
{
	return [[[self alloc] initWithFileDescriptor:open("/dev/null", O_RDWR) closeOnDealloc:YES] autorelease];
}

- (id) init;	{ NIMP; return nil; }

- (id) initWithFileDescriptor:(int) fd
{
    return [self initWithFileDescriptor:fd closeOnDealloc:NO];
}

- (id) initWithFileDescriptor:(int) fd closeOnDealloc:(BOOL) flag;
{
#if 0
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if(fd < 0)
		{ [self release]; return nil; }
	if((self=[super init]))
		{
		_inputStream=[[NSInputStream alloc] _initWithFileDescriptor:fd];
		_outputStream=[[NSOutputStream alloc] _initWithFileDescriptor:fd];
		[_inputStream setDelegate:self];
		[_outputStream setDelegate:self];
		[_inputStream open];
		[_outputStream open];
		_closeOnDealloc=flag;	// remember flag
		}
	return self;
}

- (void) dealloc;
{
	if(_closeOnDealloc)
		[self closeFile];
	[self _setReadMode:kIsNotWaiting inModes:nil];	// cancel anypending request(s)
	[_inputStream release];
	[_outputStream release];
	[super dealloc];
}

- (void) closeFile;
{
	[_inputStream close];
	[_outputStream close];
}

- (int) fileDescriptor; { return [_inputStream _readFileDescriptor]; }

- (void) acceptConnectionInBackgroundAndNotify;
{
	[self _setReadMode:kIsListening inModes:nil];
	listen([self fileDescriptor], 128);
}

- (void) acceptConnectionInBackgroundAndNotifyForModes:(NSArray *) modes;
{
	[self _setReadMode:kIsListening inModes:modes];
	listen([self fileDescriptor], 128);
}

#define FRAGMENT 1024

- (NSData *) availableData;
{
	unsigned char *buffer;
	unsigned int len=0;
	unsigned int capacity;
	int fd;
	if([_inputStream getBuffer:&buffer length:&len])
		return [NSData dataWithBytes:buffer length:len];	// buffer was directly available
	fd=[_inputStream _readFileDescriptor];
	fcntl(fd, F_SETFL, O_NONBLOCK);	// don't block
	buffer=NULL;
	capacity=0;
	while(YES)
		{ // read in fragments as much as we can get without blocking
		int l;
		if(len+FRAGMENT >= capacity)
			{ // not enough space for one more fragment
			NSLog(@"realloc buffer for %d minimum capacity", len+FRAGMENT);
			buffer=objc_realloc(buffer, capacity+=4*FRAGMENT);	// get more space
			NSLog(@"capacity %d", capacity);
			if(!buffer)
				{
				[NSException raise:NSFileHandleOperationException
							format:@"failed to allocate data buffer for NSFileHandle - %s", strerror(errno)];	
				}
			}
		l=[_inputStream read:buffer+len maxLength:FRAGMENT];	// try to get next part
		if(l == 0)
			break;	// done
		if(l < 0)
			{
			if(errno == EWOULDBLOCK)
				break;	// also done peeking for data
			objc_free(buffer);
			[NSException raise:NSFileHandleOperationException
						format:@"failed to read data from NSFileHandle - %s", strerror(errno)];	
			return nil;
			}
		len+=l;
		}
	fcntl(fd, F_SETFL, O_ASYNC);		// back to normal operation
	if(!buffer)
		return [NSData data];			// empty data
	buffer=objc_realloc(buffer, len);	// free unused buffer space
	return [NSData dataWithBytesNoCopy:buffer length:len freeWhenDone:YES];	// take over responsibility for buffer
}

- (NSData *) readDataToEndOfFile;
{
	NSData *d=nil;
	while([_inputStream streamStatus] < NSStreamStatusAtEnd)
		{
		NIMP;
		}
	return d;
}

- (NSData *) readDataOfLength:(unsigned int) length;
{
	unsigned char *buffer;
	unsigned int len;
	if([_inputStream getBuffer:&buffer length:&len])
		return [NSData dataWithBytes:buffer length:MIN(len, length)];	// buffer is directly available
	if(!(buffer=objc_malloc(length)))
		return nil;	// can't allocate large enough buffer
	len=[_inputStream read:buffer maxLength:length];	// fetch get as much as possible
	if(len < 0)
		{
		objc_free(buffer);
		[NSException raise:NSFileHandleOperationException format:@"failed to read data from NSFileHandle - %s", strerror(errno)];	
		return nil;
		}
	buffer=objc_realloc(buffer, len);	// free unused buffer space
	return [NSData dataWithBytesNoCopy:buffer length:len freeWhenDone:YES];	// take over responsibility for buffer
}

- (void) readInBackgroundAndNotify;
{
	[self _setReadMode:kIsReading inModes:nil];
}

- (void) readInBackgroundAndNotifyForModes:(NSArray *) modes;
{
	[self _setReadMode:kIsReading inModes:modes];
}

- (void) readToEndOfFileInBackgroundAndNotify;
{
	[self _setReadMode:kIsReadingToEOF inModes:nil];
}

- (void) readToEndOfFileInBackgroundAndNotifyForModes:(NSArray *) modes;
{
	[self _setReadMode:kIsReadingToEOF inModes:modes];
}

- (void) waitForDataInBackgroundAndNotify;
{
#if 0
	NSLog(@"waitForDataInBackgroundAndNotify");
#endif
	[self _setReadMode:kIsWaiting inModes:nil];
}

- (void) waitForDataInBackgroundAndNotifyForModes:(NSArray *) modes;
{
	[self _setReadMode:kIsWaiting inModes:modes];
}

- (unsigned long long) offsetInFile;
{
	off_t result=lseek([_outputStream _writeFileDescriptor], 0, SEEK_CUR);
	if(result < 0)
		[NSException raise:NSFileHandleOperationException
					format:@"failed to determine offset in NSFileHandle - %s", strerror(errno)];	
	return (unsigned long long) result;
}

- (unsigned long long) seekToEndOfFile;
{
	off_t result=lseek([_outputStream _writeFileDescriptor], 0l, SEEK_END);
	if(result < 0)
		[NSException raise:NSFileHandleOperationException
					format:@"failed to seek to EOF in NSFileHandle - %s", strerror(errno)];	
	return (unsigned long long) result;
}

- (void) seekToFileOffset:(unsigned long long) offset;
{
	off_t result=lseek([_outputStream _writeFileDescriptor], (off_t) offset, SEEK_SET);
	if(result < 0)
		[NSException raise:NSFileHandleOperationException
					format:@"failed to move to offset in NSFileHandle - %s", strerror(errno)];	
}

- (void) synchronizeFile; { fsync([_outputStream _writeFileDescriptor]); }

- (void) truncateFileAtOffset:(unsigned long long) size;
{
	if(ftruncate([_outputStream _writeFileDescriptor], size) < 0)
		[NSException raise:NSFileHandleOperationException
					format:@"failed to truncate in NSFileHandle - %s", strerror(errno)];	
	[self seekToFileOffset:size];
}

- (void) writeData:(NSData *) data;
{
	int len;
	unsigned cnt=[data length];
	len=[_outputStream write:[data bytes] maxLength:cnt];
	if(len < 0 || len != cnt)
		[NSException raise:NSFileHandleOperationException
					format:@"failed to write to NSFileHandle - %s", strerror(errno)];	
}

// internal methods

- (void) _setReadMode:(int) mode inModes:(NSArray *) modes;
{
	static NSArray *_defaultModes;
	NSEnumerator *e;
	NSString *m;
#if 0
	NSLog(@"[%@ %@] mode:%d modes:%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), mode, modes);
#endif
	if(!modes)
		modes=_defaultModes?_defaultModes:(_defaultModes=[[NSArray arrayWithObject:NSDefaultRunLoopMode] retain]);
	if(mode == 0)
		{ // remove from runloop
		if(_readMode != 0)
		   	{
			e=[modes objectEnumerator];
			while((m=[e nextObject]))
				[_inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:m];
			[_readModes release];
			}
		}
	else if(_readMode != 0)
		[NSException raise:NSFileHandleOperationException
					format:@"already running a background notification for NSFileHandle"];	
	else
		{ // add to runloop
		if(!modes)
			modes=[NSArray arrayWithObject:NSDefaultRunLoopMode];	// default modes
		_readModes=[modes retain];	// save modes so that we can remove properly if mode is set to
		e=[modes objectEnumerator];
		while((m=[e nextObject]))
			[_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:m];
		}
	_readMode=mode;	
}

/*
 FIXME:
 because we receive from untrustworthy sources here, we must protect against malformed headers trying to create buffer overflows.
 This might also be some very lage constant for record length which wraps around the 32bit address limit (e.g. a negative record length).
 Ending up in infinite loops blocking the system.
 */

- (void) stream:(NSStream *) stream handleEvent:(NSStreamEvent) event
{
#if 0
	NSLog(@"[%@ %@] event=%d readmode=%d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), event, _readMode);
#endif
    if(stream == _inputStream) 
		{
		switch(event)
			{
			default:
				break;
			case NSStreamEventOpenCompleted: 	// ignore
				return;
			case NSStreamEventHasBytesAvailable:
				{ // NSInputStream notifies successful select() on listen() by "readable event"
					if(_readMode & kIsListening)
						{ // listen is successful
						int newfd=accept([_inputStream _readFileDescriptor], NULL, NULL);	// sender's socket is ignored
						NSNumber *error=[NSNumber numberWithInt:errno];
						NSFileHandle *newfh=[[NSFileHandle alloc] initWithFileDescriptor:newfd];
						[self _setReadMode:kIsNotWaiting inModes:nil];
						[[NSNotificationCenter defaultCenter] postNotificationName:NSFileHandleConnectionAcceptedNotification
																			object:self
																		  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																			  newfh, NSFileHandleNotificationFileHandleItem,
																			  error, NSFileHandleError,
																			  nil]];
						return;
						}
					if(!(_readMode & kIsWaiting))
						{ // fetch data for immediate notification
						NSData *data=[self availableData];	// as much as we can get
						NSNumber *error=[NSNumber numberWithInt:errno];
						if(_readMode & kIsReadingToEOF)
							{
							if(errno)
								{ // some error occurred
								[self _setReadMode:kIsNotWaiting inModes:nil];
								[[NSNotificationCenter defaultCenter] postNotificationName:NSFileHandleReadToEndOfFileCompletionNotification
																					object:self
																					userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																						data, NSFileHandleNotificationDataItem,
																						error, NSFileHandleError,
																						nil]];
								}
							else
								{
								if(!_inputBuffer)
									_inputBuffer=[data mutableCopy];
								else
									[_inputBuffer appendData:data];	// collect to buffer and stay in readMode
								}
							}
						else
							{ // nonwaiting mode
							[self _setReadMode:kIsNotWaiting inModes:nil];
							[[NSNotificationCenter defaultCenter] postNotificationName:NSFileHandleReadCompletionNotification
																				object:self
																				userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																					data, NSFileHandleNotificationDataItem,
																					error, NSFileHandleError,
																					nil]];
							}
						}
					else	// no read mode
						{
						[self _setReadMode:kIsNotWaiting inModes:nil];
						[[NSNotificationCenter defaultCenter] postNotificationName:NSFileHandleDataAvailableNotification object:self];
						}
					return;
				}
			case NSStreamEventEndEncountered:
				{
					if(!(_readMode & kIsWaiting))
						{ // final notification
						NSNumber *error=[NSNumber numberWithInt:0];	// fine
						if(_readMode & kIsReadingToEOF)
							{
							[self _setReadMode:kIsNotWaiting inModes:nil];
							[[NSNotificationCenter defaultCenter] postNotificationName:NSFileHandleReadToEndOfFileCompletionNotification
																				object:self
																			  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																				  _inputBuffer, NSFileHandleNotificationDataItem,
																				  error, NSFileHandleError,
																				  nil]];
							[_inputBuffer release];
							_inputBuffer=nil;
							}
						else
							{
							[self _setReadMode:kIsNotWaiting inModes:nil];
							[[NSNotificationCenter defaultCenter] postNotificationName:NSFileHandleReadCompletionNotification
																				object:self
																			  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																				  [NSData data], NSFileHandleNotificationDataItem,
																				  error, NSFileHandleError,
																				  nil]];
							}
						}
					else
						{
						[self _setReadMode:kIsNotWaiting inModes:nil];
						// ??
						[[NSNotificationCenter defaultCenter] postNotificationName:NSFileHandleDataAvailableNotification object:self];
						}
					return;
				}
			}
		}
	else if(stream == _outputStream)
		{
		switch(event)
			{
			default:
				break;
			case NSStreamEventOpenCompleted: 	// ignore
				return;
			}
		}
	NSLog(@"An error %@ occurred on the event %08x of stream %@ of %@", [stream streamError], event, stream, self);
}
				
@end // NSFileHandle

@implementation NSPipe

+ (id) pipe; { return [[[self alloc] init] autorelease]; }
- (NSFileHandle *) fileHandleForReading; { return read; }
- (NSFileHandle *) fileHandleForWriting; { return write; }

- (id) init;
{
	self=[super init];
	if(self)
		{
		int fd[2];
		if(pipe(fd))
			{ // system error on pipe creation
			[self release];
			return nil;
			}
		read=[[[NSFileHandle alloc] initWithFileDescriptor:fd[0]] retain];
		write=[[[NSFileHandle alloc] initWithFileDescriptor:fd[1]] retain];
		}
	return self;
}

- (void) dealloc;
{
	[read release];
	[write release];
	[super dealloc];
}

@end

