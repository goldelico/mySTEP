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
#import "NSPrivate.h"

#include <sys/types.h>
#include <pwd.h>

#define NOTE(note_name) \
[NSNotification notificationWithName: NSTask##note_name##Notification \
object: self \
userInfo: nil]

static void _catchChildExit(int sig);

// Class variables
NSString *NSTaskDidTerminateNotification = @"NSTaskDidTerminateNotification";	// public

static NSMutableArray *__taskList = nil;
static NSNotification *__didReceiveSignal = nil;	// notification sent to NSTask class on SIGCHLD
static BOOL __notifyTaskDidTerminate=YES;
static int __childExitSignalCount=0;
static NSNotificationQueue *__notificationQueue = nil;
static NSString *NSTask_DidSignal_Notification = @"NSTask_DidSignal_Notification";	// internal

@implementation NSTask

- (void) _collectChild
{ // collect termination status
#if 0
	NSLog(@"_collectChild: %@", self);
#endif
	if (waitpid(_taskPID, &_terminationStatus, WNOHANG) == _taskPID)
		{
#if 0
		NSLog(@"NSTask collect: %@", self);
#endif
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
#if 0
			NSLog(@"c. tasklist count=%d", [__taskList count]);
			NSLog(@"c. tasklist=%@", __taskList);
#endif
		}
}

+ (void) initialize
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	__taskList = [NSMutableArray new];
	__didReceiveSignal = [NOTE(_DidSignal_) retain];	// we must prepare this notfication so that it can be processed in a signal handler
	[__didReceiveSignal _makeSignalSafe];	// will be called in signal context!
	[nc addObserver: self
		   selector: @selector(_didReceiveSignal:)
			   name: NSTask_DidSignal_Notification
			 object: self];
	__notifyTaskDidTerminate=YES;
	__notificationQueue = [NSNotificationQueue defaultQueue];
	(void)signal(SIGCHLD, _catchChildExit);				// set sig handler to catch child exit
	(void)signal(SIGTTOU, SIG_IGN);
#if 0
	fprintf(stderr, "NSTask: _catchChildExit installed\n");
	fprintf(stderr, "NSTask: __didReceiveSignal = %s\n", [[__didReceiveSignal description] UTF8String]);
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
	[_user release];
	[super dealloc];
}

- (void) _checkIfLaunched:(SEL) cmd
{
	if (!_task.hasLaunched)
		[NSException raise: NSInvalidArgumentException
					format: @"NSTask - task has not yet launched (%@)", NSStringFromSelector(cmd)];
}

- (void) _checkIfNotLaunched:(SEL) cmd
{
	if (_task.hasLaunched)
		[NSException raise: NSInvalidArgumentException
					format: @"NSTask - task has not already been launched (%@)", NSStringFromSelector(cmd)];
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
	[self _checkIfNotLaunched:_cmd];
	ASSIGN(_environment, env);
}

- (void) setArguments:(NSArray*)args
{
	[self _checkIfNotLaunched:_cmd];
	ASSIGN(_arguments, args);
}

- (void) setCurrentDirectoryPath:(NSString*)path
{
	[self _checkIfNotLaunched:_cmd];
	ASSIGN(_currentDirectoryPath, path);
}

- (void) setLaunchPath:(NSString*)path
{
	[self _checkIfNotLaunched:_cmd];
	ASSIGN(_launchPath, path);
}

- (NSString*) launchPath					{ return _launchPath; }
- (NSString*) currentDirectoryPath			{ return _currentDirectoryPath; }
- (NSArray*) arguments						{ return _arguments; }
- (int) processIdentifier;					{ return _taskPID; }

- (NSString *) _userName; { return _user; }

- (void) _setUserName:(NSString *) user;
{
	[self _checkIfNotLaunched:_cmd];
	[_user autorelease];
	_user=[user retain];
}

- (void) setStandardInput:(id)fd
{
	[self _checkIfNotLaunched:_cmd];
	ASSIGN(_standardInput,fd);
}

- (void) setStandardOutput:(id)fd
{
	[self _checkIfNotLaunched:_cmd];
	ASSIGN(_standardOutput,fd);
}

- (void) setStandardError:(id)fd
{
	[self _checkIfNotLaunched:_cmd];
	ASSIGN(_standardError,fd);
}

- (id) standardInput						{ return _standardInput; }
- (id) standardOutput						{ return _standardOutput; }
- (id) standardError						{ return _standardError; }

- (BOOL) isRunning
{
	return _task.hasLaunched && !_task.hasTerminated;
}

- (int) terminationStatus
{
	[self _checkIfLaunched:_cmd];

	if (!_task.hasCollected)
		[self _collectChild];
	if (!_task.hasCollected)
		[NSException raise: NSInvalidArgumentException
					format: @"NSTask - could not collect termination status"];

	if (!_task.hasTerminated)
		[NSException raise: NSInvalidArgumentException
					format: @"NSTask - task has not yet terminated"];

	return _terminationStatus;
}

- (NSTaskTerminationReason) terminationReason;
{
	[self terminationStatus];	// may collect
	return _task.hasTerminatedBySignal?NSTaskTerminationReasonUncaughtSignal:NSTaskTerminationReasonExit;
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
	NSUInteger argCount = [a count];
	const char *args[argCount+2];
	NSDictionary *e = [self environment];
	NSUInteger envCount = [e count];
	const char *envl[envCount+1];
	NSArray *k = [e allKeys];
	struct passwd *p=NULL;

	if (_task.hasLaunched)
		return; // already launched

	if (_launchPath == nil)
		[NSException raise: NSInvalidArgumentException
					format: @"NSTask: no launch path set"];
#if 0
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

	if(_currentDirectoryPath == nil)
		{ // use default directory
			_currentDirectoryPath =NSHomeDirectory();
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

	if(_user)
		{ // lookup _user and change user id
			p=getpwnam([_user UTF8String]);
			if(!p)
				[NSException raise: NSInvalidArgumentException format: @"NSTask - invalid user name %@", _user];
		}

#if 0
	NSLog(@"cd %s; %s %s %s ...", path, args[0], args[1]!=NULL?args[1]:"", (args[1]!=NULL&&args[2]!=NULL)?args[2]:"");
	NSLog(@"stdin=%d stdout=%d stderr=%d", idesc, odesc, edesc);
#endif
	_task.hasLaunched = YES;		// we may receive the SIGCHLD before our fork returns...
	switch (pid = fork()){	// fork to create a child process
		case -1:
			[NSException raise: NSInvalidArgumentException			// error
						format: @"NSTask - failed to create child process"];
		case 0: { // child process -- fork returns zero
#if 0
			NSLog(@"child process");
#endif
			if(_user)
				{ // works only if parent has proper rights (e.g. running as root)
				if(setuid(p->pw_uid) < 0)
					{
					NSLog(@"NSTask: unable to change user to %@ - exiting", _user);
					_task.hasTerminated=YES;	// since we did not execve, we still share the address space with our parent
					exit(127);
					}
				}
			// WARNING: don't raise NSExceptions here or we will end up in two instances of the calling task with shared address space!
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
			if(chdir(path) == 0)
				{
#if 0
				NSLog(@"child %@", [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/dev/fd" error:NULL]);
#endif
				execve(executable, (char *const *)args, (char *const *)envl);	// and execute
				NSLog(@"NSTask: unable to execve %s - exiting", executable);
				}
			else
				NSLog(@"NSTask: unable to change directory to %s - exiting", path);
			_task.hasTerminated=YES;	// since we did not execve, we still share the address space with our parent
			exit(127);
		}
		default: { // parent process -- fork returns PID of child
			_taskPID = pid;
			// close unused ends of NSPipes to free up file descriptors
			if([_standardInput isKindOfClass:[NSPipe class]])
				[[_standardInput fileHandleForReading] closeFile];
			if([_standardOutput isKindOfClass:[NSPipe class]])
				[[_standardOutput fileHandleForWriting] closeFile];
			if([_standardError isKindOfClass:[NSPipe class]])
				[[_standardError fileHandleForWriting] closeFile];
#if 0
			NSLog(@"parent %@", [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/dev/fd" error:NULL]);
#endif
			break;
		}
	}
}

- (void) interrupt
{
	[self _checkIfLaunched:_cmd];

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
	[self _checkIfLaunched:_cmd];

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
	[self _checkIfLaunched:_cmd];

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
	[self _checkIfLaunched:_cmd];

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
	[self retain];	// _collectChild may dealloc
	while([self isRunning])
		{
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];	// will return if we catch a signal, e.g. SIGCHLD
		}
	[self release];
#if 0
	NSLog(@"didExit %@", self);
#endif
}

/* glue with signal handler */

+ (void) _didReceiveSignal:(NSNotification *)aNotification
{ // we receive this notification from the runloop at next idle time after _catchChildExit()
#if 0
	NSLog(@"_didReceiveSignal: %@", aNotification);
#endif
	do
		{
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
		NSEnumerator *enumerator = [__taskList reverseObjectEnumerator];
		NSTask *anObject;
		// NOTE: if application calls system() or popen() we may be notified even if no NSTask is involved - then we will not collect anyone
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
		__childExitSignalCount--;	// signal has been matched
		} while(__childExitSignalCount > 0 && [__taskList count] > 0);	// we probably have lost some signal while processing the task loop
	__notifyTaskDidTerminate=YES;	// reenable queueing another notification
#if 0
	if(__childExitSignalCount != 0)	// system() may disturb our counter and if a SIGNAL occurs between the while() and __notifyTaskDidTerminate=YES
		{
		NSLog(@"did probably loose %d SIGCHLD notification(s)", __childExitSignalCount);
		NSLog(@"  tasklist count=%lu", (unsigned long)[__taskList count]);
		NSLog(@"  tasklist=%@", __taskList);
		}
#endif
}

@end

static void _catchChildExit(int sig)
{ // this is a signal handler - don't allocate memory or put anything into an ARP (like NSLog does)!
#if 0
	fprintf(stderr, "_catchChildExit %d\n", sig);
#endif
	if(sig == SIGCHLD)
		{
		__childExitSignalCount++;	// this includes children created through the system() call!
		if(__notifyTaskDidTerminate)
			{ /* coalesce by not enqueueing more than once */
				__notifyTaskDidTerminate=NO;	// ignore further signals until we have received this notification through the runloop - CHECKME: might this create a short blind period?
				/* NOTE: __didReceiveSignal must be initialized signalsafe and modes must be nil
				 * we should also not do coalescing in signal handler context
				 */
				[__notificationQueue enqueueNotification:__didReceiveSignal
											postingStyle:NSPostASAP	// a signal interrupts the runloop
											coalesceMask:NSNotificationNoCoalescing
												forModes:nil];
#if 0
				fprintf(stderr, "_catchChildExit notification queued count=%d\n", __childExitSignalCount);
#endif
			}
#if 1
		else
			fprintf(stderr, "_catchChildExit skipped count=%d\n", __childExitSignalCount);
#endif
		}
}
