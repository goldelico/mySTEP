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
		signal(SIGIO, SIG_IGN);		// the HSO driver and some others appear to send SIGIO although there was no fcntl(FASYNC)
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

- (void) finalize;
{
	if(_closeOnDealloc)
		[self closeFile];
	[self _setReadMode:kIsNotWaiting inModes:nil];	// cancel any pending request(s)
}

- (void) dealloc;
{
#if 0
	NSLog(@"NSFileHandle dealloc");
#endif
	[self finalize];
	[_inputStream release];
	[_outputStream release];
	[super dealloc];
}

- (void) closeFile;
{
#if 0
	NSLog(@"NSFileHandle close");
#endif
	[_inputStream setDelegate:nil];
	[_outputStream setDelegate:nil];
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

#define FRAGMENT (10*1024)

- (NSData *) readDataOfLength:(NSUInteger) length;
{
	unsigned char *buffer=NULL;
	NSUInteger bufpos=0;
	NSUInteger ulen;
	int len;
#if 0
	NSLog(@"NSFileHandle: readDataOfLength %u", length);
#endif
	if([_inputStream getBuffer:&buffer length:&ulen])
		return [NSData dataWithBytes:buffer length:MIN(ulen, length)];	// buffer is directly available
	while(length > 0)
		{ // read in chunks and enlarge buffer if required
			int status;
			if(bufpos == 0)
				buffer=objc_malloc(bufpos+FRAGMENT);
			else
				buffer=objc_realloc(buffer, bufpos+FRAGMENT);	// make enough room for next chunk
			if(!buffer)
				return nil;	// we can't allocate a buffer
#if 0
			NSLog(@"NSFileHandle: bufsize=%u read length=%u", bufpos+FRAGMENT, MIN(length, FRAGMENT));
#endif
			len=[_inputStream read:buffer+bufpos  maxLength: MIN(length, FRAGMENT)];	// fetch as much as possible but still in chunks
#if 0
			NSLog(@"NSFileHandle: returned length=%u err=%s", len, strerror(errno));
#endif
			status=[_inputStream streamStatus];
			if(len == 0 || status == NSStreamStatusAtEnd)
				break;
			if(status != NSStreamStatusOpen)
				{
				objc_free(buffer);
				[NSException raise:NSFileHandleOperationException format:@"NSFileHandle: failed to read data - %d %d %s",status, errno,  strerror(errno)];
				return nil;
				}
			bufpos+=len;
			length-=len;
		}
#if 0
	NSLog(@"NSFileHandle: readDataOfLength => %u", bufpos, strerror(errno));
#endif
	if(bufpos == 0)
		{
		objc_free(buffer);
		return [NSData data];	// empty data
		}
	buffer=objc_realloc(buffer, bufpos);	// free unused buffer space
	return [NSData dataWithBytesNoCopy:buffer length:bufpos freeWhenDone:YES];	// take over responsibility for buffer
}

- (NSData *) readDataToEndOfFile;
{ // read as much as we can hold in an NSData
	return [self readDataOfLength:NSIntegerMax];
}

- (NSData *) availableData;
{ // read as much as we can get but don't block
	int fd;
	NSData *r=nil;
	unsigned char *buffer;
	NSUInteger len;
	if([_inputStream getBuffer:&buffer length:&len])
		return [NSData dataWithBytes:buffer length:len];	// buffer was directly available
	fd=[_inputStream _readFileDescriptor];
	fcntl(fd, F_SETFL, O_NONBLOCK);		// don't block
	NS_DURING
	r=[self readDataToEndOfFile];
	NS_HANDLER
	fcntl(fd, F_SETFL, O_ASYNC);	// back to normal operation even in case of an exception
	[localException raise];			// re-raise
	NS_ENDHANDLER
	fcntl(fd, F_SETFL, O_ASYNC);	// back to normal operation
#if 0
	NSLog(@"availableData: %d %@", (int)[_inputStream streamStatus], r);
#endif
	return r;
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
	NSNumber *pos=[_outputStream propertyForKey:NSStreamFileCurrentOffsetKey];
	if(!pos)
		[NSException raise:NSFileHandleOperationException
					format:@"failed to determine offset in NSFileHandle"];
	return [pos unsignedLongLongValue];
}

// FIXME:
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
	if(![_outputStream setProperty:[NSNumber numberWithUnsignedLong:offset] forKey:NSStreamFileCurrentOffsetKey])
		[NSException raise:NSFileHandleOperationException
					format:@"failed to move to offset in NSFileHandle - %s", strerror(errno)];
}

- (void) synchronizeFile; { fsync([_outputStream _writeFileDescriptor]); }

// FIXME:
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
	NSEnumerator *e;
	NSString *m;
#if 0
	NSLog(@"[%@ %@] mode:%d modes:%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), mode, modes);
#endif
	if(mode == kIsNotWaiting)
		{ // don't wait
			if(_readMode != kIsNotWaiting)
				{ // remove current modes from runloop
					e=[_readModes objectEnumerator];
					while((m=[e nextObject]))
						[_inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:m];
					[_readModes release];
					_readModes=nil;
					_readMode=mode;
				}
			return;
		}
	else
		{ // set mode
			if(_readMode != kIsNotWaiting)
				[NSException raise:NSFileHandleOperationException
							format:@"already running a background notification for NSFileHandle"];
			else
				{ // add to runloop
					if(!modes)
						modes=[NSArray arrayWithObject:NSDefaultRunLoopMode];	// default mode
					_readModes=[modes retain];	// save modes so that we can remove properly if mode is set to kIsNotWaiting
					e=[_readModes objectEnumerator];
					while((m=[e nextObject]))
						[_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:m];
					_readMode=mode;
				}
		}
}

/*
 FIXME:
 because we receive from untrustworthy sources here, we must protect against malformed headers trying to create buffer overflows.
 This might also be some very large constant for record length which wraps around the 32bit address limit (e.g. a negative record length).
 Ending up in infinite loops blocking the system.
 */

- (void) stream:(NSStream *) stream handleEvent:(NSStreamEvent) event
{
#if 0
	NSLog(@"[%@ %@] event=%d readmode=%d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (int) event, (int)_readMode);
#endif
	errno=0;
	if(stream == _inputStream)
		{
		switch(event) {
			default:
				break;
			case NSStreamEventOpenCompleted:	// ignore
				return;
			case NSStreamEventHasBytesAvailable: { // NSInputStream notifies successful select() or listen()
#if 0
				NSLog(@"NSStreamEventHasBytesAvailable");
#endif
				if(_readMode == kIsListening)
					{ // listen is successful
						int newfd=accept([_inputStream _readFileDescriptor], NULL, NULL);	// sender's socket is ignored
						// should extracf from [stream streamError] -> (NSError *);
						NSNumber *error=[NSNumber numberWithInt:errno];
						NSFileHandle *newfh=[[NSFileHandle alloc] initWithFileDescriptor:newfd];
						[self _setReadMode:kIsNotWaiting inModes:nil];
						[[NSNotificationCenter defaultCenter] postNotificationName:NSFileHandleConnectionAcceptedNotification
																			object:self
																		  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																			  newfh, NSFileHandleNotificationFileHandleItem,
																			  error, NSFileHandleError,
																			  nil]];
						[newfh release];
					}
				else if(_readMode == kIsWaiting)
					{ // waiting - just notify and let notification handler fetch the data
						[self _setReadMode:kIsNotWaiting inModes:nil];
						[[NSNotificationCenter defaultCenter] postNotificationName:NSFileHandleDataAvailableNotification object:self];
					}
				else if(_readMode == kIsReadingToEOF)
					{ // read (nonblocking) as much as we can and collect - may report 0 length
						NSData *data=[self availableData];	// as much as we can get
#if 0
						NSLog(@"kIsReadingToEOF: status = %d error = %@ data = %@", (int)[stream streamStatus], [stream streamError], data);
#endif
						if(!_inputBuffer)
							_inputBuffer=[data mutableCopy];
						else
							[_inputBuffer appendData:data];	// collect to buffer and stay in readMode
						if([stream streamStatus] != NSStreamStatusOpen)
							{ // we have now StreamStatusAtEnd or some error has occurred
								NSNumber *error=[NSNumber numberWithInt:errno];
								[self _setReadMode:kIsNotWaiting inModes:nil];
								[[NSNotificationCenter defaultCenter] postNotificationName:NSFileHandleReadToEndOfFileCompletionNotification
																					object:self
																				  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																							_inputBuffer, NSFileHandleNotificationDataItem,
																							error, NSFileHandleError,
																							nil]];
							}
					}
				else
					{ // read (nonblocking) as much as we can and deliver
						NSData *data=[self availableData];	// as much as we can get
						NSNumber *error=[NSNumber numberWithInt:errno];
#if 0
						// streamStatus == NSStreamStatusAtEnd should be checked by notification handler
						if([stream streamStatus] != NSStreamStatusOpen || [data length] == 0)
							{ // pipe has no data despite sending an event!
								NSLog(@"NSFileHandle: empty data: status = %d error = %@", (int)[stream streamStatus], [stream streamError]);
							}
#endif
						[self _setReadMode:kIsNotWaiting inModes:nil];
						if([data length] != 0)	// never report 0 length
							[[NSNotificationCenter defaultCenter] postNotificationName:NSFileHandleReadCompletionNotification
																				object:self
																			  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																						data, NSFileHandleNotificationDataItem,
																						error, NSFileHandleError,
																						nil]];
					}
				return;
			}
			case NSStreamEventEndEncountered: {
#if 0
				NSLog(@"NSStreamEventEndEncountered");
#endif
				if(_readMode == kIsWaiting)
					{ // waiting mode
						[self _setReadMode:kIsNotWaiting inModes:nil];
						// ??
						[[NSNotificationCenter defaultCenter] postNotificationName:NSFileHandleDataAvailableNotification object:self];
					}
				else if(_readMode == kIsReadingToEOF)
					{
					NSNumber *error=[NSNumber numberWithInt:0];	// fine
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
					{ // report empty NSData
						NSNumber *error=[NSNumber numberWithInt:0];	// fine
						[self _setReadMode:kIsNotWaiting inModes:nil];
						[[NSNotificationCenter defaultCenter] postNotificationName:NSFileHandleReadCompletionNotification
																			object:self
																		  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																					[NSData data], NSFileHandleNotificationDataItem,
																					error, NSFileHandleError,
																					nil]];
					}
				return;
			}
		}
		}
	else if(stream == _outputStream)
		{
		switch(event) {
			default:
				break;
			case NSStreamEventOpenCompleted:	// ignore
				return;
		}
		}
	NSLog(@"An error %@ occurred on the event %lu of stream %@ of %@", [stream streamError], (unsigned long)event, stream, self);
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
		read=[[NSFileHandle alloc] initWithFileDescriptor:fd[0] closeOnDealloc:YES];
		write=[[NSFileHandle alloc] initWithFileDescriptor:fd[1] closeOnDealloc:YES];
		}
	return self;
}

- (void) dealloc;
{
#if 0
	NSLog(@"NSPipe dealloc");
#endif
	[read release];
	[write release];
	[super dealloc];
}

@end

