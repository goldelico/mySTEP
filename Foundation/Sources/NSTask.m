/* 
   NSTask.m

   Implementation of NSTask

   Copyright (C) 1998 Free Software Foundation, Inc.

   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: 	1998
   Author:  Felipe A. Rodriguez <farz@mindspring.com>
   Date: 	March 1999

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#include <sys/types.h>
#include <sys/signal.h>
#include <sys/wait.h>
#include <unistd.h>

#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSTask.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSFileHandle.h>
#import <Foundation/NSProcessInfo.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSNotificationQueue.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSValue.h>

#define NOTE(note_name) \
		[NSNotification notificationWithName: NSTask##note_name##Notification \
						object: self \
						userInfo: nil]

static void _catchChildExit(int sig);

// Class variables
static NSMutableArray *__taskList = nil;
static NSNotification *__taskDidTerminate = nil;	// notification sent to NSTask class on SIGCHLD
static BOOL __notifyTaskDidTerminate=YES;
static NSNotificationQueue *__notificationQueue = nil;
NSString *NSTaskDidTerminateNotification = @"NSTaskDidTerminateNotification";

@implementation NSTask

- (void) _collectChild
{
    if (!_task.hasCollected) 
		{
		if (waitpid(_taskPID, &_terminationStatus, WNOHANG) == _taskPID) 
			{
			_task.hasCollected = YES;
			_task.hasTerminated = YES;

	    	if (WIFEXITED(_terminationStatus)) 
				_terminationStatus = WEXITSTATUS(_terminationStatus);
			}

    	if (_task.hasTerminated && !_task.hasNotified)
			{ // post notification immediately
			NSNotificationQueue *nq = [NSNotificationQueue defaultQueue];

			_task.hasNotified = YES;
			[nq enqueueNotification:NOTE(DidTerminate)
				postingStyle:NSPostNow
				coalesceMask:NSNotificationNoCoalescing
				forModes:nil];
			[__taskList removeObject:self];
			}
		}
}

+ (void) _taskDidTerminate:(NSNotification *)aNotification
{ // we receive this notification immediately from the runloop after _catchChildExit()
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	NSEnumerator *enumerator = [__taskList reverseObjectEnumerator];
	NSTask *anObject;

	__notifyTaskDidTerminate=YES;	// reenable queuing another notification

	while ((anObject = (NSTask*)[enumerator nextObject]))
		if (!anObject->_task.hasCollected)
			[anObject _collectChild];

    [pool release];
}

+ (void) initialize
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

	[nc addObserver: self
		selector: @selector(_taskDidTerminate:)
		name: NSTaskDidTerminateNotification
		object: self];
	__taskList = [NSMutableArray new];
	__taskDidTerminate = [NOTE(DidTerminate) retain];	// we must prepare this notfication so that it can be processed in a signal handler
	__notifyTaskDidTerminate=YES;
	__notificationQueue = [NSNotificationQueue defaultQueue];
}

+ (NSTask*) launchedTaskWithLaunchPath:(NSString*)path 
							 arguments:(NSArray*)args
{
	NSTask *task = [NSTask new];

	task->_launchPath = [path retain];
	task->_arguments = [args retain];
    [task launch];

    return [task autorelease];
}

- (id) init
{
    self=[super init];
	if(self)
		{
		_standardInput = nil;
		_standardOutput = nil;
		_standardError = nil;
		}
	return self;
}

- (void) dealloc
{
#if 1
	NSLog(@"NSTask dealloc");
#endif
	[_standardInput release];
	[_standardOutput release];
	[_standardError release];
	[_arguments release];
	[_environment release];
	[_launchPath release];
	[_currentDirectoryPath release];
	[super dealloc];
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"NSTask: path=%@ args=%@ env=%@ pwd=%@", _launchPath, _arguments, _environment, _currentDirectoryPath];
}

- (NSDictionary*) environment
{
	if (_environment == nil && (!_task.hasLaunched))
		_environment = [[[NSProcessInfo processInfo] environment] retain];

	return _environment;
}

- (void) setEnvironment:(NSDictionary*)env
{
    if (_task.hasLaunched)
		[NSException raise: NSInvalidArgumentException
					 format: @"NSTask - task has been launched"];

	ASSIGN(_environment, env);
}

- (void) setArguments:(NSArray*)args
{
	if (_task.hasLaunched)
		[NSException raise: NSInvalidArgumentException
					 format: @"NSTask - task has been launched"];

	ASSIGN(_arguments, args);
}

- (void) setCurrentDirectoryPath:(NSString*)path
{
    if (_task.hasLaunched)
		[NSException raise: NSInvalidArgumentException
					 format: @"NSTask - task has been launched"];

	ASSIGN(_currentDirectoryPath, path);
}

- (void) setLaunchPath:(NSString*)path
{
    if (_task.hasLaunched)
		[NSException raise: NSInvalidArgumentException
					 format: @"NSTask - task has been launched"];

	ASSIGN(_launchPath, path);
}

- (NSString*) launchPath					{ return _launchPath; }
- (NSString*) currentDirectoryPath			{ return _currentDirectoryPath; }
- (NSArray*) arguments						{ return _arguments; }
- (int) processIdentifier;					{ return _taskPID; }

- (void) setStandardInput:(id)fd			
{
	if (_task.hasLaunched)
		[NSException raise: NSInvalidArgumentException
					format: @"NSTask - task has been launched"];
	ASSIGN(_standardInput,fd);
}

- (void) setStandardOutput:(id)fd			
{  
	if (_task.hasLaunched)
		[NSException raise: NSInvalidArgumentException
					format: @"NSTask - task has been launched"];
	ASSIGN(_standardOutput,fd); 
}

- (void) setStandardError:(id)fd	
{
	if (_task.hasLaunched)
		[NSException raise: NSInvalidArgumentException
					format: @"NSTask - task has been launched"];
	ASSIGN(_standardError,fd); 
}

- (id) standardInput						{ return _standardInput; }
- (id) standardOutput						{ return _standardOutput; }
- (id) standardError						{ return _standardError; }

- (BOOL) isRunning
{
	return (_task.hasLaunched == NO || _task.hasTerminated == YES) ? NO : YES;
}

- (int) terminationStatus
{
    if (_task.hasLaunched == NO)
		[NSException raise: NSInvalidArgumentException
					 format: @"NSTask - task has not yet launched"];
    if (_task.hasTerminated == NO)
		[NSException raise: NSInvalidArgumentException
					 format: @"NSTask - task has not yet terminated"];

    if (!_task.hasCollected)
		[self _collectChild];

    return _terminationStatus;
}

- (void) interrupt
{
    if (_task.hasLaunched == NO) 
		[NSException raise: NSInvalidArgumentException
					format: @"NSTask - task has not yet launched"];
	
	if (!_task.hasTerminated)
		{
#ifdef HAVE_KILLPG
		killpg(_taskPID, SIGINT);
#else
		kill(_taskPID, SIGINT);
#endif
		}
}

static int getfd(NSTask *self, id object, BOOL read, int def)
{ // extract file descriptor
#if 0
	NSLog(@"getfd(%@, def=%d)", object, def);
#endif
	if(!object)
		return def; // default value
	if([object isKindOfClass:[NSFileHandle class]])
		return [object fileDescriptor];
	if([object isKindOfClass:[NSPipe class]])
		return [(read?[object fileHandleForReading]:[object fileHandleForWriting]) fileDescriptor];
	if([object isKindOfClass:[NSNumber class]])
		return [object intValue];
	[NSException raise: NSInvalidArgumentException format: @"NSTask - invalid file descriptor %@", object];
	return -1;
}

- (void) launch
{
	int	idesc = getfd(self, _standardInput, YES, 0);   // reading
	int	odesc = getfd(self, _standardOutput, NO, 1);
	int	edesc = getfd(self, _standardError, NO, 2);
	int	i, pid;
	const char *executable;
	const char *path;
	NSArray *a = [self arguments];
	int argCount = [a count];
	const char *args[argCount+2];
	NSDictionary *e = [self environment];
	int envCount = [e count];
	const char *envl[envCount+1];
	NSArray *k = [e allKeys];

    if (_task.hasLaunched)
		return; // already launched

    if (_launchPath == nil)
		[NSException raise: NSInvalidArgumentException
							 format: @"NSTask: no launch path set"];
#if 0
    NSLog(@"executable=%s", [_launchPath fileSystemRepresentation]);
#endif
	if (![[NSFileManager defaultManager] isExecutableFileAtPath:_launchPath])
		[NSException raise: NSInvalidArgumentException
							 format:@"NSTask: no executable at launch path %@", _launchPath];

	[__taskList addObject:self];
    executable = [_launchPath fileSystemRepresentation];
	// set sig handler to
	(void)signal(SIGCHLD, _catchChildExit);				// catch child exit
    args[0] = [_launchPath UTF8String];					// pass full path
    for(i = 0; i < argCount; i++)
		args[i+1] = [[[a objectAtIndex: i] description] UTF8String];
    args[argCount+1] = NULL;

	if(_currentDirectoryPath == nil)
		{ // use launch path to set the directory
		_currentDirectoryPath =[_launchPath stringByDeletingLastPathComponent];
		[_currentDirectoryPath retain];
		}
	path = [_currentDirectoryPath fileSystemRepresentation];

    for (i = 0; i < envCount; i++)
		{
		NSString *s;
		id key = [k objectAtIndex: i];
		id val = [_environment objectForKey: key];
		if (val)
			s = [NSString stringWithFormat:@"%@=%@", key, val];
		else
			s = [NSString stringWithFormat:@"%@=", key];
		envl[i] = [s UTF8String];
		}
    envl[envCount] = 0;
#if 1
	NSLog(@"cd %s; %s %s %s ...", path, args[0], args[1]!=NULL?args[1]:"", (args[1]!=NULL&&args[2]!=NULL)?args[2]:"");
	NSLog(@"stdin=%d stdout=%d stderr=%d", idesc, odesc, edesc);
#endif
    switch (pid = fork())									// fork to create
		{													// a child process
		case -1:
			[NSException raise: NSInvalidArgumentException			// error
								 format: @"NSTask - failed to create child process"];
		case 0:
			{ // child process -- fork return zero
#if 0
			NSLog(@"child process");
#endif
			// WARNING - don't raise NSExceptions here or we will end up in two instances of the calling task!
			if(idesc != 0)	
				dup2(idesc, 0), close(idesc); // redirect
			if(odesc != 1)
				dup2(odesc, 1), close(odesc); // redirect
			if(edesc != 2)
				dup2(edesc, 2), close(edesc); // redirect
			// close unused ends of NSPipes to free up file descriptors
			if([_standardInput isKindOfClass:[NSPipe class]])
				[[_standardInput fileHandleForWriting] closeFile];
			if([_standardOutput isKindOfClass:[NSPipe class]])
				[[_standardOutput fileHandleForReading] closeFile];
			if([_standardError isKindOfClass:[NSPipe class]])
				[[_standardError fileHandleForReading] closeFile];
			// try to switch working directory
			if(chdir(path) == -1)
				NSLog(@"NSTask: unable to change directory to %s", path);
#if 0
			NSLog(@"execve...");
#endif
			execve(executable, (char *const *)args, (char *const *)envl);	// and execute
			NSLog(@"NSTask: unable to execve %s", executable);
			exit(127);
			}
		default:						
			{ // parent process -- fork returns PID of child
			_taskPID = pid;
			_task.hasLaunched = YES;
			// close unused ends of NSPipes to free up file descriptors
			if([_standardInput isKindOfClass:[NSPipe class]])
				[[_standardInput fileHandleForReading] closeFile];
			if([_standardOutput isKindOfClass:[NSPipe class]])
				[[_standardOutput fileHandleForWriting] closeFile];
			if([_standardError isKindOfClass:[NSPipe class]])
				[[_standardError fileHandleForWriting] closeFile];
			break;
			}
		}
}

- (void) terminate
{
    if (_task.hasLaunched == NO) 
		[NSException raise: NSInvalidArgumentException
					 format: @"NSTask - task has not yet launched"];

	if (!_task.hasTerminated)
		{
		_task.hasTerminated = YES;
#ifdef HAVE_KILLPG
		killpg(_taskPID, SIGTERM);
#else
		kill(_taskPID, SIGTERM);
#endif
		}
}

- (BOOL) suspend;
{
	if(_suspendCount++ == 0)
		{ // first suspend
		// send SIGSTOP
		NSLog(@"suspend NSTask not implemented");
		return NO;
		}
	return YES;
}

- (BOOL) resume;
{
	if(--_suspendCount == 0)
		{ // matching first suspend
		// send SIGSTART
		NSLog(@"resume NSTask not implemented");
		return NO;
		}
	return YES;
}

- (void) waitUntilExit
{
    while([self isRunning])
		{
#if OLD
		NSDate *d = [[NSDate alloc] initWithTimeIntervalSinceNow: 1.0]; // Poll at 1.0 second intervals.
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:d];
		[d release];
#endif
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];	// will return if we catch SIGCHLD
		}
}

@end

static void _catchChildExit(int sig)								
{
#if 1
	NSLog(@"_catchChildExit");
#endif
	if(sig == SIGCHLD && __notifyTaskDidTerminate)
		{
		[__notificationQueue enqueueNotification:__taskDidTerminate
							 postingStyle:NSPostWhenIdle	// a signal interrupts the runloop like Idle mode
							 coalesceMask:NSNotificationNoCoalescing
							 forModes:nil];
		__notifyTaskDidTerminate=NO;	// ignore until we have processed this notification - might this create a short blind period?
		}
}
