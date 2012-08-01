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
static int __childExitCount=0;
static NSNotificationQueue *__notificationQueue = nil;
NSString *NSTaskDidTerminateNotification = @"NSTaskDidTerminateNotification";

@implementation NSTask

- (void) _collectChild
{ // collect termination status
	if (waitpid(_taskPID, &_terminationStatus, WNOHANG) == _taskPID) 
		{
		_task.hasCollected = YES;
		_task.hasTerminated = YES;
		
		if (WIFSIGNALED(_terminationStatus))
			{
			_task.hasTerminatedBySignal=YES;
			_terminationStatus = WTERMSIG(_terminationStatus);		// replace by signal number
			}
		else if (WIFEXITED(_terminationStatus)) 
			_terminationStatus = WEXITSTATUS(_terminationStatus);	// replace by exit status
		}
	
	if (_task.hasTerminated && !_task.hasNotified)
		{ // post notification immediately
		NSNotificationQueue *nq = [NSNotificationQueue defaultQueue];
		
		_task.hasNotified = YES;
#if 0
		NSLog(@"task did terminate: %@ %p", self, self);
		NSLog(@"a. tasklist count=%d", [__taskList count]);
#endif
		[nq enqueueNotification:NOTE(DidTerminate)
				   postingStyle:NSPostNow
				   coalesceMask:NSNotificationNoCoalescing
					   forModes:nil];	// this might add new objects!
#if 0
		NSLog(@"b. tasklist count=%d", [__taskList count]);
		NSLog(@"b. tasklist=%@", __taskList);
#endif
		[__taskList removeObjectIdenticalTo:self];	// may issue a [self dealloc]
		__childExitCount--;
#if 0
		NSLog(@"c. tasklist count=%d", [__taskList count]);
		NSLog(@"c. tasklist=%@", __taskList);
#endif
		}
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
	(void)signal(SIGCHLD, _catchChildExit);				// set sig handler to catch child exit
#if 0
	fprintf(stderr, "NSTask: _catchChildExit installed\n");
#endif
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
#if 0
	NSLog(@"NSTask dealloc %@", self);
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
    if (!_task.hasCollected)
		[NSException raise: NSInvalidArgumentException
					format: @"NSTask - could not collect termination status"];

    return _terminationStatus;
}

- (NSTaskTerminationReason) terminationReason;
{
	[self terminationStatus];	// may collect
	return _task.hasTerminatedBySignal?NSTaskTerminationReasonUncaughtSignal:NSTaskTerminationReasonExit;
}

static int getfd(NSTask *self, id object, BOOL read, int def)
{ // extract file descriptor
#if 1
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
#if 1
    NSLog(@"executable=%s", [_launchPath fileSystemRepresentation]);
#endif
	if (![[NSFileManager defaultManager] isExecutableFileAtPath:_launchPath])
		{
		executable = [_launchPath UTF8String];	// try on root file system
		if(access(executable, X_OK) != 0)
			[NSException raise: NSInvalidArgumentException
						format:@"NSTask: no executable at launch path %@", _launchPath];		
		}
	else
		{
		executable = [_launchPath fileSystemRepresentation];		
		}
	[__taskList addObject:self];
    args[0] = [_launchPath UTF8String];					// pass full path as provided by caller
    for(i = 0; i < argCount; i++)
		args[i+1] = [[[a objectAtIndex: i] description] UTF8String];
    args[argCount+1] = NULL;

	// CHECKME: is this a good decision? or should we use $HOME?
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
	_task.hasLaunched = YES;		// we may receive the SIGCHLD before our fork returns...
    switch (pid = fork())	// fork to create a child process
		{
		case -1:
			[NSException raise: NSInvalidArgumentException			// error
								 format: @"NSTask - failed to create child process"];
		case 0:
			{ // child process -- fork returns zero
#if 1
			NSLog(@"child process");
#endif
			// WARNING - don't raise NSExceptions here or we will end up in two instances of the calling task with shared address space!
			if(idesc != 0) dup2(idesc, 0);	// redirect
			if(odesc != 1) dup2(odesc, 1);	// redirect
			if(edesc != 2) dup2(edesc, 2);	// redirect
			if(idesc > 2) close(idesc);	// original is no longer used after redirect
			if(odesc > 2) close(odesc);	// original is no longer used after redirect
			if(edesc > 2) close(edesc);	// original is no longer used after redirect
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
#if 1
			NSLog(@"child %@", [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/dev/fd" error:NULL]);
#endif
			execve(executable, (char *const *)args, (char *const *)envl);	// and execute
			NSLog(@"NSTask: unable to execve %s", executable);
			exit(127);
			}
		default:						
			{ // parent process -- fork returns PID of child
			_taskPID = pid;
			// close unused ends of NSPipes to free up file descriptors
			if([_standardInput isKindOfClass:[NSPipe class]])
				[[_standardInput fileHandleForReading] closeFile];
			if([_standardOutput isKindOfClass:[NSPipe class]])
				[[_standardOutput fileHandleForWriting] closeFile];
			if([_standardError isKindOfClass:[NSPipe class]])
				[[_standardError fileHandleForWriting] closeFile];
#if 1
			NSLog(@"parent %@", [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/dev/fd" error:NULL]);
#endif
			break;
			}
		}
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
#if 0
	NSLog(@"waitUntilExit");
#endif
    while([self isRunning])
		{
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];	// will return if we catch a signal, e.g. SIGCHLD
		}
#if 0
	NSLog(@"didExit %@", self);
#endif
}

+ (void) _taskDidTerminate:(NSNotification *)aNotification
{ // we receive this notification from the runloop at next idle time after _catchChildExit() - our clients may receive this as well!
	do
		{
			NSAutoreleasePool *pool = [NSAutoreleasePool new];
			NSEnumerator *enumerator = [__taskList reverseObjectEnumerator];
			NSTask *anObject;
			while ((anObject = (NSTask*)[enumerator nextObject]))
				{
				if (!anObject->_task.hasCollected)
					[anObject _collectChild];	// this may release the task
				}
#if 0
			NSLog(@"d. tasklist count=%d", [__taskList count]);
			NSLog(@"d. tasklist=%@", __taskList);
#endif
			[pool release];
#if 0
			NSLog(@"e. tasklist count=%d", [__taskList count]);
#endif
		} while(__childExitCount > 0 && [__taskList count] > 0);	// we have lost some signal while processing the task loop
	__notifyTaskDidTerminate=YES;	// reenable queuing another notification
#if 1
	if(__childExitCount != 0)	// system() may disturb our counter
		{
		NSLog(@"did probably loose %d SIGCHLD notification(s)", __childExitCount);
		NSLog(@"  tasklist count=%d", [__taskList count]);
		NSLog(@"  tasklist=%@", __taskList);
		}
#endif
}

@end

static void _catchChildExit(int sig)								
{ // this is a signal handler - don't call NSLog here or put anything into an ARP
#if 0
	fprintf(stderr, "_catchChildExit %d\n", sig);
#endif
	if(sig == SIGCHLD)
		{
		__childExitCount++;	// this includes children created through the system() call!
		if(__notifyTaskDidTerminate)
			{
			__notifyTaskDidTerminate=NO;	// ignore further signals until we have received this notification through the runloop - CHECKME: might this create a short blind period?
			[__notificationQueue enqueueNotification:__taskDidTerminate
										postingStyle:NSPostWhenIdle	// a signal interrupts the runloop like Idle mode
										coalesceMask:NSNotificationCoalescingOnName
											forModes:nil];
#if 0
			fprintf(stderr, "_catchChildExit notification queued count=%d\n", __childExitCount);
#endif
			}
#if 0
		else
			fprintf(stderr, "_catchChildExit skipped count=%d\n", __childExitCount);
#endif
		}
}
