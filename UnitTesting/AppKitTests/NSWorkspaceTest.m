//
//  NSWorkspaceTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 27.12.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Cocoa/Cocoa.h>


@implementation NSWorkspaceTest

- (void) setUp;
{
}

- (void) tearDown;
{
}

- (void) test01
{ // allocation did work
	// debugging of appname magic and CFBundleName
	NSString *path=@"/System/Library/PreferencePanes/Displays.prefPane";
	NSString *appName=@"";
	NSString *type=@"";
	[[NSWorkspace sharedWorkspace] getInfoForFile:path application:&appName type:&type];
	NSLog(@"%@ -> %@ %@", path, appName, type);
	//	NSLog(@"%@", [[QSLaunchServices sharedWorkspace] _applicationNameForIdentifier:@"com.apple.finder"]);
	NSLog(@"%@", [[NSWorkspace sharedWorkspace] fullPathForApplication:@"Finder"]);
	NSLog(@"%@", [[NSWorkspace sharedWorkspace] fullPathForApplication:@"Inventar"]);
	// FIXME: is application name case sensitive or not?
}

@end
