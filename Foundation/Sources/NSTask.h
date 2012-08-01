/* 
   NSTask.h

   Interface to NSTask

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date: 	September 2000

   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   Fabian Spillner, July 2008 - API revised to be compatible to 10.5
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSTask
#define _mySTEP_H_NSTask

#import <Foundation/NSObject.h>

@class NSDictionary;
@class NSArray;
@class NSString;
@class NSNotification;

typedef enum NSTaskTerminationReason
{
	NSTaskTerminationReasonExit				= 1,
	NSTaskTerminationReasonUncaughtSignal	= 2
} NSTaskTerminationReason;


@interface NSTask : NSObject
{
    NSString *_currentDirectoryPath;
    NSString *_launchPath;
    NSArray *_arguments;
    NSDictionary *_environment;
    id _standardError;  // NSPipe or NSFileHandle or NSNumber
    id _standardInput;
    id _standardOutput;
    int _taskPID;
    int _terminationStatus;
	int _suspendCount;
    struct __taskFlags {
		unsigned int hasLaunched:1;
		unsigned int hasTerminated:1;
        unsigned int hasCollected:1;
        unsigned int hasNotified:1;
        unsigned int hasTerminatedBySignal:1;
        unsigned int reserved:3;
    } _task;
}

+ (NSTask *) launchedTaskWithLaunchPath:(NSString *) path 
							  arguments:(NSArray*)args;

- (NSArray *) arguments;
- (NSString *) currentDirectoryPath;
- (NSDictionary *) environment;
- (id) init;
- (void) interrupt;										// Task management
- (BOOL) isRunning;										// Task state
- (void) launch;
- (NSString *) launchPath;
- (int) processIdentifier;
- (BOOL) resume;
- (void) setArguments:(NSArray *) args;
- (void) setCurrentDirectoryPath:(NSString *) path;
- (void) setEnvironment:(NSDictionary *) env;
- (void) setLaunchPath:(NSString *) path;
- (void) setStandardError:(id) hdl;	// accepts NSFileHandle, NSPipe or NSNumber
- (void) setStandardInput:(id) hdl;
- (void) setStandardOutput:(id) hdl;
- (id) standardError;
- (id) standardInput;
- (id) standardOutput;
- (BOOL) suspend;
- (void) terminate;
- (int) terminationStatus;
- (NSTaskTerminationReason) terminationReason;
- (void) waitUntilExit;

@end

extern NSString *NSTaskDidTerminateNotification;

#endif /* _mySTEP_H_NSTask */
