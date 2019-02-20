//
//  NSSystemServer.h
//  mySTEP / AppKit
//
//  Private interfaces used internally in AppKit implementation only
//  to communicate with a single, shared loginwindow process to provide
//  global services (e.g. list of all applications, inking etc.)
//
//  Created by Dr. H. Nikolaus Schaller on Thu Jan 05 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AppKit/NSApplication.h>
#import <AppKit/NSSound.h>
#import <AppKit/NSWorkspace.h>

@protocol _NSApplicationRemoteControlProtocol	// basic communication of workspace server with any application - implemented in NSApplication

- (BOOL) _application:(in NSApplication *) app openURLs:(in bycopy NSArray *) urls withOptions:(in bycopy NSWorkspaceLaunchOptions) opts;	// handle open
- (void) activate;
- (void) deactivate;
- (void) hide;
- (void) unhide;
- (void) echo;

@end

#define NSLoginWindowPort @"com.quantum-step.loginwindow"	// NSMessagePort to contact

@protocol _NSLoginWindowProtocol	// communication with system UI (which should be the loginwindow process)

	/* system menu activities */

// UI level
- (oneway void) showShutdownDialog;		// ask for shutdown
- (oneway void) showRestartDialog;		// ask for restart
- (oneway void) showForceQuitDialog;	// show the force-quit dialog
- (oneway void) chooseUser;				// allow to choose a different user
- (oneway void) logout;					// request logout with GUI interaction (may timeout)

// basic functions (without UI)
- (oneway void) terminateProcesses;		// terminate processes and immediately log out
- (oneway void) shutdown;				// request a shutdown
- (oneway void) restart;				// request a restart
- (oneway void) sleep;					// request to sleep

	/* system wide sound generator */

- (bycopy NSArray *) soundFileTypes;
- (oneway void) play:(byref NSSound *) sound;	// mix sound into currently playing sounds or schedule to end of queue
- (oneway void) pause:(byref NSSound *) sound;
- (oneway void) resume:(byref NSSound *) sound;
- (oneway void) stop:(byref NSSound *) sound;
- (BOOL) isPlaying:(byref NSSound *) sound;

	/* request&cancel user attention for a given application */

- (int) requestUserAttention:(NSRequestUserAttentionType) requestType forApplication:(byref NSApplication *) app;
- (oneway void) cancelUserAttentionRequest:(NSInteger) request;

	/* system wide inking service */

- (oneway void) startInkingAtScreenPosition:(NSPoint) point pressure:(CGFloat) pressure;	// calls back [app postEvent:] with keyboard events

	/* input methods */

- (oneway void) enableASR:(BOOL) flag;	// enable/disable automatic speech recognition
- (oneway void) enableHWR:(BOOL) flag;	// enable/disable handwriting
- (oneway void) enableOCR:(BOOL) flag;	// enable/disable OCR
- (oneway void) enableVKBD:(BOOL) flag;	// enable/disable virtual keyboard

@end

@interface NSWorkspace (NSLoginWindowServer)

+ (id <_NSLoginWindowProtocol>) _loginWindowServer;	// get distributed object to contact loginwindow - implemented in our AppKit

@end
