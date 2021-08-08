/*
   Functions.m

   Generic Functions.

   Copyright (C) 1998 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date:    December 1998
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSBundle.h>

#import <AppKit/NSApplication.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSNibLoading.h>

#import "NSAppKitPrivate.h"

@implementation NSBundle (NSPrivate)

- (NSString *) _bundleIdentifier;
{ // one that always exists...
	NSString *ident=[self bundleIdentifier];
	if(![ident length])
		{
		ident=[[self path] stringByReplacingOccurrencesOfString:@"/" withString:@"."];	// will start with a .
		NSLog(@"bundle %@ has no CFBundleIdentifier - using %@", [self path], ident);
		}
	return ident;
}

- (NSString *) _localizedBundleName;
{
	NSString *name=[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
	if(!name)
		name=[self objectForInfoDictionaryKey:@"CFBundleName"];
	if(!name)
		name=[[[self bundlePath] lastPathComponent] stringByDeletingPathExtension];
	// FIXME: check localization of this bundle...
	name=NSLocalizedString(name, @"Bundle Name");	// try to translate
	return name;
}

@end


int NSApplicationMain(int argc, const char **argv)
{
	NSAutoreleasePool *pool=[NSAutoreleasePool new];	// initial ARP
	NSBundle *b;
	NSString *mainModelFile;
	NSApplication *app=[NSApplication sharedApplication];	// initialize application
#if 1
	NSLog(@"NSApplicationMain\n");
#endif
	b=[NSBundle mainBundle];
	mainModelFile = [b objectForInfoDictionaryKey:@"NSMainNibFile"];
#if 1
	NSLog(@"NSApplicationMain - name=%@ mainmodel=%@ ident=%@", [b _localizedBundleName], mainModelFile, [b _bundleIdentifier]);
#endif

	if([[b objectForInfoDictionaryKey:@"LSGetAppDiedEvents"] boolValue])
		{ // convert SIGCHLD
		  // find a mechanism to handle kAEApplicationDied
		}
	else
		signal(SIGCHLD, SIG_IGN);	// ignore
#if 1
	NSLog(@"NSMainNibFile = %@", mainModelFile);
#endif
	if(![NSBundle loadNibNamed:mainModelFile owner:app])
		NSLog(@"Cannot load the main model file '%@'", mainModelFile);
#if 1
	NSLog(@"did load %@", mainModelFile);
#endif
	// FIXME: according to Tiger docu we should already show the menu bar here - if [NSMenu menuBarVisible] is YES
	if(![app mainMenu])
		// should take application name...
		[app setMainMenu:[[NSMenu alloc] initWithTitle:@"Default"]];	// could not load from a NIB, provide a default menu
	else
		[[NSDocumentController sharedDocumentController] _updateOpenRecentMenu];	// create/add/update Open Recent submenu
	// FIXME: why is this done here and not in [NSCursor initialize]?
	// FIXME - how does that interwork with cursor-rects?
	[[NSCursor arrowCursor] push];	// push the arrow as the default cursor
	[app run];
	[pool release];	// empty this pool
	return 0;
}
