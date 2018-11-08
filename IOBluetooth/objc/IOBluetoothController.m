//
//  IOBluetoothController.m
//  IOBluetooth
//
//  Created by H. Nikolaus Schaller on 30.10.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "IOBluetoothController.h"
#import <AppKit/NSApplication.h>	// for event loop modes

#if 0	// debugging
#define system(CMD) (printf("system: %s\n", (CMD)), 0)
#endif

BOOL modemLog = YES;

@implementation IOBluetoothController

#define SINGLETON_CLASS		IOBluetoothController
#define SINGLETON_VARIABLE	sharedController
#define SINGLETON_HANDLE	sharedController

/* static part */

static SINGLETON_CLASS * SINGLETON_VARIABLE = nil;

+ (id) allocWithZone:(NSZone *)zone
{
	//   @synchronized(self)
	{
	if (! SINGLETON_VARIABLE)
		return [super allocWithZone:zone];
	}
	return SINGLETON_VARIABLE;
}

- (id) copyWithZone:(NSZone *)zone { return self; }

- (id) retain { return self; }

- (NSUInteger) retainCount { return UINT_MAX; }

- (oneway void) release {}

- (id) autorelease { return self; }

+ (SINGLETON_CLASS *) SINGLETON_HANDLE
{
	//   @synchronized(self)
	{
	if (! SINGLETON_VARIABLE)
		[[self alloc] init];
	}
	return SINGLETON_VARIABLE;
}

- (id) init
{
	//    Class myClass = [self class];
	//    @synchronized(myClass)
	{
	if (!SINGLETON_VARIABLE && (self = [super init]))
		{
		SINGLETON_VARIABLE = self;
		/* custom initialization here */
		}
	}
	return self;
}

- (void) dealloc
{ // should not happen for a singleton!
#if 1
	NSLog(@"IOBluetoothController dealloc");
	abort();
#endif
	[_task terminate];
	[_task release];
	[_modes release];
	[_lastChunk release];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSTaskDidTerminateNotification
												  object:nil];	// don't observe any more
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSFileHandleReadCompletionNotification
												  object:nil];	// don't observe any more
	[super dealloc];
}

- (void) log:(NSString *) format, ...
{
	static NSString *name;
	if(!name)
		name=[[NSString stringWithFormat:@"/tmp/%@.log", [[NSBundle bundleForClass:[self class]] bundleIdentifier]] retain];
	// open/append/close is certainly not fast...
	FILE *f=fopen([name fileSystemRepresentation], "a");
	if(f)
		{
		va_list ap;
		va_start (ap, format);
		NSString *msg = [[NSString alloc] initWithFormat:format arguments:ap];
		fprintf(f, "%s: %s%s", [[[NSDate date] description] UTF8String], [msg UTF8String], [msg hasSuffix:@"\n"]?"":"\n");
		fprintf(stderr, "%s: %s%s", [[[NSDate date] description] UTF8String], [msg UTF8String], [msg hasSuffix:@"\n"]?"":"\n");
		[msg release];
		va_end (ap);
		fclose(f);
		}
}

- (void) _processLine:(NSString *) line;
{
	if(modemLog) [self log:@"r (done=%d): %@", _done, line];
	// separate requested responses from unsolicited
	if([line hasPrefix:@"[bluetooth]#"])
		{ // (next) command prompt
		_done=YES;
		return;
		}
	if(_done || [line hasPrefix:@"["])
		[_unsolicitedTarget performSelector:_unsolicitedAction withObject:line];
	else
		[_target performSelector:_action withObject:line];
}

- (void) _processData:(NSData *) line;
{ // we have received a new data block from the serial line
	NSString *s=[[[NSString alloc] initWithData:line encoding:NSASCIIStringEncoding] autorelease];
	NSArray *lines;
	int l;
#if 0
	NSLog(@"data=%@", line);
	NSLog(@"string=%@", s);
#endif
	if(_lastChunk)
		s=[_lastChunk stringByAppendingString:s];	// append to last chunk
	lines=[s componentsSeparatedByString:@"\n"];	// split into lines
	for(l=0; l<[lines count]-1; l++)
		{ // process lines except last chunk
		  // brauchen wir das bei bluetoothctl?
			s=[[lines objectAtIndex:l] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\r"]];
			[self _processLine:s];
		}
#if 0
	NSLog(@"string=%@", s);
#endif
	[_lastChunk release];
	_lastChunk=[[lines lastObject] retain];
}

- (void) _dataReceived:(NSNotification *) n;
{
	NSAutoreleasePool *arp=[NSAutoreleasePool new];
#if 1
	if(modemLog) [self log:@"r: %@", n];
#endif
	[self _processData:[[n userInfo] objectForKey:@"NSFileHandleNotificationDataItem"]];	// parse data as line
	[[n object] readInBackgroundAndNotifyForModes:_modes];	// and trigger more notifications
	[arp release];
}

- (void) _writeCommand:(NSString *) str;
{
	if(modemLog) [self log:@"w (done=%d): %@", _done, str];
	if(!_stdoutput)
		{
		if(modemLog) [self log:@"no port open!"];
		return;
		}
	str=[str stringByAppendingString:@"\n"];
	NS_DURING
		[_stdinput writeData:[str dataUsingEncoding:NSASCIIStringEncoding]];
	NS_HANDLER
		if(modemLog) [self log:@"_writeCommand: %@", localException];
	NS_ENDHANDLER
}

- (int) runCommand:(NSString *) cmd target:(id) t action:(SEL) a timeout:(NSTimeInterval) seconds;
{
	NSAutoreleasePool *arp=[NSAutoreleasePool new];
	NSDate *timeout;
	if(modemLog) [self log:@"run %@", cmd];
	// status=CTModemTimeout;	// default status
	if(!_task)
		{
		NSPipe *p;
		_task=[NSTask new];
		[_task setLaunchPath:@"/usr/bin/bluetoothctl"];			// on base OS
#if 0
		[_task setLaunchPath:@"/bin/cat"];
#endif
		[_task setArguments:nil];
		p=[NSPipe pipe];
		_stdinput=[[p fileHandleForWriting] retain];
		[_task setStandardInput:p];
		p=[NSPipe pipe];
		_stdoutput=[[p fileHandleForReading] retain];
		[_task setStandardOutput:p];
		// [_task setStandardError:p];	// use a single pipe for both stdout and stderr
		_modes=[[NSArray arrayWithObjects:NSDefaultRunLoopMode, NSEventTrackingRunLoopMode, nil] retain];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(terminateNotification:)
													 name:NSTaskDidTerminateNotification
												   object:_task];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(_dataReceived:)
													 name:NSFileHandleReadCompletionNotification
												   object:_stdoutput];	// make us see notifications
		[_stdinput readInBackgroundAndNotifyForModes:_modes];	// and trigger notifications
		[_task launch];
		}
	_done=NO;
	_target=t;
	_action=a;
	[self _writeCommand:cmd];
	[_stdinput synchronizeFile];	// flush to bluetoothctl process
	timeout=[NSDate dateWithTimeIntervalSinceNow:seconds];
	// CHECKME: does this really work with setting the done flag on receiving OK?
	while(!_done && [timeout timeIntervalSinceNow] >= 0)
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeout];
	if(!_done)
		{
		if(modemLog) [self log:@"timeout for: %@", cmd];
		// status=timeout
		}
	[arp release];
	return _status;
}

- (int) runCommand:(NSString *) cmd target:(id) t action:(SEL) a;
{
	return [self runCommand:cmd target:t action:a timeout:2.0];
}

- (int) runCommand:(NSString *) cmd
{ // without callback
	return [self runCommand:cmd target:nil action:NULL];
}

- (NSArray *) runCommandReturnResponse:(NSString *) cmd;
{
	[self runCommand:cmd target:self action:NULL];
	return [NSArray array];
}

- (BOOL) activateBluetoothHardware:(BOOL) flag;
{
	[self runCommand:flag?@"power on":@"power off"];
	return YES;	// ok
}

- (BOOL) bluetoothHardwareIsActive;
{
	return [[self runCommandReturnResponse:@"show"] containsObject:@"	Powered: yes"];
}

- (BOOL) setDiscoverable:(BOOL) flag;
{
	[self runCommand:flag?@"pairable on":@"pairable off"];
	return YES;	// unchaged
}

- (BOOL) isDiscoverable;
{
	return [[self runCommandReturnResponse:@"show"] containsObject:@"	Discoverable: yes"];
}

@end
