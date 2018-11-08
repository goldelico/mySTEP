//
//  IOBluetoothController.h
//  IOBluetooth
//
//  Created by H. Nikolaus Schaller on 30.10.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IOBluetoothController : NSObject
{
	NSTask *_task;
	NSArray *_modes;
	NSFileHandle *_stdinput;
	NSFileHandle *_stdoutput;
	SEL _action;
	id _target;
	SEL _unsolicitedAction;
	id _unsolicitedTarget;
	NSString *_lastChunk;
	BOOL _done;
	int _status;
}

- (void) _processLine:(NSString *) line;
- (void) _processData:(NSData *) line;
- (void) _dataReceived:(NSNotification *) n;
- (void) _writeCommand:(NSString *) str;
- (int) _runCommand:(NSString *) cmd target:(id) t action:(SEL) a timeout:(NSTimeInterval) seconds;
- (int) _runCommand:(NSString *) cmd target:(id) t action:(SEL) a;
- (int) _runCommand:(NSString *) cmd;
- (NSArray *) runCommandReturnResponse:(NSString *) cmd;

@end

@interface IOBluetoothController (Public)

+ (IOBluetoothController *) sharedController;
- (BOOL) activateBluetoothHardware:(BOOL) flag;
- (BOOL) bluetoothHardwareIsActive;
- (BOOL) setDiscoverable:(BOOL) flag;
- (BOOL) isDiscoverable;

@end
