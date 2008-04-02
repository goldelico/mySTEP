//
//  UIApplication.m
//  UIKit
//
//  Created by H. Nikolaus Schaller on 06.03.08.
//  Copyright 2008 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//
//  based on http://www.cocoadev.com/index.pl?UIKit
//

#import <UIKit/UIKit.h>

Class appClass;

int UIApplicationMain(int argc, char *argv[], Class subclass);
{
	appClass=subclass;
	reutrn NSApplicationMain(argc, argv);
}

@implementation UIApplication

- (void) applicationDidFinishLaunching:(id) unused;
{
	return;	// subclass override
}

- (void) applicationWillTerminate;
{
	return;	// subclass override
}

- (void) applicationWillSuspend;
{
	return;	// subclass override
}

- (void) deviceOrientationChanged:(GSEvent*) event;
{
	return;	// subclass override
}

- (void) applicationResume:(GSEvent *) event;
{
	return;	// subclass override
}

- (void) applicationSuspend:(GSEvent *) event;
{
	return;	// subclass override
}

- (void) menuButtonUp:(GSEvent *) event;
{
	return;	// subclass override
}

- (void) menuButtonDown:(GSEvent *) event;
{
	return;	// subclass override
}

- (BOOL) launchApplicationWithIdentifier:(NSString *) identifier suspended:(BOOL) flag;
{
	return [[NSWorkspace sharedWorkspace] launchApplication:identifier];
}

- (void) openURL:(NSURL *) url;
{
	return [[NSWorkspace sharedWorkspace] openURL:url];
}

- (void) openURL:(NSURL *) url asPanel:(BOOL) flag;
{
	return [[NSWorkspace sharedWorkspace] openURL:url];
}

@end
