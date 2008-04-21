//
//  UIApplication.h
//  UIKit
//
//  Created by H. Nikolaus Schaller on 06.03.08.
//  Copyright 2008 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//
//  based on http://www.cocoadev.com/index.pl?UIKit
//

#import <Cocoa/Cocoa.h>

@class GSEvent;

@interface UIApplication : NSObject {
	NSApplication *_application;	// the wrapped NSApplication object
	id _delegate;					// our delegate
}

int UIApplicationMain(int argc, char *argv[], NSString *subclass, NString *otherclass);

- (void) applicationDidFinishLaunching:(id) unused;
- (void) applicationWillTerminate;
- (void) applicationWillSuspend;
- (void) deviceOrientationChanged:(GSEvent*) event;
- (void) applicationResume:(GSEvent *) event;
- (void) applicationSuspend:(GSEvent *) event;
- (void) menuButtonUp:(GSEvent *) event;
- (void) menuButtonDown:(GSEvent *) event;
- (BOOL) launchApplicationWithIdentifier:(NSString *) identifier suspended:(BOOL) flag;
- (void) openURL:(NSURL *) url;
- (void) openURL:(NSURL *) url asPanel:(BOOL) flag;

@end
