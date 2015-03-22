//
//  NSStatusItem.m
//  myPDA
//
//  Created by Dr. H. Nikolaus Schaller on Sat Apr 05 2003.
//  Copyright (c) 2003 DSITRI. All rights reserved.
//

#import <AppKit/NSStatusItem.h>
#import <AppKit/NSColor.h>
#import "NSAppKitPrivate.h"

@implementation NSStatusItem

- (NSMenuItem *) _menuItem; { return menuItem; }

- (id) _initForStatusBar:(NSStatusBar *) bar andMenuItem:(NSMenuItem *) item withLength:(CGFloat) len;
{
	if((self=[super init]))
		{
#if 1
		NSLog(@"_initForStatusBar:%@ andMenuItem:%@ withLength:%lf", bar, item, len);
#endif
		statusBar=bar;
		menuItem=[item retain];
		[menuItem setRepresentedObject:self];
		[self setLength:len];
		}
	return self;
}

- (void) dealloc;
{
	[menuItem release];
	[super dealloc];
}

- (SEL) action; { return [menuItem action]; }
- (NSAttributedString *) attributedTitle; { return attributedTitle; }
- (BOOL) highlightMode; { return highlightedMode; }
- (NSImage *) image; { return [menuItem image]; }

- (BOOL) isEnabled; { return [menuItem isEnabled]; }
- (CGFloat) length; { return length; }
- (NSMenu *) menu; { return [menuItem submenu]; }
- (void) sendActionOn:(NSInteger) mask; { NIMP }
- (void) setAction:(SEL) action; { [menuItem setAction:action]; }
- (void) setAttributedTitle:(NSAttributedString *) title;  { [attributedTitle autorelease]; attributedTitle=[title retain]; [menuItem setTitle:[title string]]; }
- (void) setEnabled:(BOOL) flag;  { [menuItem setEnabled:flag]; }
- (void) setHighlightMode:(BOOL) highlightMode; { NIMP }
- (void) setImage:(NSImage *) image; { [menuItem setImage:image]; }
- (void) setLength:(CGFloat) l; { length=l; [menuItem _changed]; }

- (void) setMenu:(NSMenu *) menu;
{
#if 0
	NSLog(@"NSStatusItem setMenu:%@", menu); 
#endif
	[menuItem setSubmenu:menu]; 
}

- (void) setTarget:(id) target; { [menuItem setTarget:target]; }

- (void) setTitle:(NSString *) title;
{
	NSDictionary *attributes=[NSDictionary dictionaryWithObjectsAndKeys:
			[NSColor textColor], NSForegroundColorAttributeName,
			[[statusBar _menuView] font], NSFontAttributeName,
			nil];
	NSAttributedString *s=[[[NSAttributedString alloc] initWithString:title attributes:attributes] autorelease];
	[self setAttributedTitle:s];
}

- (void) setToolTip:(NSString *) toolTip; { NIMP }
- (void) setView:(NSView *) v; { [view autorelease]; view=[v retain]; /*[[super menu] itemChanged:self];*/ }
- (NSStatusBar *) statusBar; { return statusBar; }
- (id) target; { return [menuItem target]; }
- (NSString *) title; { return [menuItem title]; }
- (NSString *) toolTip; { return @"no tooltip"; }
- (NSView *) view; { return view; }

@end
