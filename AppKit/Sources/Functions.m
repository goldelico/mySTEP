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
#import <AppKit/NSColor.h>


int NSApplicationMain(int argc, const char **argv)
{
	id pool = [NSAutoreleasePool new];	// root ARP
	[[NSApplication sharedApplication] run];	
	[pool release];
	return 0;
}
