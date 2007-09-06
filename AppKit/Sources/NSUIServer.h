//
//  NSUIServer.h
//  mySTEP
//
//  Private interfaces used internally in AppKit implementation only
//  to communicate with a single, shared UIServer process to provide
//  global services (e.g. list of all applications, Status Menu, Menu Extras)
//
//  Created by Dr. H. Nikolaus Schaller on Thu Jan 05 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AppKit/NSApplication.h>
#import <AppKit/NSSound.h>
#import <AppKit/NSStatusBar.h>
#import <AppKit/NSWorkspace.h>

@protocol _NSUIServerProtocol

// communication with distributed workspace server (which should be the SystemUIServer process)

/* application management */

- (bycopy NSArray *) launchedApplications;		// return info about all applications (array of NSDictionary)
- (bycopy NSDictionary *) activeApplication;	// return info about active application
- (oneway void) becameActive:(int) pid;			// make this the active application
// - (int) findApp:(int) pid;			// find by process id and return index into launchedApplications list
- (oneway void) registerApplication:(int) pid						// getpid()
							   name:(bycopy NSString *) name		// name
							   path:(bycopy NSString *) path		// full file path
							  NSApp:(byref NSApplication *) app;	// creates NSDistantObject to remotely access NSApp
- (oneway void) unRegisterApplication:(int) pid;	// unregister (pid should be pid of sender!)
- (oneway void) hideOtherApplications:(int) pid;	// send hide: to all other applications

/* get access to the system wide status bar */

- (byref NSStatusBar *) systemStatusBar;			// get global status bar

/* system wide sound generator component */

- (bycopy NSArray *) soundFileTypes;
- (oneway void) play:(byref NSSound *) sound;	// mix sound into currently playing sounds or schedule to end of queue
- (oneway void) pause:(byref NSSound *) sound;
- (oneway void) resume:(byref NSSound *) sound;
- (oneway void) stop:(byref NSSound *) sound;
- (BOOL) isPlaying:(byref NSSound *) sound;

/* request&cancel user attention for a given application */

- (int) requestUserAttention:(NSRequestUserAttentionType) requestType forApplication:(byref NSApplication *) app;
- (oneway void) cancelUserAttentionRequest:(int) request;

@end

@protocol _NSInputServicesProtocol

/* system wide inking service */

- (oneway void) startInkingForApplication:(byref NSApplication *) app atScreenPosition:(NSPoint) point;
	// calls back [app postEvent:] or [app postEvent:] with keyboard events

- (oneway void) enableASR:(BOOL) flag;	// enable automatic speech recognition
- (oneway void) enableOCR:(BOOL) flag;	// enable OCR
- (oneway void) enableVKBD:(BOOL) flag;	// enable virtual keyboard

@end

@interface NSWorkspace (NSUIServer)

+ (id <_NSUIServerProtocol>) _distributedWorkspace;			// get proxy to contact UIServer
+ (id <_NSInputServicesProtocol>) _inputServices;

@end