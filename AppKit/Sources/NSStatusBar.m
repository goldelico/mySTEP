//
//  NSStatusBar.m
//  myPDA
//
//  Created by Dr. H. Nikolaus Schaller on Sat Apr 05 2003.
//  Copyright (c) 2003 DSITRI. All rights reserved.
//

#import <AppKit/NSStatusBar.h>
#import <AppKit/NSStatusItem.h>
#import <AppKit/NSWorkspace.h>

#import "NSAppKitPrivate.h"
#import "NSUIServer.h"

@implementation NSStatusBar (NSPrivate)

// private methods

- (NSMenuView *) _menuView; { return menuView; }
- (NSMenu *) _statusMenu; { return [menuView menu]; }

- (id) _initWithMenuView:(NSMenuView *) v
{ // private initializer
	self=[super init];
	if(self)
		{
		menuView=[v retain];
		}
	return self;
}

@end

@implementation NSStatusBar

- (id) init;
{
	self=[super init];
	if(self)
		{
		menuView=nil;
		}
	return self;
}

- (void) dealloc;
{
	[menuView release];
	[super dealloc];
}

+ (NSStatusBar *) systemStatusBar;
{
#if 1
	NSLog(@"NSStatusBar +systemStatusBar");
#endif
	return [[NSWorkspace _distributedWorkspace] systemStatusBar];	// request from distributed server
}

- (BOOL) isVertical; { return ![menuView isHorizontal]; }

- (void) removeStatusItem:(NSStatusItem *) item;
{
	[[self _statusMenu] removeItem:[item _menuItem]];
}

- (NSStatusItem *) statusItemWithLength:(float) length;
{
	NSMenuItem *menuItem=[[[NSMenuItem alloc] initWithTitle:@"?" action:NULL keyEquivalent:@""] autorelease];
	id item=[[[NSStatusItem alloc] _initForStatusBar:(NSStatusBar *) self andMenuItem:menuItem withLength:length] autorelease];
	[[self _statusMenu] addItem:menuItem];	// attach controlled menuitem to menu
	return item;
}

- (float) thickness;
{
	[menuView sizeToFit];
	return [menuView frame].size.height;
}

@end