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

- (CGFloat) userSpaceScaleFactor;
{ // get dots per point
	return 1.0;
#if 0	
	NSSize dpi=[[[self deviceDescription] objectForKey:NSDeviceResolution] sizeValue];
	return (dpi.width+dpi.height)/144.0;	// take average for 72dpi
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
	// CHECKME: what if we have multiple screens??
	static NSRect vFrame; // cache
	if(vFrame.size.width == 0.0)
		{
		NSRect mb=[self _menuBarFrame];
		NSRect smb=[self _systemMenuBarFrame];
		vFrame=[self frame];
		if(mb.origin.y == 0.0)
			vFrame.origin.y=mb.size.height;		// menu bar is at bottom: visible area begins above menu bar
		if(smb.origin.y > vFrame.origin.y)	// not "very small" mode
			vFrame.size.height=smb.origin.y-vFrame.origin.y;   // visible area between both menu bars
		else
			vFrame.size.height=vFrame.size.height-vFrame.origin.y;   // visible area above both menu bars
		}
#if 0
	NSLog(@"visibleFrame=%@", NSStringFromRect(vFrame));
#endif
	return vFrame;
}

#define SYSTEM_MENU_WIDTH 1.2
#define VERY_SMALL 100.0	// when do we consider a screen too small for a full menu (horiz. size on Points)

- (NSRect) _statusBarFrame;
{ // the system status menu bar (accessed by NSStatusBar)
	NSRect r;
	CGFloat h;
	r=[self frame];	// screen frame
	h=[NSMenuView menuBarHeight];
	r.origin.y=r.size.height-h;
	r.size.height=h;
	if(r.size.width > VERY_SMALL)
		{ // not a very small screen
		r.origin.x=ceilf(SYSTEM_MENU_WIDTH*r.size.height);	// leave room for systemMenu
		r.size.width-=r.origin.x;
		}
#if 0
	NSLog(@"statusBarFrame=%@", NSStringFromRect(r));
#endif
	return r;
}

- (NSRect) _systemMenuBarFrame;
{ // the system menu bar (not accessible directly by applications) - fills space to the left of the statusBar
	NSRect r=[self _statusBarFrame];
	if(r.origin.x == 0)
		{ // bottom left half (VERY_SMALL mode)
		r.origin.y=0;									// system menu bar is at bottom of screen
		r.size.height=[NSMenuView menuBarHeight];
		r.size.width/=2.0;								// width is half of the screen
		}
	else
		{
		r.size.width=r.origin.x;						// fill up room to beginning of statusBarFrame
		r.origin.x=0.0;									// starts at upper left corner
		}
#if 0
	NSLog(@"systemMenuBarFrame=%@", NSStringFromRect(r));
#endif
	return r;
}

- (NSRect) _menuBarFrame;
{ // the application main menu bar (accessed by NSApp setMainMenu)
	NSRect r=[self frame];
	if(r.size.width < r.size.height || r.size.width <= VERY_SMALL)
		{ // portrait mode: application menu bar at bottom of screen
		r.origin.x=0.0;
		r.origin.y=0.0;
		if(r.size.width <= VERY_SMALL)
			{ // pure PDA mode - application menu on right half
			r.size.width/=2.0;								// width is half of the screen
			r.origin.x=ceilf(r.size.width);					// right half of the screen
			}
		}
	else
		{ // landscape mode: at same position as system/status bar
		r=[self _systemMenuBarFrame];
		r.origin.x=r.size.width;					// but start right of the systemMenuBar
		r.size.width=[self frame].size.width-r.origin.x;		// remainder - will be sized to fit
		}
	r.size.height=[NSMenuView menuBarHeight];	// standard height
#if 0
	NSLog(@"menuBarFrame=%@", NSStringFromRect(r));
#endif
	return r;
}

@end /* NSScreen */
