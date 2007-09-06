//
//  NSMenuExtra.m
//
//  Created by Dr. H. Nikolaus Schaller on Mon Nov 24 2003.
//  Copyright (c) 2003 DSITRI. All rights reserved.
//

#import <SystemUIPlugin/NSMenuExtra.h>

@interface NSStatusBar(NSAppKitPrivate)
- (NSMenuView *) _menuView;
- (id) _initWithMenuView:(NSMenuView *) v;
- (NSMenu *) _statusMenu;
@end

@interface NSStatusItem(NSAppKitPrivate)
- (NSMenuItem *) _menuItem;
- (id) _initForStatusBar:(NSStatusBar *) bar andMenuItem:(NSMenuItem *) item withLength:(float) len;
@end

@implementation NSMenuExtra

- (id) initWithBundle:(NSBundle *) bundle;
{
	NSMenuItem *item=[[[NSMenuItem alloc] initWithTitle:@"NSMenuExtra" action:NULL keyEquivalent:@""] autorelease];
#if 0
	NSLog(@"this is %@ initWithBundle: %@", NSStringFromClass([self class]), bundle);
#endif
	self=[super _initForStatusBar:[NSStatusBar systemStatusBar] andMenuItem:item withLength:NSVariableStatusItemLength];   // make me control this menu item
	if(self)
		{
		NSString *nib;
		_bundle=bundle;
#if 0
		NSLog(@"add item");
#endif
		[[[NSStatusBar systemStatusBar] _statusMenu] addItem:item];	// attach controlled menuItem to menu
		[self setTarget:self];
		nib=[bundle objectForInfoDictionaryKey:@"NSMainNibFile"];
		if(nib)
			{ // load
#if 0
			NSLog(@"loading NSMenuExtra nib file %@", nib);
#endif
			[bundle loadNibFile:nib externalNameTable:[NSDictionary dictionaryWithObject:self forKey:@"NSOwner"] withZone:NSDefaultMallocZone()];
#if 0
			NSLog(@"loaded NSMenuExtra nib file %@", nib);
#endif
			}
		}
	return self;
}

- (id) initWithBundle:(NSBundle *) bundle data:(NSData *)data;
{
	self=[self initWithBundle:bundle];
	if(self)
		{
		// what does 'data' mean???
		// does it control default position, additional flags?
		}
	return self;
}

- (NSBundle *) bundle; { return _bundle; }

- (void) willUnload; { return; }	// default does nothing

- (BOOL) isMenuDown; { return _flags.menuDown; }

- (void) drawMenuBackground:(BOOL) flag; { return; }	// default does nothing
- (void) popUpMenu:(NSMenu *) menu; { _menu=menu; }

- (void) setImage:(NSImage *) img;
{
	[img setScalesWhenResized:YES];
	[img setSize:NSMakeSize(16.0, 16.0)];	// set default size
	[super setImage:img];
}

@end