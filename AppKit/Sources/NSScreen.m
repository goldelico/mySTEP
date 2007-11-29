/* 
   NSScreen.m

   Instances of this class encapsulate an X screen

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    July 1999
   
   Author:  Nikolaus Schaller <hns@computer.org>
   Date:    May 2004

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <Foundation/NSDictionary.h>

#import <AppKit/NSScreen.h>
#import <AppKit/NSMenuView.h>

#import "NSAppKitPrivate.h"

@implementation NSScreen

// backend methods

+ (NSArray *) screens			{ return BACKEND; }
- (NSWindowDepth) depth			{ BACKEND; return 0; }
- (const NSWindowDepth *) supportedWindowDepths; { BACKEND; return NULL; }
- (NSDictionary *) deviceDescription	{ return _device; }

// common methods

- (float) userSpaceScaleFactor;
{ // get dots per point
	return 1.0;
#if 0	
	NSSize dpi=[[[self deviceDescription] objectForKey:NSDeviceResolution] sizeValue];
	return (dpi.width+dpi.height)/144;	// take average for 72dpi
#endif
}

- (NSRect) frame
{
	NSValue *val=[[self deviceDescription] objectForKey:NSDeviceSize];
	NSSize size=val?[val sizeValue]:NSMakeSize(640, 480);
	return (NSRect){NSZeroPoint, size};
}

+ (NSScreen *) mainScreen		{ return [[NSApp keyWindow] screen]; }	// may be nil

+ (NSScreen *) deepestScreen	{ return [self mainScreen]; }	// should scan all screens for deepest one

- (NSRect) visibleFrame;
{
	static NSRect vFrame; // cache
	if(vFrame.size.width == 0.0)
		{
		NSRect mb=[self _menuBarFrame];
		vFrame=[self frame];
		if(mb.origin.y == 0.0)
			vFrame.origin.y=mb.size.height;		// menu bar is at bottom: visible area begins above menu bar
		vFrame.size.height=[self _systemMenuBarFrame].origin.y-vFrame.origin.y;   // visible area between both menu bars
		}
#if 0
	NSLog(@"visibleFrame=%@", NSStringFromRect(vFrame));
#endif
	return vFrame;
}

#define __SMARTPHONE_EDITION__ 0
#define SYSTEM_MENU_WIDTH 1.2

- (NSRect) _statusBarFrame;
{ // the system status menu bar (accessed by NSStatusBar)
	NSRect r;
	float h;
#if __SMARTPHONE_EDITION__
	r.origin.y=0;									// system menu bar is at bottom of screen
	r.size.height=[NSMenuView menuBarHeight];
	r.size.width/=2.0;								// width is half of the screen
	r.origin.x=w.size.width;						// right half of the screen
#else
	r=[self frame];	// screen frame
	h=[NSMenuView menuBarHeight];
	r.origin.y=r.size.height-h;
	r.size.height=h;
	r.origin.x=ceil(SYSTEM_MENU_WIDTH*r.size.height);	// leave room for systemMenu
	r.size.width-=r.origin.x;
#endif
#if 0
	NSLog(@"statusBarFrame=%@", NSStringFromRect(r));
#endif
	return r;
}

- (NSRect) _systemMenuBarFrame;
{ // the system menu bar (not accessible directly by applications) - fills space to the left of the statusBar
	NSRect r=[self _statusBarFrame];
	r.size.width=r.origin.x;						// fill up to beginning of statusBarFrame
	r.origin.x=0.0;									// starts at upper left corner
#if 0
	NSLog(@"systemMenuBarFrame=%@", NSStringFromRect(r));
#endif
	return r;
}

- (NSRect) _menuBarFrame;
{ // the application main menu bar (accessed by NSApp setMainMenu)
	NSRect r=[self frame];
	if(r.size.width < r.size.height)
		{ // portrait mode: application menu bar at bottom of screen
		r.origin.x=0.0;
		r.origin.y=0.0;
		}
	else
		{ // landscape mode: at same position as system/status bar
		r=[self _systemMenuBarFrame];
		r.origin.x=r.size.width;					// but start right of the systemMenuBar
		r.size.width=[self frame].size.width-r.origin.x;		// remainder - will be sized to fit
		}
	r.size.height=[NSMenuView menuBarHeight];	// standard height
#if __SMARTPHONE_EDITION__
	r.size.width/=2.0;			// half of screen
	r.origin.x=r.size.width;	// starts in the middle
#endif
#if 0
	NSLog(@"menuBarFrame=%@", NSStringFromRect(r));
#endif
	return r;
}

@end /* NSScreen */